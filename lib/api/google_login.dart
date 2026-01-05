import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class FakeGoogleLogin {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );

  static Future<bool> showGoogleLoginModal() async {
    try {
      final account = await _googleSignIn.signIn();

      // 모달에서 "취소" 누른 경우
      if (account == null) {
        debugPrint("구글 로그인 취소");
        return false;
      }

      // ✅ 여기까지 오면
      // 실제 인증은 안 했지만
      // "구글 계정 선택 모달"은 성공적으로 뜬 것
      debugPrint("선택된 계정: ${account.email}");

      return true;
    } catch (e) {
      debugPrint("구글 모달 에러: $e");
      return false;
    }
  }
}
