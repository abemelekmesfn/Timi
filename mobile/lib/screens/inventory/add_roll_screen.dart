import 'package:flutter/material.dart';

import '../../l10n/app_locale.dart';
import '../../services/inventory_service.dart';

class AddRollScreen extends StatefulWidget {
  const AddRollScreen({super.key});

  @override
  State<AddRollScreen> createState() => _AddRollScreenState();
}

class _AddRollScreenState extends State<AddRollScreen> {
  final roll = TextEditingController();
  final serial = TextEditingController();
  final meters = TextEditingController();

  Future<void> save() async {
    try {
      await InventoryService().addRoll(
        roll: roll.text,
        serial: serial.text,
        meters: double.parse(meters.text),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context, "registered"))),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${S.of(context, "error")}: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context, "newRoll"))),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: roll,
              decoration: InputDecoration(labelText: S.of(context, "rollNumber")),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: serial,
              decoration: InputDecoration(labelText: S.of(context, "serialNumber")),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: meters,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: S.of(context, "meters")),
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: save, child: Text(S.of(context, "register"))),
          ],
        ),
      ),
    );
  }
}
