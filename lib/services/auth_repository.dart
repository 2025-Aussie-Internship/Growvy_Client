import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'token_storage.dart';

/// 인증 관련 도메인 로직 (Firebase ↔ 우리 백엔드 토큰 교환 + 갱신).
///
/// 흐름:
///   1) GoogleSignIn → FirebaseAuth.signInWithCredential → user.getIdToken()
///   2) [exchangeFirebaseTokenForAccess] 로 백엔드에 `POST /api/auth/firebase`
///      등 호출하여 자체 access/refresh token 받기 (백엔드 스펙이 있을 때)
///   3) [TokenStorage] 에 저장
///   4) 일정 주기 / 401 발생 시 [refreshIdTokenFromFirebase] 로 갱신
class AuthRepository {
  AuthRepository._();

  /// 현재 로그인된 Firebase 사용자의 ID Token 을 (필요하면 강제) 새로 발급받아
  /// SecureStorage 에 캐싱하고 반환.
  static Future<String?> refreshIdTokenFromFirebase({bool force = false}) async {
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

  /// (백엔드 토큰 교환 API 가 생기면 활성화)
  ///
  /// 현재 placeholder. 실제 구현 시:
  /// ```dart
  /// final res = await ApiClient.post('/api/auth/firebase',
  ///   body: {'idToken': firebaseIdToken});
  /// await TokenStorage.saveAccessToken(res['accessToken'] as String);
  /// await TokenStorage.saveRefreshToken(res['refreshToken'] as String);
  /// ```
  static Future<void> exchangeFirebaseTokenForAccess(
      String firebaseIdToken) async {
    // TODO: 백엔드 endpoint 확정 시 ApiClient.post(...) 로 구현.
    debugPrint(
      '[AuthRepository] (stub) exchange firebase token → backend access token',
    );
  }

  /// 로그아웃 진행. Firebase signOut + 토큰 폐기.
  static Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('[AuthRepository] firebase signOut error: $e');
    }
    await TokenStorage.clearAll();
  }
}
