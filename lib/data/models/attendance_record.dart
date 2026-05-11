import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceRecord {
  final String id;
  final String subjectName;
  final DateTime date;
  final String status; // "Present" or "Absent"
  final String lectureId;

  AttendanceRecord({
    required this.id,
    required this.subjectName,
    required this.date,
    required this.status,
    required this.lectureId,
  });

  bool get isPresent => status == 'Present';

  factory AttendanceRecord.fromMap(Map<String, dynamic> map, String id) {
    return AttendanceRecord(
      id: id,
      subjectName: map['subjectName'] ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] ?? 'Absent',
      lectureId: map['lectureId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subjectName': subjectName,
      'date': Timestamp.fromDate(date),
      'status': status,
      'lectureId': lectureId,
    };
  }

  AttendanceRecord copyWith({
    String? id,
    String? subjectName,
    DateTime? date,
    String? status,
    String? lectureId,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      subjectName: subjectName ?? this.subjectName,
      date: date ?? this.date,
      status: status ?? this.status,
      lectureId: lectureId ?? this.lectureId,
    );
  }
}
