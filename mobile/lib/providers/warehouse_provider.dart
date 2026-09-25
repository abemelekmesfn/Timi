import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/warehouse_service.dart';
import '../models/warehouse_model.dart';

class WarehousesNotifier extends StateNotifier<AsyncValue<List<WarehouseModel>>> {
  WarehousesNotifier() : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final items = await WarehouseService().getWarehouses();
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createWarehouse(String name) async {
    await WarehouseService().createWarehouse(name);
    await load();
  }

  Future<void> deleteWarehouse(String id) async {
    await WarehouseService().deleteWarehouse(id);
    await load();
  }
}

final warehousesProvider = StateNotifierProvider<WarehousesNotifier, AsyncValue<List<WarehouseModel>>>((ref) {
  return WarehousesNotifier();
});
