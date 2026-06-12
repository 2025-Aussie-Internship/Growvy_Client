import '../../i18n/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:get/get.dart' hide Trans;
import '../../controllers/signup_data_controller.dart';
import '../../services/auth_repository.dart';
import '../../services/token_storage.dart';
import 'signin_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  static const Color mainColor = Color(0xFFFC6340);

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  /// 로그인 중복 클릭 방지 + 로딩 인디케이터 토글.
  bool _isLoggingIn = false;

  /// 구글 계정으로 로그인 → Firebase 인증 → SignInPage 로 진입.
  Future<void> _signInWithGoogle() async {
    if (_isLoggingIn) return;
    setState(() => _isLoggingIn = true);

    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return; // 사용자가 모달을 닫음

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      final firebaseIdToken = await userCredential.user!.getIdToken();

      // 1000+자 JWT 를 print 로 통째로 찍으면 IDE 콘솔이 막혀 앱이 렉 걸린
      // 것처럼 보인다. debugPrint + 길이만 남긴다.
      debugPrint('[SignUp] Firebase UID: ${userCredential.user?.uid}');
      debugPrint(
        '[SignUp] Firebase ID Token length: ${firebaseIdToken?.length ?? 0}',
      );

      final signupData = Get.find<SignupDataController>();
      signupData.reset();
      signupData.setGoogleAuth(
        email: userCredential.user?.email,
        displayName: userCredential.user?.displayName,
        uid: userCredential.user?.uid,
        idToken: firebaseIdToken,
      );

      // 이후 API 호출이 자동으로 Authorization 헤더를 붙일 수 있게
      // Firebase ID Token 을 SecureStorage 에 저장.
      // 백엔드 자체 access/refresh token 발급 API 가 생기면
      // AuthRepository.exchangeFirebaseTokenForAccess(...) 를 여기서 호출.
      if (firebaseIdToken != null && firebaseIdToken.isNotEmpty) {
        await TokenStorage.saveFirebaseIdToken(firebaseIdToken);
        await AuthRepository.exchangeFirebaseTokenForAccess(firebaseIdToken);
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 320),
          pageBuilder: (_, _, _) => const SignInPage(),
          transitionsBuilder: (_, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    } catch (e) {
      debugPrint('[SignUp] Google login error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('signup.google_login_failed'.tr())),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoggingIn = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: mainColor,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(),

                  SvgPicture.asset('assets/icon/logo_white.svg', width: 228),

                  const Spacer(),

                  Center(
                    child: SizedBox(
                      width: 318,
                      height: 48,
                      child: ElevatedButton(
                        // 로그인 중에는 onPressed 를 null 로 두어 중복 클릭 차단.
                        onPressed: _isLoggingIn ? null : _signInWithGoogle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black54,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          // disabled 상태에서도 동일한 흰색을 유지해서 색이
                          // 회색으로 튀어 보이지 않게 한다.
                          disabledBackgroundColor: Colors.white,
                          disabledForegroundColor: Colors.black54,
                        ),
                        child: _isLoggingIn
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: mainColor,
                                ),
                              )
                            : Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  SvgPicture.asset(
                                    'assets/icon/google_logo.svg',
                                    height: 27,
                                  ),
                                  Text(
                                    'signup.continue_with_google'.tr(),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFFB2B2B2),
                                    ),
                                  ),
                                  const SizedBox(width: 27),
                                ],
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),
                ],
              ),
            ),

            // 로그인 진행 중엔 다른 탭/스와이프를 막아서 추가 입력이 큐에
            // 쌓이는 걸 방지한다.
            if (_isLoggingIn)
              const Positioned.fill(
                child: AbsorbPointer(absorbing: true),
              ),
          ],
        ),
      ),
    );
  }
}
