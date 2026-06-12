import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'product_detail_screen.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  List<WishlistItem> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await ApiService.instance.getWishlist();
      if (mounted) {
        setState(() {
          _items = items;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _remove(int id) async {
    try {
      await ApiService.instance.removeFromWishlist(id);
      _load();
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), isError: true);
    }
  }

  Future<void> _moveToCart(WishlistItem item) async {
    try {
      await ApiService.instance.addToCart(item.product.id);
      await ApiService.instance.removeFromWishlist(item.id);
      if (mounted) showSnack(context, 'Moved to cart');
      _load();
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView();
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);
    if (_items.isEmpty) return const Center(child: Text('Your wishlist is empty'));

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          return Card(
            child: ListTile(
              leading: SizedBox(
                width: 56,
                height: 56,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ProductImage(imageUrl: item.product.image, height: 56),
                ),
              ),
              title: Text(item.product.name),
              subtitle: Text(currencyFormat.format(item.product.price)),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductDetailScreen(product: item.product),
                ),
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'cart') _moveToCart(item);
                  if (value == 'remove') _remove(item.id);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'cart', child: Text('Move to Cart')),
                  PopupMenuItem(value: 'remove', child: Text('Remove')),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
