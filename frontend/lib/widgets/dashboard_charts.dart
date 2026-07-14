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
        final width = constraints.maxWidth;
        // 4 columns on wide screens, 2 on medium, 1 on small mobile
        final cols = width > 1150 ? 4 : width > 650 ? 2 : 1;
        const spacing = 10.0;
        final cardWidth = (width - (spacing * (cols - 1))) / cols;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: cardWidth,
              child: _buildEquipmentUtilizationCard(context),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildWeeklyTrendsCard(context),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildShiftTrendsCard(context),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildOperatorPerformanceCard(context),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCard(String title, Widget child, {double height = 185}) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildEquipmentUtilizationCard(BuildContext context) {
    int total = stats.runningEquipmentCount + stats.idleEquipmentCount + stats.breakdownEquipmentCount + stats.stoppageEquipmentCount;
    if (total == 0) return _buildCard('Equipment Utilization', const Center(child: Text('No data available', style: TextStyle(fontSize: 11, color: AppColors.textMuted))));

    return _buildCard(
      'Equipment Utilization',
      Row(
        children: [
          Expanded(
            flex: 4,
            child: PieChart(
              PieChartData(
                sectionsSpace: 1.5,
                centerSpaceRadius: 22,
                sections: [
                  if (stats.runningEquipmentCount > 0)
                    PieChartSectionData(
                      color: AppColors.running,
                      value: stats.runningEquipmentCount.toDouble(),
                      title: '${stats.runningEquipmentCount}',
                      radius: 28,
                      titleStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  if (stats.idleEquipmentCount > 0)
                    PieChartSectionData(
                      color: AppColors.idle,
                      value: stats.idleEquipmentCount.toDouble(),
                      title: '${stats.idleEquipmentCount}',
                      radius: 28,
                      titleStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  if (stats.breakdownEquipmentCount > 0)
                    PieChartSectionData(
                      color: AppColors.breakdown,
                      value: stats.breakdownEquipmentCount.toDouble(),
                      title: '${stats.breakdownEquipmentCount}',
                      radius: 28,
                      titleStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  if (stats.stoppageEquipmentCount > 0)
                    PieChartSectionData(
                      color: AppColors.stoppage,
                      value: stats.stoppageEquipmentCount.toDouble(),
                      title: '${stats.stoppageEquipmentCount}',
                      radius: 28,
                      titleStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _legendItem('Running', AppColors.running),
                const SizedBox(height: 3),
                _legendItem('Idle', AppColors.idle),
                const SizedBox(height: 3),
                _legendItem('Breakdown', AppColors.breakdown),
                const SizedBox(height: 3),
                _legendItem('Stoppage', AppColors.stoppage),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textSecondary, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Widget _buildWeeklyTrendsCard(BuildContext context) {
    if (stats.weeklyTrends.isEmpty) return _buildCard('Weekly Live Entries', const Center(child: Text('No data available', style: TextStyle(fontSize: 11, color: AppColors.textMuted))));
    
    List<FlSpot> spots = [];
    for (int i = 0; i < stats.weeklyTrends.length; i++) {
      spots.add(FlSpot(i.toDouble(), (stats.weeklyTrends[i]['count'] ?? 0).toDouble()));
    }

    return _buildCard(
      'Weekly Entries (Last 7 Days)',
      Padding(
        padding: const EdgeInsets.only(right: 12, top: 4),
        child: LineChart(
          LineChartData(
            lineTouchData: LineTouchData(
              handleBuiltInTouches: true,
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (touchedSpot) => AppColors.primary.withOpacity(0.9),
                tooltipPadding: const EdgeInsets.all(4),
              ),
            ),
            gridData: const FlGridData(show: false),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    int idx = value.toInt();
                    if (idx >= 0 && idx < stats.weeklyTrends.length && idx % 2 == 0) {
                      String raw = stats.weeklyTrends[idx]['date'] ?? '';
                      // Simplify "Jul 12" format
                      return Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(raw, style: const TextStyle(fontSize: 8, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                      );
                    }
                    return const Text('');
                  },
                  reservedSize: 15,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 18,
                  getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(fontSize: 8, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
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
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(show: true, color: AppColors.primary.withOpacity(0.08)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShiftTrendsCard(BuildContext context) {
    if (stats.shiftStats.isEmpty) return _buildCard('Shift Performance', const Center(child: Text('No data available', style: TextStyle(fontSize: 11, color: AppColors.textMuted))));

    return _buildCard(
      'Shift Performance',
      Padding(
        padding: const EdgeInsets.only(right: 8, top: 4),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (group) => AppColors.accent.withOpacity(0.9),
                tooltipPadding: const EdgeInsets.all(4),
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
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(stats.shiftStats[idx]['shift'] ?? '', style: const TextStyle(fontSize: 8, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                      );
                    }
                    return const Text('');
                  },
                  reservedSize: 15,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 18,
                  getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(fontSize: 8, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(
              stats.shiftStats.length,
              (i) => BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: (stats.shiftStats[i]['count'] ?? 0).toDouble(),
                    color: AppColors.accent,
                    width: 12,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOperatorPerformanceCard(BuildContext context) {
    if (stats.operatorStats.isEmpty) return _buildCard('Top Operators', const Center(child: Text('No data available', style: TextStyle(fontSize: 11, color: AppColors.textMuted))));

    final displayList = stats.operatorStats.take(3).toList();

    return _buildCard(
      'Top Operators (Month)',
      ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: displayList.length,
        itemBuilder: (context, index) {
          final op = displayList[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text('${index + 1}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 9)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(op['operatorName'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('${op['totalEntries']} logs', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 9)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
