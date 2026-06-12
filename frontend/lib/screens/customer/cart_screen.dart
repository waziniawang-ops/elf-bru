import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/cart_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<CartItem> _items = [];
  List<PickupLocation> _locations = [];
  BankDetails _bankDetails = const BankDetails.empty();
  bool _loading = true;
  String? _error;
  int? _selectedLocationId;
  String _paymentMethod = 'cash';
  XFile? _paymentScreenshot;
  final _notesController = TextEditingController();
  bool _checkingOut = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cart = await ApiService.instance.getCart();
      final locations = await ApiService.instance.getLocations();
      BankDetails bankDetails = const BankDetails.empty();
      try {
        bankDetails = await ApiService.instance.getBankDetails();
      } catch (_) {}

      if (mounted) {
        context.read<CartProvider>().update(cart.length);
        setState(() {
          _items = cart;
          _locations = locations;
          _bankDetails = bankDetails;
          if (_selectedLocationId == null && locations.isNotEmpty) {
            _selectedLocationId = locations.first.id;
          }
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

  double get _total => _items.fold(0, (sum, item) => sum + item.subtotal);

  Future<void> _updateQuantity(CartItem item, int qty) async {
    try {
      if (qty <= 0) {
        await ApiService.instance.removeFromCart(item.id);
      } else {
        await ApiService.instance.updateCartItem(item.id, qty);
      }
      _load();
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), isError: true);
    }
  }

  Future<void> _pickScreenshot() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) setState(() => _paymentScreenshot = file);
  }

  Future<void> _checkout() async {
    if (_selectedLocationId == null) {
      showSnack(context, 'Please select a pickup location', isError: true);
      return;
    }
    if (_paymentMethod == 'bank_transfer' && _paymentScreenshot == null) {
      showSnack(context, 'Please upload your bank transfer screenshot', isError: true);
      return;
    }

    setState(() => _checkingOut = true);
    try {
      if (_paymentScreenshot != null && kIsWeb) {
        final bytes = await _paymentScreenshot!.readAsBytes();
        await ApiService.instance.createOrder(
          pickupLocationId: _selectedLocationId!,
          paymentMethod: _paymentMethod,
          paymentScreenshotBytes: bytes,
          paymentScreenshotName: _paymentScreenshot!.name,
          notes: _notesController.text,
        );
      } else {
        File? screenshotFile;
        if (_paymentScreenshot != null) {
          screenshotFile = File(_paymentScreenshot!.path);
        }
        await ApiService.instance.createOrder(
          pickupLocationId: _selectedLocationId!,
          paymentMethod: _paymentMethod,
          paymentScreenshot: screenshotFile,
          notes: _notesController.text,
        );
      }
      if (mounted) {
        showSnack(context, 'Order placed successfully!');
        setState(() {
          _paymentScreenshot = null;
          _paymentMethod = 'cash';
          _notesController.clear();
        });
        context.read<CartProvider>().clear();
      }
      _load();
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _checkingOut = false);
    }
  }

  void _copyToClipboard(String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    showSnack(context, '$label copied');
  }

  Widget _bankDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          GestureDetector(
            onTap: () => _copyToClipboard(value, label),
            child: const Icon(Icons.copy, size: 16, color: Colors.blueGrey),
          ),
        ],
      ),
    );
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
            Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('Your cart is empty', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ..._items.map((item) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 64,
                        height: 64,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: ProductImage(imageUrl: item.product.image, height: 64),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.product.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(currencyFormat.format(item.subtotal)),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: () => _updateQuantity(item, item.quantity - 1),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text('${item.quantity}',
                                      style: const TextStyle(fontSize: 16)),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: item.quantity < item.product.quantity
                                      ? () => _updateQuantity(item, item.quantity + 1)
                                      : null,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )),

          const SizedBox(height: 16),
          Text(
            'Total: ${currencyFormat.format(_total)}',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          const Divider(height: 32),

          const Text('Pickup Location',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            value: _selectedLocationId,
            decoration: const InputDecoration(labelText: 'Select location'),
            items: _locations
                .map((loc) => DropdownMenuItem(value: loc.id, child: Text(loc.name)))
                .toList(),
            onChanged: (v) => setState(() => _selectedLocationId = v),
          ),

          const SizedBox(height: 20),
          const Text('Payment Method',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          RadioListTile<String>(
            title: const Text('Cash on Pickup'),
            value: 'cash',
            groupValue: _paymentMethod,
            onChanged: (v) => setState(() => _paymentMethod = v!),
            contentPadding: EdgeInsets.zero,
          ),
          RadioListTile<String>(
            title: const Text('Bank Transfer'),
            value: 'bank_transfer',
            groupValue: _paymentMethod,
            onChanged: (v) => setState(() => _paymentMethod = v!),
            contentPadding: EdgeInsets.zero,
          ),

          if (_paymentMethod == 'bank_transfer') ...[
            if (!_bankDetails.isEmpty) ...[
              Card(
                color: Colors.blue.shade50,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bank Transfer Details',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 10),
                      if (_bankDetails.bankName.isNotEmpty)
                        _bankDetailRow('Bank', _bankDetails.bankName),
                      if (_bankDetails.accountName.isNotEmpty)
                        _bankDetailRow('Account Name', _bankDetails.accountName),
                      if (_bankDetails.accountNumber.isNotEmpty)
                        _bankDetailRow('Account Number', _bankDetails.accountNumber),
                      if (_bankDetails.instructions.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          _bankDetails.instructions,
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickScreenshot,
              icon: const Icon(Icons.upload_file),
              label: Text(
                _paymentScreenshot == null
                    ? 'Upload Payment Screenshot'
                    : 'Screenshot: ${_paymentScreenshot!.name}',
              ),
            ),
          ],

          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Order Notes (optional)',
              hintText: 'Special instructions for your order',
            ),
            maxLines: 2,
          ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _checkingOut ? null : _checkout,
              child: _checkingOut
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Place Order'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
