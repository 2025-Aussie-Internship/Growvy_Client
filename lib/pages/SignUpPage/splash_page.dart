import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'signup_page.dart';

/// 스플레시 화면. 구글 로그인 화면과 동일한 레이아웃(배경 + 로고)에서 버튼만 제외.
/// 표시 후 SignUpPage로 이동.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  static const Color _mainColor = Color(0xFFFC6340);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const SignUpPage(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) => child,
            transitionDuration: Duration.zero,
          ),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _mainColor,
      body: SafeArea(
        child: Center(
          child: SvgPicture.asset('assets/icon/logo_white.svg', width: 228),
        ),
      ),
    );
  }
}
