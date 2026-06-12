import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../config/api_config.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';

class ProductImage extends StatelessWidget {
  final String? imageUrl;
  final double height;

  const ProductImage({super.key, this.imageUrl, this.height = 160});

  @override
  Widget build(BuildContext context) {
    final url = ApiConfig.mediaUrl(imageUrl);
    if (url.isEmpty) {
      return Container(
        height: height,
        color: AppTheme.surfaceMid,
        child: const Icon(Icons.image_outlined, size: 40, color: AppTheme.textMuted),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(height: height, color: AppTheme.surfaceMid),
      errorWidget: (_, __, ___) => Container(
        height: height,
        color: AppTheme.surfaceMid,
        child: const Icon(Icons.broken_image_outlined, color: AppTheme.textMuted),
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final Widget? trailing;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final url = ApiConfig.mediaUrl(product.image);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: AppTheme.primary.withAlpha(20),
        highlightColor: AppTheme.primary.withAlpha(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image ──────────────────────────────────────────────
            Expanded(
              flex: 60,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Product image (fills available space)
                  url.isEmpty
                      ? Container(
                          color: AppTheme.surfaceMid,
                          child: const Icon(
                            Icons.image_outlined,
                            size: 48,
                            color: AppTheme.textMuted,
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: AppTheme.surfaceMid),
                          errorWidget: (_, __, ___) => Container(
                            color: AppTheme.surfaceMid,
                            child: const Icon(
                              Icons.broken_image_outlined,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ),
                  // Subtle bottom gradient for depth
                  Positioned(
                    left: 0, right: 0, bottom: 0,
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withAlpha(80),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Sale banner
                  if (product.isOnSale)
                    Positioned(
                      top: 8,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFC62828),
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                        ),
                        child: Text(
                          '${product.discountPercentage.toStringAsFixed(0)}% OFF',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),
                  // Sold out overlay
                  if (!product.inStock)
                    Container(
                      color: Colors.black.withAlpha(160),
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white38),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'SOLD OUT',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // ── Info ───────────────────────────────────────────────
            Expanded(
              flex: 40,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        height: 1.3,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (product.isOnSale) ...[
                          Text(
                            currencyFormat.format(product.price),
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              decorationColor: AppTheme.textMuted,
                              color: AppTheme.textMuted,
                              fontSize: 11,
                              height: 1.2,
                            ),
                          ),
                          Text(
                            currencyFormat.format(product.salePrice),
                            style: const TextStyle(
                              color: Color(0xFFEF5350),
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ] else
                          Text(
                            currencyFormat.format(product.price),
                            style: const TextStyle(
                              color: AppTheme.gold,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              letterSpacing: 0.2,
                            ),
                          ),
                        if (trailing != null) ...[
                          const SizedBox(height: 4),
                          trailing!,
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textMuted),
            ),
            const SizedBox(height: 20),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
