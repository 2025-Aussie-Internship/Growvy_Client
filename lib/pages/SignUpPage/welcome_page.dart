import 'package:easy_localization/easy_localization.dart' hide StringTranslateExtension;
import '../../i18n/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import '../../styles/colors.dart';
import '../MainPage/main_page.dart';
import 'seeker_interest_page.dart';
import 'signin_page.dart';

/// 언어 선택 직후 잠깐 보였다가 자동으로 사라지는 인사말 페이지.
///
/// "Welcome!"(또는 "환영합니다!") 텍스트가 페이드 인 → 잠시 유지 →
/// 페이드 아웃 된 뒤 자연스러운 fade 트랜지션으로 다음 화면으로 이동한다.
///
/// 다음 화면은 [isExistingUser] 에 따라 분기된다.
/// - true  (= 이미 가입된 사용자, 로그아웃 후 재진입 등): [MainPage]
/// - false (= 신규 사용자 또는 회원가입 흐름):                [SignInPage]
class WelcomePage extends StatefulWidget {
  const WelcomePage({
    super.key,
    this.isExistingUser = false,
    this.isSeekerProfileUpdate = false,
  });

  /// 이 흐름이 기존 회원의 재진입인지 여부.
  final bool isExistingUser;

  /// 구직자 로그아웃 후 관심사~프로필만 다시 받아 갱신하는 흐름.
  final bool isSeekerProfileUpdate;

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;

  static const Duration _totalDuration = Duration(milliseconds: 2400);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _totalDuration,
    );

    // 1초 fade-in → 0.6초 유지 → 0.8초 fade-out
    _fade = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 6,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 8,
      ),
    ]).animate(_controller);

    _controller.forward().whenComplete(_goNext);
  }

  void _goNext() {
    if (!mounted) return;
    if (widget.isSeekerProfileUpdate) {
      Get.offAll(
        () => const SeekerInterestPage(),
        transition: Transition.fadeIn,
        duration: const Duration(milliseconds: 320),
      );
      return;
    }
    if (widget.isExistingUser) {
      Get.offAll(
        () => const MainPage(),
        transition: Transition.fadeIn,
        duration: const Duration(milliseconds: 320),
      );
      return;
    }
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (_, _, _) => const SignInPage(),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.locale; // setLocale 시 자동 rebuild 보장
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: Text(
            'welcome.greeting'.tr(),
            style: const TextStyle(
              color: AppColors.mainColor,
              fontSize: 36,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}
