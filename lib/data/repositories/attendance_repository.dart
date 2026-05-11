import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/attendance_record.dart';
import '../models/subject_stats.dart';

class AttendanceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _attendanceRef(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('attendance');
  }

  /// Stream all attendance records
  Stream<List<AttendanceRecord>> getAttendanceRecords(String userId) {
    return _attendanceRef(userId)
        .orderBy('date', descending: true)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) => snapshot.docs
            .map((doc) => AttendanceRecord.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ))
            .toList());
  }

  /// Stream attendance for a specific date
  Stream<List<AttendanceRecord>> getAttendanceForDate(String userId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _attendanceRef(userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) => snapshot.docs
            .map((doc) => AttendanceRecord.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ))
            .toList());
  }

  /// Mark attendance for a lecture (Instant using merge)
  Future<void> markAttendance(String userId, AttendanceRecord record) async {
    final dateStr = '${record.date.year}-${record.date.month}-${record.date.day}';
    final docId = '${record.lectureId}_$dateStr';

    final toSave = record.copyWith(id: docId);

    await _attendanceRef(userId).doc(docId).set(
          toSave.toMap(),
          SetOptions(merge: true),
        );
  }

  /// Delete all attendance for a specific lecture (Cascade Delete)
  Future<void> deleteAttendanceForLecture(String userId, String lectureId) async {
    final snapshot = await _attendanceRef(userId)
        .where('lectureId', isEqualTo: lectureId)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  /// Calculate subject-wise stats locally
  List<SubjectStats> calculateSubjectStats(List<AttendanceRecord> records) {

    // Group by subject
    final Map<String, List<AttendanceRecord>> grouped = {};
    for (final record in records) {
      grouped.putIfAbsent(record.subjectName, () => []);
      grouped[record.subjectName]!.add(record);
    }

    return grouped.entries.map((entry) {
      final total = entry.value.length;
      final attended = entry.value.where((r) => r.isPresent).length;
      return SubjectStats(
        subjectName: entry.key,
        totalLectures: total,
        attendedLectures: attended,
      );
    }).toList()
      ..sort((a, b) => a.subjectName.compareTo(b.subjectName));
  }

  /// Calculate overall stats locally
  SubjectStats calculateOverallStats(List<AttendanceRecord> records) {

    final total = records.length;
    final attended = records.where((r) => r.isPresent).length;

    return SubjectStats(
      subjectName: 'Overall',
      totalLectures: total,
      attendedLectures: attended,
    );
  }

  /// Update status of an existing attendance record by ID
  Future<void> updateAttendanceStatus(String userId, String recordId, String status) async {
    await _attendanceRef(userId).doc(recordId).set(
      {'status': status},
      SetOptions(merge: true),
    );
  }

  /// Delete all attendance for a subject
  Future<void> deleteAttendanceForSubject(String userId, String subjectName) async {
    final snapshot = await _attendanceRef(userId)
        .where('subjectName', isEqualTo: subjectName)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
