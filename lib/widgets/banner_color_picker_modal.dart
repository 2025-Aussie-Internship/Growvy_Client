import 'package:flutter/material.dart';
import '../styles/colors.dart';
import '../styles/modal_theme.dart';

/// 배너 색상 선택 모달. 프로필 선택 모달과 스타일 완전 동일(캐러셀 스택 + 인디케이터 + Save Changes).
class BannerColorPickerModal {
  static const List<Color> _presetColors = [
    Color(0xFF2E7D32), // green
    Color(0xFFFC6340), // main orange
    Color(0xFFFF7252), // sub orange
    Color(0xFF1976D2), // blue
    Color(0xFF7B1FA2), // purple
    Color(0xFFC62828), // red
    Color(0xFF00838F), // teal
    Color(0xFFF9A825), // amber
  ];

  static Future<Color?> show(BuildContext context, {Color? initialColor}) {
    return showModalBottomSheet<Color>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Theme(
        data: modalTheme(context),
        child: _BannerColorPickerContent(
          presetColors: _presetColors,
          initialColor: initialColor,
        ),
      ),
    );
  }
}

class _BannerColorPickerContent extends StatefulWidget {
  final List<Color> presetColors;
  final Color? initialColor;

  const _BannerColorPickerContent({
    required this.presetColors,
    this.initialColor,
  });

  @override
  State<_BannerColorPickerContent> createState() =>
      _BannerColorPickerContentState();
}

class _BannerColorPickerContentState extends State<_BannerColorPickerContent> {
  late PageController _pageController;
  double _currentPage = 10000.0;

  @override
  void initState() {
    super.initState();
    int initialPage = 0;
    if (widget.initialColor != null) {
      for (int i = 0; i < widget.presetColors.length; i++) {
        if (widget.presetColors[i].value == widget.initialColor!.value) {
          initialPage = i;
          break;
        }
      }
    }
    _pageController = PageController(
      viewportFraction: 0.18,
      initialPage: 10000 + initialPage,
    );
    _pageController.addListener(() {
      setState(() => _currentPage = _pageController.page ?? 10000.0);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int get _currentIndex => (_currentPage.round() % widget.presetColors.length);

  Color get _selectedColor => widget.presetColors[_currentIndex];

  @override
  Widget build(BuildContext context) {
    const double carouselHeight = 200;
    return Container(
      height: 540,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 20),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF7252),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
          const Text(
            'Pick Banner Color',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Color(0xFFFF7252),
            ),
          ),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: SizedBox(
              height: carouselHeight,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: _buildColorStack(constraints.maxWidth, carouselHeight),
                      );
                    },
                  ),
                  PageView.builder(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) => const SizedBox(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.presetColors.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: index == _currentIndex ? 16 : 8,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: index == _currentIndex
                      ? AppColors.mainColor
                      : Colors.grey[300],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, _selectedColor),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mainColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Save Changes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  /// 프로필 모달의 _buildProfileStack과 동일한 레이아웃: 중앙 120, 양옆 80, 탭 시 해당 페이지로 이동.
  List<Widget> _buildColorStack(double screenWidth, double areaHeight) {
    List<Widget> items = [];
    int centerIndex = _currentPage.round();
    List<int> renderOrder = [-2, 2, -1, 1, 0];
    const double edgePadding = 24;

    for (int offset in renderOrder) {
      int index = centerIndex + offset;
      int actualIndex = index % widget.presetColors.length;
      if (actualIndex < 0) actualIndex += widget.presetColors.length;
      double difference = index - _currentPage;
      double size = offset == 0 ? 120 : 80;
      double availableWidth = screenWidth - (edgePadding * 2);
      double centerX = screenWidth / 2;
      double horizontalSpacing = availableWidth / 5;
      double xOffset = difference * horizontalSpacing;
      double yOffset = difference.abs() * 10;
      final color = widget.presetColors[actualIndex];
      items.add(
        Positioned(
          left: centerX - (size / 2) + xOffset,
          top: (areaHeight - size) / 2 + yOffset,
          child: GestureDetector(
            onTap: () {
              if (offset != 0) {
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            },
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(offset == 0 ? 0.2 : 0.1),
                    blurRadius: offset == 0 ? 15 : 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return items;
  }
}
