from rest_framework import viewsets

from accounts.permissions import IsAdminOrReadOnly, IsNotBlacklisted

from .models import PickupLocation
from .serializers import PickupLocationSerializer


class PickupLocationViewSet(viewsets.ModelViewSet):
    queryset = PickupLocation.objects.all()
    serializer_class = PickupLocationSerializer
    permission_classes = [IsNotBlacklisted, IsAdminOrReadOnly]
    search_fields = ['name', 'address', 'city']
    filterset_fields = ['is_active']

    def get_queryset(self):
        queryset = super().get_queryset()
        user = self.request.user
        is_admin = user.is_admin or user.is_staff or user.is_superuser
        if not is_admin:
            queryset = queryset.filter(is_active=True)
        return queryset
