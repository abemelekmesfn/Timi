import 'api/api_service.dart';
import '../models/inventory_model.dart';
import '../models/movement_model.dart';

class InventoryService {
  Future<List<InventoryModel>> getInventory(String search) async {
    final res = await ApiService.dio.get(
      "/inventory/",
      queryParameters: {"search": search},
    );

    return (res.data as List).map((e) => InventoryModel.fromJson(e)).toList();
  }

  Future<void> addRoll({
    required String roll,
    required String serial,
    required double meters,
  }) async {
    await ApiService.dio.post(
      "/inventory/",
      data: {
        "roll_number": roll,
        "serial_number": serial,
        "original_meters": meters,
      },
    );
  }

  Future<void> moveOut({
    required String id,
    required double meters,
    String note = "",
  }) async {
    await ApiService.dio.post(
      "/inventory/$id/move-out/",
      data: {"meters_out": meters.toStringAsFixed(2), "note": note},
    );
  }

  Future<List<MovementModel>> history() async {
    final res = await ApiService.dio.get("/inventory/history/");

    return (res.data as List).map((e) => MovementModel.fromJson(e)).toList();
  }
}
