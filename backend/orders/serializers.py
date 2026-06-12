from rest_framework import serializers

from products.models import Product
from products.serializers import ProductSerializer

from .models import CartItem, Order, OrderItem, WishlistItem


class CartItemSerializer(serializers.ModelSerializer):
    product = ProductSerializer(read_only=True)
    product_id = serializers.PrimaryKeyRelatedField(
        queryset=Product.objects.filter(is_active=True),
        source='product',
        write_only=True,
    )
    subtotal = serializers.ReadOnlyField()

    class Meta:
        model = CartItem
        fields = ['id', 'product', 'product_id', 'quantity', 'subtotal', 'created_at', 'updated_at']
        read_only_fields = ['id', 'created_at', 'updated_at']


class WishlistItemSerializer(serializers.ModelSerializer):
    product = ProductSerializer(read_only=True)
    product_id = serializers.PrimaryKeyRelatedField(
        queryset=Product.objects.filter(is_active=True),
        source='product',
        write_only=True,
    )

    class Meta:
        model = WishlistItem
        fields = ['id', 'product', 'product_id', 'created_at']
        read_only_fields = ['id', 'created_at']


class OrderItemSerializer(serializers.ModelSerializer):
    subtotal = serializers.ReadOnlyField()

    class Meta:
        model = OrderItem
        fields = ['id', 'product', 'product_name', 'unit_price', 'quantity', 'subtotal']
        read_only_fields = fields


class OrderSerializer(serializers.ModelSerializer):
    items = OrderItemSerializer(many=True, read_only=True)
    customer_name = serializers.CharField(source='customer.full_name', read_only=True)
    customer_phone = serializers.CharField(source='customer.phone_number', read_only=True)
    pickup_location_name = serializers.CharField(source='pickup_location.name', read_only=True)
    payment_screenshot_url = serializers.SerializerMethodField()

    class Meta:
        model = Order
        fields = [
            'id',
            'customer',
            'customer_name',
            'customer_phone',
            'pickup_location',
            'pickup_location_name',
            'payment_method',
            'payment_screenshot',
            'payment_screenshot_url',
            'status',
            'total_amount',
            'notes',
            'items',
            'created_at',
            'updated_at',
        ]
        read_only_fields = ['id', 'customer', 'total_amount', 'created_at', 'updated_at']

    def get_payment_screenshot_url(self, obj):
        if not obj.payment_screenshot:
            return None
        request = self.context.get('request')
        try:
            url = obj.payment_screenshot.url
            if request and not url.startswith('http'):
                return request.build_absolute_uri(url)
            return url
        except Exception:
            return None


class OrderCreateSerializer(serializers.Serializer):
    pickup_location_id = serializers.IntegerField()
    payment_method = serializers.ChoiceField(choices=Order.PaymentMethod.choices)
    payment_screenshot = serializers.ImageField(required=False, allow_null=True)
    notes = serializers.CharField(required=False, allow_blank=True)

    def validate(self, attrs):
        if attrs['payment_method'] == Order.PaymentMethod.BANK_TRANSFER and not attrs.get('payment_screenshot'):
            raise serializers.ValidationError({
                'payment_screenshot': 'Payment screenshot is required for bank transfers.',
            })
        return attrs

    def validate_pickup_location_id(self, value):
        from locations.models import PickupLocation
        if not PickupLocation.objects.filter(pk=value, is_active=True).exists():
            raise serializers.ValidationError('Invalid pickup location.')
        return value
