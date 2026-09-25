import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_locale.dart';
import '../../providers/inventory_provider.dart';
import '../../core/theme/app_colors.dart';
import 'add_roll_screen.dart'; // keeping file name for compatibility, but it will be updated inside
import 'inventory_history_screen.dart';
import 'move_out_dialog.dart';

class InventoryScreen extends ConsumerWidget {
  final String warehouseName;

  const InventoryScreen({super.key, required this.warehouseName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final designGroups = ref.watch(designGroupsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(warehouseName),
        actions: [
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
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddItemScreen()),
          );
          ref.invalidate(designGroupsProvider);
          ref.invalidate(historyProvider);
        },
      ),
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
                return ListView.builder(
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
                          showDialog(
                            context: context,
                            builder: (_) => MoveOutDialog(designGroup: group),
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
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text("${S.of(context, "error")}: $err")),
            ),
          ),
        ],
      ),
    );
  }
}
