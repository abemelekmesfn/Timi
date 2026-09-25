class InventoryModel {
  final String id;
  final String designNumber;
  final String colorNumber;
  final double originalMeters;
  final double remainingMeters;

  InventoryModel({
    required this.id,
    required this.designNumber,
    required this.colorNumber,
    required this.originalMeters,
    required this.remainingMeters,
  });

  factory InventoryModel.fromJson(Map<String, dynamic> json) {
    return InventoryModel(
      id: json["id"],
      designNumber: json["design_number"],
      colorNumber: json["color_number"] ?? "",
      originalMeters: double.parse(json["original_meters"].toString()),
      remainingMeters: double.parse(json["remaining_meters"].toString()),
    );
  }
}
