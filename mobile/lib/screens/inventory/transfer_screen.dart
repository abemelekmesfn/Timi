import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/app_locale.dart';
import '../../providers/warehouse_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../services/inventory_service.dart';
import '../../models/warehouse_model.dart';
import '../../models/inventory_model.dart';
import '../../models/design_name_model.dart';

class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({super.key});

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  WarehouseModel? fromWarehouse;
  WarehouseModel? toWarehouse;
  
  // List of transfer items. Each item is a map with designNumber, moveType, value
  final List<Map<String, dynamic>> transferItems = [];

  bool isSubmitting = false;

  void _addTransferItem() {
    if (fromWarehouse == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context, "selectWarehouse"))), // Make sure you have translation or use generic string
        );
        return;
    }
    
    final valueController = TextEditingController();
    String moveType = "items";
    DesignGroupModel? selectedDesign;
    final designsFuture = InventoryService().getDesignGroups(fromWarehouse!.id, "");

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(S.of(context, "addTransferItem")),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FutureBuilder<List<DesignGroupModel>>(
                  future: designsFuture,
                  builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                      }
                      if (snapshot.hasError) {
                          return Text(S.of(context, "error"));
                      }
                      
                      final designs = snapshot.data ?? [];
                      if (designs.isEmpty) {
                          return Text(S.of(context, "inventoryEmpty"));
                      }

                      return DropdownButtonFormField<DesignGroupModel>(
                          value: selectedDesign,
                          decoration: InputDecoration(labelText: S.of(context, "designName")), // The user wants design name
                          items: designs.map((d) => DropdownMenuItem(
                              value: d,
                              child: Text(d.designName.isNotEmpty ? d.designName : d.designNumber),
                          )).toList(),
                          onChanged: (val) {
                              setStateDialog(() => selectedDesign = val);
                          },
                      );
                  }
              ),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(value: "items", label: Text(S.of(context, "byItem"))),
                  ButtonSegment(value: "meters", label: Text(S.of(context, "byMeter"))),
                ],
                selected: {moveType},
                onSelectionChanged: (set) {
                  setStateDialog(() => moveType = set.first);
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: valueController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: moveType == "items" ? S.of(context, "numberOfItems") : S.of(context, "meters"),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(S.of(context, "cancel")),
            ),
            FilledButton(
              onPressed: () {
                if (selectedDesign == null || valueController.text.trim().isEmpty) return;
                final value = double.tryParse(valueController.text);
                if (value == null || value <= 0) return;

                setState(() {
                  transferItems.add({
                    "design_number": selectedDesign!.designNumber,
                    "design_name": selectedDesign!.designName.isNotEmpty ? selectedDesign!.designName : selectedDesign!.designNumber,
                    "move_type": moveType,
                    "value": value,
                  });
                });
                Navigator.pop(context);
              },
              child: Text(S.of(context, "addTransferItem")),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitTransfer() async {
    if (fromWarehouse == null || toWarehouse == null || transferItems.isEmpty) return;

    if (fromWarehouse!.id == toWarehouse!.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context, "sameWarehouseError"))),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      await InventoryService().transferItems(
        fromWarehouseId: fromWarehouse!.id,
        toWarehouseId: toWarehouse!.id,
        items: transferItems,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context, "successTransferred"))),
        );
        ref.read(warehousesProvider.notifier).load();
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

  @override
  Widget build(BuildContext context) {
    final warehouses = ref.watch(warehousesProvider).valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context, "transfer")),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<WarehouseModel>(
                    decoration: InputDecoration(labelText: S.of(context, "fromWarehouse")),
                    value: fromWarehouse,
                    items: warehouses.map((w) {
                      return DropdownMenuItem(value: w, child: Text(w.name));
                    }).toList(),
                    onChanged: (val) => setState(() => fromWarehouse = val),
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.arrow_forward, color: AppColors.primary),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<WarehouseModel>(
                    decoration: InputDecoration(labelText: S.of(context, "toWarehouse")),
                    value: toWarehouse,
                    items: warehouses.map((w) {
                      return DropdownMenuItem(value: w, child: Text(w.name));
                    }).toList(),
                    onChanged: (val) => setState(() => toWarehouse = val),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  S.of(context, "items"),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                OutlinedButton.icon(
                  onPressed: _addTransferItem,
                  icon: const Icon(Icons.add),
                  label: Text(S.of(context, "addTransferItem")),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: transferItems.isEmpty
                  ? Center(child: Text(S.of(context, "noData")))
                  : ListView.builder(
                      itemCount: transferItems.length,
                      itemBuilder: (context, index) {
                        final item = transferItems[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(item["design_name"] ?? item["design_number"]),
                            subtitle: Text("${item["value"]} ${item["move_type"] == 'items' ? S.of(context, 'items') : S.of(context, 'meters')}"),
                            trailing: IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  transferItems.removeAt(index);
                                });
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: isSubmitting || transferItems.isEmpty || fromWarehouse == null || toWarehouse == null ? null : _submitTransfer,
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: isSubmitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(S.of(context, "transferConfirm")),
            ),
          ],
        ),
      ),
    );
  }
}
