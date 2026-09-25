import 'api/api_service.dart';
import '../models/warehouse_model.dart';

class WarehouseService {
  Future<List<WarehouseModel>> getWarehouses() async {
    final res = await ApiService.dio.get("/inventory/warehouses/");
    return (res.data as List).map((e) => WarehouseModel.fromJson(e)).toList();
  }

  Future<void> createWarehouse(String name) async {
    await ApiService.dio.post("/inventory/warehouses/", data: {"name": name});
  }

  Future<void> deleteWarehouse(String id) async {
    await ApiService.dio.delete("/inventory/warehouses/$id/");
  }
}
