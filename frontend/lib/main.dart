import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'screens/auth/auth_gate.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ApiService.instance.init();
  runApp(const WifeBusinessApp());
}

class WifeBusinessApp extends StatelessWidget {
  const WifeBusinessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MaterialApp(
        title: 'Elf Bru',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const AuthGate(),
      ),
    );
  }
}
