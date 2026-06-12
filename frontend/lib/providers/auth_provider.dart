import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _loading = false;
  bool _initializing = true;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _loading || _initializing;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get isAdmin => _user?.isAdmin ?? false;

  Future<void> init() async {
    _initializing = true;
    notifyListeners();
    await ApiService.instance.loadToken();
    try {
      _user = await ApiService.instance.getProfile();
    } catch (_) {
      await ApiService.instance.clearTokens();
      _user = null;
    }
    _initializing = false;
    notifyListeners();
  }

  Future<bool> login(String phone, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await ApiService.instance.login(phone, password);
      _user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      _loading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String phone,
    required String password,
    required String passwordConfirm,
    String firstName = '',
    String lastName = '',
    String email = '',
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await ApiService.instance.register(
        phone: phone,
        password: password,
        passwordConfirm: passwordConfirm,
        firstName: firstName,
        lastName: lastName,
        email: email,
      );
      _loading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await ApiService.instance.clearTokens();
    _user = null;
    notifyListeners();
  }

  void updateUser(UserModel user) {
    _user = user;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
