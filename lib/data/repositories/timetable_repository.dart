import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/timetable_lecture.dart';

class TimetableRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _timetableRef(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('timetable');
  }

  /// Get all lectures for a user
  Stream<List<TimetableLecture>> getLectures(String userId) {
    return _timetableRef(userId)
        .orderBy('dayOfWeek')
        .orderBy('startTime')
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) => snapshot.docs
            .map((doc) => TimetableLecture.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ))
            .toList());
  }

  /// Get lectures for a specific day
  Stream<List<TimetableLecture>> getLecturesForDay(String userId, int dayOfWeek) {
    return _timetableRef(userId)
        .where('dayOfWeek', isEqualTo: dayOfWeek)
        .orderBy('startTime')
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) => snapshot.docs
            .map((doc) => TimetableLecture.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ))
            .toList());
  }

  /// Add a new lecture
  Future<void> addLecture(String userId, TimetableLecture lecture) async {
    await _timetableRef(userId).add(lecture.toMap());
  }

  /// Update an existing lecture
  Future<void> updateLecture(String userId, TimetableLecture lecture) async {
    await _timetableRef(userId).doc(lecture.id).update(lecture.toMap());
  }

  /// Delete a lecture
  Future<void> deleteLecture(String userId, String lectureId) async {
    await _timetableRef(userId).doc(lectureId).delete();
  }

  /// Get unique subject names
  Future<List<String>> getUniqueSubjects(String userId) async {
    final snapshot = await _timetableRef(userId).get();
    final subjects = snapshot.docs
        .map((doc) => (doc.data() as Map<String, dynamic>)['subjectName'] as String)
        .toSet()
        .toList();
    subjects.sort();
    return subjects;
  }
}
