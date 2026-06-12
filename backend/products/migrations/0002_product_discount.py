from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('products', '0001_initial'),
    ]

    operations = [
        migrations.AddField(
            model_name='product',
            name='discount_percentage',
            field=models.DecimalField(
                decimal_places=2,
                default=0,
                help_text='Discount percentage 0–100 (0 = no sale)',
                max_digits=5,
            ),
        ),
    ]
