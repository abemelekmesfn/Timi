import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/inventory_service.dart';
import '../models/inventory_model.dart';
import '../models/movement_model.dart';
import '../models/design_name_model.dart';

final searchProvider = StateProvider<String>((ref) => "");

final inventoryProvider = FutureProvider<List<InventoryModel>>((ref) {
  final search = ref.watch(searchProvider);
  return InventoryService().getInventory(search);
});

final historyProvider = FutureProvider<List<MovementModel>>((ref) {
  return InventoryService().history();
});

// ── Active warehouse context ──

final activeWarehouseIdProvider = StateProvider<String>((ref) => "");
final designSearchProvider = StateProvider<String>((ref) => "");

final designGroupsProvider = FutureProvider<List<DesignGroupModel>>((ref) {
  final warehouseId = ref.watch(activeWarehouseIdProvider);
  final search = ref.watch(designSearchProvider);
  if (warehouseId.isEmpty) return Future.value([]);
  return InventoryService().getDesignGroups(warehouseId, search);
});

// ── Design Name Mappings ──

final designNamesProvider = FutureProvider<List<DesignNameModel>>((ref) {
  return InventoryService().getDesignNames();
});
