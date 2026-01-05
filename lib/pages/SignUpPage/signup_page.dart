import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  static const Color mainColor = Color(0xFFFC6340);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: mainColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            // [수정 1] 자식 위젯들을 가로축 기준 중앙으로 정렬
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. 상단 여백
              const Spacer(),

              // Welcome Text
              const Text(
                'Welcome To',
                style: TextStyle(
                  // fontFamily: 'Pretendard',
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 10),

              // 2. 중앙 로고
              SvgPicture.asset(
                'assets/icon/logo_white.svg',
                width: 228, 
              ),

              // 3. 하단 여백
              const Spacer(),

              // 4. 구글 로그인 버튼
              // [수정 2] 확실한 중앙 정렬을 위해 Center 위젯으로 감싸기
              Center(
                child: SizedBox(
                  width: 318, // 너비 고정
                  height: 48, // 높이 고정
                  child: ElevatedButton(
                    onPressed: () {
                      debugPrint("Google Login Pressed");
                    },
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
                        // 왼쪽: 구글 로고
                        SvgPicture.asset(
                          'assets/icon/google_logo.svg',
                          height: 27,
                        ),
                        
                        // 오른쪽: 텍스트
                        const Text(
                          'Continue With Google',
                          style: TextStyle(
                            // fontFamily: 'Pretendard',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFB2B2B2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 버튼 아래 여백
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}
