import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  bool _busy = false;

  Future<void> _addToCart() async {
    setState(() => _busy = true);
    try {
      await ApiService.instance.addToCart(widget.product.id, quantity: _quantity);
      if (mounted) showSnack(context, 'Added to cart');
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addToWishlist() async {
    setState(() => _busy = true);
    try {
      await ApiService.instance.addToWishlist(widget.product.id);
      if (mounted) showSnack(context, 'Added to wishlist');
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero image ───────────────────────────────────────
            Stack(
              children: [
                SizedBox(
                  height: 340,
                  width: double.infinity,
                  child: ProductImage(imageUrl: product.image, height: 340),
                ),
                // Gradient overlay bottom
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, AppTheme.bgDark.withAlpha(240)],
                      ),
                    ),
                  ),
                ),
                // Sale badge
                if (product.isOnSale)
                  Positioned(
                    top: 90, left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFC62828),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(10),
                          bottomRight: Radius.circular(10),
                        ),
                      ),
                      child: Text(
                        '${product.discountPercentage.toStringAsFixed(0)}% OFF',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // ── Info panel ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product.category.isNotEmpty) ...[
                    Text(
                      product.category.toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.gold,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 2.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                  Text(
                    product.name,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.3,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Price block
                  if (product.isOnSale) ...[
                    Text(
                      currencyFormat.format(product.price),
                      style: const TextStyle(
                        decoration: TextDecoration.lineThrough,
                        decorationColor: AppTheme.textMuted,
                        color: AppTheme.textMuted,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currencyFormat.format(product.salePrice),
                      style: const TextStyle(
                        color: Color(0xFFEF5350),
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ] else
                    Text(
                      currencyFormat.format(product.price),
                      style: const TextStyle(
                        color: AppTheme.gold,
                        fontWeight: FontWeight.w600,
                        fontSize: 28,
                        letterSpacing: 0.2,
                      ),
                    ),

                  const SizedBox(height: 16),
                  Container(height: 1, color: AppTheme.borderColor),
                  const SizedBox(height: 16),

                  // Stock status
                  Row(
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: product.inStock
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFEF5350),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        product.inStock
                            ? '${product.quantity} in stock'
                            : 'Out of stock',
                        style: TextStyle(
                          color: product.inStock
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFEF5350),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),

                  if (product.description.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'DESCRIPTION',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.description,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  ],

                  if (product.inStock) ...[
                    const SizedBox(height: 28),

                    // Quantity selector
                    const Text(
                      'QUANTITY',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _qtyButton(
                          icon: Icons.remove,
                          onTap: _quantity > 1
                              ? () => setState(() => _quantity--)
                              : null,
                        ),
                        SizedBox(
                          width: 48,
                          child: Text(
                            '$_quantity',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        _qtyButton(
                          icon: Icons.add,
                          onTap: _quantity < product.quantity
                              ? () => setState(() => _quantity++)
                              : null,
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Action buttons
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _busy ? null : _addToCart,
                        icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                        label: const Text('ADD TO CART'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : _addToWishlist,
                        icon: const Icon(Icons.favorite_border, size: 18),
                        label: const Text('SAVE TO WISHLIST'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyButton({required IconData icon, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          border: Border.all(
            color: onTap != null ? AppTheme.borderColor : AppTheme.borderColor.withAlpha(80),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: onTap != null ? AppTheme.textPrimary : AppTheme.textMuted,
        ),
      ),
    );
  }
}
