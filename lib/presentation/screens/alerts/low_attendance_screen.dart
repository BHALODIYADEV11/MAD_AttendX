import 'package:flutter/material.dart';
import '../../widgets/glass_loading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/subject_stats.dart';
import '../../../logic/attendance/attendance_provider.dart';

class LowAttendanceScreen extends ConsumerWidget {
  const LowAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subjectStatsAsync = ref.watch(subjectStatsProvider);
    final criteria = ref.watch(criteriaProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.darkBgGradient : null,
          color: isDark ? null : AppColors.lightBg,
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Low Attendance',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textPrimary : AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Subjects below $criteria% criteria',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? AppColors.textSecondary : AppColors.textLightSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Alert cards
              Expanded(
                child: subjectStatsAsync.when(
                  data: (stats) {
                    final lowStats = stats.where((s) => s.isBelowCriteria(criteria)).toList();
                    
                    if (lowStats.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Icon(
                                Icons.check_circle_outline_rounded,
                                size: 48,
                                color: AppColors.success,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'All Good! 🎉',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.textPrimary : AppColors.textLight,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'All subjects are above the\n$criteria% attendance criteria',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? AppColors.textSecondary : AppColors.textLightSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      itemCount: lowStats.length,
                      itemBuilder: (context, index) {
                        final stat = lowStats[index];
                        return _AlertCard(
                          stats: stat,
                          criteria: criteria,
                          isDark: isDark,
                          isCritical: stat.percentage < (criteria - 15),
                        );
                      },
                    );
                  },
                  loading: () => GlassLoading(message: "Analyzing attendance..."),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final SubjectStats stats;
  final int criteria;
  final bool isDark;
  final bool isCritical;

  const _AlertCard({
    required this.stats,
    required this.criteria,
    required this.isDark,
    required this.isCritical,
  });

  @override
  Widget build(BuildContext context) {
    final lecturesNeeded = stats.lecturesNeededToMeetCriteria(criteria);
    final deficit = criteria - stats.percentage;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCritical
              ? AppColors.danger.withValues(alpha: 0.4)
              : AppColors.warning.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isCritical ? AppColors.danger : AppColors.warning).withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: isCritical ? AppColors.dangerGradient : const LinearGradient(
                    colors: [Color(0xFFFFC542), Color(0xFFFF9A42)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    stats.subjectName.isNotEmpty ? stats.subjectName[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stats.subjectName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: isDark ? AppColors.textPrimary : AppColors.textLight,
                      ),
                    ),
                    Text(
                      '${stats.attendedLectures}/${stats.totalLectures} lectures',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.textSecondary : AppColors.textLightSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Percentage
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${stats.percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isCritical ? AppColors.danger : AppColors.warning,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isCritical ? AppColors.danger : AppColors.warning).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isCritical ? 'Critical' : 'Warning',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isCritical ? AppColors.danger : AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: stats.percentage / 100,
              minHeight: 6,
              backgroundColor: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation(isCritical ? AppColors.danger : AppColors.warning),
            ),
          ),

          const SizedBox(height: 16),

          // Info chips
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBg.withValues(alpha: 0.5) : AppColors.lightBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.trending_down_rounded, size: 18,
                      color: isCritical ? AppColors.danger : AppColors.warning),
                    const SizedBox(width: 8),
                    Text(
                      '${deficit.toStringAsFixed(1)}% below criteria',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.textPrimary : AppColors.textLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.event_available_rounded, size: 18, color: AppColors.success),
                    const SizedBox(width: 8),
                    Text(
                      lecturesNeeded > 0
                          ? 'Attend next $lecturesNeeded lecture${lecturesNeeded > 1 ? 's' : ''} to reach $criteria%'
                          : 'Keep attending to stay above criteria',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
