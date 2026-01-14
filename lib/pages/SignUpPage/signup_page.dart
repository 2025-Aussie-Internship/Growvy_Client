import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'signin_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  static const Color mainColor = Color(0xFFFC6340);

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  // google-login
  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      // Firebase ID Token 확보
      final firebaseIdToken = await userCredential.user!.getIdToken();
      print('Firebase UID: ${userCredential.user?.uid}');
      print('Firebase Token: $firebaseIdToken');

      // 백엔드 로그인 요청
      final response = await http.post(
        Uri.parse('http://43.201.9.192/api/auth/login'),
        headers: {'Authorization': 'Bearer $firebaseIdToken'},
      );
      print('Backend status: ${response.statusCode}');
      print('Backend response: ${response.body}');

      // registered 여부 따라 flow 처리

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SignInPage()),
        );
      }
    } catch (e) {
      debugPrint('Google login error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Google 로그인 실패')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: mainColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),

              const Text(
                'Welcome To',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 10),

              SvgPicture.asset('assets/icon/logo_white.svg', width: 228),

              const Spacer(),

              Center(
                child: SizedBox(
                  width: 318,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => _signInWithGoogle(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black54,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SvgPicture.asset(
                          'assets/icon/google_logo.svg',
                          height: 27,
                        ),
                        const Text(
                          'Continue With Google',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFB2B2B2),
                          ),
                        ),
                        const SizedBox(width: 27), // 좌우 균형 맞춤
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}
