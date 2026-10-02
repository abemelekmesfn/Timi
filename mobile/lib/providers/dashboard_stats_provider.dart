import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dashboard_stats_model.dart';
import '../services/dashboard_service.dart';

final dashboardPeriodProvider = StateProvider<String>((ref) => "weekly"); // daily, weekly, yearly
final dashboardWarehouseProvider = StateProvider<String?>((ref) => null);

final dashboardStatsProvider = FutureProvider<DashboardStatsModel>((ref) async {
  final period = ref.watch(dashboardPeriodProvider);
  final warehouseId = ref.watch(dashboardWarehouseProvider);
  return DashboardService().getStats(period, warehouseId: warehouseId);
});
