import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/api_config.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/receipt_dialog.dart';

class AdminSalesScreen extends StatefulWidget {
  const AdminSalesScreen({super.key});

  @override
  State<AdminSalesScreen> createState() => _AdminSalesScreenState();
}

class _AdminSalesScreenState extends State<AdminSalesScreen> {
  List<Order> _orders = [];
  bool _loading = true;
  String? _error;
  final _searchController = TextEditingController();
  String? _statusFilter;

  static const _statusOptions = [
    ('', 'All'),
    ('pending', 'Pending'),
    ('confirmed', 'Confirmed'),
    ('completed', 'Completed'),
    ('cancelled', 'Cancelled'),
  ];

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
      final orders = await ApiService.instance.getOrders(
        search: _searchController.text.trim(),
        status: _statusFilter,
      );
      if (mounted) {
        setState(() {
          _orders = orders;
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

  Future<void> _updateStatus(Order order, String status) async {
    try {
      await ApiService.instance.updateOrder(order.id, {'status': status});
      _load();
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), isError: true);
    }
  }

  Future<void> _delete(Order order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Sale'),
        content: Text('Delete order #${order.id}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiService.instance.deleteOrder(order.id);
      _load();
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), isError: true);
    }
  }

  Future<void> _openScreenshot(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) showSnack(context, 'Cannot open screenshot', isError: true);
    }
  }

  Future<void> _openDeliveryLocation(Order order) async {
    final url = order.deliveryMapsUrl;
    if (url == null) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) showSnack(context, 'Cannot open maps', isError: true);
    }
  }

  void _copyDeliveryLink(Order order) {
    final url = order.deliveryMapsUrl;
    if (url == null) return;
    Clipboard.setData(ClipboardData(text: url));
    showSnack(context, 'Location link copied — share with runner');
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by customer name/phone…',
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
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _statusFilter ?? '',
                items: _statusOptions
                    .map((s) => DropdownMenuItem(value: s.$1, child: Text(s.$2)))
                    .toList(),
                onChanged: (v) {
                  setState(() => _statusFilter = v!.isEmpty ? null : v);
                  _load();
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const LoadingView()
              : _error != null
                  ? ErrorView(message: _error!, onRetry: _load)
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: _orders.isEmpty
                          ? ListView(
                              children: const [
                                SizedBox(
                                  height: 200,
                                  child: Center(child: Text('No sales found')),
                                ),
                              ],
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: _orders.length,
                              itemBuilder: (context, index) {
                                final order = _orders[index];
                                return Card(
                                  child: ExpansionTile(
                                    title: Text('Order #${order.id} — ${order.customerName}'),
                                    subtitle: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _statusColor(order.status).withAlpha(30),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                                color: _statusColor(order.status)),
                                          ),
                                          child: Text(
                                            order.statusLabel,
                                            style: TextStyle(
                                              color: _statusColor(order.status),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(currencyFormat.format(order.totalAmount)),
                                        const SizedBox(width: 8),
                                        Text(order.paymentMethodLabel,
                                            style: const TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                                'Customer: ${order.customerPhone}'),
                                            Text(
                                                'Fulfillment: ${order.fulfillmentLabel}'),
                                            if (!order.isDelivery)
                                              Text(
                                                  'Pickup: ${order.pickupLocationName ?? '—'}'),
                                            if (order.isDelivery &&
                                                order.hasDeliveryLocation) ...[
                                              Text(
                                                'Location: ${order.deliveryLatitude!.toStringAsFixed(5)}, '
                                                '${order.deliveryLongitude!.toStringAsFixed(5)}',
                                              ),
                                            ],
                                            if (order.createdAt != null)
                                              Text(
                                                'Date: ${order.createdAt!.toLocal().toString().substring(0, 16)}',
                                                style: const TextStyle(
                                                    color: Colors.grey),
                                              ),
                                            const SizedBox(height: 8),
                                            ...order.items.map(
                                              (item) => Text(
                                                '• ${item.productName} x${item.quantity} — ${currencyFormat.format(item.subtotal)}',
                                              ),
                                            ),
                                            if (order.effectiveScreenshotUrl != null &&
                                                order.effectiveScreenshotUrl!
                                                    .isNotEmpty) ...[
                                              const SizedBox(height: 12),
                                              const Text('Payment Screenshot:',
                                                  style: TextStyle(
                                                      fontWeight: FontWeight.bold)),
                                              const SizedBox(height: 6),
                                              InkWell(
                                                onTap: () => _openScreenshot(
                                                    ApiConfig.mediaUrl(
                                                        order.effectiveScreenshotUrl)),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Stack(
                                                  alignment: Alignment.center,
                                                  children: [
                                                    ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(8),
                                                      child: ProductImage(
                                                        imageUrl: order
                                                            .effectiveScreenshotUrl,
                                                        height: 140,
                                                      ),
                                                    ),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.all(6),
                                                      decoration: BoxDecoration(
                                                        color: Colors.black45,
                                                        borderRadius:
                                                            BorderRadius.circular(20),
                                                      ),
                                                      child: const Icon(
                                                        Icons.open_in_new,
                                                        color: Colors.white,
                                                        size: 20,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                            const SizedBox(height: 12),
                                            if (order.isDelivery &&
                                                order.hasDeliveryLocation) ...[
                                              const SizedBox(height: 8),
                                              Container(
                                                padding: const EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue
                                                      .withAlpha(15),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                      color: Colors.blue
                                                          .withAlpha(60)),
                                                ),
                                                child: Row(
                                                  children: [
                                                    const Icon(
                                                        Icons.delivery_dining,
                                                        color: Colors.blue,
                                                        size: 16),
                                                    const SizedBox(width: 8),
                                                    const Expanded(
                                                      child: Text(
                                                        'DELIVERY LOCATION',
                                                        style: TextStyle(
                                                          color: Colors.blue,
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          letterSpacing: 1,
                                                        ),
                                                      ),
                                                    ),
                                                    TextButton.icon(
                                                      onPressed: () =>
                                                          _openDeliveryLocation(
                                                              order),
                                                      icon: const Icon(
                                                          Icons.map_outlined,
                                                          size: 14,
                                                          color: Colors.blue),
                                                      label: const Text(
                                                        'Open',
                                                        style: TextStyle(
                                                            color: Colors.blue,
                                                            fontSize: 12),
                                                      ),
                                                      style:
                                                          TextButton.styleFrom(
                                                              padding:
                                                                  EdgeInsets
                                                                      .zero,
                                                              minimumSize:
                                                                  Size.zero,
                                                              tapTargetSize:
                                                                  MaterialTapTargetSize
                                                                      .shrinkWrap),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    TextButton.icon(
                                                      onPressed: () =>
                                                          _copyDeliveryLink(
                                                              order),
                                                      icon: const Icon(
                                                          Icons.share_outlined,
                                                          size: 14,
                                                          color: Colors.blue),
                                                      label: const Text(
                                                        'Share',
                                                        style: TextStyle(
                                                            color: Colors.blue,
                                                            fontSize: 12),
                                                      ),
                                                      style:
                                                          TextButton.styleFrom(
                                                              padding:
                                                                  EdgeInsets
                                                                      .zero,
                                                              minimumSize:
                                                                  Size.zero,
                                                              tapTargetSize:
                                                                  MaterialTapTargetSize
                                                                      .shrinkWrap),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: [
                                                DropdownButton<String>(
                                                  value: order.status,
                                                  isDense: true,
                                                  items: const [
                                                    DropdownMenuItem(
                                                        value: 'pending',
                                                        child: Text('Pending')),
                                                    DropdownMenuItem(
                                                        value: 'confirmed',
                                                        child: Text('Confirmed')),
                                                    DropdownMenuItem(
                                                        value: 'completed',
                                                        child: Text('Completed')),
                                                    DropdownMenuItem(
                                                        value: 'cancelled',
                                                        child: Text('Cancelled')),
                                                  ],
                                                  onChanged: (v) {
                                                    if (v != null)
                                                      _updateStatus(order, v);
                                                  },
                                                ),
                                                OutlinedButton.icon(
                                                  onPressed: () =>
                                                      ReceiptDialog.show(
                                                          context, order),
                                                  icon:
                                                      const Icon(Icons.print, size: 16),
                                                  label: const Text('Receipt'),
                                                ),
                                                TextButton.icon(
                                                  onPressed: () => _delete(order),
                                                  icon: const Icon(Icons.delete,
                                                      color: Colors.red, size: 16),
                                                  label: const Text('Delete',
                                                      style: TextStyle(
                                                          color: Colors.red)),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
        ),
      ],
    );
  }
}
