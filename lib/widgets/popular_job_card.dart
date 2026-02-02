import 'package:flutter/material.dart';
import '../styles/colors.dart';

class PopularJobCard extends StatelessWidget {
  final String title;
  final String company;
  final String dDay;
  final VoidCallback? onTap;

  const PopularJobCard({
    super.key,
    required this.title,
    required this.company,
    required this.dDay,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 300,
        height: 121,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.subColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color.fromARGB(255, 255, 255, 255),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 4),
                Text(
                  company,
                  style: const TextStyle(
                    color: Color(0xFF931515),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE9D8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    dDay,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF931515),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
