import 'dart:async';

import 'package:easy_localization/easy_localization.dart' hide StringTranslateExtension;
import '../../i18n/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import '../../bindings/main_binding.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/signup_data_controller.dart';
import '../../controllers/user_profile_controller.dart';
import '../../models/user_profile.dart';
import '../../services/user_profile_cache.dart';
import '../../services/user_repository.dart';
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
  /// setState 로 묶어 두어 로딩 오버레이 표시도 같이 토글한다.
  bool _isNavigating = false;

  /// 사용자가 끊겼다고 느끼지 않도록 보여 주는 최소 로딩 시간.
  /// (300~400ms 면 자연스러운 "잠깐 처리 중" 느낌)
  static const Duration _minLoadingDuration = Duration(milliseconds: 350);

  /// "Ready to Start" 버튼 핸들러.
  ///
  /// 핵심 정책: **백엔드 응답을 기다리지 않는다.**
  ///   - 로컬 프로필(`UserProfileController`)을 즉시 채워 MainPage 가 바로 사진/이름을 그릴 수 있게 하고,
  ///   - 백엔드 회원가입 호출은 fire-and-forget 으로 백그라운드에서 진행 → 응답이 도착하면 프로필을 보강.
  ///   - 짧은 로딩 오버레이(350ms)만 보여 주고 곧바로 MainPage 로 fade-in.
  ///
  /// 이렇게 하면 백엔드가 느리거나 꺼져 있어도 사용자는 "끊긴 느낌" 없이 자연스럽게 진입.
  Future<void> _goToMain() async {
    debugPrint('[SignupComplete] Ready to Start tap (isNavigating=$_isNavigating)');
    if (_isNavigating) return;
    setState(() => _isNavigating = true);

    try {
      final signupData = Get.find<SignupDataController>();

      // 1) 로컬 프로필 컨트롤러를 즉시 채운다 (MainPage 가 곧장 사진/이름 표시).
      final profileCtrl = Get.isRegistered<UserProfileController>()
          ? UserProfileController.to
          : Get.put<UserProfileController>(
              UserProfileController(),
              permanent: true,
            );
      final isProfileUpdate = signupData.isSeekerProfileUpdate;
      if (isProfileUpdate) {
        profileCtrl.hydrateFromProfileUpdate(signupData);
      } else {
        profileCtrl.hydrateFromSignup(signupData);
      }

      final pendingSubmit = isProfileUpdate
          ? signupData.updateProfileToBackend()
          : signupData.submitToBackend();
      unawaited(
        pendingSubmit.then((serverUser) async {
          try {
            if (isProfileUpdate) {
              if (Get.isRegistered<AuthController>()) {
                await AuthController.to.saveUserType(false);
              }
              if (serverUser.isNotEmpty) {
                final current = profileCtrl.profile.value;
                if (current != null) {
                  final useLocalImage = current.profileImageAsset != null &&
                      current.profileImageAsset!.isNotEmpty;
                  final merged = UserProfile(
                    id: current.id,
                    email: current.email,
                    displayName: current.displayName,
                    name: current.name,
                    gender: current.gender,
                    pronouns: current.pronouns,
                    phoneNumber: current.phoneNumber,
                    birthDate: current.birthDate,
                    isEmployer: false,
                    profileImageId:
                        current.profileImageId ?? serverUser['profileImageId'] as int?,
                    profileImageAsset: current.profileImageAsset,
                    profileImageUrl: useLocalImage ? null : current.profileImageUrl,
                    career: current.career ?? serverUser['career'] as String?,
                    introduction:
                        current.introduction ?? serverUser['bio'] as String?,
                    interestIds: current.interestIds,
                  );
                  profileCtrl.profile.value = merged;
                  await UserProfileCache.save(merged);
                }
              }
              final me = await UserRepository.fetchAuthMe()
                  .timeout(const Duration(seconds: 8));
              if (me.isNotEmpty) {
                await profileCtrl.refreshFromServerMergingLocal(() async => me);
              }
            } else {
              if (serverUser.isEmpty) {
                debugPrint('[SignupComplete] (bg) submit 응답 비어 있음');
                return;
              }
              profileCtrl.profile.value = UserProfile.fromJson(serverUser);
              await UserProfileCache.save(profileCtrl.profile.value!);
            }
            debugPrint('[SignupComplete] (bg) 서버 반영 완료');
          } catch (e) {
            debugPrint('[SignupComplete] (bg) 프로필 보강 실패: $e');
          }
        }).catchError((Object e) {
          // SignupRepository 는 throw 하지 않도록 막아 뒀지만,
          // 혹시 미처 잡지 못한 예외가 올라와도 흐름은 막지 않는다.
          debugPrint('[SignupComplete] (bg) submit 예외: $e');
        }),
      );

      // 3) 다음 회원가입 흐름을 위해 누적값 초기화.
      signupData.reset();

      // 4) 최소 로딩 시간만큼 잠깐 대기 — 사용자에게 "처리됐다" 느낌을 준다.
      await Future.delayed(_minLoadingDuration);

      if (!mounted) return;

      // 5) 라우트 교체. 다음 프레임에서 Get.offAll → MainPage fade-in.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        debugPrint('[SignupComplete] MainPage 로 offAll 호출');
        try {
          Get.offAll(
            () => MainPage(initialTab: isProfileUpdate ? 4 : 0),
            binding: MainBinding(),
            transition: Transition.fadeIn,
            duration: const Duration(milliseconds: 220),
          );
        } catch (e, st) {
          debugPrint('[SignupComplete] Get.offAll 실패: $e\n$st');
          if (mounted) {
            setState(() => _isNavigating = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('홈으로 이동에 실패했어요. 다시 시도해 주세요.'),
              ),
            );
          }
        }
      });
    } catch (e, st) {
      debugPrint('[SignupComplete] _goToMain 실패: $e\n$st');
      if (mounted) {
        setState(() => _isNavigating = false);
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
      body: Stack(
        children: [
          Center(
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
                      // 로딩 중에는 onPressed 를 null 로 만들어 자동으로 회색 비활성 상태가 되게 한다.
                      onPressed: _isNavigating ? null : () => _goToMain(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 로딩 오버레이 — fade-in 으로 자연스럽게 등장하고, 화면 입력을 막아
          // "왜 안 넘어가지?" 같은 중복 탭/끊김 느낌을 없앤다.
          IgnorePointer(
            ignoring: !_isNavigating,
            child: AnimatedOpacity(
              opacity: _isNavigating ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              child: Container(
                color: Colors.white.withValues(alpha: 0.85),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.mainColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'signup.preparing_home'.tr(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF747474),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
