import 'package:flutter/material.dart';

import '../../l10n/app_locale.dart';
import '../../models/inventory_model.dart';
import '../../services/inventory_service.dart';

class MoveOutScreen extends StatefulWidget {
  final InventoryModel inventory;

  const MoveOutScreen({super.key, required this.inventory});

  @override
  State<MoveOutScreen> createState() => _MoveOutScreenState();
}

class _MoveOutScreenState extends State<MoveOutScreen> {
  final meter = TextEditingController();
  final note = TextEditingController();

  Future<void> submit() async {
    if (meter.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context, "invalidNumber"))),
      );
      return;
    }

    final value = double.tryParse(meter.text);
    if (value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context, "invalidNumber"))),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(S.of(context, "areYouSure")),
        content: Text(
          "$value ${S.of(context, "moveConfirm")} (${widget.inventory.rollNumber})",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(S.of(context, "cancel")),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(S.of(context, "yes")),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await InventoryService().moveOut(
        id: widget.inventory.id,
        meters: value,
        note: note.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context, "successMoved"))),
        );
        Navigator.pop(context);
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
      appBar: AppBar(title: Text(S.of(context, "moveOut"))),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: meter,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: S.of(context, "meters")),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: note,
              decoration: InputDecoration(labelText: S.of(context, "note")),
            ),
            const Spacer(),
            ElevatedButton(onPressed: submit, child: Text(S.of(context, "confirm"))),
          ],
        ),
      ),
    );
  }
}
