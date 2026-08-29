import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/app_locale.dart';
import '../../models/credit_model.dart';
import '../../services/credit_service.dart';

class EditCreditScreen extends StatefulWidget {
  final CreditModel credit;

  const EditCreditScreen({super.key, required this.credit});

  @override
  State<EditCreditScreen> createState() => _EditCreditScreenState();
}

class _EditCreditScreenState extends State<EditCreditScreen> {
  late final TextEditingController firstName;
  late final TextEditingController lastName;
  late final TextEditingController meters;
  late final TextEditingController price;

  double newTotal = 0;

  @override
  void initState() {
    super.initState();

    firstName = TextEditingController(text: widget.credit.client.firstName);
    lastName = TextEditingController(text: widget.credit.client.lastName);

    meters = TextEditingController(
      text: widget.credit.meters.toStringAsFixed(1),
    );

    price = TextEditingController(
      text: widget.credit.pricePerMeter.toStringAsFixed(0),
    );

    calculate();
  }

  void calculate() {
    final m = double.tryParse(meters.text) ?? 0;
    final p = double.tryParse(price.text) ?? 0;

    setState(() {
      newTotal = m * p;
    });
  }

  Future<void> save() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(S.of(context, "confirmEdit")),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    S.of(context, "before"),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Text(
                    S.of(context, "after"),
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            _compare(
              widget.credit.client.fullName,
              "${firstName.text} ${lastName.text}".trim(),
            ),
            _compare("${widget.credit.meters} m", "${meters.text} m"),
            _compare("${widget.credit.pricePerMeter} ETB", "${price.text} ETB"),
            _compare(
              widget.credit.totalCredit.toStringAsFixed(0),
              newTotal.toStringAsFixed(0),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text(S.of(context, "cancel")),
            onPressed: () => Navigator.pop(context, false),
          ),
          FilledButton(
            child: Text(S.of(context, "yes")),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await CreditService().editCredit(widget.credit.id, {
      "first_name": firstName.text,
      "last_name": lastName.text,
      "meters": double.parse(meters.text),
      "price_per_meter": double.parse(price.text),
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(S.of(context, "creditUpdated"))),
    );

    Navigator.pop(context);
  }

  Widget _compare(String oldValue, String newValue) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(oldValue)),
          Expanded(
            child: Text(
              newValue,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context, "editCredit"))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: firstName,
            decoration: InputDecoration(labelText: S.of(context, "firstName")),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: lastName,
            decoration: InputDecoration(labelText: S.of(context, "lastName")),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: meters,
            keyboardType: TextInputType.number,
            onChanged: (_) => calculate(),
            decoration: InputDecoration(labelText: S.of(context, "meters")),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: price,
            keyboardType: TextInputType.number,
            onChanged: (_) => calculate(),
            decoration: InputDecoration(labelText: S.of(context, "pricePerMeter")),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 0,
            color: AppColors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(S.of(context, "newTotalCredit"), style: const TextStyle(color: AppColors.warmGrey, fontSize: 13)),
                  const SizedBox(height: 8),
                  Text(
                    "${newTotal.toStringAsFixed(0)} ETB",
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
          const SizedBox(height: 30),
          ElevatedButton(onPressed: save, child: Text(S.of(context, "saveChanges"))),
        ],
      ),
    );
  }
}
