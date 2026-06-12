class UserModel {
  final int id;
  final String phoneNumber;
  final String firstName;
  final String lastName;
  final String fullName;
  final String email;
  final bool isAdmin;
  final bool isBlacklisted;
  final bool isActive;

  UserModel({
    required this.id,
    required this.phoneNumber,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.email,
    required this.isAdmin,
    this.isBlacklisted = false,
    this.isActive = true,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      phoneNumber: json['phone_number'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      isAdmin: json['is_admin'] as bool? ?? false,
      isBlacklisted: json['is_blacklisted'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'phone_number': phoneNumber,
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
      };
}

class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final int quantity;
  final String category;
  final String? image;
  final bool isActive;
  final bool inStock;
  final double discountPercentage;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.quantity,
    required this.category,
    this.image,
    required this.isActive,
    required this.inStock,
    this.discountPercentage = 0,
  });

  bool get isOnSale => discountPercentage > 0;
  double get salePrice => isOnSale ? price * (1 - discountPercentage / 100) : price;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: double.parse(json['price'].toString()),
      quantity: json['quantity'] as int? ?? 0,
      category: json['category'] as String? ?? '',
      image: json['image'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      inStock: json['in_stock'] as bool? ?? false,
      discountPercentage: double.parse((json['discount_percentage'] ?? '0').toString()),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'price': price.toStringAsFixed(2),
        'quantity': quantity,
        'category': category,
        'is_active': isActive,
      };
}

class PickupLocation {
  final int id;
  final String name;
  final String address;
  final String city;
  final String phone;
  final String notes;
  final bool isActive;

  PickupLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.phone,
    required this.notes,
    required this.isActive,
  });

  factory PickupLocation.fromJson(Map<String, dynamic> json) {
    return PickupLocation(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'address': address,
        'city': city,
        'phone': phone,
        'notes': notes,
        'is_active': isActive,
      };
}

class CartItem {
  final int id;
  final Product product;
  final int quantity;
  final double subtotal;

  CartItem({
    required this.id,
    required this.product,
    required this.quantity,
    required this.subtotal,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as int,
      product: Product.fromJson(json['product'] as Map<String, dynamic>),
      quantity: json['quantity'] as int? ?? 1,
      subtotal: double.parse(json['subtotal'].toString()),
    );
  }
}

class WishlistItem {
  final int id;
  final Product product;

  WishlistItem({required this.id, required this.product});

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    return WishlistItem(
      id: json['id'] as int,
      product: Product.fromJson(json['product'] as Map<String, dynamic>),
    );
  }
}

class OrderItem {
  final int id;
  final String productName;
  final double unitPrice;
  final int quantity;
  final double subtotal;

  OrderItem({
    required this.id,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as int,
      productName: json['product_name'] as String? ?? '',
      unitPrice: double.parse(json['unit_price'].toString()),
      quantity: json['quantity'] as int? ?? 0,
      subtotal: double.parse(json['subtotal'].toString()),
    );
  }
}

class Order {
  final int id;
  final int customerId;
  final String customerName;
  final String customerPhone;
  final int? pickupLocationId;
  final String? pickupLocationName;
  final String fulfillmentMethod;
  final double deliveryCharge;
  final String paymentMethod;
  final String? paymentScreenshot;
  final String? paymentScreenshotUrl;
  final String status;
  final double totalAmount;
  final String notes;
  final List<OrderItem> items;
  final DateTime? createdAt;

  Order({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    this.pickupLocationId,
    this.pickupLocationName,
    required this.fulfillmentMethod,
    required this.deliveryCharge,
    required this.paymentMethod,
    this.paymentScreenshot,
    this.paymentScreenshotUrl,
    required this.status,
    required this.totalAmount,
    required this.notes,
    required this.items,
    this.createdAt,
  });

  bool get isDelivery => fulfillmentMethod == 'delivery';

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as int,
      customerId: json['customer'] as int? ?? 0,
      customerName: json['customer_name'] as String? ?? '',
      customerPhone: json['customer_phone'] as String? ?? '',
      pickupLocationId: json['pickup_location'] as int?,
      pickupLocationName: json['pickup_location_name'] as String?,
      fulfillmentMethod: json['fulfillment_method'] as String? ?? 'pickup',
      deliveryCharge: double.parse((json['delivery_charge'] ?? '0').toString()),
      paymentMethod: json['payment_method'] as String? ?? '',
      paymentScreenshot: json['payment_screenshot'] as String?,
      paymentScreenshotUrl: json['payment_screenshot_url'] as String?,
      status: json['status'] as String? ?? '',
      totalAmount: double.parse(json['total_amount'].toString()),
      notes: json['notes'] as String? ?? '',
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  String get paymentMethodLabel =>
      paymentMethod == 'bank_transfer' ? 'Bank Transfer' : 'Cash';

  String get fulfillmentLabel =>
      fulfillmentMethod == 'delivery' ? 'Delivery' : 'Pickup';

  String get statusLabel {
    switch (status) {
      case 'confirmed':
        return 'Confirmed';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Pending';
    }
  }

  String? get effectiveScreenshotUrl => paymentScreenshotUrl ?? paymentScreenshot;
}

class BankDetails {
  final String bankName;
  final String accountName;
  final String accountNumber;
  final String instructions;

  const BankDetails({
    required this.bankName,
    required this.accountName,
    required this.accountNumber,
    required this.instructions,
  });

  const BankDetails.empty()
      : bankName = '',
        accountName = '',
        accountNumber = '',
        instructions = '';

  factory BankDetails.fromJson(Map<String, dynamic> json) {
    return BankDetails(
      bankName: json['bank_name'] as String? ?? '',
      accountName: json['account_name'] as String? ?? '',
      accountNumber: json['account_number'] as String? ?? '',
      instructions: json['instructions'] as String? ?? '',
    );
  }

  bool get isEmpty =>
      bankName.isEmpty && accountName.isEmpty && accountNumber.isEmpty;
}

class PaginatedResponse<T> {
  final int count;
  final List<T> results;

  PaginatedResponse({required this.count, required this.results});
}
