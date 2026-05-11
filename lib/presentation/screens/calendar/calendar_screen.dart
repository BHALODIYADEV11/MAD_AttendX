import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/glass_loading.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/attendance_record.dart';
import '../../../logic/attendance/attendance_provider.dart';
import '../../../data/repositories/attendance_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';


class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allRecordsAsync = ref.watch(attendanceRecordsProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.darkBgGradient : null,
          color: isDark ? null : AppColors.lightBg,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Calendar',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textPrimary : AppColors.textLight,
                      ),
                    ),
                    // Today button
                    GestureDetector(
                      onTap: () => setState(() {
                        _focusedMonth = DateTime.now();
                        _selectedDate = null;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Today',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Month navigator
              _MonthNavigator(
                focusedMonth: _focusedMonth,
                isDark: isDark,
                onPrev: () => setState(() {
                  _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
                }),
                onNext: () => setState(() {
                  _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
                }),
              ),

              const SizedBox(height: 8),

              // Day-of-week labels
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: const ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                      .map((d) => Expanded(
                            child: Center(
                              child: Text(
                                d,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 8),

              // Calendar grid
              allRecordsAsync.when(
                data: (records) => _CalendarGrid(
                  focusedMonth: _focusedMonth,
                  records: records,
                  selectedDate: _selectedDate,
                  isDark: isDark,
                  onDayTap: (date) {
                    setState(() => _selectedDate = date);
                    _showDayDetail(context, date, records, isDark);
                  },
                ),
                loading: () => Expanded(child: GlassLoading(message: "Loading calendar records...")),
                error: (_, __) => const Expanded(
                  child: Center(child: Text('Error loading attendance')),
                ),
              ),

              // Legend
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const _LegendDot(color: AppColors.success, label: 'Present'),
                    const SizedBox(width: 20),
                    const _LegendDot(color: AppColors.danger, label: 'Absent'),
                    const SizedBox(width: 20),
                    const _LegendDot(color: AppColors.textSecondary, label: 'No Class'),
                    const SizedBox(width: 20),
                    const _LegendDot(color: AppColors.warning, label: 'Partial'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDayDetail(
    BuildContext context,
    DateTime date,
    List<AttendanceRecord> allRecords,
    bool isDark,
  ) {
    final dayRecords = allRecords.where((r) {
      return r.date.year == date.year &&
          r.date.month == date.month &&
          r.date.day == date.day;
    }).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DayDetailSheet(
        date: date,
        records: dayRecords,
        isDark: isDark,
        onEdit: (record, newStatus) async {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) return;
          
          // Instant local state update, stream handles reactivity
          await AttendanceRepository().updateAttendanceStatus(user.uid, record.id, newStatus);
          
          if (ctx.mounted) Navigator.pop(ctx);
        },
      ),
    );
  }
}

class _MonthNavigator extends StatelessWidget {
  final DateTime focusedMonth;
  final bool isDark;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _MonthNavigator({
    required this.focusedMonth,
    required this.isDark,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          IconButton(
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left_rounded, size: 28),
            color: isDark ? AppColors.textPrimary : AppColors.textLight,
          ),
          Expanded(
            child: Text(
              DateFormat('MMMM yyyy').format(focusedMonth),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimary : AppColors.textLight,
              ),
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded, size: 28),
            color: isDark ? AppColors.textPrimary : AppColors.textLight,
          ),
        ],
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final DateTime focusedMonth;
  final List<AttendanceRecord> records;
  final DateTime? selectedDate;
  final bool isDark;
  final Function(DateTime) onDayTap;

  const _CalendarGrid({
    required this.focusedMonth,
    required this.records,
    required this.selectedDate,
    required this.isDark,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(focusedMonth.year, focusedMonth.month, 1);
    // Shift: Monday=1, so offset = (weekday - 1)
    final startOffset = (firstDay.weekday - 1) % 7;
    final daysInMonth = DateUtils.getDaysInMonth(focusedMonth.year, focusedMonth.month);
    final totalCells = startOffset + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          children: List.generate(rows, (row) {
            return Expanded(
              child: Row(
                children: List.generate(7, (col) {
                  final cellIndex = row * 7 + col;
                  final dayNum = cellIndex - startOffset + 1;

                  if (dayNum < 1 || dayNum > daysInMonth) {
                    return const Expanded(child: SizedBox());
                  }

                  final date = DateTime(focusedMonth.year, focusedMonth.month, dayNum);
                  final isToday = DateUtils.isSameDay(date, DateTime.now());
                  final isSelected = selectedDate != null && DateUtils.isSameDay(date, selectedDate!);
                  final isFuture = date.isAfter(DateTime.now());

                  // Get attendance for this day
                  final dayRecords = records.where((r) =>
                    r.date.year == date.year &&
                    r.date.month == date.month &&
                    r.date.day == date.day
                  ).toList();

                  Color? dotColor;
                  if (!isFuture && dayRecords.isNotEmpty) {
                    final present = dayRecords.where((r) => r.isPresent).length;
                    final total = dayRecords.length;
                    if (present == total) {
                      dotColor = AppColors.success;
                    } else if (present == 0) {
                      dotColor = AppColors.danger;
                    } else {
                      dotColor = AppColors.warning;
                    }
                  }

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onDayTap(date),
                      child: Container(
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : isToday
                                  ? AppColors.primary.withValues(alpha: 0.08)
                                  : null,
                          borderRadius: BorderRadius.circular(12),
                          border: isToday
                              ? Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 1.5)
                              : isSelected
                                  ? Border.all(color: AppColors.primary, width: 1.5)
                                  : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$dayNum',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isFuture
                                    ? AppColors.textSecondary.withValues(alpha: 0.4)
                                    : isToday || isSelected
                                        ? AppColors.primary
                                        : isDark
                                            ? AppColors.textPrimary
                                            : AppColors.textLight,
                              ),
                            ),
                            if (dotColor != null) ...[
                              const SizedBox(height: 2),
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: dotColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _DayDetailSheet extends StatelessWidget {
  final DateTime date;
  final List<AttendanceRecord> records;
  final bool isDark;
  final Function(AttendanceRecord record, String newStatus) onEdit;

  const _DayDetailSheet({
    required this.date,
    required this.records,
    required this.isDark,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${date.day}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE').format(date),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.textPrimary : AppColors.textLight,
                        ),
                      ),
                      Text(
                        DateFormat('MMMM yyyy').format(date),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: records.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.event_available_outlined,
                            size: 48,
                            color: isDark ? AppColors.textSecondary : AppColors.textLightSecondary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No attendance recorded',
                            style: TextStyle(
                              color: isDark ? AppColors.textSecondary : AppColors.textLightSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: controller,
                      padding: const EdgeInsets.all(16),
                      itemCount: records.length,
                      itemBuilder: (_, i) {
                        final r = records[i];
                        return _AttendanceEditTile(
                          record: r,
                          isDark: isDark,
                          onEdit: onEdit,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceEditTile extends StatefulWidget {
  final AttendanceRecord record;
  final bool isDark;
  final Function(AttendanceRecord, String) onEdit;

  const _AttendanceEditTile({
    required this.record,
    required this.isDark,
    required this.onEdit,
  });

  @override
  State<_AttendanceEditTile> createState() => _AttendanceEditTileState();
}

class _AttendanceEditTileState extends State<_AttendanceEditTile> {
  late bool _isPresent;

  @override
  void initState() {
    super.initState();
    _isPresent = widget.record.isPresent;
  }

  void _handleEdit(String newStatus) {
    setState(() {
      _isPresent = newStatus == 'Present';
    });
    widget.onEdit(widget.record, newStatus);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkCard : AppColors.lightBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isPresent
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.danger.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: _isPresent ? AppColors.successGradient : AppColors.dangerGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                widget.record.subjectName.isNotEmpty ? widget.record.subjectName[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.record.subjectName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: widget.isDark ? AppColors.textPrimary : AppColors.textLight,
                  ),
                ),
                Text(
                  _isPresent ? 'Present' : 'Absent',
                  style: TextStyle(
                    fontSize: 13,
                    color: _isPresent ? AppColors.success : AppColors.danger,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Edit toggle
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => _handleEdit('Present'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isPresent
                        ? AppColors.success
                        : AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: _isPresent ? Colors.white : AppColors.success,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _handleEdit('Absent'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: !_isPresent
                        ? AppColors.danger
                        : AppColors.danger.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: !_isPresent ? Colors.white : AppColors.danger,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
