import 'package:flutter_dotenv/flutter_dotenv.dart';

/// `.env` 키 접근을 위한 헬퍼.
/// 키 누락 시 `MissingEnvException` 을 던져 빌드 단계에서 빠르게 감지한다.
class Env {
  Env._();

  static String _require(String key) {
    final value = dotenv.maybeGet(key);
    if (value == null || value.isEmpty) {
      throw MissingEnvException(key);
    }
    return value;
  }

  static String _optional(String key) => dotenv.maybeGet(key) ?? '';

  // --- API ---
  static String get apiBaseUrl => _require('API_BASE_URL');
  static String get serverBaseUrl => _require('SERVER_BASE_URL');

  // --- Firebase: web ---
  static String get firebaseWebApiKey => _require('FIREBASE_WEB_API_KEY');
  static String get firebaseWebAppId => _require('FIREBASE_WEB_APP_ID');
  static String get firebaseWebMeasurementId =>
      _optional('FIREBASE_WEB_MEASUREMENT_ID');

  // --- Firebase: android ---
  static String get firebaseAndroidApiKey =>
      _require('FIREBASE_ANDROID_API_KEY');
  static String get firebaseAndroidAppId => _require('FIREBASE_ANDROID_APP_ID');

  // --- Firebase: ios / macos ---
  static String get firebaseIosApiKey => _require('FIREBASE_IOS_API_KEY');
  static String get firebaseIosAppId => _require('FIREBASE_IOS_APP_ID');
  static String get firebaseIosClientId => _require('FIREBASE_IOS_CLIENT_ID');
  static String get firebaseIosBundleId => _require('FIREBASE_IOS_BUNDLE_ID');

  // --- Firebase: windows ---
  static String get firebaseWindowsApiKey =>
      _require('FIREBASE_WINDOWS_API_KEY');
  static String get firebaseWindowsAppId => _require('FIREBASE_WINDOWS_APP_ID');
  static String get firebaseWindowsMeasurementId =>
      _optional('FIREBASE_WINDOWS_MEASUREMENT_ID');

  // --- Firebase: 공통 ---
  static String get firebaseMessagingSenderId =>
      _require('FIREBASE_MESSAGING_SENDER_ID');
  static String get firebaseProjectId => _require('FIREBASE_PROJECT_ID');
  static String get firebaseAuthDomain => _require('FIREBASE_AUTH_DOMAIN');
  static String get firebaseStorageBucket =>
      _require('FIREBASE_STORAGE_BUCKET');
}

class MissingEnvException implements Exception {
  MissingEnvException(this.key);
  final String key;

  @override
  String toString() => 'MissingEnvException: .env 에 "$key" 가 설정되어 있지 않습니다.';
}
