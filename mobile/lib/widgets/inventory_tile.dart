import 'package:flutter/material.dart';
import '../models/inventory_model.dart';
import '../core/theme/app_colors.dart';

class InventoryTile extends StatelessWidget {
  final InventoryModel item;
  final VoidCallback onTap;

  const InventoryTile({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.white,
      margin: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onTap: onTap,
        title: Text(
          item.rollNumber,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            item.serialNumber,
            style: const TextStyle(color: AppColors.warmGrey, fontSize: 13),
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(18),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            "${item.remainingMeters} m",
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
