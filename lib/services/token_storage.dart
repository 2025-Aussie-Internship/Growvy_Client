import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 인증 토큰을 OS 보안 저장소(iOS Keychain / Android Keystore)에 보관.
///
/// 저장 항목:
///   - `access_token` : 서버가 발급한 JWT (또는 Firebase ID Token 미사용 시).
///   - `refresh_token`: 서버가 발급한 갱신 토큰 (백엔드 스펙에 따라).
///   - `firebase_id_token`: 최근 Firebase ID Token (선택적 캐시).
///
/// 일반 사용자 데이터(프로필 등) 는 [UserProfileCache] (SharedPreferences) 사용.
/// 토큰만 SecureStorage 에 둔다.
class TokenStorage {
  TokenStorage._();

  static const _storage = FlutterSecureStorage();

  static const _kAccess = 'access_token';
  static const _kRefresh = 'refresh_token';
  static const _kFirebase = 'firebase_id_token';

  static Future<void> saveAccessToken(String token) =>
      _storage.write(key: _kAccess, value: token);

  static Future<String?> readAccessToken() => _storage.read(key: _kAccess);

  static Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _kRefresh, value: token);

  static Future<String?> readRefreshToken() => _storage.read(key: _kRefresh);

  static Future<void> saveFirebaseIdToken(String token) =>
      _storage.write(key: _kFirebase, value: token);

  static Future<String?> readFirebaseIdToken() =>
      _storage.read(key: _kFirebase);

  /// 로그아웃 시 모든 토큰 폐기.
  static Future<void> clearAll() async {
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
    await _storage.delete(key: _kFirebase);
  }
}
