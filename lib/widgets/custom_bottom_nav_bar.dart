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
            offset: const Offset(4, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 80,
          // padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
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

    final String svgPath = isSelected
        ? 'assets/icon/${iconName}_filled.svg'
        : 'assets/icon/${iconName}_not.svg';

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
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