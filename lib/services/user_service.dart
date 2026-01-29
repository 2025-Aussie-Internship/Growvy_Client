import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static const String _userTypeKey = 'user_type';

  static SharedPreferences? _prefs;

  /// 앱 시작 시 한 번 호출하여 SharedPreferences 초기화 (main.dart에서 호출)
  static Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e, stack) {
      debugPrint('UserService.init SharedPreferences error: $e\n$stack');
    }
  }

  static Future<SharedPreferences?> _getPrefs() async {
    if (_prefs != null) return _prefs;
    try {
      _prefs = await SharedPreferences.getInstance();
      return _prefs;
    } catch (e, stack) {
      debugPrint('UserService SharedPreferences getInstance error: $e\n$stack');
      return null;
    }
  }

  // 사용자 타입 저장 (employer 또는 seeker)
  static Future<void> saveUserType(bool isEmployer) async {
    final prefs = await _getPrefs();
    if (prefs == null) return;
    try {
      await prefs.setString(_userTypeKey, isEmployer ? 'employer' : 'seeker');
    } catch (e) {
      debugPrint('UserService saveUserType error: $e');
    }
  }

  // 사용자 타입 확인
  static Future<String?> getUserType() async {
    final prefs = await _getPrefs();
    if (prefs == null) return null;
    try {
      return prefs.getString(_userTypeKey);
    } catch (e) {
      debugPrint('UserService getUserType error: $e');
      return null;
    }
  }

  // Employer인지 확인
  static Future<bool> isEmployer() async {
    final userType = await getUserType();
    return userType == 'employer';
  }

  // 사용자 타입 삭제 (로그아웃 시)
  static Future<void> clearUserType() async {
    final prefs = await _getPrefs();
    if (prefs == null) return;
    try {
      await prefs.remove(_userTypeKey);
    } catch (e) {
      debugPrint('UserService clearUserType error: $e');
    }
  }
}
