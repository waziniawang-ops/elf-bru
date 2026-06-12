import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/print_helper.dart';

class ReceiptDialog extends StatelessWidget {
  final Order order;

  const ReceiptDialog({super.key, required this.order});

  static Future<void> show(BuildContext context, Order order) {
    return showDialog(
      context: context,
      builder: (_) => ReceiptDialog(order: order),
    );
  }

  Future<void> _print(BuildContext context) async {
    try {
      final html = await ApiService.instance.getReceiptHtml(order.id);
      if (kIsWeb) {
        printReceiptHtml(html);
      } else {
        // On native, close dialog — receipt view is in the web portal
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Print is available on the web version')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Print failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy HH:mm');
    return AlertDialog(
      title: Text('Receipt #${order.id}'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (order.createdAt != null)
              Text('Date: ${dateFormat.format(order.createdAt!.toLocal())}'),
            Text('Customer: ${order.customerName} (${order.customerPhone})'),
            Text('Pickup: ${order.pickupLocationName}'),
            Text('Payment: ${order.paymentMethodLabel}'),
            Text('Status: ${order.statusLabel}'),
            const Divider(height: 24),
            ...order.items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('${item.productName} x${item.quantity}'),
                    ),
                    Text(currencyFormat.format(item.subtotal)),
                  ],
                ),
              ),
            ),
            const Divider(height: 24),
            Text(
              'Total: ${currencyFormat.format(order.totalAmount)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            if (order.notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Notes: ${order.notes}'),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        ElevatedButton.icon(
          onPressed: () => _print(context),
          icon: const Icon(Icons.print, size: 16),
          label: const Text('Print'),
        ),
      ],
    );
  }
}
