import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../bindings/main_binding.dart';
import '../../styles/colors.dart';
import '../../widgets/signin_app_bar.dart';
import '../../widgets/next_button.dart';
import '../MainPage/main_page.dart';

class SignupCompletePage extends StatefulWidget {
  const SignupCompletePage({super.key});

  @override
  State<SignupCompletePage> createState() => _SignupCompletePageState();
}

class _SignupCompletePageState extends State<SignupCompletePage> {
  /// 중복 탭으로 인한 라우트 전환 충돌 방지용 가드.
  bool _isNavigating = false;

  void _goToMain() {
    if (_isNavigating) return;
    _isNavigating = true;

    // 현재 빌드 사이클이 끝난 뒤 라우트를 교체한다.
    // GetX 의 offAll 에 binding 파라미터를 직접 넘기면 의존성 등록 → 라우트 push 가
    // 한 라이프사이클 안에서 처리되어 seeker/employer 모두 안정적으로 동작한다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Get.offAll(
        () => const MainPage(),
        binding: MainBinding(),
        transition: Transition.fadeIn,
        duration: const Duration(milliseconds: 220),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const SignInAppBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'All Done!',
              style: TextStyle(
                color: AppColors.mainColor,
                fontSize: 32,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 40),
            Center(
              child: SizedBox(
                width: 320,
                child: NextButton(
                  text: 'Ready to Start!',
                  onPressed: _goToMain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
