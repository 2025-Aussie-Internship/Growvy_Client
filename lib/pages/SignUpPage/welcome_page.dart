import 'package:flutter/material.dart';
import '../../styles/colors.dart';
import 'signin_page.dart';

/// 구글 로그인 직후 잠깐 보였다가 자동으로 사라지는 인사말 페이지.
///
/// iPhone 부팅 직후 "Hello" 화면처럼, "Welcome!" 텍스트가 페이드 인 →
/// 잠시 유지 → 페이드 아웃 된 뒤 자연스러운 fade 트랜지션으로 [SignInPage] 로 이동한다.
class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

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
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: const Text(
            'Welcome!',
            style: TextStyle(
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
