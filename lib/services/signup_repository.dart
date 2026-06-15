import 'dart:async';

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
  static const bool enabled = bool.fromEnvironment(
    'API_ENABLED',
    defaultValue: true,
  );

  // 알려주신 백엔드 엔드포인트로 경로 수정
  static const String _seekerPath = 'auth/signup/jobseeker';
  static const String _employerPath = 'auth/signup/employer';

  /// 회원가입 페이로드를 백엔드로 전송.
  /// 응답으로 생성된 user JSON 을 반환한다 (없으면 빈 map).
  ///
  /// **여기서는 절대 throw 하지 않는다.** 백엔드가 아직 안 떠 있거나
  /// (timeout / network / 5xx) 응답이 깨져 있어도 빈 map 을 돌려서
  /// SignupCompletePage → MainPage 진입이 막히지 않게 한다.
  /// 백엔드가 붙으면 자동으로 정상 응답이 들어와 채워진다.
  static Future<Map<String, dynamic>> submit({
    required bool isEmployer,
    required Map<String, dynamic> payload,
    String? firebaseIdToken,
  }) async {
    if (!enabled) {
      debugPrint(
        '[SignupRepository] (stub, API_ENABLED=false) payload=$payload\ntoken=$firebaseIdToken',
      );
      return <String, dynamic>{};
    }

    final path = isEmployer ? _employerPath : _seekerPath;

    // 로그인(`auth/login`) 과 정확히 동일한 형식으로 Firebase ID Token 을
    // Authorization 헤더에 싣는다. (백엔드에서 Firebase Admin SDK 로 동일하게 검증)
    final headers = <String, String>{};
    if (firebaseIdToken != null && firebaseIdToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $firebaseIdToken';
    }

    try {
      // ApiClient 기본 30초 timeout 은 사용자가 "Ready to Start" 누르고
      // 한참 멈춘 것처럼 보이게 만든다. submit 단계만 더 짧게(8초) 감싸서
      // 백엔드가 없으면 빠르게 빈 map 으로 떨어지도록 한다.
      return await ApiClient.post(
        path,
        body: payload,
        headers: headers,
      ).timeout(const Duration(seconds: 8));
    } on TimeoutException catch (e) {
      debugPrint('[SignupRepository] backend timeout(8s) → 빈 응답으로 fallback: $e');
      return <String, dynamic>{};
    } on ApiException catch (e) {
      debugPrint('[SignupRepository] backend unreachable → 빈 응답으로 fallback: $e');
      return <String, dynamic>{};
    } catch (e) {
      debugPrint('[SignupRepository] unexpected → 빈 응답으로 fallback: $e');
      return <String, dynamic>{};
    }
  }
}
