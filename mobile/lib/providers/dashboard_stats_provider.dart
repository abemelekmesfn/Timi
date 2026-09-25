import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dashboard_stats_model.dart';
import '../services/dashboard_service.dart';

final dashboardPeriodProvider = StateProvider<String>((ref) => "weekly"); // daily, weekly, yearly

final dashboardStatsProvider = FutureProvider<DashboardStatsModel>((ref) async {
  final period = ref.watch(dashboardPeriodProvider);
  return DashboardService().getStats(period);
});
