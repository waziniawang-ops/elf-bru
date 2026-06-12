import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import 'cart_screen.dart';
import 'orders_screen.dart';
import 'products_screen.dart';
import 'profile_screen.dart';
import 'wishlist_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int _index = 0;

  final _screens = const [
    ProductsScreen(),
    WishlistScreen(),
    CartScreen(),
    OrdersScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(['Shop', 'Wishlist', 'Cart', 'Orders'][_index]),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Center(
              child: Text(
                auth.user?.fullName.isNotEmpty == true
                    ? auth.user!.fullName
                    : auth.user?.phoneNumber ?? '',
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      body: _screens[_index],
      bottomNavigationBar: Consumer<CartProvider>(
        builder: (context, cart, _) => NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.store),
              label: 'Shop',
            ),
            const NavigationDestination(
              icon: Icon(Icons.favorite_border),
              label: 'Wishlist',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: cart.itemCount > 0,
                label: Text('${cart.itemCount}'),
                child: const Icon(Icons.shopping_cart),
              ),
              label: 'Cart',
            ),
            const NavigationDestination(
              icon: Icon(Icons.receipt_long),
              label: 'Orders',
            ),
          ],
        ),
      ),
    );
  }
}
