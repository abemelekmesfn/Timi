import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/app_locale.dart';
import '../../models/credit_model.dart';

import 'payment_screen.dart';
import 'edit_credit_screen.dart';

class CreditDetailScreen extends StatelessWidget {
  final CreditModel credit;

  const CreditDetailScreen({super.key, required this.credit});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(credit.client.fullName)),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Card(
              elevation: 0,
              color: AppColors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      S.of(context, "remainingBalance"),
                      style: const TextStyle(color: AppColors.warmGrey, fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "${credit.remainingBalance.toStringAsFixed(0)} ETB",
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _info(S.of(context, "meters"), credit.meters.toStringAsFixed(1)),
                        _info(S.of(context, "price"), credit.pricePerMeter.toStringAsFixed(0)),
                        _info(S.of(context, "paid"), credit.paidAmount.toStringAsFixed(0)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    child: Text(S.of(context, "pay")),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PaymentScreen(credit: credit),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      side: const BorderSide(color: AppColors.black),
                      foregroundColor: AppColors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(S.of(context, "edit")),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditCreditScreen(credit: credit),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                S.of(context, "summary"),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),

            const SizedBox(height: 10),

            Card(
              elevation: 0,
              color: AppColors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: ListTile(
                title: Text(S.of(context, "totalCredit")),
                trailing: Text(
                  "${credit.totalCredit.toStringAsFixed(0)} ETB",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),

            Card(
              elevation: 0,
              color: AppColors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: ListTile(
                title: Text(S.of(context, "status")),
                trailing: Text(
                  credit.status,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _info(String title, String value) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: AppColors.warmGrey, fontSize: 12)),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ],
    );
  }
}
