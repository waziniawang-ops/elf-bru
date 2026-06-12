from django.contrib.auth import get_user_model
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

User = get_user_model()


class AuthSetupMixin:
    def setUp(self):
        self.admin = User.objects.create_user(
            phone_number='admin_test',
            password='admin123',
            is_admin=True,
            is_staff=True,
        )
        self.customer = User.objects.create_user(
            phone_number='0900000001',
            password='pass1234',
            first_name='Alice',
        )

    def get_token(self, phone, password):
        resp = self.client.post(reverse('login'), {'phone_number': phone, 'password': password})
        return resp.data.get('access', '')

    def auth(self, phone='0900000001', password='pass1234'):
        token = self.get_token(phone, password)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')

    def auth_admin(self):
        token = self.get_token('admin_test', 'admin123')
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')


class RegisterTests(APITestCase):
    def test_register_success(self):
        resp = self.client.post(reverse('register'), {
            'phone_number': '0911111111',
            'password': 'pass1234',
            'password_confirm': 'pass1234',
            'first_name': 'Bob',
        })
        self.assertEqual(resp.status_code, status.HTTP_201_CREATED)

    def test_register_duplicate_phone(self):
        User.objects.create_user(phone_number='0922222222', password='pass1234')
        resp = self.client.post(reverse('register'), {
            'phone_number': '0922222222',
            'password': 'pass1234',
            'password_confirm': 'pass1234',
        })
        self.assertEqual(resp.status_code, status.HTTP_400_BAD_REQUEST)

    def test_register_password_mismatch(self):
        resp = self.client.post(reverse('register'), {
            'phone_number': '0933333333',
            'password': 'pass1234',
            'password_confirm': 'different',
        })
        self.assertEqual(resp.status_code, status.HTTP_400_BAD_REQUEST)


class LoginTests(AuthSetupMixin, APITestCase):
    def test_login_success(self):
        resp = self.client.post(reverse('login'), {
            'phone_number': '0900000001',
            'password': 'pass1234',
        })
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertIn('access', resp.data)
        self.assertIn('refresh', resp.data)
        self.assertIn('user', resp.data)

    def test_login_wrong_password(self):
        resp = self.client.post(reverse('login'), {
            'phone_number': '0900000001',
            'password': 'wrongpass',
        })
        self.assertEqual(resp.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_login_blacklisted_user(self):
        self.customer.is_blacklisted = True
        self.customer.save()
        resp = self.client.post(reverse('login'), {
            'phone_number': '0900000001',
            'password': 'pass1234',
        })
        self.assertEqual(resp.status_code, status.HTTP_401_UNAUTHORIZED)


class ProfileTests(AuthSetupMixin, APITestCase):
    def test_get_profile(self):
        self.auth()
        resp = self.client.get(reverse('profile'))
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(resp.data['phone_number'], '0900000001')

    def test_update_profile(self):
        self.auth()
        resp = self.client.patch(reverse('profile'), {'first_name': 'Updated'})
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(resp.data['first_name'], 'Updated')

    def test_profile_requires_auth(self):
        resp = self.client.get(reverse('profile'))
        self.assertEqual(resp.status_code, status.HTTP_401_UNAUTHORIZED)


class ChangePasswordTests(AuthSetupMixin, APITestCase):
    def test_change_password_success(self):
        self.auth()
        resp = self.client.post(reverse('change-password'), {
            'old_password': 'pass1234',
            'new_password': 'newpass999',
            'new_password_confirm': 'newpass999',
        })
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        resp2 = self.client.post(reverse('login'), {
            'phone_number': '0900000001',
            'password': 'pass1234',
        })
        self.assertEqual(resp2.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_change_password_wrong_old(self):
        self.auth()
        resp = self.client.post(reverse('change-password'), {
            'old_password': 'wrongpass',
            'new_password': 'newpass999',
            'new_password_confirm': 'newpass999',
        })
        self.assertEqual(resp.status_code, status.HTTP_400_BAD_REQUEST)

    def test_change_password_mismatch(self):
        self.auth()
        resp = self.client.post(reverse('change-password'), {
            'old_password': 'pass1234',
            'new_password': 'newpass999',
            'new_password_confirm': 'different',
        })
        self.assertEqual(resp.status_code, status.HTTP_400_BAD_REQUEST)


class AdminCustomerTests(AuthSetupMixin, APITestCase):
    def test_list_customers_admin(self):
        self.auth_admin()
        resp = self.client.get(reverse('admin-customers'))
        self.assertEqual(resp.status_code, status.HTTP_200_OK)

    def test_list_customers_forbidden_for_customer(self):
        self.auth()
        resp = self.client.get(reverse('admin-customers'))
        self.assertEqual(resp.status_code, status.HTTP_403_FORBIDDEN)

    def test_create_customer_admin(self):
        self.auth_admin()
        resp = self.client.post(reverse('admin-customers'), {
            'phone_number': '0944444444',
            'password': 'pass1234',
            'first_name': 'New',
        })
        self.assertEqual(resp.status_code, status.HTTP_201_CREATED)

    def test_blacklist_customer(self):
        self.auth_admin()
        resp = self.client.post(
            reverse('admin-customer-blacklist', kwargs={'pk': self.customer.pk})
        )
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.customer.refresh_from_db()
        self.assertTrue(self.customer.is_blacklisted)

    def test_unblacklist_customer(self):
        self.customer.is_blacklisted = True
        self.customer.is_active = False
        self.customer.save()
        self.auth_admin()
        resp = self.client.delete(
            reverse('admin-customer-blacklist', kwargs={'pk': self.customer.pk})
        )
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.customer.refresh_from_db()
        self.assertFalse(self.customer.is_blacklisted)
