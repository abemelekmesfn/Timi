import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/app_locale.dart';
import '../../models/inventory_model.dart';
import 'move_out_screen.dart';

class RollDetailScreen extends StatelessWidget {
  final InventoryModel inventory;

  const RollDetailScreen({super.key, required this.inventory});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(inventory.rollNumber)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Card(
              elevation: 0,
              color: AppColors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    ListTile(
                      title: Text(S.of(context, "serial"), style: const TextStyle(color: AppColors.warmGrey, fontSize: 13)),
                      subtitle: Text(inventory.serialNumber, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    ),
                    Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey.shade200),
                    ListTile(
                      title: Text(S.of(context, "original"), style: const TextStyle(color: AppColors.warmGrey, fontSize: 13)),
                      subtitle: Text("${inventory.originalMeters} m", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    ),
                    Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey.shade200),
                    ListTile(
                      title: Text(S.of(context, "remaining"), style: const TextStyle(color: AppColors.warmGrey, fontSize: 13)),
                      subtitle: Text(
                        "${inventory.remainingMeters} m",
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MoveOutScreen(inventory: inventory),
                  ),
                );
              },
              child: Text(S.of(context, "moveOut")),
            ),
          ],
        ),
      ),
    );
  }
}
