import 'package:flutter/material.dart';
import '../../widgets/glass_loading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/constants.dart';
import '../../../data/models/timetable_lecture.dart';
import '../../../logic/timetable/timetable_provider.dart';

class TimetableManagementScreen extends ConsumerStatefulWidget {
  const TimetableManagementScreen({super.key});

  @override
  ConsumerState<TimetableManagementScreen> createState() => _TimetableManagementScreenState();
}

class _TimetableManagementScreenState extends ConsumerState<TimetableManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedDay = DateTime.now().weekday; // 1=Monday

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 7,
      vsync: this,
      initialIndex: _selectedDay - 1,
    );
    _tabController.addListener(() {
      setState(() => _selectedDay = _tabController.index + 1);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddLectureDialog() {
    final subjectController = TextEditingController();
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 10, minute: 0);
    String selectedType = 'Theory';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Add Lecture',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimary : AppColors.textLight,
                ),
              ),
              Text(
                AppConstants.weekDays[_selectedDay - 1],
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.textSecondary : AppColors.textLightSecondary,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: subjectController,
                style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.textLight),
                decoration: const InputDecoration(
                  labelText: 'Subject Name',
                  prefixIcon: Icon(Icons.book_outlined, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setModalState(() => selectedType = 'Theory'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selectedType == 'Theory' ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selectedType == 'Theory' ? AppColors.primary : AppColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Theory',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: selectedType == 'Theory' ? Colors.white : AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setModalState(() => selectedType = 'Lab'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selectedType == 'Lab' ? AppColors.warning : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selectedType == 'Lab' ? AppColors.warning : AppColors.warning.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Lab',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: selectedType == 'Lab' ? Colors.white : AppColors.warning,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _TimePicker(
                      label: 'Start Time',
                      time: startTime,
                      isDark: isDark,
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: ctx,
                          initialTime: startTime,
                        );
                        if (picked != null) {
                          setModalState(() => startTime = picked);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _TimePicker(
                      label: 'End Time',
                      time: endTime,
                      isDark: isDark,
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: ctx,
                          initialTime: endTime,
                        );
                        if (picked != null) {
                          setModalState(() => endTime = picked);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    if (subjectController.text.trim().isEmpty) return;
                    final lecture = TimetableLecture(
                      id: '',
                      subjectName: subjectController.text.trim(),
                      dayOfWeek: _selectedDay,
                      startTime: '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
                      endTime: '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
                      type: selectedType,
                    );
                    ref.read(timetableControllerProvider)?.addLecture(lecture);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Add Lecture'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lecturesAsync = ref.watch(dayLecturesProvider(_selectedDay));

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
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Text(
                  'Timetable',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textPrimary : AppColors.textLight,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Day tabs
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: Colors.white,
                  unselectedLabelColor: isDark ? AppColors.textSecondary : AppColors.textLightSecondary,
                  indicator: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  tabs: AppConstants.weekDays.map((d) => Tab(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(d.substring(0, 3)),
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Lectures list
              Expanded(
                child: lecturesAsync.when(
                  data: (lectures) {
                    if (lectures.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.event_note_outlined,
                              size: 64,
                              color: isDark ? AppColors.textSecondary : AppColors.textLightSecondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No lectures on ${AppConstants.weekDays[_selectedDay - 1]}',
                              style: TextStyle(
                                fontSize: 16,
                                color: isDark ? AppColors.textSecondary : AppColors.textLightSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap + to add a lecture',
                              style: TextStyle(
                                fontSize: 13,
                                color: (isDark ? AppColors.textSecondary : AppColors.textLightSecondary).withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: lectures.length,
                      itemBuilder: (context, index) {
                        final lecture = lectures[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
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
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: Text(
                                    lecture.subjectName.isNotEmpty ? lecture.subjectName[0].toUpperCase() : '?',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
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
                                        Icon(Icons.access_time_rounded, size: 14,
                                          color: isDark ? AppColors.textSecondary : AppColors.textLightSecondary),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${lecture.startTime} - ${lecture.endTime}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: isDark ? AppColors.textSecondary : AppColors.textLightSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete_outline_rounded,
                                  color: AppColors.danger.withValues(alpha: 0.7), size: 22),
                                onPressed: () {
                                  ref.read(timetableControllerProvider)?.deleteLecture(lecture.id);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () => GlassLoading(message: "Fetching timetable..."),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddLectureDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}

class _TimePicker extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final bool isDark;
  final VoidCallback onTap;

  const _TimePicker({
    required this.label,
    required this.time,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textSecondary : AppColors.textLightSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimary : AppColors.textLight,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
