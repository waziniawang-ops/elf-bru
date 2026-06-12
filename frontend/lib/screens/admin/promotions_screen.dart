import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class AdminPromotionsScreen extends StatefulWidget {
  const AdminPromotionsScreen({super.key});

  @override
  State<AdminPromotionsScreen> createState() => _AdminPromotionsScreenState();
}

class _AdminPromotionsScreenState extends State<AdminPromotionsScreen> {
  List<Product> _products = [];
  bool _loading = true;
  String? _error;
  bool _showOnSaleOnly = false;

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
      final all = await ApiService.instance.getProducts();
      if (mounted) {
        setState(() {
          _products = all;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _showDiscountDialog(Product product) async {
    double discount = product.discountPercentage;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final salePrice = product.price * (1 - discount / 100);
          return AlertDialog(
            title: Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Set discount percentage (0 = remove sale):'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: discount,
                        min: 0,
                        max: 90,
                        divisions: 90,
                        label: '${discount.toStringAsFixed(0)}%',
                        onChanged: (v) => setDialogState(() => discount = v),
                      ),
                    ),
                    SizedBox(
                      width: 56,
                      child: TextField(
                        controller: TextEditingController(text: discount.toStringAsFixed(0)),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(suffix: Text('%'), isDense: true),
                        onChanged: (v) {
                          final parsed = double.tryParse(v);
                          if (parsed != null && parsed >= 0 && parsed <= 90) {
                            setDialogState(() => discount = parsed);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (discount > 0) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Original: ${currencyFormat.format(product.price)}',
                              style: const TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              'Sale price: ${currencyFormat.format(salePrice)}',
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${discount.toStringAsFixed(0)}% OFF',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else
                  const Text(
                    'No active promotion',
                    style: TextStyle(color: Colors.grey),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              if (product.discountPercentage > 0)
                TextButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _applyDiscount(product, 0);
                  },
                  style: TextButton.styleFrom(foregroundColor: Colors.grey),
                  child: const Text('Remove Sale'),
                ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _applyDiscount(product, discount);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _applyDiscount(Product product, double percentage) async {
    try {
      await ApiService.instance.setProductDiscount(product.id, percentage);
      _load();
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayed = _showOnSaleOnly
        ? _products.where((p) => p.isOnSale).toList()
        : _products;

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('On Sale Only'),
                  selected: _showOnSaleOnly,
                  onSelected: (v) => setState(() => _showOnSaleOnly = v),
                  selectedColor: Colors.red.shade100,
                  checkmarkColor: Colors.red,
                ),
                const SizedBox(width: 12),
                Text(
                  '${_products.where((p) => p.isOnSale).length} on sale',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const LoadingView()
                : _error != null
                    ? ErrorView(message: _error!, onRetry: _load)
                    : displayed.isEmpty
                        ? Center(
                            child: Text(
                              _showOnSaleOnly ? 'No products on sale' : 'No products',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                              itemCount: displayed.length,
                              itemBuilder: (context, index) {
                                final p = displayed[index];
                                return Card(
                                  child: ListTile(
                                    leading: SizedBox(
                                      width: 48,
                                      height: 48,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: ProductImage(imageUrl: p.image, height: 48),
                                      ),
                                    ),
                                    title: Text(p.name),
                                    subtitle: p.isOnSale
                                        ? Row(
                                            children: [
                                              Text(
                                                currencyFormat.format(p.price),
                                                style: const TextStyle(
                                                  decoration: TextDecoration.lineThrough,
                                                  color: Colors.grey,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                currencyFormat.format(p.salePrice),
                                                style: const TextStyle(
                                                  color: Colors.red,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          )
                                        : Text(currencyFormat.format(p.price)),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (p.isOnSale)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: Colors.red,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              '${p.discountPercentage.toStringAsFixed(0)}% OFF',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined),
                                          onPressed: () => _showDiscountDialog(p),
                                        ),
                                      ],
                                    ),
                                    onTap: () => _showDiscountDialog(p),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
