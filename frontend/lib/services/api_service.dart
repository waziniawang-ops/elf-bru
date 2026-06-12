import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/models.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  late final Dio _dio;
  String? _accessToken;

  void init() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_accessToken != null) {
          options.headers['Authorization'] = 'Bearer $_accessToken';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401 &&
            _accessToken != null &&
            error.requestOptions.extra['retried'] != true) {
          final refreshed = await _refreshToken();
          if (refreshed) {
            final opts = error.requestOptions;
            opts.headers['Authorization'] = 'Bearer $_accessToken';
            opts.extra['retried'] = true;
            try {
              final response = await _dio.fetch(opts);
              return handler.resolve(response);
            } catch (_) {}
          }
        }
        handler.next(error);
      },
    ));
  }

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
  }

  Future<void> _saveTokens(String access, String refresh) async {
    _accessToken = access;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', access);
    await prefs.setString('refresh_token', refresh);
  }

  Future<void> clearTokens() async {
    _accessToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_json');
  }

  Future<bool> _refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refresh = prefs.getString('refresh_token');
    if (refresh == null) return false;
    try {
      final response = await Dio().post(
        '${ApiConfig.baseUrl}/auth/token/refresh/',
        data: {'refresh': refresh},
      );
      final access = response.data['access'] as String;
      await prefs.setString('access_token', access);
      _accessToken = access;
      return true;
    } catch (_) {
      return false;
    }
  }

  String _extractError(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      if (data['detail'] != null) return data['detail'].toString();
      final messages = <String>[];
      data.forEach((key, value) {
        if (value is List) {
          messages.add('$key: ${value.join(', ')}');
        } else {
          messages.add('$key: $value');
        }
      });
      if (messages.isNotEmpty) return messages.join('\n');
    }
    return e.message ?? 'Request failed';
  }

  Future<T> _handle<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } on DioException catch (e) {
      throw ApiException(_extractError(e));
    }
  }

  /// Fetches all pages of a paginated endpoint, following `next` links.
  Future<List<T>> _fetchAll<T>(
    String path,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, dynamic>? params,
  }) async {
    return _handle(() async {
      final results = <T>[];
      var response = await _dio.get(path, queryParameters: params);
      while (true) {
        final data = response.data;
        if (data is Map) {
          final items = (data['results'] as List? ?? []);
          results.addAll(items.map((e) => fromJson(e as Map<String, dynamic>)));
          final next = data['next'] as String?;
          if (next == null) break;
          response = await _dio.getUri(Uri.parse(next));
        } else {
          results.addAll(
            (data as List).map((e) => fromJson(e as Map<String, dynamic>)),
          );
          break;
        }
      }
      return results;
    });
  }

  // ── Auth ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> login(String phone, String password) async {
    return _handle(() async {
      final response = await _dio.post('/auth/login/', data: {
        'phone_number': phone,
        'password': password,
      });
      await _saveTokens(
        response.data['access'] as String,
        response.data['refresh'] as String,
      );
      return response.data as Map<String, dynamic>;
    });
  }

  Future<UserModel> register({
    required String phone,
    required String password,
    required String passwordConfirm,
    String firstName = '',
    String lastName = '',
    String email = '',
  }) async {
    return _handle(() async {
      await _dio.post('/auth/register/', data: {
        'phone_number': phone,
        'password': password,
        'password_confirm': passwordConfirm,
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
      });
      final loginData = await login(phone, password);
      return UserModel.fromJson(loginData['user'] as Map<String, dynamic>);
    });
  }

  Future<UserModel> getProfile() async {
    return _handle(() async {
      final response = await _dio.get('/auth/profile/');
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    });
  }

  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    return _handle(() async {
      final response = await _dio.patch('/auth/profile/', data: data);
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    });
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
    required String newPasswordConfirm,
  }) async {
    return _handle(() async {
      await _dio.post('/auth/change-password/', data: {
        'old_password': oldPassword,
        'new_password': newPassword,
        'new_password_confirm': newPasswordConfirm,
      });
    });
  }

  // ── Products ──────────────────────────────────────────────────────────────

  Future<List<Product>> getProducts({String? search, String? category}) async {
    return _fetchAll(
      '/products/',
      Product.fromJson,
      params: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (category != null && category.isNotEmpty) 'category': category,
      },
    );
  }

  Future<Product> createProduct(
    Map<String, dynamic> data, {
    File? image,
    List<int>? imageBytes,
    String? imageFilename,
  }) async {
    return _handle(() async {
      final formData = FormData.fromMap({
        ...data,
        if (image != null)
          'image': await MultipartFile.fromFile(image.path, filename: imageFilename ?? 'product.jpg'),
        if (imageBytes != null)
          'image': MultipartFile.fromBytes(imageBytes, filename: imageFilename ?? 'product.jpg'),
      });
      final response = await _dio.post('/products/', data: formData);
      return Product.fromJson(response.data as Map<String, dynamic>);
    });
  }

  Future<Product> updateProduct(
    int id,
    Map<String, dynamic> data, {
    File? image,
    List<int>? imageBytes,
    String? imageFilename,
  }) async {
    return _handle(() async {
      final formData = FormData.fromMap({
        ...data,
        if (image != null)
          'image': await MultipartFile.fromFile(image.path, filename: imageFilename ?? 'product.jpg'),
        if (imageBytes != null)
          'image': MultipartFile.fromBytes(imageBytes, filename: imageFilename ?? 'product.jpg'),
      });
      final response = await _dio.patch('/products/$id/', data: formData);
      return Product.fromJson(response.data as Map<String, dynamic>);
    });
  }

  Future<void> deleteProduct(int id) async {
    return _handle(() async => _dio.delete('/products/$id/'));
  }

  // ── Locations ─────────────────────────────────────────────────────────────

  Future<List<PickupLocation>> getLocations() async {
    return _fetchAll('/locations/', PickupLocation.fromJson);
  }

  Future<PickupLocation> createLocation(Map<String, dynamic> data) async {
    return _handle(() async {
      final response = await _dio.post('/locations/', data: data);
      return PickupLocation.fromJson(response.data as Map<String, dynamic>);
    });
  }

  Future<PickupLocation> updateLocation(int id, Map<String, dynamic> data) async {
    return _handle(() async {
      final response = await _dio.patch('/locations/$id/', data: data);
      return PickupLocation.fromJson(response.data as Map<String, dynamic>);
    });
  }

  Future<void> deleteLocation(int id) async {
    return _handle(() async => _dio.delete('/locations/$id/'));
  }

  // ── Cart ──────────────────────────────────────────────────────────────────

  Future<List<CartItem>> getCart() async {
    return _fetchAll('/orders/cart/', CartItem.fromJson);
  }

  Future<void> addToCart(int productId, {int quantity = 1}) async {
    return _handle(() async {
      await _dio.post('/orders/cart/', data: {
        'product_id': productId,
        'quantity': quantity,
      });
    });
  }

  Future<void> updateCartItem(int id, int quantity) async {
    return _handle(() async {
      await _dio.patch('/orders/cart/$id/', data: {'quantity': quantity});
    });
  }

  Future<void> removeFromCart(int id) async {
    return _handle(() async => _dio.delete('/orders/cart/$id/'));
  }

  // ── Wishlist ──────────────────────────────────────────────────────────────

  Future<List<WishlistItem>> getWishlist() async {
    return _fetchAll('/orders/wishlist/', WishlistItem.fromJson);
  }

  Future<void> addToWishlist(int productId) async {
    return _handle(() async {
      await _dio.post('/orders/wishlist/', data: {'product_id': productId});
    });
  }

  Future<void> removeFromWishlist(int id) async {
    return _handle(() async => _dio.delete('/orders/wishlist/$id/'));
  }

  Future<List<WishlistItem>> getCustomerWishlist(int customerId) async {
    return _fetchAll(
      '/orders/customers/$customerId/wishlist/',
      WishlistItem.fromJson,
    );
  }

  // ── Orders / Sales ────────────────────────────────────────────────────────

  Future<List<Order>> getOrders({String? search, String? status}) async {
    return _fetchAll(
      '/orders/sales/',
      Order.fromJson,
      params: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );
  }

  Future<Order> getOrder(int id) async {
    return _handle(() async {
      final response = await _dio.get('/orders/sales/$id/');
      return Order.fromJson(response.data as Map<String, dynamic>);
    });
  }

  Future<Order> createOrder({
    required int pickupLocationId,
    required String paymentMethod,
    File? paymentScreenshot,
    List<int>? paymentScreenshotBytes,
    String? paymentScreenshotName,
    String notes = '',
  }) async {
    return _handle(() async {
      final map = <String, dynamic>{
        'pickup_location_id': pickupLocationId,
        'payment_method': paymentMethod,
        'notes': notes,
      };
      if (paymentScreenshot != null) {
        map['payment_screenshot'] = await MultipartFile.fromFile(
          paymentScreenshot.path,
          filename: paymentScreenshotName ?? 'payment.jpg',
        );
      } else if (paymentScreenshotBytes != null) {
        map['payment_screenshot'] = MultipartFile.fromBytes(
          paymentScreenshotBytes,
          filename: paymentScreenshotName ?? 'payment.jpg',
        );
      }
      final formData = FormData.fromMap(map);
      final response = await _dio.post('/orders/sales/', data: formData);
      return Order.fromJson(response.data as Map<String, dynamic>);
    });
  }

  Future<Order> updateOrder(int id, Map<String, dynamic> data) async {
    return _handle(() async {
      final response = await _dio.patch('/orders/sales/$id/', data: data);
      return Order.fromJson(response.data as Map<String, dynamic>);
    });
  }

  Future<Order> cancelOrder(int id) async {
    return _handle(() async {
      final response = await _dio.post('/orders/sales/$id/cancel/');
      return Order.fromJson(response.data as Map<String, dynamic>);
    });
  }

  Future<void> deleteOrder(int id) async {
    return _handle(() async => _dio.delete('/orders/sales/$id/'));
  }

  Future<String> getReceiptHtml(int orderId) async {
    return _handle(() async {
      final response = await _dio.get('/orders/sales/$orderId/receipt/');
      return response.data['html'] as String;
    });
  }

  // ── Bank Details ──────────────────────────────────────────────────────────

  Future<BankDetails> getBankDetails() async {
    return _handle(() async {
      final response = await _dio.get('/orders/bank-details/');
      return BankDetails.fromJson(response.data as Map<String, dynamic>);
    });
  }

  // ── Admin Customers ───────────────────────────────────────────────────────

  Future<List<UserModel>> getCustomers({String? search}) async {
    return _fetchAll(
      '/auth/customers/',
      UserModel.fromJson,
      params: {
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
  }

  Future<UserModel> createCustomer({
    required String phone,
    required String password,
    String firstName = '',
    String lastName = '',
    String email = '',
  }) async {
    return _handle(() async {
      final response = await _dio.post('/auth/customers/', data: {
        'phone_number': phone,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
      });
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    });
  }

  Future<UserModel> updateCustomer(int id, Map<String, dynamic> data) async {
    return _handle(() async {
      final response = await _dio.patch('/auth/customers/$id/', data: data);
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    });
  }

  Future<void> deleteCustomer(int id) async {
    return _handle(() async => _dio.delete('/auth/customers/$id/'));
  }

  Future<UserModel> blacklistCustomer(int id) async {
    return _handle(() async {
      final response = await _dio.post('/auth/customers/$id/blacklist/');
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    });
  }

  Future<UserModel> unblacklistCustomer(int id) async {
    return _handle(() async {
      final response = await _dio.delete('/auth/customers/$id/blacklist/');
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    });
  }
}
