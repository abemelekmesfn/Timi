import 'package:flutter/material.dart';

import '../../l10n/app_locale.dart';
import '../../models/credit_model.dart';
import '../../services/credit_service.dart';
import '../../core/theme/app_colors.dart';

class PaymentScreen extends StatefulWidget {
  final CreditModel credit;

  const PaymentScreen({super.key, required this.credit});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final amount = TextEditingController();

  double remaining = 0;

  @override
  void initState() {
    super.initState();
    remaining = widget.credit.remainingBalance;
  }

  void calculate(String value) {
    final pay = double.tryParse(value) ?? 0;

    setState(() {
      remaining = widget.credit.remainingBalance - pay;

      if (remaining < 0) {
        remaining = 0;
      }
    });
  }

  Future<void> submit() async {
    final pay = double.tryParse(amount.text);
    if (pay == null || pay <= 0) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(S.of(context, "confirmPayment")),
        content: Text(
          "${pay.toStringAsFixed(0)} ETB - ${widget.credit.client.fullName}?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(S.of(context, "cancel")),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(S.of(context, "confirm")),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await CreditService().receivePayment(id: widget.credit.id, amount: pay);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(S.of(context, "paymentReceived"))),
    );

    Navigator.pop(context);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context, "receivePayment"))),
      body: Padding(
        padding: const EdgeInsets.all(20),
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
                    Text(S.of(context, "currentBalance"), style: const TextStyle(color: AppColors.warmGrey, fontSize: 13)),
                    const SizedBox(height: 8),
                    Text(
                      "${widget.credit.remainingBalance.toStringAsFixed(0)} ETB",
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            TextField(
              controller: amount,
              keyboardType: TextInputType.number,
              onChanged: calculate,
              decoration: InputDecoration(
                labelText: S.of(context, "amount"),
                prefixText: "ETB ",
              ),
            ),

            const SizedBox(height: 20),

            Card(
              elevation: 0,
              color: AppColors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(S.of(context, "remainingAfterPayment"), style: const TextStyle(color: AppColors.warmGrey, fontSize: 13)),
                    const SizedBox(height: 8),
                    Text(
                      "${remaining.toStringAsFixed(0)} ETB",
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            ElevatedButton(
              onPressed: submit,
              child: Text(S.of(context, "confirmPayment")),
            ),
          ],
        ),
      ),
    );
  }
}
