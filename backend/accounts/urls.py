from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView

from .views import (
    AdminCustomerDetailView,
    AdminCustomerListCreateView,
    BlacklistCustomerView,
    ChangePasswordView,
    PhoneTokenObtainPairView,
    ProfileView,
    RegisterView,
)

urlpatterns = [
    path('register/', RegisterView.as_view(), name='register'),
    path('login/', PhoneTokenObtainPairView.as_view(), name='login'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('profile/', ProfileView.as_view(), name='profile'),
    path('change-password/', ChangePasswordView.as_view(), name='change-password'),
    path('customers/', AdminCustomerListCreateView.as_view(), name='admin-customers'),
    path('customers/<int:pk>/', AdminCustomerDetailView.as_view(), name='admin-customer-detail'),
    path('customers/<int:pk>/blacklist/', BlacklistCustomerView.as_view(), name='admin-customer-blacklist'),
]
