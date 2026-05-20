import 'package:flutter/material.dart';
import '../styles/colors.dart';

/// Note 페이지 상단 탭 (employer/seeker 공용) + 슬라이딩 인디케이터
class NoteTabBar extends StatelessWidget {
  const NoteTabBar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.tabs,
  });

  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final List<String> tabs;

  static const Duration _animationDuration = Duration(milliseconds: 280);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tabWidth = constraints.maxWidth / tabs.length;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: List.generate(tabs.length, (index) {
                final isSelected = selectedIndex == index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onTabSelected(index),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Text(
                        tabs[index],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            SizedBox(
              height: 3,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedPositioned(
                    duration: _animationDuration,
                    curve: Curves.easeInOutCubic,
                    left: selectedIndex * tabWidth,
                    width: tabWidth,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: AnimatedContainer(
                        duration: _animationDuration,
                        curve: Curves.easeInOutCubic,
                        width: 48,
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppColors.mainColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
