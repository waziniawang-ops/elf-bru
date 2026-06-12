from rest_framework import viewsets

from accounts.permissions import IsAdminOrReadOnly, IsNotBlacklisted

from .models import Product
from .serializers import ProductSerializer


class ProductViewSet(viewsets.ModelViewSet):
    queryset = Product.objects.all()
    serializer_class = ProductSerializer
    permission_classes = [IsNotBlacklisted, IsAdminOrReadOnly]
    search_fields = ['name', 'description', 'category']
    filterset_fields = ['category', 'is_active']
    ordering_fields = ['name', 'price', 'created_at']

    def get_queryset(self):
        queryset = super().get_queryset()
        user = self.request.user
        is_admin = user.is_admin or user.is_staff or user.is_superuser
        if not is_admin:
            queryset = queryset.filter(is_active=True)
        return queryset
