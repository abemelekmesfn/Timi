class WarehouseModel {
  final String id;
  final String name;
  final int itemCount;

  WarehouseModel({
    required this.id,
    required this.name,
    required this.itemCount,
  });

  factory WarehouseModel.fromJson(Map<String, dynamic> json) {
    return WarehouseModel(
      id: json["id"],
      name: json["name"],
      itemCount: json["item_count"] ?? 0,
    );
  }
}
