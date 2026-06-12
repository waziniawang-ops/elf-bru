import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  List<Product> _products = [];
  bool _loading = true;
  String? _error;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final products =
          await ApiService.instance.getProducts(search: _searchController.text.trim());
      if (mounted) {
        setState(() {
          _products = products;
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

  Future<void> _showForm({Product? product}) async {
    final nameController = TextEditingController(text: product?.name ?? '');
    final descController = TextEditingController(text: product?.description ?? '');
    final priceController =
        TextEditingController(text: product?.price.toStringAsFixed(2) ?? '');
    final qtyController =
        TextEditingController(text: '${product?.quantity ?? 0}');
    final categoryController = TextEditingController(text: product?.category ?? '');
    bool isActive = product?.isActive ?? true;
    XFile? image;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(product == null ? 'Add Product' : 'Edit Product'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name')),
                TextField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 3),
                TextField(
                    controller: priceController,
                    decoration: const InputDecoration(labelText: 'Price'),
                    keyboardType: TextInputType.number),
                TextField(
                    controller: qtyController,
                    decoration: const InputDecoration(labelText: 'Quantity'),
                    keyboardType: TextInputType.number),
                TextField(
                    controller: categoryController,
                    decoration: const InputDecoration(labelText: 'Category')),
                SwitchListTile(
                  title: const Text('Active'),
                  value: isActive,
                  onChanged: (v) => setDialogState(() => isActive = v),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked =
                        await ImagePicker().pickImage(source: ImageSource.gallery);
                    if (picked != null) setDialogState(() => image = picked);
                  },
                  icon: const Icon(Icons.image),
                  label: Text(image == null ? 'Pick Image' : 'Image: ${image!.name}'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                try {
                  final data = {
                    'name': nameController.text.trim(),
                    'description': descController.text.trim(),
                    'price': priceController.text.trim(),
                    'quantity': int.parse(qtyController.text.trim()),
                    'category': categoryController.text.trim(),
                    'is_active': isActive,
                  };
                  File? imageFile;
                  List<int>? imageBytes;
                  String? imageName;
                  if (image != null) {
                    imageName = image!.name;
                    if (kIsWeb) {
                      imageBytes = await image!.readAsBytes();
                    } else {
                      imageFile = File(image!.path);
                    }
                  }
                  if (product == null) {
                    await ApiService.instance.createProduct(data,
                        image: imageFile,
                        imageBytes: imageBytes,
                        imageFilename: imageName);
                  } else {
                    await ApiService.instance.updateProduct(product.id, data,
                        image: imageFile,
                        imageBytes: imageBytes,
                        imageFilename: imageName);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                  _load();
                } catch (e) {
                  if (ctx.mounted) showSnack(ctx, e.toString(), isError: true);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(Product product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Delete "${product.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiService.instance.deleteProduct(product.id);
      _load();
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _load();
                        },
                      )
                    : null,
                isDense: true,
              ),
              onSubmitted: (_) => _load(),
            ),
          ),
          Expanded(
            child: _loading
                ? const LoadingView()
                : _error != null
                    ? ErrorView(message: _error!, onRetry: _load)
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
                          itemCount: _products.length,
                          itemBuilder: (context, index) {
                            final p = _products[index];
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
                                subtitle: Text(
                                  '${currencyFormat.format(p.price)} • Qty: ${p.quantity}'
                                  '${p.isActive ? '' : ' • Inactive'}',
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (v) {
                                    if (v == 'edit') _showForm(product: p);
                                    if (v == 'delete') _delete(p);
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                                  ],
                                ),
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
