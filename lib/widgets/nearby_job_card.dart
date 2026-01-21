import 'package:flutter/material.dart';
import '../styles/colors.dart';

class NearbyJobCard extends StatelessWidget {
  final String title;
  final String company;
  final String distance;
  final List<String> tags;
  final VoidCallback? onTap;

  const NearbyJobCard({
    super.key,
    required this.title,
    required this.company,
    required this.distance,
    required this.tags,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 358,
      height: 180,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF5F5F5), width: 1),
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
          // 1. 타이틀
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.black,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 8),

          // 2. 회사명
          Text(
            company,
            style: const TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 12,
              color: Color(0xFF696969),
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),

          const SizedBox(height: 24),

          // 3. 태그와 거리
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: tags
                    .map(
                      (tag) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _buildTag(tag),
                      ),
                    )
                    .toList(),
              ),
              Text(
                "Around $distance",
                style: const TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                  color: Color(0xFF747474),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 4. See More 버튼
          GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: double.infinity,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.mainColor),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                "See More",
                style: TextStyle(
                  color: AppColors.mainColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
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
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Color(0xFFFF7062),
        ),
      ),
    );
  }
}
