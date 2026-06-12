from django.contrib import admin

from .models import PickupLocation


@admin.register(PickupLocation)
class PickupLocationAdmin(admin.ModelAdmin):
    list_display = ('name', 'city', 'phone', 'is_active')
    list_filter = ('is_active', 'city')
    search_fields = ('name', 'address')
