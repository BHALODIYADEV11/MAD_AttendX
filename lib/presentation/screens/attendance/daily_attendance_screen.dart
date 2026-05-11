import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/glass_loading.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/timetable_lecture.dart';
import '../../../data/models/attendance_record.dart';
import '../../../logic/timetable/timetable_provider.dart';
import '../../../logic/attendance/attendance_provider.dart';
import '../../widgets/lecture_tile.dart';

class DailyAttendanceScreen extends ConsumerWidget {
  const DailyAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final todayLectures = ref.watch(todayLecturesProvider);
    final todayAttendance = ref.watch(todayAttendanceProvider);
    final today = DateFormat('EEEE, MMMM d').format(DateTime.now());

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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mark Attendance',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.textPrimary : AppColors.textLight,
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
                    ),
                    // Quick Actions
                    todayLectures.when(
                      data: (lectures) => lectures.isNotEmpty
                          ? _QuickActionsMenu(
                              lectures: lectures,
                              ref: ref,
                              isDark: isDark,
                            )
                          : const SizedBox.shrink(),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Quick stats bar
              todayAttendance.when(
                data: (records) {
                  final present = records.where((r) => r.isPresent).length;
                  final absent = records.where((r) => !r.isPresent).length;
                  final total = records.length;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : AppColors.lightSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06),
                        ),
                      ),
                      child: Row(
                        children: [
                          _QuickStat(
                            label: 'Total',
                            value: '$total',
                            color: AppColors.primary,
                            isDark: isDark,
                          ),
                          Container(
                            width: 1,
                            height: 30,
                            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
                          ),
                          _QuickStat(
                            label: 'Present',
                            value: '$present',
                            color: AppColors.success,
                            isDark: isDark,
                          ),
                          Container(
                            width: 1,
                            height: 30,
                            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
                          ),
                          _QuickStat(
                            label: 'Absent',
                            value: '$absent',
                            color: AppColors.danger,
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              // Lectures list
              Expanded(
                child: todayLectures.when(
                  data: (lectures) {
                    if (lectures.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.event_available_outlined,
                              size: 64,
                              color: isDark ? AppColors.textSecondary : AppColors.textLightSecondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No lectures today! 🎉',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.textPrimary : AppColors.textLight,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Enjoy your day off',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? AppColors.textSecondary : AppColors.textLightSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return todayAttendance.when(
                      data: (records) {
                        // Filter out lectures that already have an attendance record today
                        final unmarkedLectures = lectures.where((l) => _findRecord(records, l) == null).toList();

                        if (unmarkedLectures.isEmpty && lectures.isNotEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.task_alt_rounded,
                                  size: 64,
                                  color: AppColors.success,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'All caught up! 🎉',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.textPrimary : AppColors.textLight,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'You have marked attendance for all classes today.',
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
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                          itemCount: unmarkedLectures.length,
                          itemBuilder: (context, index) {
                            final lecture = unmarkedLectures[index];
                            return LectureTile(
                              lecture: lecture,
                              attendanceStatus: null,
                              onMarkAttendance: (status) {
                                ref.read(attendanceControllerProvider)?.markAttendance(
                                  subjectName: lecture.subjectName,
                                  lectureId: lecture.id,
                                  status: status,
                                );
                              },
                            );
                          },
                        );
                      },
                      loading: () => GlassLoading(message: "Syncing today's records..."),
                      error: (_, __) => const Center(child: Text('Error loading attendance')),
                    );
                  },
                  loading: () => GlassLoading(message: "Syncing timetable..."),
                  error: (e, _) => Center(
                    child: Text('Error: $e'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  AttendanceRecord? _findRecord(List<AttendanceRecord> records, TimetableLecture lecture) {
    try {
      return records.firstWhere((r) => r.lectureId == lecture.id);
    } catch (_) {
      return null;
    }
  }
}

/// Quick actions popup menu for Mark All
class _QuickActionsMenu extends StatelessWidget {
  final List<TimetableLecture> lectures;
  final WidgetRef ref;
  final bool isDark;

  const _QuickActionsMenu({
    required this.lectures,
    required this.ref,
    required this.isDark,
  });

  Future<void> _markAll(BuildContext context, String status) async {
    final controller = ref.read(attendanceControllerProvider);
    if (controller == null) return;

    for (final lecture in lectures) {
      await controller.markAttendance(
        subjectName: lecture.subjectName,
        lectureId: lecture.id,
        status: status,
      );
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'Present'
                ? '✅ All ${lectures.length} lectures marked Present'
                : '❌ All ${lectures.length} lectures marked Absent',
          ),
          backgroundColor: status == 'Present' ? AppColors.success : AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.more_horiz_rounded, color: AppColors.primary, size: 22),
      ),
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (value) => _markAll(context, value),
      itemBuilder: (ctx) => [
        PopupMenuItem(
          value: 'Present',
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Mark All Present',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textPrimary : AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'Absent',
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.cancel_outlined, color: AppColors.danger, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Mark All Absent',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textPrimary : AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _QuickStat({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.textSecondary : AppColors.textLightSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
