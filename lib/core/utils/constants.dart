class AppConstants {
  AppConstants._();

  static const String appName = 'AttendX';
  static const int defaultCriteria = 75;
  static const int notificationMinutesBefore = 20;

  static const List<String> weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  // Firestore collections
  static const String usersCollection = 'users';
  static const String timetableCollection = 'timetable';
  static const String attendanceCollection = 'attendance';

  // SharedPreferences keys
  static const String themeKey = 'isDarkMode';
  static const String criteriaKey = 'attendanceCriteria';
  static const String notifMinutesKey = 'notifMinutesBefore';
}
