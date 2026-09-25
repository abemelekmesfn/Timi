class MovementModel {
  final String designNumber;
  final String colorNumber;
  final double metersOut;
  final String movedBy;
  final String date;

  MovementModel({
    required this.designNumber,
    required this.colorNumber,
    required this.metersOut,
    required this.movedBy,
    required this.date,
  });

  factory MovementModel.fromJson(Map<String, dynamic> json) {
    return MovementModel(
      designNumber: json["design_number"] ?? "",
      colorNumber: json["color_number"] ?? "",
      metersOut: double.tryParse(json["meters_out"]?.toString() ?? "0") ?? 0.0,
      movedBy: json["moved_by_name"] ?? "System",
      date: json["created_at"] ?? "",
    );
  }
}
