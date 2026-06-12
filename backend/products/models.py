from decimal import Decimal

from django.db import models


class Product(models.Model):
    name = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    price = models.DecimalField(max_digits=10, decimal_places=2)
    quantity = models.PositiveIntegerField(default=0)
    category = models.CharField(max_length=100, blank=True)
    image = models.ImageField(upload_to='products/', blank=True, null=True)
    is_active = models.BooleanField(default=True)
    discount_percentage = models.DecimalField(
        max_digits=5, decimal_places=2, default=0,
        help_text='Discount percentage 0–100 (0 = no sale)',
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['name']

    def __str__(self):
        return self.name

    @property
    def in_stock(self):
        return self.quantity > 0

    @property
    def is_on_sale(self):
        return self.discount_percentage > 0

    @property
    def sale_price(self):
        if not self.is_on_sale:
            return self.price
        return round(self.price * (1 - self.discount_percentage / Decimal('100')), 2)
