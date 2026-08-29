import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_locale.dart';
import '../../providers/inventory_provider.dart';
import '../../widgets/inventory_tile.dart';
import 'add_roll_screen.dart';
import 'roll_detail_screen.dart';
import 'inventory_history_screen.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventory = ref.watch(inventoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context, "warehouse")),
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
            MaterialPageRoute(builder: (_) => const AddRollScreen()),
          );
          ref.invalidate(inventoryProvider);
          ref.invalidate(historyProvider);
        },
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: S.of(context, "searchRollSerial"),
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (value) {
                ref.read(searchProvider.notifier).state = value;
              },
            ),
          ),

          Expanded(
            child: inventory.when(
              data: (items) => ListView.builder(
                itemCount: items.length,
                itemBuilder: (_, i) {
                  return InventoryTile(
                    item: items[i],
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RollDetailScreen(inventory: items[i]),
                        ),
                      );
                      ref.invalidate(inventoryProvider);
                      ref.invalidate(historyProvider);
                    },
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(child: Text(S.of(context, "error"))),
            ),
          ),
        ],
      ),
    );
  }
}
