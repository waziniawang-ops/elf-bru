from rest_framework import serializers

from .models import Product


class ProductSerializer(serializers.ModelSerializer):
    in_stock = serializers.ReadOnlyField()
    is_on_sale = serializers.ReadOnlyField()
    sale_price = serializers.ReadOnlyField()

    class Meta:
        model = Product
        fields = [
            'id',
            'name',
            'description',
            'price',
            'quantity',
            'category',
            'image',
            'is_active',
            'in_stock',
            'discount_percentage',
            'is_on_sale',
            'sale_price',
            'created_at',
            'updated_at',
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']
