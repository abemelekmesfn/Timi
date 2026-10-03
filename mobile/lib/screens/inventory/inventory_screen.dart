import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/user_provider.dart';

import '../../l10n/app_locale.dart';
import '../../providers/inventory_provider.dart';
import '../../core/theme/app_colors.dart';
import 'add_roll_screen.dart'; // keeping file name for compatibility, but it will be updated inside
import 'inventory_history_screen.dart';
import 'move_out_dialog.dart';
import '../../widgets/friendly_error_widget.dart';

class InventoryScreen extends ConsumerWidget {
  final String warehouseName;

  const InventoryScreen({super.key, required this.warehouseName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final designGroups = ref.watch(designGroupsProvider);
    final userAsync = ref.watch(userProvider);
    final user = userAsync.valueOrNull;
    final isOwner = user?.roles.contains("owner") ?? false;
    final canImport = user?.permissions["can_import_items"] == true;
    final canViewHistory = user?.permissions["can_view_warehouse_history"] == true;
    final canMoveOut = user?.permissions["can_move_out"] == true;

    return Scaffold(
      appBar: AppBar(
        title: Text(warehouseName),
        actions: [
          if (isOwner || canViewHistory)
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const InventoryHistoryScreen(),
                  ),
                );
              },
            ),
        ],
      ),
      floatingActionButton: (isOwner || canImport)
          ? FloatingActionButton(
              child: const Icon(Icons.add),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddItemScreen()),
                );
                ref.invalidate(designGroupsProvider);
                ref.invalidate(historyProvider);
              },
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: S.of(context, "searchDesignColor"),
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (value) {
                ref.read(designSearchProvider.notifier).state = value;
              },
            ),
          ),
          Expanded(
            child: designGroups.when(
              data: (groups) {
                if (groups.isEmpty) {
                  return const Center(child: Text("No items"));
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(designGroupsProvider);
                    await Future.delayed(const Duration(milliseconds: 300));
                  },
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: groups.length,
                    itemBuilder: (_, i) {
                    final group = groups[i];
                    return Card(
                      elevation: 0,
                      color: AppColors.white,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: AppColors.border.withOpacity(0.5)),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          if (isOwner || canMoveOut) {
                            showDialog(
                              context: context,
                              builder: (_) => MoveOutDialog(designGroup: group),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(S.of(context, "error") + ": You do not have permission to move out items.")),
                            );
                          }
                        },
                        onLongPress: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(group.designName.isNotEmpty ? group.designName : S.of(ctx, "designName")),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Design Number: ${group.designNumber}"),
                                  const SizedBox(height: 8),
                                  Text("Price: ${group.pricePerMeter.toStringAsFixed(2)} ETB"),
                                  const SizedBox(height: 8),
                                  Text("Meters Available: ${group.totalMeters}"),
                                  const SizedBox(height: 8),
                                  Text("Items Available: ${group.itemCount}"),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: Text(S.of(ctx, "cancel")),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      group.designName.isNotEmpty ? group.designName : S.of(context, "designName"),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      group.designNumber,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppColors.warmGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withAlpha(18),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      group.itemCount.toString(),
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    Text(
                                      S.of(context, "items"),
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => FriendlyErrorWidget(
                error: err,
                onRetry: () => ref.invalidate(designGroupsProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
