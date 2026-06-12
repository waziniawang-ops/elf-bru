import 'package:flutter/foundation.dart';

// Set at build time via --dart-define=API_URL=https://your-backend.onrender.com/api
const _kApiUrl = String.fromEnvironment('API_URL', defaultValue: '');
const _kMediaBaseUrl = String.fromEnvironment('MEDIA_BASE_URL', defaultValue: '');

class ApiConfig {
  static String get baseUrl {
    if (_kApiUrl.isNotEmpty) return _kApiUrl;
    // Dev fallbacks: web and Android emulator differ
    return kIsWeb ? 'http://127.0.0.1:8000/api' : 'http://10.0.2.2:8000/api';
  }

  static String get mediaBaseUrl {
    if (_kMediaBaseUrl.isNotEmpty) return _kMediaBaseUrl;
    return kIsWeb ? 'http://127.0.0.1:8000' : 'http://10.0.2.2:8000';
  }

  static String mediaUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '$mediaBaseUrl$path';
  }
}
