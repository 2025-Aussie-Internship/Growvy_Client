// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:flutter/foundation.dart';

// class FakeGoogleLogin {
//   static final GoogleSignIn _googleSignIn = GoogleSignIn(
//     scopes: ['email'],
//   );

//   static Future<bool> showGoogleLoginModal() async {
//     try {
//       final account = await _googleSignIn.signIn();

//       // 모달에서 "취소" 누른 경우
//       if (account == null) {
//         debugPrint("구글 로그인 취소");
//         return false;
//       }

//       debugPrint("선택된 계정: ${account.email}");

//       return true;
//     } catch (e) {
//       debugPrint("구글 모달 에러: $e");
//       return false;
//     }
//   }
// }
