class DesignNameModel {
  final String id;
  final String designNumber;
  final String designName;
  final double pricePerMeter;

  DesignNameModel({
    required this.id,
    required this.designNumber,
    required this.designName,
    required this.pricePerMeter,
  });

  factory DesignNameModel.fromJson(Map<String, dynamic> json) {
    return DesignNameModel(
      id: json["id"],
      designNumber: json["design_number"],
      designName: json["design_name"],
      pricePerMeter: double.parse((json["price_per_meter"] ?? 0).toString()),
    );
  }
}


class DesignGroupModel {
  final String designNumber;
  final String designName;
  final double pricePerMeter;
  final int itemCount;
  final double totalMeters;

  DesignGroupModel({
    required this.designNumber,
    required this.designName,
    required this.pricePerMeter,
    required this.itemCount,
    required this.totalMeters,
  });

  factory DesignGroupModel.fromJson(Map<String, dynamic> json) {
    return DesignGroupModel(
      designNumber: json["design_number"],
      designName: json["design_name"] ?? "",
      pricePerMeter: double.parse((json["price_per_meter"] ?? 0).toString()),
      itemCount: json["item_count"] ?? 0,
      totalMeters: double.parse(json["total_meters"].toString()),
    );
  }
}
