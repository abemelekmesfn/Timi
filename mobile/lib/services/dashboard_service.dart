import 'api/api_service.dart';
import '../models/dashboard_stats_model.dart';

class DashboardService {
  Future<DashboardStatsModel> getStats(String period, {String? warehouseId}) async {
    final queryParameters = {"period": period};
    if (warehouseId != null) {
      queryParameters["warehouse_id"] = warehouseId;
    }
    
    final res = await ApiService.dio.get(
      "/inventory/dashboard-stats/",
      queryParameters: queryParameters,
    );
    return DashboardStatsModel.fromJson(res.data);
  }
}
