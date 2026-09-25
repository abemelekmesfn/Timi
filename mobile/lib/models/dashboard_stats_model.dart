class DashboardStatsModel {
  final int totalItems;
  final double totalMeters;
  final double totalBirr;
  final List<ChartDataModel> chartData;
  final List<TopDesignModel> topDesigns;

  DashboardStatsModel({
    required this.totalItems,
    required this.totalMeters,
    required this.totalBirr,
    required this.chartData,
    required this.topDesigns,
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return DashboardStatsModel(
      totalItems: json["total_items"] ?? 0,
      totalMeters: double.parse((json["total_meters"] ?? 0).toString()),
      totalBirr: double.parse((json["total_birr"] ?? 0).toString()),
      chartData: (json["chart_data"] as List?)?.map((e) => ChartDataModel.fromJson(e)).toList() ?? [],
      topDesigns: (json["top_designs"] as List?)?.map((e) => TopDesignModel.fromJson(e)).toList() ?? [],
    );
  }
}

class ChartDataModel {
  final String date;
  final double entered;
  final double out;

  ChartDataModel({required this.date, required this.entered, required this.out});

  factory ChartDataModel.fromJson(Map<String, dynamic> json) {
    return ChartDataModel(
      date: json["date"],
      entered: double.parse((json["entered"] ?? 0).toString()),
      out: double.parse((json["out"] ?? 0).toString()),
    );
  }
}

class TopDesignModel {
  final String designNumber;
  final double totalOut;

  TopDesignModel({required this.designNumber, required this.totalOut});

  factory TopDesignModel.fromJson(Map<String, dynamic> json) {
    return TopDesignModel(
      designNumber: json["design_number"],
      totalOut: double.parse((json["total_out"] ?? 0).toString()),
    );
  }
}
