import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_locale.dart';
import '../../services/inventory_service.dart';
import '../../providers/inventory_provider.dart';
import '../../core/theme/app_colors.dart';

class DesignNameDialog extends ConsumerStatefulWidget {
  const DesignNameDialog({super.key});

  @override
  ConsumerState<DesignNameDialog> createState() => _DesignNameDialogState();
}

class _DesignNameDialogState extends ConsumerState<DesignNameDialog> {
  final designNoController = TextEditingController();
  final designNameController = TextEditingController();
  final pricePerMeterController = TextEditingController();
  bool isSubmitting = false;

  Future<void> submit() async {
    if (designNoController.text.trim().isEmpty || designNameController.text.trim().isEmpty) return;

    final price = double.tryParse(pricePerMeterController.text.trim()) ?? 0.0;

    setState(() => isSubmitting = true);
    try {
      await InventoryService().addDesignName(
        designNumber: designNoController.text.trim(),
        designName: designNameController.text.trim(),
        pricePerMeter: price,
      );

      if (mounted) {
        ref.invalidate(designNamesProvider);
        ref.invalidate(designGroupsProvider);
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
        setState(() => isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              S.of(context, "addDesignName"),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: designNoController,
              decoration: InputDecoration(labelText: S.of(context, "designNumber")),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: designNameController,
              decoration: InputDecoration(labelText: S.of(context, "designName")),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pricePerMeterController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: S.of(context, "pricePerMeter")),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(S.of(context, "cancel")),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: isSubmitting ? null : submit,
                  child: isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(S.of(context, "register")),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
