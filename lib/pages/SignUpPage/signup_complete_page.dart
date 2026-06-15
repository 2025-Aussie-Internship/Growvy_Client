import 'package:easy_localization/easy_localization.dart' hide StringTranslateExtension;
import '../../i18n/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import '../../bindings/main_binding.dart';
import '../../controllers/signup_data_controller.dart';
import '../../controllers/user_profile_controller.dart';
import '../../models/user_profile.dart';
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

  Future<void> _goToMain() async {
    if (_isNavigating) return;
    _isNavigating = true;
    debugPrint('[SignupComplete] Ready to Start 클릭됨 → MainPage 진입 시작');

    try {
      // 1) 회원가입 단계마다 누적해 둔 입력값을 한 번에 서버로 보낸다.
      //    SignupRepository.submit 는 백엔드 미응답이어도 throw 하지 않고
      //    빈 map 으로 떨어지므로 UI 흐름이 막히지 않는다.
      final signupData = Get.find<SignupDataController>();
      final serverUser = await signupData.submitToBackend();
      debugPrint(
        '[SignupComplete] submitToBackend 완료. serverUser.isEmpty=${serverUser.isEmpty}',
      );

      // 2) MyPage 등에서 사용할 in-memory 사용자 프로필을 채운다.
      final profileCtrl = Get.isRegistered<UserProfileController>()
          ? UserProfileController.to
          : Get.put<UserProfileController>(
              UserProfileController(),
              permanent: true,
            );
      profileCtrl.hydrateFromSignup(signupData);
      if (serverUser.isNotEmpty) {
        profileCtrl.profile.value = UserProfile.fromJson(serverUser);
      }

      // 3) 다음 회원가입 흐름을 위해 누적값 초기화.
      signupData.reset();

      // 4) 라우트 교체. GetX 의 offAll 에 binding 을 직접 넘기면 의존성
      //    등록 → 라우트 push 가 한 라이프사이클 안에서 처리되어 안정적이다.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        debugPrint('[SignupComplete] MainPage 로 offAll 호출');
        Get.offAll(
          () => const MainPage(),
          binding: MainBinding(),
          transition: Transition.fadeIn,
          duration: const Duration(milliseconds: 220),
        );
      });
    } catch (e, st) {
      // 여기 들어오면 안 되지만, 들어오더라도 사용자가 다시 누를 수 있도록
      // 가드 풀고 콘솔에 명확한 원인을 남긴다.
      debugPrint('[SignupComplete] _goToMain 실패: $e\n$st');
      _isNavigating = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('홈으로 이동에 실패했어요. 다시 시도해 주세요.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    context.locale; // setLocale 시 자동 rebuild 보장
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const SignInAppBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'signup.all_done'.tr(),
              style: const TextStyle(
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
                  text: 'signup.ready_to_start'.tr(),
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
