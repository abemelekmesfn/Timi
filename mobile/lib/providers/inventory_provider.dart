import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/inventory_service.dart';
import '../models/inventory_model.dart';
import '../models/movement_model.dart';

final searchProvider = StateProvider<String>((ref) => "");

final inventoryProvider = FutureProvider<List<InventoryModel>>((ref) {
  final search = ref.watch(searchProvider);
  return InventoryService().getInventory(search);
});

final historyProvider = FutureProvider<List<MovementModel>>((ref) {
  return InventoryService().history();
});
