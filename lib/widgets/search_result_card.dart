import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../styles/colors.dart';

/// 검색 결과 리스트에서 사용하는 카드.
/// 디자인: 흰 배경 r=8, 라이트 보더, 우상단 북마크, 좌하단 태그 칩, 우하단 apply 버튼.
class SearchResultCard extends StatelessWidget {
  const SearchResultCard({
    super.key,
    required this.title,
    required this.company,
    required this.tags,
    this.bookmarked = false,
    this.onTap,
    this.onApply,
    this.onBookmarkTap,
  });

  final String title;
  final String company;
  final List<String> tags;
  final bool bookmarked;
  final VoidCallback? onTap;
  final VoidCallback? onApply;
  final VoidCallback? onBookmarkTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFF5F5F5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        company,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF696969),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onBookmarkTap,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8, top: 2),
                    child: SvgPicture.asset(
                      bookmarked
                          ? 'assets/icon/bookmark_filled_icon.svg'
                          : 'assets/icon/bookmark_icon.svg',
                      width: 20,
                      height: 22,
                      colorFilter: bookmarked
                          ? const ColorFilter.mode(
                              AppColors.mainColor,
                              BlendMode.srcIn,
                            )
                          : const ColorFilter.mode(
                              Color(0xFF8E8E8E),
                              BlendMode.srcIn,
                            ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: tags.map(_buildTag).toList(),
                  ),
                ),
                const SizedBox(width: 12),
                _buildApplyButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEAEA),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFFFF7062),
          height: 14 / 12,
        ),
      ),
    );
  }

  Widget _buildApplyButton() {
    return GestureDetector(
      onTap: onApply,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 70,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.mainColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'apply',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
