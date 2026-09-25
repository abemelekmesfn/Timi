import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/app_locale.dart';
import '../../providers/user_provider.dart';
import '../../providers/warehouse_provider.dart';
import '../../providers/inventory_provider.dart';
import 'inventory_screen.dart';
import 'transfer_screen.dart';

class WarehousesScreen extends ConsumerStatefulWidget {
  const WarehousesScreen({super.key});

  @override
  ConsumerState<WarehousesScreen> createState() => _WarehousesScreenState();
}

class _WarehousesScreenState extends ConsumerState<WarehousesScreen> {
  @override
  void initState() {
    super.initState();
    // Always load fresh data when this screen is opened
    Future.microtask(() => ref.read(warehousesProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final warehouses = ref.watch(warehousesProvider);
    final isOwner = user.valueOrNull?.roles.contains("owner") ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context, "warehouses")),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TransferScreen()),
              );
              // Reload warehouses when returning from transfer
              ref.read(warehousesProvider.notifier).load();
            },
          ),
        ],
      ),
      floatingActionButton: isOwner
          ? FloatingActionButton(
              child: const Icon(Icons.add),
              onPressed: () {
                _showAddWarehouseDialog(context, ref);
              },
            )
          : null,
      body: warehouses.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(child: Text(S.of(context, "noHistory")));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final w = items[index];
              return Card(
                elevation: 0,
                color: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: AppColors.border.withOpacity(0.5)),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    ref.read(activeWarehouseIdProvider.notifier).state = w.id;
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => InventoryScreen(warehouseName: w.name),
                      ),
                    );
                    // Reload warehouses when returning — this is the key fix
                    ref.read(warehousesProvider.notifier).load();
                  },
                  onLongPress: isOwner
                      ? () => _showDeleteWarehouseDialog(context, ref, w.id, w.name)
                      : null,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(18),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.warehouse, size: 28, color: AppColors.primary),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        w.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: AppColors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${w.itemCount} ${S.of(context, "items")}",
                        style: const TextStyle(
                          color: AppColors.warmGrey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("${S.of(context, "error")}: $e")),
      ),
    );
  }

  void _showAddWarehouseDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context, "newWarehouse")),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: S.of(context, "warehouseName"),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(S.of(context, "cancel")),
          ),
          FilledButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              try {
                await ref.read(warehousesProvider.notifier).createWarehouse(nameController.text.trim());
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                // handle error
              }
            },
            child: Text(S.of(context, "create")),
          ),
        ],
      ),
    );
  }

  void _showDeleteWarehouseDialog(BuildContext context, WidgetRef ref, String warehouseId, String warehouseName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context, "deleteWarehouse")),
        content: Text(
          "${S.of(context, "deleteWarehouseConfirm")} \"$warehouseName\"?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(S.of(context, "cancel")),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await ref.read(warehousesProvider.notifier).deleteWarehouse(warehouseId);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(S.of(context, "warehouseDeleted"))),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("${S.of(context, "error")}: $e")),
                  );
                }
              }
            },
            child: Text(S.of(context, "delete")),
          ),
        ],
      ),
    );
  }
}
