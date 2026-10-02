import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_locale.dart';
import '../../models/design_name_model.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/inventory_service.dart';
import '../../core/theme/app_colors.dart';

class MoveOutDialog extends ConsumerStatefulWidget {
  final DesignGroupModel designGroup;

  const MoveOutDialog({super.key, required this.designGroup});

  @override
  ConsumerState<MoveOutDialog> createState() => _MoveOutDialogState();
}

class _MoveOutDialogState extends ConsumerState<MoveOutDialog> {
  final valueController = TextEditingController(); // For "items" mode and search in "meters" mode
  String moveType = "items"; // "items" or "meters"

  bool isSubmitting = false;

  // Exact roll selection state
  List<Map<String, dynamic>>? allItems;
  bool isLoadingItems = false;
  Set<String> selectedItemIds = {};
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    valueController.addListener(() {
      if (moveType == "meters") {
        setState(() {
          searchQuery = valueController.text.trim();
        });
      }
    });
  }

  Future<void> fetchItems() async {
    if (allItems != null) return;
    setState(() => isLoadingItems = true);
    try {
      final warehouseId = ref.read(activeWarehouseIdProvider);
      final items = await InventoryService().getDesignItems(warehouseId, widget.designGroup.designNumber);
      if (mounted) {
        setState(() {
          allItems = items;
          isLoadingItems = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoadingItems = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${S.of(context, "error")}: $e")),
        );
      }
    }
  }

  void _onMoveTypeChanged(Set<String> newSelection) {
    setState(() {
      moveType = newSelection.first;
      valueController.clear();
      searchQuery = "";
    });
    if (moveType == "meters") {
      fetchItems();
    }
  }

  Future<void> submit() async {
    if (moveType == "items") {
      if (valueController.text.trim().isEmpty) return;
      final value = double.tryParse(valueController.text);
      if (value == null || value <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.of(context, "invalidNumber"))));
        return;
      }
      if (value > widget.designGroup.itemCount) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.of(context, "notEnoughItems"))));
        return;
      }

      setState(() => isSubmitting = true);
      try {
        final warehouseId = ref.read(activeWarehouseIdProvider);
        await InventoryService().designMoveOut(
          warehouseId: warehouseId,
          designNumber: widget.designGroup.designNumber,
          moveType: "items",
          value: value,
        );
        _onSuccess();
      } catch (e) {
        _onError(e);
      }
    } else {
      // Meters (Specific Items)
      if (selectedItemIds.isEmpty) return;
      setState(() => isSubmitting = true);
      try {
        final warehouseId = ref.read(activeWarehouseIdProvider);
        await InventoryService().designMoveOutSpecific(
          warehouseId: warehouseId,
          designNumber: widget.designGroup.designNumber,
          itemIds: selectedItemIds.toList(),
        );
        _onSuccess();
      } catch (e) {
        _onError(e);
      }
    }
  }

  Future<void> _addToCart() async {
    if (moveType == "items") {
      if (valueController.text.trim().isEmpty) return;
      final value = double.tryParse(valueController.text);
      if (value == null || value <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.of(context, "invalidNumber"))));
        return;
      }
      if (value > widget.designGroup.itemCount) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.of(context, "notEnoughItems"))));
        return;
      }

      setState(() => isSubmitting = true);
      try {
        final warehouseId = ref.read(activeWarehouseIdProvider);
        await ref.read(cartProvider.notifier).addItem(
          warehouseId: warehouseId,
          designNumber: widget.designGroup.designNumber,
          moveType: "items",
          value: value,
        );
        _onCartSuccess();
      } catch (e) {
        _onError(e);
      }
    } else {
      // Meters (Specific Items)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cart support for specific rolls is not yet available.")),
      );
    }
  }

  void _onSuccess() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.of(context, "successMoved"))));
      ref.invalidate(designGroupsProvider);
      ref.invalidate(historyProvider);
      Navigator.pop(context);
    }
  }

  void _onCartSuccess() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.of(context, "addedToCart"))));
      ref.invalidate(designGroupsProvider);
      Navigator.pop(context);
    }
  }

  void _onError(Object e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${S.of(context, "error")}: $e")));
      setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // To solve keyboard distortion on popups (the user mentioned it!), 
    // we use a Padding to handle MediaQuery inset, or just let Dialog handle it
    // by making sure we use SingleChildScrollView and bounds.
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
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
                      label: Text(S.of(context, "byMeter")), // We label it as By Meter, but it selects specific rolls
                    ),
                  ],
                  selected: {moveType},
                  onSelectionChanged: _onMoveTypeChanged,
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: AppColors.primary.withOpacity(0.1),
                    selectedForegroundColor: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 24),

                if (moveType == "items") ...[
                  TextField(
                    controller: valueController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: S.of(context, "numberOfItems"),
                    ),
                  ),
                  const SizedBox(height: 24),
                ] else ...[
                  TextField(
                    controller: valueController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: S.of(context, "searchMeters"),
                      prefixIcon: const Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: _buildRollsList(),
                  ),
                  const SizedBox(height: 16),
                ],

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
                    if (moveType == "items") ...[
                      OutlinedButton.icon(
                        onPressed: isSubmitting ? null : _addToCart,
                        icon: const Icon(Icons.add_shopping_cart, size: 18),
                        label: Text(S.of(context, "addToCart")),
                      ),
                      const SizedBox(height: 8),
                    ],
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

  Widget _buildRollsList() {
    if (isLoadingItems) {
      return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()));
    }

    if (allItems == null || allItems!.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text("No items found.")));
    }

    // Filter and sort items:
    // 1. Pinned (selected) items always at the top
    // 2. Then items matching the search query
    List<Map<String, dynamic>> displayedItems = [];
    
    // First add selected items
    for (var item in allItems!) {
      if (selectedItemIds.contains(item['id'])) {
        displayedItems.add(item);
      }
    }

    // Then add non-selected items that match search query
    for (var item in allItems!) {
      if (!selectedItemIds.contains(item['id'])) {
        final meterStr = item['remaining_meters'].toString();
        if (searchQuery.isEmpty || meterStr.startsWith(searchQuery)) {
          displayedItems.add(item);
        }
      }
    }
    
    if (displayedItems.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text("No matching items.")));
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.warmGrey.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: displayedItems.length,
        separatorBuilder: (context, index) => Divider(height: 1, color: AppColors.warmGrey.withOpacity(0.2)),
        itemBuilder: (context, index) {
          final item = displayedItems[index];
          final itemId = item['id'] as String;
          final meters = item['remaining_meters'].toString();
          final color = item['color_number']?.toString() ?? '';
          final isSelected = selectedItemIds.contains(itemId);

          return InkWell(
            onTap: () {
              setState(() {
                if (isSelected) {
                  selectedItemIds.remove(itemId);
                } else {
                  selectedItemIds.add(itemId);
                  // Optional: clear search if you want
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "$meters m",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (color.isNotEmpty) ...[
                    Text(
                      color,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.warmGrey,
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (bool? val) {
                        setState(() {
                          if (val == true) {
                            selectedItemIds.add(itemId);
                          } else {
                            selectedItemIds.remove(itemId);
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
