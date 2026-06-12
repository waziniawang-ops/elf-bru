from django.contrib.auth import get_user_model
from rest_framework import generics, status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .permissions import IsAdminUser, IsNotBlacklisted
from .serializers import (
    AdminUserCreateSerializer,
    AdminUserSerializer,
    PasswordChangeSerializer,
    UserRegistrationSerializer,
    UserSerializer,
)
from .tokens import PhoneTokenObtainPairSerializer

User = get_user_model()


class PhoneTokenObtainPairView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = PhoneTokenObtainPairSerializer(data=request.data, context={'request': request})
        serializer.is_valid(raise_exception=True)
        return Response(serializer.validated_data)


class RegisterView(generics.CreateAPIView):
    serializer_class = UserRegistrationSerializer
    permission_classes = [AllowAny]


class ProfileView(generics.RetrieveUpdateAPIView):
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated, IsNotBlacklisted]

    def get_object(self):
        return self.request.user


class ChangePasswordView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = PasswordChangeSerializer(data=request.data, context={'request': request})
        serializer.is_valid(raise_exception=True)
        request.user.set_password(serializer.validated_data['new_password'])
        request.user.save(update_fields=['password'])
        return Response({'detail': 'Password changed successfully.'})


class AdminCustomerListCreateView(generics.ListCreateAPIView):
    permission_classes = [IsAuthenticated, IsAdminUser]

    def get_queryset(self):
        return User.objects.filter(is_admin=False, is_superuser=False)

    def get_serializer_class(self):
        if self.request.method == 'POST':
            return AdminUserCreateSerializer
        return AdminUserSerializer


class AdminCustomerDetailView(generics.RetrieveUpdateDestroyAPIView):
    permission_classes = [IsAuthenticated, IsAdminUser]
    serializer_class = AdminUserSerializer

    def get_queryset(self):
        return User.objects.filter(is_admin=False, is_superuser=False)


class BlacklistCustomerView(APIView):
    permission_classes = [IsAuthenticated, IsAdminUser]

    def post(self, request, pk):
        try:
            customer = User.objects.get(pk=pk, is_admin=False, is_superuser=False)
        except User.DoesNotExist:
            return Response({'detail': 'Customer not found.'}, status=status.HTTP_404_NOT_FOUND)
        customer.is_blacklisted = True
        customer.is_active = False
        customer.save(update_fields=['is_blacklisted', 'is_active', 'updated_at'])
        return Response(AdminUserSerializer(customer).data)

    def delete(self, request, pk):
        try:
            customer = User.objects.get(pk=pk, is_admin=False, is_superuser=False)
        except User.DoesNotExist:
            return Response({'detail': 'Customer not found.'}, status=status.HTTP_404_NOT_FOUND)
        customer.is_blacklisted = False
        customer.is_active = True
        customer.save(update_fields=['is_blacklisted', 'is_active', 'updated_at'])
        return Response(AdminUserSerializer(customer).data)
