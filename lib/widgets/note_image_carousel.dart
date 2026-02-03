import 'package:flutter/material.dart';

/// 노트 상세에서 사용자가 올린 사진을 가로로 넘길 수 있는 캐러셀 위젯
class NoteImageCarousel extends StatefulWidget {
  const NoteImageCarousel({
    super.key,
    required this.imageUrls,
    this.width = 358,
    this.height = 200,
  });

  final List<String> imageUrls;
  final double width;
  final double height;

  @override
  State<NoteImageCarousel> createState() => _NoteImageCarouselState();
}

class _NoteImageCarouselState extends State<NoteImageCarousel> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: Center(
          child: Container(
            color: Colors.grey[200],
            child: const Icon(Icons.image_not_supported, size: 48),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.width,
          height: widget.height,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemCount: widget.imageUrls.length,
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.imageUrls[index],
                  fit: BoxFit.cover,
                  width: widget.width,
                  height: widget.height,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, size: 48),
                    );
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.imageUrls.length, (index) {
            final isActive = index == _currentIndex;
            return Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive
                    ? const Color(0xFFFC6340)
                    : const Color(0xFFE0E0E0),
              ),
            );
          }),
        ),
      ],
    );
  }
}
