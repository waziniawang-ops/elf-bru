from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import PickupLocationViewSet

router = DefaultRouter()
router.register('', PickupLocationViewSet, basename='pickup-location')

urlpatterns = [
    path('', include(router.urls)),
]
