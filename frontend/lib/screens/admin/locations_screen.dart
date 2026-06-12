import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class AdminLocationsScreen extends StatefulWidget {
  const AdminLocationsScreen({super.key});

  @override
  State<AdminLocationsScreen> createState() => _AdminLocationsScreenState();
}

class _AdminLocationsScreenState extends State<AdminLocationsScreen> {
  List<PickupLocation> _locations = [];
  bool _loading = true;
  String? _error;

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
      final locations = await ApiService.instance.getLocations();
      if (mounted) {
        setState(() {
          _locations = locations;
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

  Future<void> _showForm({PickupLocation? location}) async {
    final nameController = TextEditingController(text: location?.name ?? '');
    final addressController = TextEditingController(text: location?.address ?? '');
    final cityController = TextEditingController(text: location?.city ?? '');
    final phoneController = TextEditingController(text: location?.phone ?? '');
    final notesController = TextEditingController(text: location?.notes ?? '');
    bool isActive = location?.isActive ?? true;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(location == null ? 'Add Location' : 'Edit Location'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
                TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Address'), maxLines: 2),
                TextField(controller: cityController, decoration: const InputDecoration(labelText: 'City')),
                TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone')),
                TextField(controller: notesController, decoration: const InputDecoration(labelText: 'Notes'), maxLines: 2),
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
                  final data = {
                    'name': nameController.text.trim(),
                    'address': addressController.text.trim(),
                    'city': cityController.text.trim(),
                    'phone': phoneController.text.trim(),
                    'notes': notesController.text.trim(),
                    'is_active': isActive,
                  };
                  if (location == null) {
                    await ApiService.instance.createLocation(data);
                  } else {
                    await ApiService.instance.updateLocation(location.id, data);
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

  Future<void> _delete(PickupLocation location) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Location'),
        content: Text('Delete "${location.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiService.instance.deleteLocation(location.id);
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
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _locations.length,
                    itemBuilder: (context, index) {
                      final loc = _locations[index];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.location_on),
                          title: Text(loc.name),
                          subtitle: Text('${loc.address}\n${loc.city}'),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'edit') _showForm(location: loc);
                              if (v == 'delete') _delete(loc);
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
    );
  }
}
