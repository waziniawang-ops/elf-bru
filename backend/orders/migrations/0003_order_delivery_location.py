from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('orders', '0002_order_fulfillment'),
    ]

    operations = [
        migrations.AddField(
            model_name='order',
            name='delivery_latitude',
            field=models.DecimalField(
                blank=True, decimal_places=7, max_digits=10, null=True,
            ),
        ),
        migrations.AddField(
            model_name='order',
            name='delivery_longitude',
            field=models.DecimalField(
                blank=True, decimal_places=7, max_digits=10, null=True,
            ),
        ),
    ]
