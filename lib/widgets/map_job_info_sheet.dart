import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 지도에서 공고 마커 선택 시 뜨는 공고 정보 카드 (357x168, r24, Payment/Time/Qualifications). (357x168, r24, Payment/Time/Qualifications).
class MapJobInfoSheet extends StatelessWidget {
  const MapJobInfoSheet({
    super.key,
    required this.title,
    required this.company,
    required this.payment,
    required this.time,
    required this.qualifications,
    this.isBookmarked = false,
    required this.onBookmarkTap,
    required this.onClose,
    required this.onAddTap,
  });

  final String title;
  final String company;
  final String payment;
  final String time;
  final String qualifications;
  final bool isBookmarked;
  final VoidCallback onBookmarkTap;
  final VoidCallback onClose;
  final VoidCallback onAddTap;

  static const double _cardWidth = 357;
  static const double _cardHeight = 180;
  static const double _radius = 24;
  static const Color _strokeColor = Color(0xFFD9D9D9);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: _cardWidth,
        height: _cardHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_radius),
          border: Border.all(color: _strokeColor, width: 0.5),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더: 제목·회사 같은 줄, 북마크·X 24px 검정
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            company,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF747474),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: onBookmarkTap,
                    child: SvgPicture.asset(
                      isBookmarked
                          ? 'assets/icon/bookmark_filled_icon.svg'
                          : 'assets/icon/bookmark_icon.svg',
                      width: 24,
                      height: 24,
                      colorFilter: const ColorFilter.mode(
                        Colors.black,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onClose,
                    child: const Icon(
                      Icons.close,
                      size: 24,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Payment / Time / Qualifications 카드 (8px 간격) + Qualifications와 39px 간격 + plus 버튼 (리스트 오른쪽 아래, bottom 16, right 12)
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildDetailCard(
                    icon: 'assets/icon/salary_icon.svg',
                    label: 'Payment',
                    value: _parsePaymentValue(payment),
                    sub: _parsePaymentSub(payment),
                  ),
                  const SizedBox(width: 8),
                  _buildDetailCard(
                    icon: 'assets/icon/time_icon.svg',
                    label: 'Time',
                    value: _parseTimeValue(time),
                    sub: _parseTimeSub(time),
                  ),
                  const SizedBox(width: 8),
                  _buildDetailCard(
                    icon: 'assets/icon/people_icon.svg',
                    label: 'Qualifications',
                    value: _parseQualValue(qualifications),
                    sub: _parseQualSub(qualifications),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onAddTap,
                    child: SvgPicture.asset(
                      'assets/icon/plus_button.svg',
                      width: 32,
                      height: 32,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _parsePaymentValue(String s) {
    final parts = s.split(' per ');
    return parts.isNotEmpty ? parts[0].trim() : s;
  }

  String _parsePaymentSub(String s) {
    final parts = s.split(' per ');
    return parts.length > 1 ? 'per ${parts[1].trim()}' : '';
  }

  String _parseTimeValue(String s) {
    final i = s.indexOf(' ');
    return i > 0 ? s.substring(0, i) : s;
  }

  String _parseTimeSub(String s) {
    final i = s.indexOf(' ');
    return i > 0 ? s.substring(i + 1) : '';
  }

  String _parseQualValue(String s) {
    final i = s.lastIndexOf(' ');
    return i > 0 ? s.substring(0, i) : s;
  }

  String _parseQualSub(String s) {
    final i = s.lastIndexOf(' ');
    return i > 0 ? s.substring(i + 1) : '';
  }

  static const double _detailCardWidth = 85;

  Widget _buildDetailCard({
    required String icon,
    required String label,
    required String value,
    required String sub,
  }) {
    return SizedBox(
      width: _detailCardWidth,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 9.5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _strokeColor, width: 0.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 주황색 원 42px, 가운데 하얀 아이콘 20px
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: Color(0xFFFF7252),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SvgPicture.asset(
                  icon,
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (sub.isNotEmpty) ...[
              const SizedBox(height: 0),
              Text(
                sub,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF747474),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
