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
    setState(() { _loading = true; _error = null; });
    try {
      final items = await ApiService.instance.getWishlist();
      if (mounted) setState(() { _items = items; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
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
    if (_items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_border, size: 56, color: AppTheme.borderColor),
            SizedBox(height: 16),
            Text(
              'YOUR WISHLIST IS EMPTY',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 12,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = _items[index];
          final p = item.product;
          return Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductDetailScreen(product: p),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Thumbnail
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 72,
                        height: 72,
                        child: ProductImage(imageUrl: p.image, height: 72),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          if (p.isOnSale) ...[
                            Text(
                              currencyFormat.format(p.price),
                              style: const TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: AppTheme.textMuted,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              currencyFormat.format(p.salePrice),
                              style: const TextStyle(
                                color: Color(0xFFEF5350),
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ] else
                            Text(
                              currencyFormat.format(p.price),
                              style: const TextStyle(
                                color: AppTheme.gold,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            p.inStock ? 'In stock' : 'Out of stock',
                            style: TextStyle(
                              color: p.inStock
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFFEF5350),
                              fontSize: 11,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Actions
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: AppTheme.textMuted),
                      onSelected: (v) {
                        if (v == 'cart') _moveToCart(item);
                        if (v == 'remove') _remove(item.id);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'cart',
                          child: Row(
                            children: [
                              Icon(Icons.shopping_bag_outlined, size: 18),
                              SizedBox(width: 10),
                              Text('Move to Cart'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'remove',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF5350)),
                              SizedBox(width: 10),
                              Text('Remove', style: TextStyle(color: Color(0xFFEF5350))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
