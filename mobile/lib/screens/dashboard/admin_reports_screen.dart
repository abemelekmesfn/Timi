import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../l10n/app_locale.dart';
import '../../providers/dashboard_stats_provider.dart';
import '../../providers/warehouse_provider.dart';
import '../../widgets/summary_card.dart';

class AdminReportsScreen extends ConsumerWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final period = ref.watch(dashboardPeriodProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(S.of(context, "reports")),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.black,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.download, color: AppColors.primary),
            tooltip: S.of(context, "exportReport"),
            onSelected: (val) => _export(context, ref, val, period),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: "pdf",
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, color: AppColors.danger, size: 20),
                    const SizedBox(width: 8),
                    Text(S.of(context, "exportPdf")),
                  ],
                ),
              ),
              PopupMenuItem(
                value: "excel",
                child: Row(
                  children: [
                    Icon(Icons.table_chart, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(S.of(context, "exportExcel")),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.danger, size: 48),
              const SizedBox(height: 12),
              Text("${S.of(context, "error")}: $err", textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(dashboardStatsProvider),
                child: Text(S.of(context, "retry")),
              ),
            ],
          ),
        ),
        data: (stats) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Warehouse Filter ──
                _buildWarehouseSelector(context, ref),
                const SizedBox(height: 12),
                
                // ── Period Filter ──
                _buildPeriodSelector(context, ref, period),
                
                const SizedBox(height: 16),

                // ── Total Assets ETB (highlighted) ──
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0B6E4F), Color(0xFF14A76C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(40),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        S.of(context, "totalAssetsBirr"),
                        style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${NumberFormat('#,##0.00').format(stats.totalBirr)} ETB",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Items & Meters Side by Side ──
                Row(
                  children: [
                    Expanded(
                      child: _miniStatCard(
                        icon: Icons.inventory_2,
                        label: S.of(context, "totalItemsLabel"),
                        value: stats.totalItems.toString(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _miniStatCard(
                        icon: Icons.straighten,
                        label: S.of(context, "totalMetersLabel"),
                        value: "${stats.totalMeters.toStringAsFixed(1)} m",
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 28),
                
                // ── Entered vs Out Bar Chart ──
                _sectionTitle(S.of(context, "enteredVsOut")),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 220,
                        child: stats.chartData.isEmpty
                            ? Center(child: Text(S.of(context, "noData"), style: TextStyle(color: AppColors.warmGrey)))
                            : BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: _calcMaxY(stats.chartData),
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    if (value.toInt() >= 0 && value.toInt() < stats.chartData.length) {
                                      final date = stats.chartData[value.toInt()].date;
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          date.length >= 10 ? date.substring(5) : date,
                                          style: const TextStyle(fontSize: 10, color: AppColors.warmGrey),
                                        ),
                                      );
                                    }
                                    return const Text("");
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  getTitlesWidget: (value, meta) {
                                    return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10, color: AppColors.warmGrey));
                                  },
                                ),
                              ),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(show: false),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: AppColors.border,
                                strokeWidth: 0.5,
                              ),
                            ),
                            barGroups: List.generate(stats.chartData.length, (index) {
                              final d = stats.chartData[index];
                              return BarChartGroupData(
                                x: index,
                                barRods: [
                                  BarChartRodData(
                                    toY: d.entered,
                                    color: const Color(0xFF3B82F6),
                                    width: 10,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  BarChartRodData(
                                    toY: d.out,
                                    color: AppColors.danger,
                                    width: 10,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ],
                              );
                            }),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _legendDot(S.of(context, "entered"), const Color(0xFF3B82F6)),
                          const SizedBox(width: 20),
                          _legendDot(S.of(context, "outLabel"), AppColors.danger),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 28),
                
                // ── Top Designs Pie Chart ──
                _sectionTitle(S.of(context, "topDesignsOut")),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: stats.topDesigns.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(child: Text(S.of(context, "noData"), style: TextStyle(color: AppColors.warmGrey))),
                        )
                      : SizedBox(
                          height: 220,
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: PieChart(
                                  PieChartData(
                                    sectionsSpace: 2,
                                    centerSpaceRadius: 35,
                                    sections: List.generate(stats.topDesigns.length, (index) {
                                      final d = stats.topDesigns[index];
                                      final colors = [
                                        AppColors.primary,
                                        const Color(0xFF3B82F6),
                                        const Color(0xFFF59E0B),
                                        const Color(0xFF8B5CF6),
                                        const Color(0xFF14B8A6),
                                      ];
                                      return PieChartSectionData(
                                        color: colors[index % colors.length],
                                        value: d.totalOut,
                                        title: '${d.totalOut.toStringAsFixed(0)}m',
                                        radius: 50,
                                        titleStyle: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: List.generate(stats.topDesigns.length, (index) {
                                    final d = stats.topDesigns[index];
                                    final colors = [
                                      AppColors.primary,
                                      const Color(0xFF3B82F6),
                                      const Color(0xFFF59E0B),
                                      const Color(0xFF8B5CF6),
                                      const Color(0xFF14B8A6),
                                    ];
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 3),
                                      child: Row(
                                        children: [
                                          Container(width: 10, height: 10, decoration: BoxDecoration(color: colors[index % colors.length], shape: BoxShape.circle)),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              d.designNumber,
                                              style: const TextStyle(fontSize: 12),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
                  
                const SizedBox(height: 48),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildWarehouseSelector(BuildContext context, WidgetRef ref) {
    final warehousesAsync = ref.watch(warehousesProvider);
    final selectedId = ref.watch(dashboardWarehouseProvider);

    return warehousesAsync.when(
      data: (warehouses) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: selectedId,
              isExpanded: true,
              hint: Text(S.of(context, "warehouse")),
              icon: const Icon(Icons.arrow_drop_down, color: AppColors.warmGrey),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text("All Warehouses", style: const TextStyle(fontSize: 14)),
                ),
                ...warehouses.map((w) {
                  return DropdownMenuItem<String?>(
                    value: w.id,
                    child: Text(w.name, style: const TextStyle(fontSize: 14)),
                  );
                }),
              ],
              onChanged: (val) {
                ref.read(dashboardWarehouseProvider.notifier).state = val;
              },
            ),
          ),
        );
      },
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _buildPeriodSelector(BuildContext context, WidgetRef ref, String period) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _periodChip(context, ref, "daily", S.of(context, "daily"), period),
          _periodChip(context, ref, "weekly", S.of(context, "weekly"), period),
          _periodChip(context, ref, "yearly", S.of(context, "yearly"), period),
        ],
      ),
    );
  }

  Widget _periodChip(BuildContext context, WidgetRef ref, String value, String label, String current) {
    final isSelected = value == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(dashboardPeriodProvider.notifier).state = value,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.warmGrey,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniStatCard({required IconData icon, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.warmGrey)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.black)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.black),
    );
  }

  Widget _legendDot(String label, Color color) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.warmGrey)),
      ],
    );
  }

  double _calcMaxY(List chartData) {
    double max = 0;
    for (final d in chartData) {
      if (d.entered > max) max = d.entered;
      if (d.out > max) max = d.out;
    }
    return max * 1.2;
  }

  Future<void> _export(BuildContext context, WidgetRef ref, String format, String period) async {
    try {
      final scaffold = ScaffoldMessenger.of(context);
      scaffold.showSnackBar(
        SnackBar(content: Text("${S.of(context, "exportReport")}...")),
      );

      final baseUrl = AppConstants.baseUrl;
      final lang = Localizations.localeOf(context).languageCode;
      String url = '$baseUrl/inventory/dashboard-export/?export_format=$format&period=$period&lang=$lang';
      
      final warehouseId = ref.read(dashboardWarehouseProvider);
      if (warehouseId != null) {
        url += '&warehouse_id=$warehouseId';
      }
      
      final dio = Dio();
      // Add tunnel bypass header
      dio.options.headers["bypass-tunnel-reminder"] = "true";
      dio.options.headers["User-Agent"] = "TimiApp/1.0";
      
      // Get auth token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      if (token != null) {
        dio.options.headers["Authorization"] = "Bearer $token";
      }
      
      final tempDir = await getTemporaryDirectory();
      final ext = format == 'pdf' ? 'pdf' : 'xlsx';
      final fileName = 'timi_report_${period}_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final filePath = '${tempDir.path}/$fileName';
      
      await dio.download(url, filePath);
      scaffold.hideCurrentSnackBar();
      
      await Share.shareXFiles(
        [XFile(filePath)], 
        text: 'Timi Dashboard Report ($period)',
      );
      
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${S.of(context, "error")}: $e")),
        );
      }
    }
  }
}
