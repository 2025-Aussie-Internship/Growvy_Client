import 'package:flutter/foundation.dart';

import 'api_client.dart';

/// 회원가입 단계의 모든 입력을 한 번에 백엔드로 보내는 repository.
///
/// 백엔드 endpoint 가 확정되면 [enabled] 만 true 로 바꾸면 실제 호출이 실행되고,
/// 그 전엔 안전하게 debugPrint 만 한다. (회원가입 흐름 차단되지 않게)
class SignupRepository {
  SignupRepository._();

  /// 백엔드 endpoint 가 준비됐을 때만 true 로 변경.
  /// 또는 dart-define 로 주입: `--dart-define=API_ENABLED=true`
  static const bool enabled =
      bool.fromEnvironment('API_ENABLED', defaultValue: false);

  static const String _seekerPath = '/api/users/seeker';
  static const String _employerPath = '/api/users/employer';

  /// 회원가입 페이로드를 백엔드로 전송.
  /// 응답으로 생성된 user JSON 을 반환한다 (없으면 빈 map).
  ///
  /// 백엔드 미준비 시: 페이로드를 로그로만 남기고 빈 map 반환.
  static Future<Map<String, dynamic>> submit({
    required bool isEmployer,
    required Map<String, dynamic> payload,
  }) async {
    if (!enabled) {
      debugPrint(
        '[SignupRepository] (stub, API_ENABLED=false) payload=$payload',
      );
      return <String, dynamic>{};
    }
    final path = isEmployer ? _employerPath : _seekerPath;
    return ApiClient.post(path, body: payload);
  }
}
