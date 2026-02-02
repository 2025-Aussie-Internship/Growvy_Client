import 'package:flutter/material.dart';
import '../styles/colors.dart';

/// 프로필 이미지 선택 모달. [onSelected]에 선택한 인덱스 전달.
class ProfilePickerModal {
  static Future<void> show(
    BuildContext context, {
    required List<ImageProvider> profileImages,
    required void Function(int index) onSelected,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _ProfilePickerContent(
        profileImages: profileImages,
        onSelected: onSelected,
      ),
    );
  }
}

class _ProfilePickerContent extends StatefulWidget {
  final List<ImageProvider> profileImages;
  final void Function(int index) onSelected;

  const _ProfilePickerContent({
    required this.profileImages,
    required this.onSelected,
  });

  @override
  State<_ProfilePickerContent> createState() => _ProfilePickerContentState();
}

class _ProfilePickerContentState extends State<_ProfilePickerContent> {
  late PageController _pageController;
  double _currentPage = 10000.0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.18,
      initialPage: 10000,
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

  int get _currentIndex => (_currentPage.round() % widget.profileImages.length);

  @override
  Widget build(BuildContext context) {
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
            'Pick Your Profile',
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
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: _buildProfileStack(constraints.maxWidth, 200),
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
              widget.profileImages.length,
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
                onPressed: () {
                  widget.onSelected(_currentIndex);
                  Navigator.pop(context);
                },
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

  List<Widget> _buildProfileStack(double screenWidth, double areaHeight) {
    List<Widget> items = [];
    int centerIndex = _currentPage.round();
    List<int> renderOrder = [-2, 2, -1, 1, 0];
    const double edgePadding = 24;

    for (int offset in renderOrder) {
      int index = centerIndex + offset;
      int actualIndex = index % widget.profileImages.length;
      if (actualIndex < 0) actualIndex += widget.profileImages.length;
      double difference = index - _currentPage;
      double size = offset == 0 ? 120 : 80;
      double availableWidth = screenWidth - (edgePadding * 2);
      double centerX = screenWidth / 2;
      double horizontalSpacing = availableWidth / 5;
      double xOffset = difference * horizontalSpacing;
      double yOffset = difference.abs() * 10;
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
                image: DecorationImage(
                  image: widget.profileImages[actualIndex],
                  fit: BoxFit.cover,
                ),
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
