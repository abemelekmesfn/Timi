import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/credit_model.dart';

class CreditTile extends StatelessWidget {
  final CreditModel credit;
  final VoidCallback onTap;

  const CreditTile({super.key, required this.credit, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final remaining = credit.remainingBalance.toStringAsFixed(0);

    return Card(
      elevation: 0,
      color: AppColors.white,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withAlpha(18),
                child: const Icon(Icons.person, color: AppColors.primary, size: 22),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      credit.client.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      "${credit.meters.toStringAsFixed(1)} m × ${credit.pricePerMeter.toStringAsFixed(0)} ETB",
                      style: const TextStyle(color: AppColors.warmGrey, fontSize: 13),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  remaining,
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
