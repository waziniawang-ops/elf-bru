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

const double _kDeliveryCharge = 3.00;

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

  String _fulfillmentMethod = 'pickup';
  int? _selectedLocationId;
  String _paymentMethod = 'cash';
  XFile? _paymentScreenshot;
  final _notesController = TextEditingController();
  final _addressController = TextEditingController();
  bool _checkingOut = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _addressController.dispose();
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

  double get _itemsTotal => _items.fold(0, (sum, item) => sum + item.subtotal);
  double get _grandTotal =>
      _fulfillmentMethod == 'delivery' ? _itemsTotal + _kDeliveryCharge : _itemsTotal;

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

  Future<bool> _showPickupDisclaimer() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppTheme.surfaceDark,
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: AppTheme.gold, size: 20),
            const SizedBox(width: 8),
            const Text(
              'PICKUP REMINDER',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        content: const Text(
          'Please collect your purchase within 2 weeks of your order being placed.\n\n'
          'Items not collected within this period may be returned to stock.',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 14,
            height: 1.6,
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text(
                'I ACKNOWLEDGE',
                style: TextStyle(letterSpacing: 1.5, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppTheme.textMuted),
              ),
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
    return result ?? false;
  }

  Future<void> _checkout() async {
    if (_fulfillmentMethod == 'pickup' && _selectedLocationId == null) {
      showSnack(context, 'Please select a pickup location', isError: true);
      return;
    }
    if (_fulfillmentMethod == 'delivery' && _addressController.text.trim().isEmpty) {
      showSnack(context, 'Please enter your delivery address', isError: true);
      return;
    }
    if (_paymentMethod == 'bank_transfer' && _paymentScreenshot == null) {
      showSnack(context, 'Please upload your bank transfer screenshot', isError: true);
      return;
    }

    if (_fulfillmentMethod == 'pickup') {
      final acknowledged = await _showPickupDisclaimer();
      if (!acknowledged) return;
    }

    setState(() => _checkingOut = true);
    try {
      final notes = _fulfillmentMethod == 'delivery'
          ? 'Delivery address: ${_addressController.text.trim()}'
              '${_notesController.text.isNotEmpty ? '\n${_notesController.text}' : ''}'
          : _notesController.text;

      if (_paymentScreenshot != null && kIsWeb) {
        final bytes = await _paymentScreenshot!.readAsBytes();
        await ApiService.instance.createOrder(
          fulfillmentMethod: _fulfillmentMethod,
          pickupLocationId:
              _fulfillmentMethod == 'pickup' ? _selectedLocationId : null,
          paymentMethod: _paymentMethod,
          paymentScreenshotBytes: bytes,
          paymentScreenshotName: _paymentScreenshot!.name,
          notes: notes,
        );
      } else {
        File? screenshotFile;
        if (_paymentScreenshot != null) {
          screenshotFile = File(_paymentScreenshot!.path);
        }
        await ApiService.instance.createOrder(
          fulfillmentMethod: _fulfillmentMethod,
          pickupLocationId:
              _fulfillmentMethod == 'pickup' ? _selectedLocationId : null,
          paymentMethod: _paymentMethod,
          paymentScreenshot: screenshotFile,
          notes: notes,
        );
      }
      if (mounted) {
        showSnack(context, 'Order placed successfully!');
        setState(() {
          _paymentScreenshot = null;
          _paymentMethod = 'cash';
          _notesController.clear();
          _addressController.clear();
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

  Widget _sectionLabel(String label) {
    return Row(
      children: [
        Container(width: 3, height: 13, color: AppTheme.gold),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.5,
          ),
        ),
      ],
    );
  }

  void _copyToClipboard(String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    showSnack(context, '$label copied');
  }

  Widget _bankDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _copyToClipboard(value, label),
            child: const Icon(Icons.copy_outlined, size: 15, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _fulfillmentTile({
    required String value,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final selected = _fulfillmentMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _fulfillmentMethod = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppTheme.surfaceMid : AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.borderColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? AppTheme.primary : AppTheme.textMuted,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: selected ? AppTheme.textPrimary : AppTheme.textMuted,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 12),
              )
            else
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.borderColor),
                ),
              ),
          ],
        ),
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
            Icon(Icons.shopping_bag_outlined, size: 56, color: AppTheme.borderColor),
            SizedBox(height: 16),
            Text(
              'YOUR CART IS EMPTY',
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
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Cart items
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

          // Total box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceMid,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ITEMS',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      currencyFormat.format(_itemsTotal),
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (_fulfillmentMethod == 'delivery') ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'DELIVERY',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                        ),
                      ),
                      Text(
                        currencyFormat.format(_kDeliveryCharge),
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Divider(color: AppTheme.borderColor, height: 1),
                  ),
                ],
                if (_fulfillmentMethod == 'delivery') const SizedBox(height: 0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.5,
                      ),
                    ),
                    Text(
                      currencyFormat.format(_grandTotal),
                      style: const TextStyle(
                        color: AppTheme.gold,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Fulfillment selector
          _sectionLabel('FULFILLMENT'),
          const SizedBox(height: 10),
          _fulfillmentTile(
            value: 'pickup',
            icon: Icons.store_outlined,
            title: 'Store Pickup',
            subtitle: 'Collect in-store · Free',
          ),
          const SizedBox(height: 8),
          _fulfillmentTile(
            value: 'delivery',
            icon: Icons.local_shipping_outlined,
            title: 'Delivery',
            subtitle: 'Delivered to your address · \$${_kDeliveryCharge.toStringAsFixed(2)}',
          ),

          // Pickup location (pickup only)
          if (_fulfillmentMethod == 'pickup') ...[
            const SizedBox(height: 20),
            _sectionLabel('PICKUP LOCATION'),
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              value: _selectedLocationId,
              decoration: const InputDecoration(labelText: 'Select location'),
              items: _locations
                  .map((loc) => DropdownMenuItem(value: loc.id, child: Text(loc.name)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedLocationId = v),
            ),
          ],

          // Delivery address (delivery only)
          if (_fulfillmentMethod == 'delivery') ...[
            const SizedBox(height: 20),
            _sectionLabel('DELIVERY ADDRESS'),
            const SizedBox(height: 10),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Delivery Address',
                hintText: 'Street, City, Postal Code',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              maxLines: 2,
            ),
          ],

          const SizedBox(height: 20),
          _sectionLabel('PAYMENT METHOD'),
          RadioListTile<String>(
            title: Text(
              _fulfillmentMethod == 'delivery' ? 'Cash on Delivery' : 'Cash on Pickup',
            ),
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
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceMid,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.gold.withAlpha(80)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.account_balance_outlined,
                            color: AppTheme.gold, size: 16),
                        const SizedBox(width: 8),
                        const Text(
                          'BANK TRANSFER DETAILS',
                          style: TextStyle(
                            color: AppTheme.gold,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_bankDetails.bankName.isNotEmpty)
                      _bankDetailRow('Bank', _bankDetails.bankName),
                    if (_bankDetails.accountName.isNotEmpty)
                      _bankDetailRow('Account Name', _bankDetails.accountName),
                    if (_bankDetails.accountNumber.isNotEmpty)
                      _bankDetailRow('Account Number', _bankDetails.accountNumber),
                    if (_bankDetails.instructions.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        _bankDetails.instructions,
                        style: const TextStyle(
                            color: AppTheme.textMuted, fontSize: 12, height: 1.5),
                      ),
                    ],
                  ],
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
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('PLACE ORDER'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
