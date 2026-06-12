from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import (
    AdminCustomerWishlistView,
    BankDetailsView,
    CartItemDetailView,
    CartItemListCreateView,
    OrderViewSet,
    ReceiptPrintView,
    WishlistItemDetailView,
    WishlistItemListCreateView,
)

router = DefaultRouter()
router.register('sales', OrderViewSet, basename='order')

urlpatterns = [
    path('bank-details/', BankDetailsView.as_view(), name='bank-details'),
    path('cart/', CartItemListCreateView.as_view(), name='cart-list'),
    path('cart/<int:pk>/', CartItemDetailView.as_view(), name='cart-detail'),
    path('wishlist/', WishlistItemListCreateView.as_view(), name='wishlist-list'),
    path('wishlist/<int:pk>/', WishlistItemDetailView.as_view(), name='wishlist-detail'),
    path('customers/<int:customer_id>/wishlist/', AdminCustomerWishlistView.as_view(), name='admin-customer-wishlist'),
    path('sales/<int:pk>/receipt/print/', ReceiptPrintView.as_view(), name='receipt-print'),
    path('', include(router.urls)),
]
