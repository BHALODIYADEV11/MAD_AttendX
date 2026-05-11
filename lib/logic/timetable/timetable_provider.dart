import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/timetable_lecture.dart';
import '../../data/repositories/timetable_repository.dart';
import '../../data/repositories/attendance_repository.dart';
import '../attendance/attendance_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

final timetableRepositoryProvider = Provider<TimetableRepository>((ref) {
  return TimetableRepository();
});

final allLecturesProvider = StreamProvider<List<TimetableLecture>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value([]);
  return ref.watch(timetableRepositoryProvider).getLectures(user.uid);
});

final todayLecturesProvider = StreamProvider<List<TimetableLecture>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value([]);
  final today = DateTime.now().weekday; // 1=Monday ... 7=Sunday
  return ref.watch(timetableRepositoryProvider).getLecturesForDay(user.uid, today);
});

final dayLecturesProvider = StreamProvider.family<List<TimetableLecture>, int>((ref, dayOfWeek) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value([]);
  return ref.watch(timetableRepositoryProvider).getLecturesForDay(user.uid, dayOfWeek);
});

class TimetableController {
  final TimetableRepository _repo;
  final AttendanceRepository _attendanceRepo;
  final String _userId;

  TimetableController(this._repo, this._attendanceRepo, this._userId);

  Future<void> addLecture(TimetableLecture lecture) async {
    await _repo.addLecture(_userId, lecture);
  }

  Future<void> updateLecture(TimetableLecture lecture) async {
    await _repo.updateLecture(_userId, lecture);
  }

  Future<void> deleteLecture(String lectureId) async {
    await _repo.deleteLecture(_userId, lectureId);
    await _attendanceRepo.deleteAttendanceForLecture(_userId, lectureId);
  }
}

final timetableControllerProvider = Provider<TimetableController?>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;
  final repo = ref.watch(timetableRepositoryProvider);
  final attendanceRepo = ref.watch(attendanceRepositoryProvider);
  return TimetableController(repo, attendanceRepo, user.uid);
});
