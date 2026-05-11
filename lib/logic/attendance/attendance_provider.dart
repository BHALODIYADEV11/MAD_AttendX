import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/attendance_record.dart';
import '../../data/models/subject_stats.dart';
import '../../data/repositories/attendance_repository.dart';
import '../../data/repositories/settings_repository.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository();
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

/// Stream of all attendance records
final attendanceRecordsProvider = StreamProvider<List<AttendanceRecord>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value([]);
  return ref.watch(attendanceRepositoryProvider).getAttendanceRecords(user.uid);
});

/// Stream of today's attendance records
final todayAttendanceProvider = StreamProvider<List<AttendanceRecord>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value([]);
  return ref.watch(attendanceRepositoryProvider).getAttendanceForDate(user.uid, DateTime.now());
});

/// Subject-wise stats (computed locally from the stream)
final subjectStatsProvider = Provider<AsyncValue<List<SubjectStats>>>((ref) {
  final recordsAsync = ref.watch(attendanceRecordsProvider);
  return recordsAsync.whenData((records) {
    return ref.read(attendanceRepositoryProvider).calculateSubjectStats(records);
  });
});

/// Overall stats (computed locally from the stream)
final overallStatsProvider = Provider<AsyncValue<SubjectStats>>((ref) {
  final recordsAsync = ref.watch(attendanceRecordsProvider);
  return recordsAsync.whenData((records) {
    if (records.isEmpty) {
      return SubjectStats(subjectName: 'Overall', totalLectures: 0, attendedLectures: 0);
    }
    return ref.read(attendanceRepositoryProvider).calculateOverallStats(records);
  });
});

/// Attendance criteria
final criteriaProvider = StateNotifierProvider<CriteriaNotifier, int>((ref) {
  return CriteriaNotifier(ref.read(settingsRepositoryProvider));
});

class CriteriaNotifier extends StateNotifier<int> {
  final SettingsRepository _repo;

  CriteriaNotifier(this._repo) : super(75) {
    _load();
  }

  Future<void> _load() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      state = await _repo.getCriteria(user.uid);
    }
  }

  Future<void> setCriteria(int value) async {
    state = value; // Optimistic update for instant UI feedback
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await _repo.setCriteria(user.uid, value);
      } catch (e) {
        // Fallback or log error if needed
      }
    }
  }
}

/// Theme mode
final isDarkModeProvider = StateNotifierProvider<ThemeModeNotifier, bool>((ref) {
  return ThemeModeNotifier(ref.read(settingsRepositoryProvider));
});

class ThemeModeNotifier extends StateNotifier<bool> {
  final SettingsRepository _repo;

  ThemeModeNotifier(this._repo) : super(true) {
    _load();
  }

  Future<void> _load() async {
    state = await _repo.getIsDarkMode();
  }

  Future<void> toggle() async {
    state = !state;
    await _repo.setIsDarkMode(state);
  }
}

/// User name
final userNameProvider = FutureProvider<String>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return 'Student';
  return ref.read(settingsRepositoryProvider).getUserName(user.uid);
});

/// Attendance controller for marking
class AttendanceController {
  final AttendanceRepository _repo;
  final String _userId;

  AttendanceController(this._repo, this._userId);

  Future<void> markAttendance({
    required String subjectName,
    required String lectureId,
    required String status,
  }) async {
    final record = AttendanceRecord(
      id: '',
      subjectName: subjectName,
      date: DateTime.now(),
      status: status,
      lectureId: lectureId,
    );
    await _repo.markAttendance(_userId, record);
  }
}

final attendanceControllerProvider = Provider<AttendanceController?>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;
  final repo = ref.watch(attendanceRepositoryProvider);
  return AttendanceController(repo, user.uid);
});
