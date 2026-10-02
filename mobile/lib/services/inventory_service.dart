import 'package:dio/dio.dart';
import 'api/api_service.dart';
import '../models/inventory_model.dart';
import '../models/movement_model.dart';
import '../models/design_name_model.dart';
import '../models/cart_item_model.dart';

class InventoryService {
  Future<List<InventoryModel>> getInventory(String search, {String? warehouseId}) async {
    final res = await ApiService.dio.get(
      "/inventory/",
      queryParameters: {
        "search": search,
        if (warehouseId != null) "warehouse": warehouseId,
      },
    );

    return (res.data as List).map((e) => InventoryModel.fromJson(e)).toList();
  }

  Future<List<DesignGroupModel>> getDesignGroups(String warehouseId, String search) async {
    final res = await ApiService.dio.get(
      "/inventory/warehouses/$warehouseId/designs/",
      queryParameters: {"search": search},
    );

    return (res.data as List).map((e) => DesignGroupModel.fromJson(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getDesignItems(String warehouseId, String designNumber) async {
    final res = await ApiService.dio.get(
      "/inventory/warehouses/$warehouseId/designs/$designNumber/items/",
    );
    return (res.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> designMoveOutSpecific({
    required String warehouseId,
    required String designNumber,
    required List<String> itemIds,
    String note = "",
  }) async {
    await ApiService.dio.post(
      "/inventory/design-move-out/",
      data: {
        "warehouse": warehouseId,
        "design_number": designNumber,
        "move_type": "specific_items",
        "item_ids": itemIds,
        "note": note,
      },
    );
  }

  Future<void> addItem({
    required String warehouseId,
    required String designNumber,
    String colorNumber = "",
    required double meters,
  }) async {
    await ApiService.dio.post(
      "/inventory/",
      data: {
        "warehouse": warehouseId,
        "design_number": designNumber,
        "color_number": colorNumber,
        "original_meters": meters,
      },
    );
  }

  Future<void> bulkAddItems({
    required String warehouseId,
    required List<Map<String, dynamic>> items,
  }) async {
    await ApiService.dio.post(
      "/inventory/bulk/",
      data: {
        "warehouse": warehouseId,
        "items": items,
      },
    );
  }

  Future<List<CartItemModel>> getCartItems() async {
    final res = await ApiService.dio.get("/inventory/cart/");
    return (res.data as List).map((e) => CartItemModel.fromJson(e)).toList();
  }

  Future<void> addToCart({
    required String warehouseId,
    required String designNumber,
    required String moveType,
    required double value,
  }) async {
    await ApiService.dio.post("/inventory/cart/add/", data: {
      "warehouseId": warehouseId,
      "designNumber": designNumber,
      "moveType": moveType,
      "value": value,
    });
  }

  Future<void> removeFromCart(String id) async {
    await ApiService.dio.post("/inventory/cart/remove/$id/");
  }

  Future<void> clearCart() async {
    await ApiService.dio.post("/inventory/cart/clear/");
  }

  Future<void> checkoutCart(Map<String, String> notes) async {
    await ApiService.dio.post("/inventory/cart/checkout/", data: {
      "notes": notes,
    });
  }

  Future<void> designMoveOut({
    required String warehouseId,
    required String designNumber,
    required String moveType,
    required double value,
    String note = "",
  }) async {
    await ApiService.dio.post(
      "/inventory/design-move-out/",
      data: {
        "warehouse": warehouseId,
        "design_number": designNumber,
        "move_type": moveType,
        "value": value.toStringAsFixed(2),
        "note": note,
      },
    );
  }

  Future<void> batchMoveOut(List<Map<String, dynamic>> items) async {
    await ApiService.dio.post(
      "/inventory/batch-move-out/",
      data: {"items": items},
    );
  }

  Future<void> transferItems({
    required String fromWarehouseId,
    required String toWarehouseId,
    required List<Map<String, dynamic>> items,
    String note = "",
  }) async {
    await ApiService.dio.post(
      "/inventory/transfer/",
      data: {
        "from_warehouse": fromWarehouseId,
        "to_warehouse": toWarehouseId,
        "items": items,
        "note": note,
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

  // ── Design Name Mapping ──

  Future<List<DesignNameModel>> getDesignNames() async {
    final res = await ApiService.dio.get("/inventory/designs/");
    return (res.data as List).map((e) => DesignNameModel.fromJson(e)).toList();
  }

  Future<void> addDesignName({
    required String designNumber,
    required String designName,
    double pricePerMeter = 0.0,
  }) async {
    await ApiService.dio.post(
      "/inventory/designs/",
      data: {
        "design_number": designNumber,
        "design_name": designName,
        "price_per_meter": pricePerMeter,
      },
    );
  }

  Future<void> updateDesignName({
    required String designNumber,
    required String designName,
    double pricePerMeter = 0.0,
  }) async {
    await ApiService.dio.put(
      "/inventory/designs/$designNumber/",
      data: {
        "design_number": designNumber,
        "design_name": designName,
        "price_per_meter": pricePerMeter,
      },
    );
  }

  Future<List<Map<String, dynamic>>> parseExcel(String filePath) async {
    final formData = FormData.fromMap({
      "file": await MultipartFile.fromFile(filePath),
    });
    
    final res = await ApiService.dio.post(
      "/inventory/parse-excel/",
      data: formData,
    );
    
    final List<dynamic> items = res.data["items"] ?? [];
    return items.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}
