import 'package:flutter/foundation.dart';

import 'api_client.dart';

/// 내 정보 조회/수정 repository.
///
/// `enabled` 가 false 인 동안엔 모든 호출이 stub 으로 동작하여 UI 흐름이
/// 깨지지 않는다.
class UserRepository {
  UserRepository._();

  static const bool enabled =
      bool.fromEnvironment('API_ENABLED', defaultValue: false);

  static const String _mePath = '/api/users/me';

  /// GET /api/users/me → 현재 로그인된 사용자의 프로필 전체.
  static Future<Map<String, dynamic>> fetchMe() async {
    if (!enabled) {
      debugPrint('[UserRepository] (stub) fetchMe');
      return <String, dynamic>{};
    }
    return ApiClient.get(_mePath);
  }

  /// PATCH /api/users/me → 프로필 부분 수정.
  static Future<Map<String, dynamic>> updateMe(Map<String, dynamic> patch) async {
    if (!enabled) {
      debugPrint('[UserRepository] (stub) updateMe patch=$patch');
      return <String, dynamic>{};
    }
    return ApiClient.patch(_mePath, body: patch);
  }
}
