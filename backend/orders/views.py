from django.conf import settings
from django.db import transaction
from django.http import HttpResponse
from django.shortcuts import get_object_or_404, render
from django.template.loader import render_to_string
from rest_framework import generics, status, viewsets
from rest_framework.decorators import action
from rest_framework.parsers import FormParser, JSONParser, MultiPartParser
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from accounts.permissions import IsAdminUser, IsNotBlacklisted
from locations.models import PickupLocation
from products.models import Product

from .models import CartItem, Order, OrderItem, WishlistItem
from .serializers import (
    CartItemSerializer,
    OrderCreateSerializer,
    OrderSerializer,
    WishlistItemSerializer,
)


class CartItemListCreateView(generics.ListCreateAPIView):
    serializer_class = CartItemSerializer
    permission_classes = [IsAuthenticated, IsNotBlacklisted]

    def get_queryset(self):
        return CartItem.objects.filter(user=self.request.user).select_related('product')

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        product = serializer.validated_data['product']
        quantity = serializer.validated_data.get('quantity', 1)
        cart_item, created = CartItem.objects.get_or_create(
            user=request.user,
            product=product,
            defaults={'quantity': quantity},
        )
        if not created:
            cart_item.quantity += quantity
            cart_item.save(update_fields=['quantity', 'updated_at'])
        output = CartItemSerializer(cart_item)
        return Response(output.data, status=status.HTTP_201_CREATED)


class CartItemDetailView(generics.RetrieveUpdateDestroyAPIView):
    serializer_class = CartItemSerializer
    permission_classes = [IsAuthenticated, IsNotBlacklisted]

    def get_queryset(self):
        return CartItem.objects.filter(user=self.request.user).select_related('product')


class WishlistItemListCreateView(generics.ListCreateAPIView):
    serializer_class = WishlistItemSerializer
    permission_classes = [IsAuthenticated, IsNotBlacklisted]

    def get_queryset(self):
        return WishlistItem.objects.filter(user=self.request.user).select_related('product')

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class WishlistItemDetailView(generics.DestroyAPIView):
    serializer_class = WishlistItemSerializer
    permission_classes = [IsAuthenticated, IsNotBlacklisted]

    def get_queryset(self):
        return WishlistItem.objects.filter(user=self.request.user).select_related('product')


class AdminCustomerWishlistView(generics.ListAPIView):
    serializer_class = WishlistItemSerializer
    permission_classes = [IsAuthenticated, IsAdminUser]

    def get_queryset(self):
        customer_id = self.kwargs['customer_id']
        return WishlistItem.objects.filter(user_id=customer_id).select_related('product', 'user')


class BankDetailsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        return Response({
            'bank_name': settings.BANK_NAME,
            'account_name': settings.BANK_ACCOUNT_NAME,
            'account_number': settings.BANK_ACCOUNT_NUMBER,
            'instructions': settings.BANK_INSTRUCTIONS,
        })


class OrderViewSet(viewsets.ModelViewSet):
    serializer_class = OrderSerializer
    permission_classes = [IsAuthenticated, IsNotBlacklisted]
    parser_classes = [MultiPartParser, FormParser, JSONParser]
    filterset_fields = ['status', 'payment_method']
    search_fields = ['customer__phone_number', 'customer__first_name', 'customer__last_name']
    ordering_fields = ['created_at', 'total_amount']

    def get_queryset(self):
        user = self.request.user
        queryset = Order.objects.select_related('customer', 'pickup_location').prefetch_related('items')
        if user.is_admin or user.is_staff or user.is_superuser:
            return queryset
        return queryset.filter(customer=user)

    def get_permissions(self):
        if self.action in ['create', 'list', 'retrieve', 'cancel', 'receipt']:
            return [IsAuthenticated(), IsNotBlacklisted()]
        return [IsAuthenticated(), IsAdminUser()]

    def get_serializer_context(self):
        context = super().get_serializer_context()
        context['request'] = self.request
        return context

    @transaction.atomic
    def create(self, request, *args, **kwargs):
        serializer = OrderCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        cart_items = CartItem.objects.filter(user=request.user).select_related('product')
        if not cart_items.exists():
            return Response({'detail': 'Your cart is empty.'}, status=status.HTTP_400_BAD_REQUEST)

        for item in cart_items:
            if item.quantity > item.product.quantity:
                return Response(
                    {
                        'detail': (
                            f'Insufficient stock for {item.product.name}. '
                            f'Available: {item.product.quantity}'
                        ),
                    },
                    status=status.HTTP_400_BAD_REQUEST,
                )

        pickup_location = get_object_or_404(PickupLocation, pk=data['pickup_location_id'], is_active=True)
        order = Order.objects.create(
            customer=request.user,
            pickup_location=pickup_location,
            payment_method=data['payment_method'],
            payment_screenshot=data.get('payment_screenshot'),
            notes=data.get('notes', ''),
            status=Order.Status.PENDING,
        )

        total = 0
        for cart_item in cart_items:
            product = cart_item.product
            OrderItem.objects.create(
                order=order,
                product=product,
                product_name=product.name,
                unit_price=product.price,
                quantity=cart_item.quantity,
            )
            product.quantity -= cart_item.quantity
            product.save(update_fields=['quantity', 'updated_at'])
            total += product.price * cart_item.quantity

        order.total_amount = total
        order.save(update_fields=['total_amount', 'updated_at'])
        cart_items.delete()

        return Response(
            OrderSerializer(order, context={'request': request}).data,
            status=status.HTTP_201_CREATED,
        )

    @action(detail=True, methods=['post'])
    @transaction.atomic
    def cancel(self, request, pk=None):
        order = self.get_object()
        user = request.user
        is_admin = user.is_admin or user.is_staff or user.is_superuser

        if order.status == Order.Status.CANCELLED:
            return Response(
                {'detail': 'Order is already cancelled.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if not is_admin and order.status != Order.Status.PENDING:
            return Response(
                {'detail': 'Only pending orders can be cancelled.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        for item in order.items.select_related('product'):
            item.product.quantity += item.quantity
            item.product.save(update_fields=['quantity', 'updated_at'])

        order.status = Order.Status.CANCELLED
        order.save(update_fields=['status', 'updated_at'])
        return Response(OrderSerializer(order, context={'request': request}).data)

    @action(detail=True, methods=['get'], url_path='receipt')
    def receipt(self, request, pk=None):
        order = self.get_object()
        html = render_to_string('orders/receipt.html', {'order': order})
        if request.query_params.get('format') == 'html':
            return HttpResponse(html)
        return Response({'html': html, 'order': OrderSerializer(order, context={'request': request}).data})


class ReceiptPrintView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        user = request.user
        if user.is_admin or user.is_staff or user.is_superuser:
            order = get_object_or_404(Order.objects.prefetch_related('items'), pk=pk)
        else:
            order = get_object_or_404(
                Order.objects.prefetch_related('items'),
                pk=pk,
                customer=user,
            )
        return render(request, 'orders/receipt.html', {'order': order})
