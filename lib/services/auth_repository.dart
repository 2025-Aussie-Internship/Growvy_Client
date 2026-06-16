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

  /// 백엔드의 `auth/login`을 호출하여 백엔드 토큰 발급 및 가입/고용주 여부 확인
  static Future<bool> exchangeFirebaseTokenForAccess(
    String firebaseIdToken,
  ) async {
    try {
      // 1. 로그인 API 호출
      final response = await ApiClient.post(
        'auth/login',
        headers: {'Authorization': 'Bearer $firebaseIdToken'},
      );

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
            // ApiClient를 통해 is-employer API 호출 (GET 방식)
            final roleResponse = await ApiClient.get('auth/is-employer');

            // 응답값에서 employer 여부 추출 (API 명세대로 'employer' 키 사용)
            final isEmployer = roleResponse['employer'] as bool? ?? false;
            debugPrint('[AuthRepository] isEmployer 확인됨: $isEmployer');

            //  UserService를 사용해 기기에 유저 타입 저장!
            await UserService.saveUserType(isEmployer);
          } catch (e) {
            debugPrint('[AuthRepository] 고용주 여부 확인 실패: $e');
          }
        }
      }

      return registered; // true: 기존 유저, false: 신규 유저
    } catch (e) {
      debugPrint('[AuthRepository] exchangeFirebaseTokenForAccess error: $e');
      throw Exception('백엔드 로그인 API 호출 실패: $e');
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
