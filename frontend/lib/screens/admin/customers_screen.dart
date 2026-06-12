import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class AdminCustomersScreen extends StatefulWidget {
  const AdminCustomersScreen({super.key});

  @override
  State<AdminCustomersScreen> createState() => _AdminCustomersScreenState();
}

class _AdminCustomersScreenState extends State<AdminCustomersScreen> {
  List<UserModel> _customers = [];
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
      final customers =
          await ApiService.instance.getCustomers(search: _searchController.text.trim());
      if (mounted) {
        setState(() {
          _customers = customers;
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

  Future<void> _showForm({UserModel? customer}) async {
    final phoneController = TextEditingController(text: customer?.phoneNumber ?? '');
    final firstNameController = TextEditingController(text: customer?.firstName ?? '');
    final lastNameController = TextEditingController(text: customer?.lastName ?? '');
    final emailController = TextEditingController(text: customer?.email ?? '');
    final passwordController = TextEditingController();
    bool isActive = customer?.isActive ?? true;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(customer == null ? 'Add Customer' : 'Edit Customer'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                  enabled: customer == null,
                ),
                if (customer == null)
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                  ),
                TextField(
                    controller: firstNameController,
                    decoration: const InputDecoration(labelText: 'First Name')),
                TextField(
                    controller: lastNameController,
                    decoration: const InputDecoration(labelText: 'Last Name')),
                TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email')),
                if (customer != null)
                  SwitchListTile(
                    title: const Text('Active'),
                    value: isActive,
                    onChanged: (v) => setDialogState(() => isActive = v),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                try {
                  if (customer == null) {
                    await ApiService.instance.createCustomer(
                      phone: phoneController.text.trim(),
                      password: passwordController.text,
                      firstName: firstNameController.text.trim(),
                      lastName: lastNameController.text.trim(),
                      email: emailController.text.trim(),
                    );
                  } else {
                    await ApiService.instance.updateCustomer(customer.id, {
                      'first_name': firstNameController.text.trim(),
                      'last_name': lastNameController.text.trim(),
                      'email': emailController.text.trim(),
                      'is_active': isActive,
                    });
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

  Future<void> _toggleBlacklist(UserModel customer) async {
    try {
      if (customer.isBlacklisted) {
        await ApiService.instance.unblacklistCustomer(customer.id);
        if (mounted) showSnack(context, 'Customer removed from blacklist');
      } else {
        await ApiService.instance.blacklistCustomer(customer.id);
        if (mounted) showSnack(context, 'Customer blacklisted');
      }
      _load();
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), isError: true);
    }
  }

  Future<void> _viewWishlist(UserModel customer) async {
    try {
      final items = await ApiService.instance.getCustomerWishlist(customer.id);
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Wishlist — ${customer.fullName}'),
          content: SizedBox(
            width: double.maxFinite,
            child: items.isEmpty
                ? const Text('No wishlist items')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final item = items[i];
                      return ListTile(
                        leading: SizedBox(
                          width: 40,
                          height: 40,
                          child: ProductImage(imageUrl: item.product.image, height: 40),
                        ),
                        title: Text(item.product.name),
                        subtitle: Text(currencyFormat.format(item.product.price)),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ],
        ),
      );
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), isError: true);
    }
  }

  Future<void> _delete(UserModel customer) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text('Delete ${customer.fullName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiService.instance.deleteCustomer(customer.id);
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
        child: const Icon(Icons.person_add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or phone…',
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
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          itemCount: _customers.length,
                          itemBuilder: (context, index) {
                            final c = _customers[index];
                            return Card(
                              color: c.isBlacklisted ? Colors.red.shade50 : null,
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Text(c.fullName.isNotEmpty
                                      ? c.fullName[0].toUpperCase()
                                      : '?'),
                                ),
                                title: Text(c.fullName),
                                subtitle: Text(
                                  '${c.phoneNumber}${c.isBlacklisted ? ' • BLACKLISTED' : ''}',
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (v) {
                                    if (v == 'edit') _showForm(customer: c);
                                    if (v == 'wishlist') _viewWishlist(c);
                                    if (v == 'blacklist') _toggleBlacklist(c);
                                    if (v == 'delete') _delete(c);
                                  },
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                    const PopupMenuItem(
                                        value: 'wishlist', child: Text('View Wishlist')),
                                    PopupMenuItem(
                                      value: 'blacklist',
                                      child: Text(c.isBlacklisted
                                          ? 'Remove Blacklist'
                                          : 'Blacklist'),
                                    ),
                                    const PopupMenuItem(
                                        value: 'delete', child: Text('Delete')),
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
