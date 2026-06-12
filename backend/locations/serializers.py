from rest_framework import serializers

from .models import PickupLocation


class PickupLocationSerializer(serializers.ModelSerializer):
    class Meta:
        model = PickupLocation
        fields = [
            'id',
            'name',
            'address',
            'city',
            'phone',
            'notes',
            'is_active',
            'created_at',
            'updated_at',
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']
