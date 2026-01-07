import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF202020).withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(4, -4), // 그림자를 위쪽으로
          ),
        ],
      ),
      child: SafeArea(
        // 하단 안전 영역 확보 (홈 인디케이터 등)
        child: Container(
          height: 80, // 높이 조절 (SVG 크기에 맞춰 조정 필요)
          // padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center, // [수정] 가운데 정렬
            children: [
              _buildNavItem(0, 'home'),
              _buildNavItem(1, 'map'),
              _buildNavItem(2, 'chat'),
              _buildNavItem(3, 'note'),
              _buildNavItem(4, 'profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String iconName) {
    final bool isSelected = currentIndex == index;

    // 선택 여부에 따라 _filled 또는 _not 파일명 결정
    final String svgPath = isSelected
        ? 'assets/icon/${iconName}_filled.svg'
        : 'assets/icon/${iconName}_not.svg';

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque, // 터치 영역 확보
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.center,
        child: SvgPicture.asset(
          svgPath,
          width: 31,
          height: 44,
        ),
      ),
    );
  }
}