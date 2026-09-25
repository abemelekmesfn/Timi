import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_locale.dart';
import '../../models/design_name_model.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/cart_provider.dart';
import '../../models/cart_item_model.dart';
import '../../services/inventory_service.dart';
import '../../core/theme/app_colors.dart';

class MoveOutDialog extends ConsumerStatefulWidget {
  final DesignGroupModel designGroup;

  const MoveOutDialog({super.key, required this.designGroup});

  @override
  ConsumerState<MoveOutDialog> createState() => _MoveOutDialogState();
}

class _MoveOutDialogState extends ConsumerState<MoveOutDialog> {
  final valueController = TextEditingController();
  String moveType = "items"; // "items" or "meters"

  bool isSubmitting = false;

  Future<void> submit() async {
    if (valueController.text.trim().isEmpty) return;
    
    final value = double.tryParse(valueController.text);
    if (value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context, "invalidNumber"))),
      );
      return;
    }

    if (moveType == "items" && value > widget.designGroup.itemCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context, "notEnoughItems"))),
      );
      return;
    }
    
    if (moveType == "meters" && value > widget.designGroup.totalMeters) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context, "notEnoughItems"))),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final warehouseId = ref.read(activeWarehouseIdProvider);
      await InventoryService().designMoveOut(
        warehouseId: warehouseId,
        designNumber: widget.designGroup.designNumber,
        moveType: moveType,
        value: value,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context, "successMoved"))),
        );
        ref.invalidate(designGroupsProvider);
        ref.invalidate(historyProvider);
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

  Future<void> _addToCart() async {
    if (valueController.text.trim().isEmpty) return;

    final value = double.tryParse(valueController.text);
    if (value == null || value <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context, "invalidNumber"))),
        );
        return;
    }

    if (moveType == "items" && value > widget.designGroup.itemCount) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context, "notEnoughItems"))),
        );
        return;
    }

    if (moveType == "meters" && value > widget.designGroup.totalMeters) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context, "notEnoughItems"))),
        );
        return;
    }

    setState(() => isSubmitting = true);

    try {
        final warehouseId = ref.read(activeWarehouseIdProvider);

        await ref.read(cartProvider.notifier).addItem(
            warehouseId: warehouseId,
            designNumber: widget.designGroup.designNumber,
            moveType: moveType,
            value: value,
        );

        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(S.of(context, "addedToCart"))),
            );
            ref.invalidate(designGroupsProvider);
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
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                S.of(context, "moveOut"),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "${widget.designGroup.designName} (${widget.designGroup.designNumber})",
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.warmGrey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: "items",
                    label: Text(S.of(context, "byItem")),
                  ),
                  ButtonSegment(
                    value: "meters",
                    label: Text(S.of(context, "byMeter")),
                  ),
                ],
                selected: {moveType},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    moveType = newSelection.first;
                    valueController.clear();
                  });
                },
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: AppColors.primary.withOpacity(0.1),
                  selectedForegroundColor: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: valueController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: moveType == "items" ? S.of(context, "numberOfItems") : S.of(context, "meters"),
                  suffixText: moveType == "items" ? "" : "m",
                ),
              ),
              const SizedBox(height: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    onPressed: isSubmitting ? null : submit,
                    child: isSubmitting 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(S.of(context, "confirm")),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: isSubmitting ? null : _addToCart,
                    icon: const Icon(Icons.add_shopping_cart, size: 18),
                    label: Text(S.of(context, "addToCart")),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(S.of(context, "cancel")),
                  ),
                ],
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}
