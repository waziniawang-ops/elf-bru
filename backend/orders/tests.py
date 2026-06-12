from django.contrib.auth import get_user_model
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from locations.models import PickupLocation
from products.models import Product

User = get_user_model()


class OrderTestBase(APITestCase):
    def setUp(self):
        self.admin = User.objects.create_user(
            phone_number='admin_orders',
            password='admin123',
            is_admin=True,
            is_staff=True,
        )
        self.customer = User.objects.create_user(
            phone_number='0800000001',
            password='pass1234',
        )
        self.product = Product.objects.create(
            name='Lipstick',
            price='25.00',
            quantity=10,
            is_active=True,
        )
        self.location = PickupLocation.objects.create(
            name='Main Store',
            address='123 Main St',
            is_active=True,
        )

    def auth_customer(self):
        resp = self.client.post(reverse('login'), {
            'phone_number': '0800000001',
            'password': 'pass1234',
        })
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {resp.data["access"]}')

    def auth_admin(self):
        resp = self.client.post(reverse('login'), {
            'phone_number': 'admin_orders',
            'password': 'admin123',
        })
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {resp.data["access"]}')


class CartTests(OrderTestBase):
    def test_add_to_cart(self):
        self.auth_customer()
        resp = self.client.post(reverse('cart-list'), {
            'product_id': self.product.pk,
            'quantity': 2,
        })
        self.assertEqual(resp.status_code, status.HTTP_201_CREATED)
        self.assertEqual(resp.data['quantity'], 2)

    def test_get_cart(self):
        self.auth_customer()
        self.client.post(reverse('cart-list'), {'product_id': self.product.pk, 'quantity': 1})
        resp = self.client.get(reverse('cart-list'))
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        results = resp.data.get('results', resp.data)
        self.assertEqual(len(results), 1)

    def test_add_same_product_increases_quantity(self):
        self.auth_customer()
        self.client.post(reverse('cart-list'), {'product_id': self.product.pk, 'quantity': 1})
        self.client.post(reverse('cart-list'), {'product_id': self.product.pk, 'quantity': 2})
        resp = self.client.get(reverse('cart-list'))
        results = resp.data.get('results', resp.data)
        self.assertEqual(results[0]['quantity'], 3)

    def test_remove_from_cart(self):
        self.auth_customer()
        add_resp = self.client.post(reverse('cart-list'), {
            'product_id': self.product.pk,
            'quantity': 1,
        })
        item_id = add_resp.data['id']
        resp = self.client.delete(reverse('cart-detail', kwargs={'pk': item_id}))
        self.assertEqual(resp.status_code, status.HTTP_204_NO_CONTENT)


class WishlistTests(OrderTestBase):
    def test_add_to_wishlist(self):
        self.auth_customer()
        resp = self.client.post(reverse('wishlist-list'), {'product_id': self.product.pk})
        self.assertEqual(resp.status_code, status.HTTP_201_CREATED)

    def test_remove_from_wishlist(self):
        self.auth_customer()
        add_resp = self.client.post(reverse('wishlist-list'), {'product_id': self.product.pk})
        item_id = add_resp.data['id']
        resp = self.client.delete(reverse('wishlist-detail', kwargs={'pk': item_id}))
        self.assertEqual(resp.status_code, status.HTTP_204_NO_CONTENT)


class BankDetailsTests(OrderTestBase):
    def test_get_bank_details_authenticated(self):
        self.auth_customer()
        resp = self.client.get(reverse('bank-details'))
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertIn('bank_name', resp.data)
        self.assertIn('account_number', resp.data)

    def test_get_bank_details_unauthenticated(self):
        resp = self.client.get(reverse('bank-details'))
        self.assertEqual(resp.status_code, status.HTTP_401_UNAUTHORIZED)


class OrderCreateTests(OrderTestBase):
    def _add_to_cart(self, qty=2):
        self.auth_customer()
        self.client.post(reverse('cart-list'), {
            'product_id': self.product.pk,
            'quantity': qty,
        })

    def test_create_order_cash(self):
        self._add_to_cart()
        resp = self.client.post('/api/orders/sales/', {
            'pickup_location_id': self.location.pk,
            'payment_method': 'cash',
        })
        self.assertEqual(resp.status_code, status.HTTP_201_CREATED)
        self.assertEqual(resp.data['status'], 'pending')
        self.product.refresh_from_db()
        self.assertEqual(self.product.quantity, 8)

    def test_create_order_empty_cart(self):
        self.auth_customer()
        resp = self.client.post('/api/orders/sales/', {
            'pickup_location_id': self.location.pk,
            'payment_method': 'cash',
        })
        self.assertEqual(resp.status_code, status.HTTP_400_BAD_REQUEST)

    def test_create_order_bank_transfer_requires_screenshot(self):
        self._add_to_cart()
        resp = self.client.post('/api/orders/sales/', {
            'pickup_location_id': self.location.pk,
            'payment_method': 'bank_transfer',
        })
        self.assertEqual(resp.status_code, status.HTTP_400_BAD_REQUEST)

    def test_cancel_pending_order(self):
        self._add_to_cart()
        create_resp = self.client.post('/api/orders/sales/', {
            'pickup_location_id': self.location.pk,
            'payment_method': 'cash',
        })
        order_id = create_resp.data['id']
        resp = self.client.post(f'/api/orders/sales/{order_id}/cancel/')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(resp.data['status'], 'cancelled')
        self.product.refresh_from_db()
        self.assertEqual(self.product.quantity, 10)

    def test_cannot_cancel_completed_order_as_customer(self):
        from .models import Order
        self._add_to_cart()
        create_resp = self.client.post('/api/orders/sales/', {
            'pickup_location_id': self.location.pk,
            'payment_method': 'cash',
        })
        order_id = create_resp.data['id']
        Order.objects.filter(pk=order_id).update(status='completed')
        resp = self.client.post(f'/api/orders/sales/{order_id}/cancel/')
        self.assertEqual(resp.status_code, status.HTTP_400_BAD_REQUEST)

    def test_list_orders_customer_sees_own(self):
        self._add_to_cart()
        self.client.post('/api/orders/sales/', {
            'pickup_location_id': self.location.pk,
            'payment_method': 'cash',
        })
        resp = self.client.get('/api/orders/sales/')
        results = resp.data.get('results', resp.data)
        self.assertEqual(len(results), 1)

    def test_admin_sees_all_orders(self):
        self._add_to_cart()
        self.client.post('/api/orders/sales/', {
            'pickup_location_id': self.location.pk,
            'payment_method': 'cash',
        })
        self.auth_admin()
        resp = self.client.get('/api/orders/sales/')
        results = resp.data.get('results', resp.data)
        self.assertGreaterEqual(len(results), 1)
