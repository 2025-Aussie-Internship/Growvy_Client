import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'signup_repository.dart';
import 'token_storage.dart';
import 'user_service.dart';

/// 인증 관련 도메인 로직 (Firebase ↔ 우리 백엔드 토큰 교환 + 갱신).
class AuthRepository {
  AuthRepository._();

  /// 백엔드 stub 모드 여부. `SignupRepository.enabled` 와 같은 플래그를 공유해서
  /// 회원가입/로그인 양쪽이 같은 ON/OFF 로 묶이게 한다.
  /// `--dart-define=API_ENABLED=false` 로 빌드하면 백엔드 호출을 모두 우회한다.
  static bool get _apiEnabled => SignupRepository.enabled;

  /// 현재 로그인된 Firebase 사용자의 ID Token 을 새로 발급받아 캐싱.
  static Future<String?> refreshIdTokenFromFirebase({
    bool force = false,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    try {
      final token = await user.getIdToken(force);
      if (token != null && token.isNotEmpty) {
        await TokenStorage.saveFirebaseIdToken(token);
      }
      return token;
    } catch (e) {
      debugPrint('[AuthRepository] refreshIdToken error: $e');
      return null;
    }
  }

  /// 백엔드의 `auth/login` 을 호출하여 자체 JWT 발급 + 가입/고용주 여부를 확인.
  ///
  /// 반환값: true = 기존 회원 (MainPage 로 직행),
  ///         false = 신규 회원 (SignInPage 추가 정보 입력으로 진행).
  ///
  /// **여기서는 절대 throw 하지 않는다.** 백엔드가 아직 안 떠 있어도(timeout /
  /// network error / 5xx) 사용자는 그냥 "신규 회원" 으로 간주되어 회원가입
  /// 흐름이 끊기지 않는다. 백엔드가 붙으면 별도 변경 없이 자동으로 정상
  /// 분기된다.
  static Future<bool> exchangeFirebaseTokenForAccess(
    String firebaseIdToken,
  ) async {
    // stub 모드: 백엔드 호출을 완전히 우회하고 항상 신규 회원으로 본다.
    if (!_apiEnabled) {
      debugPrint(
        '[AuthRepository] (stub, API_ENABLED=false) 백엔드 호출 우회 → 신규 회원으로 진행',
      );
      return false;
    }

    try {
      // 1. 로그인 API 호출.
      //    ApiClient 기본 30초 timeout 은 백엔드 미응답 상황에서 너무 길어
      //    사용자가 30초 동안 로딩만 보게 된다. 로그인 단계만 더 짧게(7초)
      //    감싸서, 백엔드가 없으면 빠르게 신규 회원 흐름으로 떨어지도록 한다.
      final response = await ApiClient.post(
        'auth/login',
        headers: {'Authorization': 'Bearer $firebaseIdToken'},
      ).timeout(const Duration(seconds: 7));

      final jwt = response['accessToken'] as String?;
      final registered = response['registered'] as bool? ?? false;

      debugPrint(
        '[AuthRepository] Token received: ${jwt != null} | Registered: $registered',
      );

      // 2. 백엔드 자체 토큰(JWT) 저장
      if (jwt != null && jwt.isNotEmpty) {
        // await TokenStorage.saveAccessToken(jwt);

        // 3. 가입된 유저라면 고용주 여부를 확인해서 기기에 저장.
        if (registered) {
          try {
            final roleResponse = await ApiClient.get('auth/is-employer');
            final isEmployer = roleResponse['employer'] as bool? ?? false;
            debugPrint('[AuthRepository] isEmployer 확인됨: $isEmployer');
            await UserService.saveUserType(isEmployer);
          } catch (e) {
            debugPrint('[AuthRepository] 고용주 여부 확인 실패: $e');
          }
        }
      }

      return registered;
    } on TimeoutException catch (e) {
      debugPrint('[AuthRepository] backend timeout(7s) → 신규 회원 흐름으로 fallback: $e');
      return false;
    } on ApiException catch (e) {
      // 백엔드가 안 떠 있거나(timeout/network) 5xx 면 회원가입 흐름이 끊기지
      // 않도록 "신규 회원" 으로 간주. 401/403 같은 인증 거절은 정말로
      // 회원 정보가 없는 케이스라서 동일하게 신규로 보내도 안전하다.
      debugPrint('[AuthRepository] backend unreachable → 신규 회원 흐름으로 fallback: $e');
      return false;
    } catch (e) {
      debugPrint('[AuthRepository] unexpected error → 신규 회원 흐름으로 fallback: $e');
      return false;
    }
  }

  /// 로그아웃 진행. Firebase signOut + 토큰 및 유저 타입 폐기.
  static Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('[AuthRepository] firebase signOut error: $e');
    }

    // 토큰 날리기
    await TokenStorage.clearAll();

    await UserService.clearUserType();
  }
}
