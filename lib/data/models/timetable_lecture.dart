class TimetableLecture {
  final String id;
  final String subjectName;
  final int dayOfWeek; // 1=Monday ... 7=Sunday
  final String startTime; // "HH:mm" format
  final String endTime;   // "HH:mm" format
  final String type;      // "Theory" or "Lab"

  TimetableLecture({
    required this.id,
    required this.subjectName,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.type = 'Theory',
  });

  factory TimetableLecture.fromMap(Map<String, dynamic> map, String id) {
    return TimetableLecture(
      id: id,
      subjectName: map['subjectName'] ?? '',
      dayOfWeek: map['dayOfWeek'] ?? 1,
      startTime: map['startTime'] ?? '09:00',
      endTime: map['endTime'] ?? '10:00',
      type: map['type'] ?? 'Theory',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subjectName': subjectName,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'type': type,
    };
  }

  TimetableLecture copyWith({
    String? id,
    String? subjectName,
    int? dayOfWeek,
    String? startTime,
    String? endTime,
    String? type,
  }) {
    return TimetableLecture(
      id: id ?? this.id,
      subjectName: subjectName ?? this.subjectName,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      type: type ?? this.type,
    );
  }

  /// Returns the day name for display
  String get dayName {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    if (dayOfWeek >= 1 && dayOfWeek <= 7) return days[dayOfWeek - 1];
    return 'Unknown';
  }
}
