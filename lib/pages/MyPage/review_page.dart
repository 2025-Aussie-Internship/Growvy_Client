import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/token_storage.dart';
import '../../config/env.dart';

import '../../i18n/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../styles/colors.dart';
import '../../widgets/auto_translate_text.dart';
import '../../widgets/employer_note_tab_bar.dart';
import 'review_detail_page.dart';

class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  int _selectedTab = 0;

  // 🌟 API 데이터 저장용 리스트
  List<dynamic> _myReviews = [];
  List<dynamic> _receivedReviews = [];
  bool _isLoading = true;

  static const List<String> _tabKeys = [
    'my_page.my_reviews',
    'my_page.received',
  ];

  static final Color _bodyBg = const Color(0xFFF4BFB3).withValues(alpha: 0.11);

  @override
  void initState() {
    super.initState();
    _fetchAllReviews();
  }

  // 🌟 API 연동: 내가 쓴 리뷰 & 받은 리뷰 가져오기
  Future<void> _fetchAllReviews() async {
    try {
      final token = await TokenStorage.readAccessToken();
      final baseUrl = '${Env.apiBaseUrl}reviews';
      // 병렬로 API 호출
      final results = await Future.wait([
        http.get(
          Uri.parse('$baseUrl/written'),
          headers: {'Authorization': 'Bearer $token'},
        ),
        http.get(
          Uri.parse('$baseUrl/received'),
          headers: {'Authorization': 'Bearer $token'},
        ),
      ]);

      if (mounted) {
        setState(() {
          if (results[0].statusCode == 200)
            _myReviews = jsonDecode(utf8.decode(results[0].bodyBytes));
          if (results[1].statusCode == 200)
            _receivedReviews = jsonDecode(utf8.decode(results[1].bodyBytes));
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ 리뷰 로딩 에러: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> get _currentList =>
      _selectedTab == 0 ? _myReviews : _receivedReviews;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        NoteTabBar(
          selectedIndex: _selectedTab,
          onTabSelected: (index) => setState(() => _selectedTab = index),
          // 🌟 에러 해결: AppStringTr(k).tr() 로 어떤 tr을 쓸지 명확하게 지정합니다.
          tabs: _tabKeys.map((k) => AppStringTr(k).tr()).toList(),
          indicatorWidth: 179,
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Container(
                  color: _bodyBg,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    itemCount: _currentList.length,
                    itemBuilder: (context, index) {
                      return _buildReviewCard(_currentList[index], index);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildReviewCard(dynamic item, int index) {
    // 🌟 API 응답 필드명에 맞게 매핑
    final rating = item['rating'] as int;
    final title = item['title'] as String;
    final body = item['body'] as String;
    final reviewId = item['reviewId'] as int; // 상세 이동 시 사용 가능
    final isMyReviews = _selectedTab == 0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        final result = await Navigator.of(context).push<Map<String, dynamic>>(
          MaterialPageRoute(
            builder: (context) => ReviewDetailPage(
              title: title,
              rating: rating,
              body: body,
              index: index, // 로컬 인덱스 사용
              isEditable: isMyReviews,
            ),
          ),
        );
        // 수정 후 반영 로직은 기존과 동일하게 유지
        if (result != null && isMyReviews && mounted) {
          setState(() {
            _myReviews[index]['body'] = result['body'];
            _myReviews[index]['rating'] = result['rating'];
          });
        }
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF5F5F5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              offset: const Offset(0, 2),
              blurRadius: 8,
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
                  child: AutoTranslateText(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.pointColor,
                    ),
                  ),
                ),
                _buildStarRating(rating),
              ],
            ),
            const SizedBox(height: 8),
            AutoTranslateText(
              body,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF4E2121),
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStarRating(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final filled = index < rating;
        return Padding(
          padding: const EdgeInsets.only(left: 2),
          child: SvgPicture.asset(
            filled
                ? 'assets/icon/score_filled_icon.svg'
                : 'assets/icon/score_not_icon.svg',
            width: 16,
            height: 16,
            colorFilter: ColorFilter.mode(
              filled ? AppColors.subColor1 : const Color(0xFFBDBDBD),
              BlendMode.srcIn,
            ),
          ),
        );
      }),
    );
  }
}
