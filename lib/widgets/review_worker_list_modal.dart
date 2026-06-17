import '../../i18n/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../styles/colors.dart';
import '../../styles/modal_theme.dart';
import '../../widgets/auto_translate_text.dart';
import '../../utils/image_url.dart';
import '../../config/env.dart';

import 'package:dio/dio.dart' as dio;
import '../../services/token_storage.dart';

/// 구인자용 Review Target List 모달. (Job Application 모달과 100% 동일한 레이아웃)
class ReviewTargetListModal {
  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required int postId,
  }) async {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Theme(
        data: modalTheme(context),
        child: _ReviewTargetListContent(postId: postId),
      ),
    );
  }
}

void showTargetProfileModal(BuildContext context, _TargetItem target) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (context) => Theme(
      data: modalTheme(context),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Material(
            color: Colors.transparent,
            child: _TargetProfileSheetContent(target: target),
          ),
        ),
      ),
    ),
  );
}

class _TargetItem {
  final int targetUserId;
  final String name;
  final String profileImagePath;
  final int rating;
  final bool isReviewed;

  _TargetItem({
    required this.targetUserId,
    required this.name,
    required this.profileImagePath,
    this.rating = 5,
    this.isReviewed = false,
  });
}

class _TargetProfileSheetContent extends StatefulWidget {
  const _TargetProfileSheetContent({required this.target});

  final _TargetItem target;

  @override
  State<_TargetProfileSheetContent> createState() =>
      _TargetProfileSheetContentState();
}

