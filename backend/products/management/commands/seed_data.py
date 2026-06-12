from django.core.management.base import BaseCommand

from locations.models import PickupLocation
from products.models import Product


class Command(BaseCommand):
    help = 'Load sample products and pickup locations'

    def handle(self, *args, **options):
        products = [
            {
                'name': 'Matte Lipstick — Rose',
                'description': 'Long-lasting matte lipstick in a classic rose shade.',
                'price': '18.99',
                'quantity': 25,
                'category': 'Makeup',
            },
            {
                'name': 'Hydrating Foundation',
                'description': 'Lightweight foundation with SPF 15.',
                'price': '32.50',
                'quantity': 15,
                'category': 'Makeup',
            },
            {
                'name': 'Volume Mascara',
                'description': 'Smudge-proof mascara for full lashes.',
                'price': '14.99',
                'quantity': 30,
                'category': 'Makeup',
            },
            {
                'name': 'Makeup Brush Set',
                'description': '10-piece professional brush set with pouch.',
                'price': '45.00',
                'quantity': 10,
                'category': 'Accessories',
            },
        ]

        for item in products:
            Product.objects.update_or_create(name=item['name'], defaults=item)

        PickupLocation.objects.update_or_create(
            name='Main Store',
            defaults={
                'address': '123 Beauty Lane',
                'city': 'Downtown',
                'phone': '555-0100',
                'notes': 'Open Mon–Sat 10am–6pm',
            },
        )

        self.stdout.write(self.style.SUCCESS('Sample data loaded.'))
