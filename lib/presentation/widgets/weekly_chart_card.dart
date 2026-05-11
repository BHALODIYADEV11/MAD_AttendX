import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../logic/attendance/attendance_provider.dart';

class WeeklyChartCard extends ConsumerWidget {
  const WeeklyChartCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final recordsAsync = ref.watch(attendanceRecordsProvider);

    return recordsAsync.when(
      data: (records) {
        if (records.isEmpty) return const SizedBox.shrink();

        // Calculate attendance for the last 7 days
        final now = DateTime.now();
        final last7Days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
        
        final List<BarChartGroupData> barGroups = [];
        double maxY = 0;

        for (int i = 0; i < 7; i++) {
          final date = last7Days[i];
          final dayRecords = records.where((r) => 
            r.date.year == date.year &&
            r.date.month == date.month &&
            r.date.day == date.day
          ).toList();

          final present = dayRecords.where((r) => r.isPresent).length.toDouble();
          final total = dayRecords.length.toDouble();
          
          if (total > maxY) maxY = total;

          barGroups.add(
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: total,
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                  width: 14,
                  borderRadius: BorderRadius.circular(4),
                ),
                BarChartRodData(
                  toY: present,
                  color: AppColors.primary,
                  width: 14,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
              showingTooltipIndicators: [1],
            ),
          );
        }

        if (maxY == 0) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Weekly Insights',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimary : AppColors.textLight,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 160,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxY + 1,
                    barTouchData: BarTouchData(
                      enabled: false,
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final date = last7Days[value.toInt()];
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                DateFormat('E').format(date)[0],
                                style: TextStyle(
                                  color: isDark ? AppColors.textSecondary : AppColors.textLightSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: barGroups,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
