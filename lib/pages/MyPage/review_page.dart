import '../../i18n/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../styles/colors.dart';
import '../../widgets/auto_translate_text.dart';
import '../../widgets/employer_note_tab_bar.dart';
import 'review_detail_page.dart';

/// 프로필 하위 리뷰 화면. MyPage 안에서 인라인으로 표시되어
/// 하단 네비게이션 바가 유지되도록 Scaffold를 사용하지 않는다.
/// 뒤로가기는 nav 바에서 Profile 탭을 다시 누르면 발생한다.
class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  int _selectedTab = 0;

  // i18n 키 → tr 로 변환된 라벨이 NoteTabBar 에 전달됨.
  static const List<String> _tabKeys = ['my_page.my_reviews', 'my_page.received'];

  /// 본문 배경: #F4BFB3 @ 11% (헤더와 탭바는 흰색 유지)
  static final Color _bodyBg = const Color(0xFFF4BFB3).withValues(alpha: 0.11);

  final List<Map<String, dynamic>> _myReviews = [
    {
      'title': 'Event Staff',
      'rating': 5,
      'body':
          'Really well organized event. The team lead was clear with instructions and the hours were as posted. Would work here again.',
    },
    {
      'title': 'Café Crew',
      'rating': 4,
      'body':
          'Busy shift but the manager was supportive. Only downside was the break room was a bit cramped. Good pay for the day.',
    },
    {
      'title': 'Retail Assistant',
      'rating': 3,
      'body':
          'Decent experience. Training was quick so I had to ask a lot of questions. Could have used one more person on the floor during peak hours.',
    },
    {
      'title': 'Festival Staff',
      'rating': 5,
      'body':
          'Best gig I\'ve done through the app. On-time payment, friendly staff, and the venue was easy to get to. Highly recommend.',
    },
    {
      'title': 'Warehouse Helper',
      'rating': 2,
      'body':
          'Schedule changed last minute and the site was farther than expected. The work itself was okay but communication could be better.',
    },
    {
      'title': 'Promotional Staff',
      'rating': 4,
      'body':
          'Fun atmosphere and the brand team was nice. Long standing hours but they provided snacks and water. Would do again.',
    },
  ];

  final List<Map<String, dynamic>> _receivedReviews = [
    {
      'title': 'Concierge',
      'rating': 5,
      'body':
          'Showed up on time and picked up tasks quickly. Handled the rush hour well. We\'d love to have them back next time.',
    },
    {
      'title': 'Store Associate',
      'rating': 4,
      'body':
          'Reliable and polite with customers. Only small note: a bit more product training would help, but overall great help for the day.',
    },
    {
      'title': 'Conference Helper',
      'rating': 5,
      'body':
          'Outstanding. Took initiative, stayed until breakdown was done, and the guests had good things to say. Will definitely request again.',
    },
    {
      'title': 'Inventory Assistant',
      'rating': 3,
      'body':
          'Got the job done. A few mix-ups with the packing list but they fixed it when we pointed it out. Would consider for future shifts.',
    },
  ];

  List<Map<String, dynamic>> get _currentList =>
      _selectedTab == 0 ? _myReviews : _receivedReviews;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        NoteTabBar(
          selectedIndex: _selectedTab,
          onTabSelected: (index) => setState(() => _selectedTab = index),
          tabs: _tabKeys.map((k) => k.tr()).toList(),
          indicatorWidth: 179,
        ),
        Expanded(
          child: Container(
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

  Widget _buildReviewCard(Map<String, dynamic> item, int index) {
    final rating = item['rating'] as int;
    final title = item['title'] as String;
    final body = item['body'] as String;
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
              index: isMyReviews ? index : null,
              isEditable: isMyReviews,
            ),
          ),
        );
        if (result != null &&
            result.containsKey('index') &&
            isMyReviews &&
            mounted) {
          setState(() {
            if (result.containsKey('body')) {
              _myReviews[result['index']!]['body'] = result['body'];
            }
            if (result.containsKey('rating')) {
              _myReviews[result['index']!]['rating'] = result['rating'];
            }
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
