import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../logic/attendance/attendance_provider.dart';
import '../../widgets/attendance_ring.dart';
import '../../widgets/subject_card.dart';
import '../../widgets/weekly_chart_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final overallAsync = ref.watch(overallStatsProvider);
    final subjectStatsAsync = ref.watch(subjectStatsProvider);
    final criteria = ref.watch(criteriaProvider);
    final userNameAsync = ref.watch(userNameProvider);
    final today = DateFormat('EEEE, MMM d').format(DateTime.now());

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.darkBgGradient : null,
          color: isDark ? null : AppColors.lightBg,
        ),
        child: SafeArea(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(overallStatsProvider);
              ref.invalidate(subjectStatsProvider);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Attend',
                                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 28),
                                  ),
                                  TextSpan(
                                    text: 'X',
                                    style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 28),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            userNameAsync.when(
                              data: (name) => Text(
                                'Hi, $name 👋',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.textPrimary : AppColors.textLight,
                                ),
                              ),
                              loading: () => Text(
                                'Hi there 👋',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.textPrimary : AppColors.textLight,
                                ),
                              ),
                              error: (_, __) => Text(
                                'Hi there 👋',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.textPrimary : AppColors.textLight,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              today,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? AppColors.textSecondary : AppColors.textLightSecondary,
                              ),
                            ),
                          ],
                        ),
                        // Criteria badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.flag_rounded, size: 16, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(
                                '$criteria%',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Overall attendance card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: overallAsync.when(
                        data: (overall) => Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Overall Attendance',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${overall.percentage.toStringAsFixed(1)}%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${overall.attendedLectures}/${overall.totalLectures} lectures',
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: overall.percentage >= criteria
                                          ? Colors.white.withValues(alpha: 0.2)
                                          : AppColors.danger.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      overall.percentage >= criteria
                                          ? '✓ Above criteria'
                                          : '⚠ Below criteria',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            AttendanceRing(
                              percentage: overall.percentage,
                              size: 110,
                              criteria: criteria,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${overall.percentage.toStringAsFixed(0)}%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text(
                                    'Overall',
                                    style: TextStyle(color: Colors.white60, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        loading: () => _buildEmptyOverall(),
                        error: (_, __) => _buildEmptyOverall(),
                      ),
                    ),
                  ),
                ),

                // Weekly Chart Card
                const SliverToBoxAdapter(
                  child: WeeklyChartCard(),
                ),

                // Section header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Subject-wise',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.textPrimary : AppColors.textLight,
                          ),
                        ),
                        subjectStatsAsync.when(
                          data: (stats) {
                            final lowCount = stats.where((s) => s.isBelowCriteria(criteria)).length;
                            if (lowCount > 0) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.danger.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$lowCount low',
                                  style: const TextStyle(
                                    color: AppColors.danger,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),

                // Subject cards
                subjectStatsAsync.when(
                  data: (stats) {
                    if (stats.isEmpty) {
                      return SliverToBoxAdapter(child: _emptySubjects(isDark));
                    }
                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => SubjectCard(
                            stats: stats[index],
                            criteria: criteria,
                          ),
                          childCount: stats.length,
                        ),
                      ),
                    );
                  },
                  loading: () => SliverToBoxAdapter(child: _emptySubjects(isDark)),
                  error: (_, __) => SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Text(
                          'Could not load stats',
                          style: TextStyle(color: isDark ? AppColors.textSecondary : AppColors.textLightSecondary),
                        ),
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Helper for empty overall stats
Widget _buildEmptyOverall() {
  return Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Overall Attendance',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '0.0%',
              style: TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(
        width: 110,
        height: 110,
        child: AttendanceRing(
          percentage: 0.0,
          size: 110,
          criteria: 75,
        ),
      ),
    ],
  );
}

/// Helper for empty subjects
Widget _emptySubjects(bool isDark) {
  return Padding(
    padding: const EdgeInsets.all(40),
    child: Column(
      children: [
        Icon(
          Icons.school_outlined,
          size: 64,
          color: isDark ? AppColors.textSecondary : AppColors.textLightSecondary,
        ),
        const SizedBox(height: 16),
        Text(
          'No attendance data yet',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textSecondary : AppColors.textLightSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Set up your timetable and start\nmarking attendance to see stats here.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: isDark
                ? AppColors.textSecondary.withValues(alpha: 0.7)
                : AppColors.textLightSecondary.withValues(alpha: 0.7),
          ),
        ),
      ],
    ),
  );
}
