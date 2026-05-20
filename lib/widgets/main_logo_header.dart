import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 메인 홈 탭 상단 로고 영역 (표시/숨김 애니메이션)
class MainLogoHeader extends StatelessWidget {
  const MainLogoHeader({
    super.key,
    required this.visible,
  });

  final bool visible;

  static const double logoBarHeight = 48;
  static const Duration animationDuration = Duration(milliseconds: 280);

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final fullHeight = topInset + logoBarHeight + 0.5;
    final targetHeight = visible ? fullHeight : 0.0;

    return AnimatedContainer(
      duration: animationDuration,
      curve: Curves.easeInOutCubic,
      height: targetHeight,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Colors.white,
        border: visible
            ? const Border(
                bottom: BorderSide(color: Color(0x1A000000), width: 0.5),
              )
            : null,
      ),
      child: OverflowBox(
        alignment: Alignment.bottomCenter,
        minHeight: 0,
        maxHeight: double.infinity,
        child: SizedBox(
          height: fullHeight,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: topInset),
              SizedBox(
                height: logoBarHeight,
                child: Center(
                  child: SvgPicture.asset(
                    'assets/icon/logo_orange.svg',
                    height: 36,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
