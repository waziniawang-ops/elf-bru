#!/usr/bin/env bash
set -o errexit

pip install -r requirements.txt
python manage.py collectstatic --no-input
python manage.py migrate

# Create default superuser if not present
python manage.py shell -c "
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(phone_number='admin').exists():
    User.objects.create_superuser(phone_number='admin', password='admin123', is_admin=True)
    print('Superuser created: admin / admin123')
else:
    print('Superuser already exists')
"
