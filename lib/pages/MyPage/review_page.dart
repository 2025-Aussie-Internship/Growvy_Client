import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../styles/colors.dart';
import 'review_detail_page.dart';

class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  int _selectedTab = 0;

  static const Color _bgColor = Color(0xFFFF7252);

  final List<Map<String, dynamic>> _myReviews = [
    {
      'title': 'Event Staff',
      'rating': 5,
      'body':
          'Lorem ipsum dolor sit amet consectetur. At id varius facilisis morbi tortor elementum lectus. Nisi adipiscing in hac leo. Ut phasellus tristique lorem porttitor vitae ac. Id pellentesque fermentum in egestas a tortor diam.',
    },
    {
      'title': 'Event Staff',
      'rating': 5,
      'body':
          'Lorem ipsum dolor sit amet consectetur. At id varius facilisis morbi tortor elementum lectus. Nisi adipiscing in hac leo. Ut phasellus tristique lorem porttitor vitae ac. Id pellentesque fermentum in egestas a tortor diam.',
    },
    {
      'title': 'Event Staff',
      'rating': 5,
      'body':
          'Lorem ipsum dolor sit amet consectetur. At id varius facilisis morbi tortor elementum lectus. Nisi adipiscing in hac leo. Ut phasellus tristique lorem porttitor vitae ac. Id pellentesque fermentum in egestas a tortor diam.',
    },
    {
      'title': 'Event Staff',
      'rating': 5,
      'body':
          'Lorem ipsum dolor sit amet consectetur. At id varius facilisis morbi tortor elementum lectus. Nisi adipiscing in hac leo. Ut phasellus tristique lorem porttitor vitae ac. Id pellentesque fermentum in egestas a tortor diam.',
    },
    {
      'title': 'Event Staff',
      'rating': 5,
      'body':
          'Lorem ipsum dolor sit amet consectetur. At id varius facilisis morbi tortor elementum lectus. Nisi adipiscing in hac leo. Ut phasellus tristique lorem porttitor vitae ac. Id pellentesque fermentum in egestas a tortor diam.',
    },
    {
      'title': 'Event Staff',
      'rating': 5,
      'body':
          'Lorem ipsum dolor sit amet consectetur. At id varius facilisis morbi tortor elementum lectus. Nisi adipiscing in hac leo. Ut phasellus tristique lorem porttitor vitae ac. Id pellentesque fermentum in egestas a tortor diam.',
    },
  ];

  final List<Map<String, dynamic>> _receivedReviews = [
    {
      'title': 'Café Crew',
      'rating': 4,
      'body':
          'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.',
    },
    {
      'title': 'Retail Assistant',
      'rating': 5,
      'body':
          'Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.',
    },
  ];

  List<Map<String, dynamic>> get _currentList =>
      _selectedTab == 0 ? _myReviews : _receivedReviews;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: SvgPicture.asset('assets/icon/logo_orange.svg', height: 36),
          centerTitle: true,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0.5,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                Expanded(child: _buildTab(0, 'My Reviews')),
                Expanded(child: _buildTab(1, 'Received Reviews')),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: _bgColor,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                itemCount: _currentList.length,
                itemBuilder: (context, index) {
                  return _buildReviewCard(_currentList[index], index);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String label) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10.5),
        decoration: BoxDecoration(
          color: isSelected ? _bgColor : const Color(0xFFF5F5F5),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    offset: const Offset(0, -2),
                    blurRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF747474),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> item, int index) {
    final rating = item['rating'] as int;
    final title = item['title'] as String;
    final body = item['body'] as String;
    final isMyReviews = _selectedTab == 0;

    return GestureDetector(
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
        width: 358,
        height: 137,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              offset: const Offset(0, 2),
              blurRadius: 8.4,
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
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF931515),
                    ),
                  ),
                ),
                _buildStarRating(rating),
              ],
            ),
            const SizedBox(height: 7.5),
            Text(
              body,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF4E2121),
                fontWeight: FontWeight.w400,
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
          padding: const EdgeInsets.only(right: 2),
          child: SvgPicture.asset(
            filled ? 'assets/icon/score_filled_icon.svg' : 'assets/icon/score_not_icon.svg',
            width: 20,
            height: 20,
            colorFilter: ColorFilter.mode(
              filled ? AppColors.mainColor : const Color(0xFFBDBDBD),
              BlendMode.srcIn,
            ),
          ),
        );
      }),
    );
  }
}