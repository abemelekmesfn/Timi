import 'api/api_service.dart';
import '../models/dashboard_stats_model.dart';

class DashboardService {
  Future<DashboardStatsModel> getStats(String period) async {
    final res = await ApiService.dio.get(
      "/inventory/dashboard-stats/",
      queryParameters: {"period": period},
    );
    return DashboardStatsModel.fromJson(res.data);
  }
}
