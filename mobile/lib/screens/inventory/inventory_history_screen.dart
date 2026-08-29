import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_locale.dart';
import '../../providers/inventory_provider.dart';
import '../../core/theme/app_colors.dart';

class InventoryHistoryScreen extends ConsumerWidget {
  const InventoryHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(title: Text(S.of(context, "inventoryHistory"))),
      body: history.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(child: Text(S.of(context, "noHistory")));
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                elevation: 0,
                color: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  title: Text(
                    "${item.rollNumber} - ${item.serialNumber}",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      "${S.of(context, "out")}: ${item.metersOut} m\n${S.of(context, "by")}: ${item.movedBy}\n${S.of(context, "date")}: ${item.date.split('T')[0]}",
                      style: const TextStyle(color: AppColors.warmGrey, height: 1.4),
                    ),
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("${S.of(context, "error")}: $err")),
      ),
    );
  }
}
