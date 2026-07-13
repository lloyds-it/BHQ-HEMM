import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/theme.dart';
import '../providers/dashboard_provider.dart';

class DashboardAnalyticsGrid extends StatelessWidget {
  final DashboardProvider stats;
  
  const DashboardAnalyticsGrid({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 800;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: isDesktop ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth,
              child: _buildEquipmentUtilizationCard(context),
            ),
            SizedBox(
              width: isDesktop ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth,
              child: _buildWeeklyTrendsCard(context),
            ),
            SizedBox(
              width: isDesktop ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth,
              child: _buildShiftTrendsCard(context),
            ),
            SizedBox(
              width: isDesktop ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth,
              child: _buildOperatorPerformanceCard(context),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCard(String title, Widget child, {double height = 300}) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildEquipmentUtilizationCard(BuildContext context) {
    int total = stats.runningEquipmentCount + stats.idleEquipmentCount + stats.breakdownEquipmentCount + stats.stoppageEquipmentCount;
    if (total == 0) return _buildCard('Equipment Utilization', const Center(child: Text('No data')));

    return _buildCard(
      'Equipment Utilization',
      PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          sections: [
            PieChartSectionData(
              color: AppColors.running,
              value: stats.runningEquipmentCount.toDouble(),
              title: 'Running',
              radius: 50,
              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            PieChartSectionData(
              color: AppColors.idle,
              value: stats.idleEquipmentCount.toDouble(),
              title: 'Idle',
              radius: 50,
              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            PieChartSectionData(
              color: AppColors.breakdown,
              value: stats.breakdownEquipmentCount.toDouble(),
              title: 'Breakdown',
              radius: 50,
              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            PieChartSectionData(
              color: AppColors.stoppage,
              value: stats.stoppageEquipmentCount.toDouble(),
              title: 'Stoppage',
              radius: 50,
              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyTrendsCard(BuildContext context) {
    if (stats.weeklyTrends.isEmpty) return _buildCard('Weekly Trends', const Center(child: Text('No data')));
    
    List<FlSpot> spots = [];
    for (int i = 0; i < stats.weeklyTrends.length; i++) {
      spots.add(FlSpot(i.toDouble(), (stats.weeklyTrends[i]['count'] ?? 0).toDouble()));
    }

    return _buildCard(
      'Weekly Live Entries (Last 7 Days)',
      LineChart(
        LineChartData(
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => Colors.blueGrey.withOpacity(0.8),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) => FlLine(color: AppColors.border, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int idx = value.toInt();
                  if (idx >= 0 && idx < stats.weeklyTrends.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(stats.weeklyTrends[idx]['date'] ?? '', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    );
                  }
                  return const Text('');
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: true, color: AppColors.primary.withOpacity(0.1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShiftTrendsCard(BuildContext context) {
    if (stats.shiftStats.isEmpty) return _buildCard('Shift Performance', const Center(child: Text('No data')));

    return _buildCard(
      'Shift Performance (Last 7 Days)',
      BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => Colors.blueGrey.withOpacity(0.8),
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int idx = value.toInt();
                  if (idx >= 0 && idx < stats.shiftStats.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(stats.shiftStats[idx]['shift'] ?? '', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    );
                  }
                  return const Text('');
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) => FlLine(color: AppColors.border, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(
            stats.shiftStats.length,
            (i) => BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: (stats.shiftStats[i]['count'] ?? 0).toDouble(),
                  color: AppColors.accent,
                  width: 20,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOperatorPerformanceCard(BuildContext context) {
    if (stats.operatorStats.isEmpty) return _buildCard('Top Operators', const Center(child: Text('No data')));

    return _buildCard(
      'Top Operators (This Month)',
      ListView.separated(
        itemCount: stats.operatorStats.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final op = stats.operatorStats[index];
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text('${index + 1}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
            title: Text(op['operatorName'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('${op['totalEntries']} entries', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          );
        },
      ),
    );
  }
}
