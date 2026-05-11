import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/timetable_lecture.dart';

class LectureTile extends StatelessWidget {
  final TimetableLecture lecture;
  final String? attendanceStatus; // null = not marked, "Present", "Absent"
  final Function(String status)? onMarkAttendance;
  final VoidCallback? onDelete;

  const LectureTile({
    super.key,
    required this.lecture,
    this.attendanceStatus,
    this.onMarkAttendance,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPresent = attendanceStatus == 'Present';
    final isAbsent = attendanceStatus == 'Absent';
    final isMarked = attendanceStatus != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPresent
              ? AppColors.success.withValues(alpha: 0.4)
              : isAbsent
                  ? AppColors.danger.withValues(alpha: 0.4)
                  : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06)),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Time indicator
                Container(
                  width: 4,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: isPresent
                        ? AppColors.successGradient
                        : isAbsent
                            ? AppColors.dangerGradient
                            : AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 14),

                // Lecture info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              lecture.subjectName,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: isDark ? AppColors.textPrimary : AppColors.textLight,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: lecture.type == 'Lab'
                                  ? AppColors.warning.withValues(alpha: 0.15)
                                  : AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              lecture.type,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: lecture.type == 'Lab' ? AppColors.warning : AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: isDark
                                ? AppColors.textSecondary
                                : AppColors.textLightSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${lecture.startTime} - ${lecture.endTime}',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.textSecondary
                                  : AppColors.textLightSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Status badge
                if (isMarked)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (isPresent ? AppColors.success : AppColors.danger)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPresent ? Icons.check_circle : Icons.cancel,
                          size: 16,
                          color: isPresent ? AppColors.success : AppColors.danger,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isPresent ? 'Present' : 'Absent',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isPresent ? AppColors.success : AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                  ),

                if (onDelete != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onDelete,
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.danger.withValues(alpha: 0.6),
                      size: 20,
                    ),
                  ),
                ],
              ],
            ),

            // Attendance action buttons
            if (onMarkAttendance != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _AttendanceButton(
                      label: 'Present',
                      icon: Icons.check_rounded,
                      isSelected: isPresent,
                      color: AppColors.success,
                      onTap: () => onMarkAttendance!('Present'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _AttendanceButton(
                      label: 'Absent',
                      icon: Icons.close_rounded,
                      isSelected: isAbsent,
                      color: AppColors.danger,
                      onTap: () => onMarkAttendance!('Absent'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AttendanceButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _AttendanceButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: isSelected ? 1 : 0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : color,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
