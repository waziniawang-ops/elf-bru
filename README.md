# Elf Bru — Beauty & Retail Shop

Full-stack shop app for **Elf Bru** with a **Django REST API** backend and **Flutter** frontend for customers and admin.

## Features

### Customer app
- Register & login with **phone number + password**
- Browse products, view details
- Add to **cart** or **wishlist**
- Checkout with **cash** or **bank transfer**
- Upload **payment screenshot** for bank transfers
- View order history and receipts

### Admin portal
- CRUD **products** (details, price, quantity, images)
- CRUD **pickup locations**
- CRUD **sales/orders** and update status
- **Print/view receipts**
- CRUD **customers**
- **Blacklist** customers
- View any customer's **wishlist**

---

## Quick start

### 1. Backend (Django)

```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python manage.py migrate
python manage.py createsuperuser   # use phone number as login
python manage.py runserver
```

Default admin created during setup:
- **Phone:** `admin`
- **Password:** `admin123`

API base URL: `http://127.0.0.1:8000/api/`

### 2. Frontend (Flutter)

```bash
cd frontend
flutter pub get
flutter run -d chrome    # or linux / android / ios
```

**API URL config** is in `frontend/lib/config/api_config.dart`:
- Desktop/Web: `127.0.0.1:8000`
- Android emulator: `10.0.2.2:8000`

---

## API overview

| Endpoint | Description |
|----------|-------------|
| `POST /api/auth/register/` | Customer registration |
| `POST /api/auth/login/` | Login (returns JWT) |
| `GET /api/products/` | List products |
| `GET /api/locations/` | List pickup locations |
| `GET/POST /api/orders/cart/` | Cart |
| `GET/POST /api/orders/wishlist/` | Wishlist |
| `POST /api/orders/sales/` | Place order (multipart for payment screenshot) |
| `GET /api/auth/customers/` | Admin: list customers |
| `GET /api/orders/customers/{id}/wishlist/` | Admin: customer wishlist |

Receipt HTML: `GET /api/orders/sales/{id}/receipt/print/` (requires auth)

---

## Project structure

```
elf_bru/
├── backend/          # Django + DRF
│   ├── accounts/     # Phone auth, customers, blacklist
│   ├── products/     # Product catalog
│   ├── locations/    # Pickup locations
│   └── orders/       # Cart, wishlist, sales, receipts
└── frontend/         # Flutter app (customer + admin)
    └── lib/
        ├── screens/customer/
        └── screens/admin/
```

---

## Production notes

1. Set `SECRET_KEY`, `DEBUG=False`, and `ALLOWED_HOSTS` in environment or `.env`
2. Use PostgreSQL instead of SQLite
3. Serve media files via nginx/S3
4. Use HTTPS and restrict `CORS_ALLOWED_ORIGINS`
5. Change the default admin password immediately
