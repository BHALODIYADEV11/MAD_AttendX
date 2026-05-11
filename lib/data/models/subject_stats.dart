class SubjectStats {
  final String subjectName;
  final int totalLectures;
  final int attendedLectures;

  SubjectStats({
    required this.subjectName,
    required this.totalLectures,
    required this.attendedLectures,
  });

  double get percentage {
    if (totalLectures == 0) return 0.0;
    return (attendedLectures / totalLectures) * 100;
  }

  bool isBelowCriteria(int criteria) => percentage < criteria;

  /// Calculate how many more lectures needed to meet the criteria
  int lecturesNeededToMeetCriteria(int criteria) {
    if (percentage >= criteria) return 0;
    // We need: (attended + x) / (total + x) >= criteria / 100
    // Solving: 100*(attended + x) >= criteria*(total + x)
    // 100*attended + 100*x >= criteria*total + criteria*x
    // x*(100 - criteria) >= criteria*total - 100*attended
    // x >= (criteria*total - 100*attended) / (100 - criteria)
    if (criteria >= 100) return -1; // Impossible
    double needed = (criteria * totalLectures - 100 * attendedLectures) / (100 - criteria);
    return needed.ceil().clamp(0, 999);
  }

  /// Calculate how many lectures can be missed and still meet criteria
  int lecturesCanMiss(int criteria) {
    if (percentage < criteria) return 0;
    // We need: attended / (total + x) >= criteria / 100
    // 100 * attended >= criteria * (total + x)
    // x <= (100 * attended - criteria * total) / criteria
    if (criteria <= 0) return 999;
    double canMiss = (100 * attendedLectures - criteria * totalLectures) / criteria;
    return canMiss.floor().clamp(0, 999);
  }
}
