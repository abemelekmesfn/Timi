class MovementModel {
  final String rollNumber;
  final String serialNumber;
  final double metersOut;
  final String movedBy;
  final String date;

  MovementModel({
    required this.rollNumber,
    required this.serialNumber,
    required this.metersOut,
    required this.movedBy,
    required this.date,
  });

  factory MovementModel.fromJson(Map<String, dynamic> json) {
    return MovementModel(
      rollNumber: json["roll_number"],
      serialNumber: json["serial_number"],
      metersOut: double.parse(json["meters_out"].toString()),
      movedBy: json["moved_by_name"],
      date: json["created_at"],
    );
  }
}
