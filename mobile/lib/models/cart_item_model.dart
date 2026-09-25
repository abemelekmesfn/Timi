class CartItemModel {
  final String id;
  final String designNumber;
  final String designName;
  final String moveType; 
  final double value; 
  final String note;

  CartItemModel({
    required this.id,
    required this.designNumber,
    required this.designName,
    required this.moveType,
    required this.value,
    this.note = "",
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id'],
      designNumber: json['design_number'],
      designName: json['design_name'] ?? json['design_number'],
      moveType: json['move_type'],
      value: double.parse(json['requested_value'].toString()),
    );
  }

  CartItemModel copyWith({String? note}) {
    return CartItemModel(
      id: id,
      designNumber: designNumber,
      designName: designName,
      moveType: moveType,
      value: value,
      note: note ?? this.note,
    );
  }
}
