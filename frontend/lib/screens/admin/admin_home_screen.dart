import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import 'customers_screen.dart';
import 'locations_screen.dart';
import 'products_screen.dart';
import 'promotions_screen.dart';
import 'sales_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _index = 0;

  final _screens = const [
    AdminProductsScreen(),
    AdminLocationsScreen(),
    AdminSalesScreen(),
    AdminCustomersScreen(),
    AdminPromotionsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/logo.png', height: 28, fit: BoxFit.contain),
              const SizedBox(width: 10),
              const Text('ADMIN', style: TextStyle(fontSize: 11, letterSpacing: 3, fontWeight: FontWeight.w400)),
            ],
          ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      body: _screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.inventory_2), label: 'Products'),
          NavigationDestination(icon: Icon(Icons.location_on), label: 'Locations'),
          NavigationDestination(icon: Icon(Icons.point_of_sale), label: 'Sales'),
          NavigationDestination(icon: Icon(Icons.people), label: 'Customers'),
          NavigationDestination(icon: Icon(Icons.local_offer), label: 'Promotions'),
        ],
      ),
    );
  }
}
