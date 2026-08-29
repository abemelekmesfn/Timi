class InventoryModel {
  final String id;
  final String rollNumber;
  final String serialNumber;
  final double originalMeters;
  final double remainingMeters;

  InventoryModel({
    required this.id,
    required this.rollNumber,
    required this.serialNumber,
    required this.originalMeters,
    required this.remainingMeters,
  });

  factory InventoryModel.fromJson(Map<String, dynamic> json) {
    return InventoryModel(
      id: json["id"],
      rollNumber: json["roll_number"],
      serialNumber: json["serial_number"],
      originalMeters: double.parse(json["original_meters"].toString()),
      remainingMeters: double.parse(json["remaining_meters"].toString()),
    );
  }
}