class _TargetProfileSheetContentState
    extends State<_TargetProfileSheetContent> {
  bool _expanded = false;

  static final List<Map<String, dynamic>> _dummyReviews = [
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
      'rating': 5,
      'body':
          'Best gig I\'ve done through the app. On-time payment, friendly staff, and the venue was easy to get to. Highly recommend.',
    },
  ];

  static const double _modalHeight = 337;
  static const double _modalHeightExpanded = 664;
  static const double _profileSize = 80;
  static const double _profileOverlap = 40;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
      height: _expanded ? _modalHeightExpanded : _modalHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            offset: Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildProfileHeader(context),
          if (_expanded) ...[
            _buildFixedNameBlock(),
            Expanded(child: _buildReviewListOnly(context)),
          ] else
            _buildSummary(context),
        ],
      ),
    );
  }

  Widget _buildFixedNameBlock() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AutoTranslateText(
            widget.target.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 2),
          AutoTranslateText(
            'She/Her',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 48 + _profileOverlap,
          width: double.infinity,
          decoration: const BoxDecoration(
            color: AppColors.mainColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 12,
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
        Positioned(
          bottom: -_profileOverlap,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: _profileSize,
              height: _profileSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: widget.target.profileImagePath.startsWith('http')
                      ? NetworkImage(widget.target.profileImagePath)
                            as ImageProvider
                      : AssetImage(widget.target.profileImagePath),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummary(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AutoTranslateText(
            widget.target.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 2),
          AutoTranslateText(
            'She/Her',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 10),
          _buildRatingCard(context),
        ],
      ),
    );
  }

  Widget _buildRatingCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4EE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < 4; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: SvgPicture.asset(
                    'assets/icon/score_filled_icon.svg',
                    width: 28,
                    height: 28,
                  ),
                ),
              SvgPicture.asset(
                'assets/icon/score_not_icon.svg',
                width: 28,
                height: 28,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _expanded = true),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Center(
                  child: AutoTranslateText(
                    'Check reviews',
                    style: const TextStyle(
                      color: Color(0xFF931515),
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewListOnly(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._dummyReviews.map((r) => _buildReviewCard(r)),
          const SizedBox(height: 6),
          Center(
            child: Text(
              'common.see_more'.tr(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF931515),
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> item) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF2F4F7)),
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
                child: AutoTranslateText(
                  item['title'] as String,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF931515),
                  ),
                ),
              ),
              _buildCardStarRating(item['rating'] as int),
            ],
          ),
          const SizedBox(height: 5),
          AutoTranslateText(
            item['body'] as String,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF4E2121),
              fontWeight: FontWeight.w400,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCardStarRating(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final filled = index < rating;
        return Padding(
          padding: const EdgeInsets.only(right: 2),
          child: SvgPicture.asset(
            filled
                ? 'assets/icon/score_filled_icon.svg'
                : 'assets/icon/score_not_icon.svg',
            width: 14,
            height: 14,
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

class _ReviewTargetListContent extends StatefulWidget {
  const _ReviewTargetListContent({required this.postId});

  final int postId;

  @override
  State<_ReviewTargetListContent> createState() =>
      _ReviewTargetListContentState();
}

class _ReviewTargetListContentState extends State<_ReviewTargetListContent> {
  List<_TargetItem> _targets = [];
  bool _isLoading = true;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _fetchTargets();
  }

  Future<void> _fetchTargets() async {
    try {
      String? token = await TokenStorage.readAccessToken();
      if (token == null || token.isEmpty) {
        token = await TokenStorage.readFirebaseIdToken();
      }

      final dioClient = dio.Dio();
      final response = await dioClient.get(
        '${Env.apiBaseUrl}employer/posts/${widget.postId}/review-targets',
        options: dio.Options(
          headers: {if (token != null) 'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        setState(() {
          _targets = data
              .map(
                (e) => _TargetItem(
                  targetUserId: (e['targetUserId'] as num).toInt(),
                  name: e['name']?.toString() ?? 'Unknown',
                  profileImagePath: e['profileImage'] != null
                      ? resolveImageUrl(e['profileImage'].toString())
                      : 'assets/image/test_profile1.png',
                  rating: 5,
                  // 🌟 Jackson의 자동 네이밍 변환(isReviewed -> reviewed) 이슈 완벽 방어
                  isReviewed: e['isReviewed'] == true || e['reviewed'] == true,
                ),
              )
              // 🌟 [핵심 변경] 이미 리뷰를 완수한 사람은 목록에 안 뜨도록 원천 차단!
              .where((target) => !target.isReviewed)
              .toList();
          _isLoading = false;
          _selectedIndex = null; // 인덱스 초기화
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('리뷰 대상자 목록 로드 에러: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.75;
    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const AutoTranslateText(
              'Select Member to Review',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Divider(height: 1, thickness: 1, color: Colors.grey[300]),
            Flexible(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.mainColor,
                      ),
                    )
                  : _targets.isEmpty
                  ? const Center(
                      child: Text(
                        'No members available.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      itemCount: _targets.length,
                      itemBuilder: (context, index) {
                        final target = _targets[index];
                        final isSelected = _selectedIndex == index;
                        return _buildTargetTile(index, target, isSelected);
                      },
                    ),
            ),
            Divider(height: 1, thickness: 1, color: const Color(0xFFD9D9D9)),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 358,
                height: 51,
                child: ElevatedButton(
                  onPressed: () {
                    if (_selectedIndex == null || _targets.isEmpty) return;

                    final target = _targets[_selectedIndex!];
                    if (target.isReviewed) return;

                    Navigator.pop(context, <String, dynamic>{
                      'targetUserId': target.targetUserId,
                      'name': target.name,
                      'profileImagePath': target.profileImagePath,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFC6340),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(90),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Review',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetTile(int index, _TargetItem target, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => showTargetProfileModal(context, target),
              borderRadius: BorderRadius.circular(12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: target.profileImagePath.startsWith('http')
                        ? NetworkImage(target.profileImagePath) as ImageProvider
                        : AssetImage(target.profileImagePath),
                    onBackgroundImageError: (_, __) {},
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AutoTranslateText(
                          target.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: List.generate(5, (i) {
                            final filled = i < target.rating;
                            return Padding(
                              padding: const EdgeInsets.only(right: 2),
                              child: SvgPicture.asset(
                                filled
                                    ? 'assets/icon/score_filled_icon.svg'
                                    : 'assets/icon/score_not_icon.svg',
                                width: 16,
                                height: 16,
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (target.isReviewed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Reviewed',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            GestureDetector(
              onTap: () => setState(() => _selectedIndex = index),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFFC6340)
                        : Colors.grey[400]!,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        size: 16,
                        color: Color(0xFFFC6340),
                      )
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}
