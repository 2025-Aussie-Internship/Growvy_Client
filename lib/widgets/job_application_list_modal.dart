import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../styles/colors.dart';
import '../styles/modal_theme.dart';

/// 구인자용 Job Application List 모달. 아래에서 위로 슬라이드, 신청한 구직자 중 선택 후 Accept로 새 채팅방 생성.
/// Accept 시 선택한 지원자 정보를 반환. [name], [profileImagePath].
class JobApplicationListModal {
  static Future<Map<String, String>?> show(BuildContext context) async {
    return showModalBottomSheet<Map<String, String>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Theme(
        data: modalTheme(context),
        child: const _JobApplicationListContent(),
      ),
    );
  }
}

void showApplicantProfileModal(BuildContext context, _ApplicantItem applicant) {
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
            child: _ApplicantProfileSheetContent(applicant: applicant),
          ),
        ),
      ),
    ),
  );
}

class _ApplicantItem {
  final String name;
  final String profileImagePath;

  _ApplicantItem({
    required this.name,
    required this.profileImagePath,
  });
}

class _ApplicantProfileSheetContent extends StatefulWidget {
  const _ApplicantProfileSheetContent({required this.applicant});

  final _ApplicantItem applicant;

  @override
  State<_ApplicantProfileSheetContent> createState() =>
      _ApplicantProfileSheetContentState();
}

class _ApplicantProfileSheetContentState
    extends State<_ApplicantProfileSheetContent> {
  bool _expanded = false;

  static final List<Map<String, dynamic>> _dummyReviews = [
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

  static const double _modalHeight = 337;
  static const double _modalHeightExpanded = 664;
  static const double _profileSize = 80;
  static const double _profileOverlap = 40; // 절반이 배너와 겹침

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

  /// 확장 시 고정: 이름 + She/Her (배너·프로필은 헤더에 이미 포함)
  Widget _buildFixedNameBlock() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.applicant.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'She/Her',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  /// 오렌지 배너 + 우상단 X(다른 모달과 동일 스타일) + 프로필 원형이 배너와 반쯤 겹침(스트로크 없음)
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
                  image: AssetImage(widget.applicant.profileImagePath),
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
          Text(
            widget.applicant.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 2),
          Text(
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

  /// 마이페이지와 동일 스타일, 패딩/간격만 축소 (h 337 맞춤)
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
              SvgPicture.asset('assets/icon/score_filled_icon.svg', width: 28, height: 28),
              const SizedBox(width: 6),
              SvgPicture.asset('assets/icon/score_filled_icon.svg', width: 28, height: 28),
              const SizedBox(width: 6),
              SvgPicture.asset('assets/icon/score_filled_icon.svg', width: 28, height: 28),
              const SizedBox(width: 6),
              SvgPicture.asset('assets/icon/score_filled_icon.svg', width: 28, height: 28),
              const SizedBox(width: 6),
              SvgPicture.asset('assets/icon/score_not_icon.svg', width: 28, height: 28),
            ],
          ),
          const SizedBox(height: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _expanded = true),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Center(
                  child: Text(
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

  /// 리뷰 리스트만 스크롤 (배너·프로필·이름·성별은 위에서 고정)
  Widget _buildReviewListOnly(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._dummyReviews.map((r) => _buildReviewCard(r)),
          const SizedBox(height: 6),
          Center(
            child: GestureDetector(
              onTap: () {},
              child: const Text(
                'See More',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF931515),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> item) {
    final rating = item['rating'] as int;
    final title = item['title'] as String;
    final body = item['body'] as String;
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
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF931515),
                  ),
                ),
              ),
              _buildCardStarRating(rating),
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

class _JobApplicationListContent extends StatefulWidget {
  const _JobApplicationListContent();

  @override
  State<_JobApplicationListContent> createState() =>
      _JobApplicationListContentState();
}

class _JobApplicationListContentState extends State<_JobApplicationListContent> {
  static final List<_ApplicantItem> _dummyApplicants = [
    _ApplicantItem(name: 'User Name', profileImagePath: 'assets/image/test_profile1.png'),
    _ApplicantItem(name: 'User Name', profileImagePath: 'assets/image/test_profile2.png'),
    _ApplicantItem(name: 'User Name', profileImagePath: 'assets/image/test_profile3.png'),
    _ApplicantItem(name: 'User Name', profileImagePath: 'assets/image/test_profile4.png'),
    _ApplicantItem(name: 'User Name', profileImagePath: 'assets/image/test_profile5.png'),
    _ApplicantItem(name: 'User Name', profileImagePath: 'assets/image/test_profile6.png'),
  ];

  int? _selectedIndex;

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
            // 드래그 핸들
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Job Application List',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Divider(height: 1, thickness: 1, color: Colors.grey[300]),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                itemCount: _dummyApplicants.length,
                itemBuilder: (context, index) {
                  final applicant = _dummyApplicants[index];
                  final isSelected = _selectedIndex == index;
                  return _buildApplicantTile(index, applicant, isSelected);
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
                    if (_selectedIndex != null) {
                      final applicant = _dummyApplicants[_selectedIndex!];
                      Navigator.pop(context, {
                        'name': applicant.name,
                        'profileImagePath': applicant.profileImagePath,
                      });
                    }
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
                    'Accept',
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

  Widget _buildApplicantTile(int index, _ApplicantItem applicant, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => showApplicantProfileModal(context, applicant),
              borderRadius: BorderRadius.circular(12),
              child: Row(
                children: [
                  CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: AssetImage(applicant.profileImagePath),
                  onBackgroundImageError: (_, __) {},
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        applicant.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: List.generate(5, (i) {
                          final filled = i < 3;
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
          GestureDetector(
            onTap: () => setState(() => _selectedIndex = index),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
                border: Border.all(
                  color: isSelected ? const Color(0xFFFC6340) : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Color(0xFFFC6340))
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
