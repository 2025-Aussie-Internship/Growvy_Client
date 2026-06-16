import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'token_storage.dart';
import 'user_service.dart';

/// 인증 관련 도메인 로직 (Firebase ↔ 우리 백엔드 토큰 교환 + 갱신).
class AuthRepository {
  AuthRepository._();

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

  /// 백엔드의 `auth/login`을 호출하여 백엔드 토큰 발급 및 가입/고용주 여부 확인.
  ///
  /// 백엔드가 떠 있지 않거나 응답이 늦을 때 SignUpPage 가 무한 버퍼링으로
  /// 보이는 것을 막기 위해 짧은(8초) timeout 을 두고, TimeoutException /
  /// ApiException / 기타 예외를 throw 하지 않고 `false` 를 반환한다.
  /// (= "신규 유저" 흐름으로 자연스럽게 진입시켜 사용자가 회원가입을 계속
  /// 진행할 수 있게 함. 백엔드가 살아나면 SignupCompletePage 의 submit 에서
  /// 다시 시도된다.)
  static Future<bool> exchangeFirebaseTokenForAccess(
    String firebaseIdToken,
  ) async {
    try {
      // 1. 로그인 API 호출 — ApiClient 자체 timeout(30s) 보다 짧은 8s 로 wrap.
      final response = await ApiClient.post(
        'auth/login',
        headers: {'Authorization': 'Bearer $firebaseIdToken'},
      ).timeout(const Duration(seconds: 8));

      final jwt = response['accessToken'] as String?;
      final registered = response['registered'] as bool? ?? false;

      debugPrint(
        '[AuthRepository] Token received: ${jwt != null} | Registered: $registered',
      );

      // 2. 백엔드 자체 토큰(JWT) 저장
      if (jwt != null && jwt.isNotEmpty) {
        await TokenStorage.saveAccessToken(jwt);

        // 3. 가입된 유저라면 추가로 고용주(Employer) 여부를 확인하고 저장합니다.
        if (registered) {
          try {
            final roleResponse = await ApiClient.get('auth/is-employer')
                .timeout(const Duration(seconds: 5));
            final isEmployer = roleResponse['employer'] as bool? ?? false;
            debugPrint('[AuthRepository] isEmployer 확인됨: $isEmployer');
            await UserService.saveUserType(isEmployer);
          } catch (e) {
            debugPrint('[AuthRepository] 고용주 여부 확인 실패: $e');
          }
        }
      }

      return registered; // true: 기존 유저, false: 신규 유저
    } on TimeoutException {
      debugPrint(
        '[AuthRepository] auth/login timeout — 신규 유저 흐름으로 진행',
      );
      return false;
    } catch (e) {
      // ApiException(네트워크/서버 오류 포함) + 기타 예외 모두 신규 유저로 처리.
      debugPrint('[AuthRepository] exchangeFirebaseTokenForAccess error: $e');
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
