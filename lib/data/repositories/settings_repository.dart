import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/constants.dart';

class SettingsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get attendance criteria from Firestore
  Future<int> getCriteria(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get(const GetOptions(source: Source.cache));
      if (doc.exists) {
        return (doc.data()?['criteria'] ?? AppConstants.defaultCriteria) as int;
      }
    } catch (_) {}
    
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return (doc.data()?['criteria'] ?? AppConstants.defaultCriteria) as int;
      }
    } catch (e) {
      // Ignore offline error
    }
    return AppConstants.defaultCriteria;
  }

  /// Update attendance criteria in Firestore
  Future<void> setCriteria(String userId, int criteria) async {
    await _firestore.collection('users').doc(userId).set({
      'criteria': criteria,
    }, SetOptions(merge: true));
  }

  /// Get theme preference from local storage
  Future<bool> getIsDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.themeKey) ?? true;
  }

  /// Set theme preference to local storage
  Future<void> setIsDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.themeKey, value);
  }

  /// Get notification minutes before
  Future<int> getNotificationMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(AppConstants.notifMinutesKey) ?? AppConstants.notificationMinutesBefore;
  }

  /// Set notification minutes before
  Future<void> setNotificationMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.notifMinutesKey, minutes);
  }

  /// Get user name
  Future<String> getUserName(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get(const GetOptions(source: Source.cache));
      if (doc.exists) return (doc.data()?['name'] ?? 'Student') as String;
    } catch (_) {}

    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) return (doc.data()?['name'] ?? 'Student') as String;
    } catch (_) {}
    
    return 'Student';
  }
}
