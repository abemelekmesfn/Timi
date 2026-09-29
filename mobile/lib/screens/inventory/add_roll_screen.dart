import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';

import '../../l10n/app_locale.dart';
import '../../services/inventory_service.dart';
import '../../providers/inventory_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/warehouse_provider.dart';
import 'design_name_dialog.dart';

class AddItemScreen extends ConsumerStatefulWidget {
  const AddItemScreen({super.key});

  @override
  ConsumerState<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends ConsumerState<AddItemScreen> {
  final designNoController = TextEditingController();
  final colorNoController = TextEditingController();
  final metersController = TextEditingController();

  bool isSaving = false;

  Future<void> saveManual() async {
    if (designNoController.text.trim().isEmpty || metersController.text.trim().isEmpty) return;

    setState(() => isSaving = true);
    try {
      final warehouseId = ref.read(activeWarehouseIdProvider);
      await InventoryService().addItem(
        warehouseId: warehouseId,
        designNumber: designNoController.text.trim(),
        colorNumber: colorNoController.text.trim(),
        meters: double.parse(metersController.text.trim()),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context, "registered"))),
        );
        ref.read(warehousesProvider.notifier).load();
        ref.invalidate(designGroupsProvider);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${S.of(context, "error")}: $e")),
        );
        setState(() => isSaving = false);
      }
    }
  }

  Future<void> importExcel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
      );

      if (result == null || result.files.single.path == null) return;

      // Show a loading indicator since uploading and parsing might take a second
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      // Upload the file to the backend to be parsed
      final parsedItems = await InventoryService().parseExcel(result.files.single.path!);

      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading dialog

      debugPrint("Excel: Backend parsed ${parsedItems.length} items total");

      if (parsedItems.isNotEmpty) {
        _showBatchConfirmation(parsedItems);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No valid items found in file")),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Dismiss loading dialog if error
      
      String errorMsg = e.toString();
      if (e is DioException && e.response?.data != null) {
        if (e.response!.data is Map && e.response!.data['error'] != null) {
          errorMsg = e.response!.data['error'];
        } else {
          errorMsg = e.response!.data.toString();
        }
      }
      
      debugPrint("Excel import error: $errorMsg");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Import error: $errorMsg"),
            duration: const Duration(seconds: 10),
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> _parseRows(List<List<dynamic>> rows) {
    List<Map<String, dynamic>> parsedItems = [];
    int headerRowIndex = -1;
    List<List<int>> dataSets = [];

    // ── Step 1: Auto-detect header row and column positions ──
    for (int r = 0; r < rows.length && r < 10; r++) {
      var row = rows[r];
      List<int> desColumns = [];
      List<int> colColumns = [];
      List<int> qtyColumns = [];

      for (int c = 0; c < row.length; c++) {
        if (row[c] == null) continue;
        String cellText = row[c].toString().toUpperCase().trim();

        if (cellText.contains("DES")) {
          desColumns.add(c);
        } else if (cellText.contains("COL") && !cellText.contains("C/NO")) {
          colColumns.add(c);
        } else if (cellText.contains("QTY") || cellText.contains("MET")) {
          qtyColumns.add(c);
        }
      }

      if (desColumns.isNotEmpty && qtyColumns.isNotEmpty) {
        headerRowIndex = r;
        for (int d = 0; d < desColumns.length; d++) {
          int desIdx = desColumns[d];
          int qtyIdx = -1;
          for (var q in qtyColumns) {
            if (q > desIdx) { qtyIdx = q; break; }
          }
          if (qtyIdx == -1) continue;

          int colIdx = -1;
          for (var cl in colColumns) {
            if (cl > desIdx && cl < qtyIdx) { colIdx = cl; break; }
          }
          dataSets.add([desIdx, colIdx, qtyIdx]);
        }
        break;
      }
    }

    // Fallback if no header found
    if (headerRowIndex == -1 || dataSets.isEmpty) {
      headerRowIndex = 1;
      dataSets = [
        [1, 2, 3],
        [5, 6, 7],
      ];
    }

    debugPrint("Parser: headerRow=$headerRowIndex, dataSets=$dataSets");

    // ── Step 2: Parse data rows ──
    for (int i = headerRowIndex + 1; i < rows.length; i++) {
      var row = rows[i];
      if (row.isEmpty) continue;

      for (var ds in dataSets) {
        int desIdx = ds[0];
        int colIdx = ds[1];
        int qtyIdx = ds[2];

        if (qtyIdx >= row.length) continue;
        if (desIdx >= row.length || row[desIdx] == null) continue;
        if (row[qtyIdx] == null) continue;

        final designNo = row[desIdx].toString().trim();
        final colorNo = (colIdx >= 0 && colIdx < row.length && row[colIdx] != null)
            ? row[colIdx].toString().trim()
            : "";
        final metersStr = row[qtyIdx].toString().trim();
        final meters = double.tryParse(metersStr);

        if (designNo.isNotEmpty && meters != null && meters > 0) {
          parsedItems.add({
            "design_number": designNo,
            "color_number": colorNo,
            "original_meters": meters,
          });
        }
      }
    }
    return parsedItems;
  }

  void _showBatchConfirmation(List<Map<String, dynamic>> items) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BatchConfirmScreen(items: items),
      ),
    ).then((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context, "newDesign")),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: S.of(context, "addDesignName"),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const DesignNameDialog(),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: designNoController,
              decoration: InputDecoration(labelText: S.of(context, "designNumber")),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: colorNoController,
              decoration: InputDecoration(labelText: "${S.of(context, "colorNumber")} (${S.of(context, "optional")})"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: metersController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: S.of(context, "meters")),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isSaving ? null : saveManual,
              child: isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(S.of(context, "register")),
            ),

            const SizedBox(height: 40),
            Row(
              children: [
                const Expanded(child: Divider()),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text("OR", style: TextStyle(color: AppColors.warmGrey)),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 40),

            InkWell(
              onTap: importExcel,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary, width: 2, style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(16),
                  color: AppColors.primary.withOpacity(0.05),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.upload_file, size: 48, color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text(
                      S.of(context, "importExcel"),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      S.of(context, "dragDropExcel"),
                      style: const TextStyle(color: AppColors.warmGrey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Batch Confirmation Screen ──

class BatchConfirmScreen extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> items;

  const BatchConfirmScreen({super.key, required this.items});

  @override
  ConsumerState<BatchConfirmScreen> createState() => _BatchConfirmScreenState();
}

class _BatchConfirmScreenState extends ConsumerState<BatchConfirmScreen> {
  late List<Map<String, dynamic>> pendingItems;
  List<Map<String, dynamic>> currentBatch = [];
  bool isUploading = false;
  int batchSize = 150;
  int totalImported = 0;

  @override
  void initState() {
    super.initState();
    pendingItems = List.from(widget.items);
    _loadNextBatch();
  }

  void _loadNextBatch() {
    if (pendingItems.isEmpty) {
      if (mounted) Navigator.pop(context);
      return;
    }

    setState(() {
      int take = pendingItems.length > batchSize ? batchSize : pendingItems.length;
      currentBatch = pendingItems.sublist(0, take);
    });
  }

  Future<void> _confirmBatch() async {
    setState(() => isUploading = true);
    try {
      final warehouseId = ref.read(activeWarehouseIdProvider);

      final cleanBatch = currentBatch.map((e) {
        return {
          "design_number": e["design_number"] ?? "",
          "color_number": e["color_number"] ?? "",
          "original_meters": double.tryParse(e["original_meters"].toString()) ?? 0.0,
        };
      }).toList();

      await InventoryService().bulkAddItems(
        warehouseId: warehouseId,
        items: cleanBatch,
      );

      totalImported += currentBatch.length;
      pendingItems.removeRange(0, currentBatch.length);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$totalImported ${S.of(context, "itemsImported")}")),
        );
      }

      setState(() => isUploading = false);
      if (pendingItems.isEmpty) {
        if (mounted) {
          ref.read(warehousesProvider.notifier).load();
          ref.invalidate(designGroupsProvider);
          Navigator.pop(context); // Close the batch confirmation dialog
        }
      } else {
        _loadNextBatch();
      }
    } catch (e) {
      setState(() => isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${S.of(context, "error")}: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentBatch.isEmpty) {
      return Scaffold(body: Center(child: Text(S.of(context, "finished"))));
    }

    return Scaffold(
      appBar: AppBar(title: Text(S.of(context, "batchConfirmation"))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Confirming ${currentBatch.length} items (Total remaining: ${pendingItems.length})",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: currentBatch.length,
              itemBuilder: (context, index) {
                final item = currentBatch[index];
                return ListTile(
                  title: TextFormField(
                    initialValue: item["design_number"].toString(),
                    decoration: InputDecoration(labelText: S.of(context, "designNumber")),
                    onChanged: (val) => item["design_number"] = val,
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: item["color_number"].toString(),
                            decoration: InputDecoration(labelText: S.of(context, "colorNumber")),
                            onChanged: (val) => item["color_number"] = val,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: item["original_meters"].toString(),
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(labelText: S.of(context, "meters")),
                            onChanged: (val) => item["original_meters"] = val,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: isUploading ? null : _confirmBatch,
              child: isUploading
                  ? Text(S.of(context, "confirming"))
                  : Text(S.of(context, "confirmBatch")),
            ),
          ),
        ],
      ),
    );
  }
}
