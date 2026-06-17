import '../i18n/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../styles/colors.dart';
import '../styles/modal_theme.dart';
import 'auto_translate_text.dart';
import '../../utils/image_url.dart'; // 상단에 추가

// 🌟 API 연동을 위해 추가된 패키지
import 'package:dio/dio.dart' as dio;
import '../services/token_storage.dart';

/// 구인자용 Job Application List 모달. 아래에서 위로 슬라이드, 신청한 구직자 중 선택 후 Accept로 새 채팅방 생성.
/// Accept 시 선택한 지원자 정보를 반환. [name], [profileImagePath].
class JobApplicationListModal {
  static Future<Map<String, String>?> show(
    BuildContext context, {
    required int postId, // 🌟 더미 개수 대신 실제 공고 ID(postId)를 받습니다.
  }) async {
    return showModalBottomSheet<Map<String, String>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Theme(
        data: modalTheme(context),
        child: _JobApplicationListContent(postId: postId),
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
  final int applicationId; // ← 추가
  final String name;
  final String profileImagePath;
  final int rating;

  _ApplicantItem({
    required this.applicationId, // ← 추가
    required this.name,
    required this.profileImagePath,
    this.rating = 5,
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
    {
      'title': 'Promotional Staff',
      'rating': 4,
      'body':
          'Fun atmosphere and the brand team was nice. Long standing hours but they provided snacks and water. Would do again.',
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

  /// 확장 시 고정: 이름 + She/Her (배너·프로필은 헤더에 이미 포함)
  Widget _buildFixedNameBlock() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AutoTranslateText(
            widget.applicant.name,
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
                // 🌟 API에서 받아온 이미지 URL 처리 (URL이면 NetworkImage, 아니면 로컬 AssetImage)
                image: DecorationImage(
                  image: widget.applicant.profileImagePath.startsWith('http')
                      ? NetworkImage(widget.applicant.profileImagePath)
                            as ImageProvider
                      : AssetImage(widget.applicant.profileImagePath),
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
            widget.applicant.name,
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
              SvgPicture.asset(
                'assets/icon/score_filled_icon.svg',
                width: 28,
                height: 28,
              ),
              const SizedBox(width: 6),
              SvgPicture.asset(
                'assets/icon/score_filled_icon.svg',
                width: 28,
                height: 28,
              ),
              const SizedBox(width: 6),
              SvgPicture.asset(
                'assets/icon/score_filled_icon.svg',
                width: 28,
                height: 28,
              ),
              const SizedBox(width: 6),
              SvgPicture.asset(
                'assets/icon/score_filled_icon.svg',
                width: 28,
                height: 28,
              ),
              const SizedBox(width: 6),
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
            child: GestureDetector(
              onTap: () {},
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
                child: AutoTranslateText(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF931515),
                  ),
                ),
              ),
              _buildCardStarRating(rating),
            ],
          ),
          const SizedBox(height: 5),
          AutoTranslateText(
            body,
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

class _JobApplicationListContent extends StatefulWidget {
  const _JobApplicationListContent({
    required this.postId,
  }); // 🌟 더미 개수 대신 postId로 변경

  final int postId;

  @override
  State<_JobApplicationListContent> createState() =>
      _JobApplicationListContentState();
}

class _JobApplicationListContentState
    extends State<_JobApplicationListContent> {
  // 🌟 API 연동을 위한 상태 변수 추가
  List<_ApplicantItem> _applicants = [];
  bool _isLoading = true;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _fetchApplicants(); // 🌟 초기화 시 API 호출
  }

  // 🌟 백엔드 서버에서 지원자 목록을 가져오는 함수
  Future<void> _fetchApplicants() async {
    try {
      String? token = await TokenStorage.readAccessToken();
      debugPrint('🔑 토큰: $token');
      if (token == null || token.isEmpty) {
        token = await TokenStorage.readFirebaseIdToken();
      }

      final dioClient = dio.Dio();
      final response = await dioClient.get(
        'https://growvy.mirim-it-show.site/api/employer/posts/${widget.postId}/applicants',
        options: dio.Options(
          headers: {if (token != null) 'Authorization': 'Bearer $token'},
        ),
      );

      debugPrint('📡 상태코드: ${response.statusCode}');
      debugPrint('📡 응답 데이터: ${response.data}');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        setState(() {
          _applicants = data
              .map(
                (e) => _ApplicantItem(
                  applicationId: (e['applicationId'] as num).toInt(), // ← 추가
                  name: e['name']?.toString() ?? 'Unknown',
                  profileImagePath: e['profileImage'] != null
                      ? resolveImageUrl(e['profileImage'].toString())
                      : 'assets/image/test_profile1.png',
                  rating: (e['averageRating'] ?? 5).toInt(),
                ),
              )
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('지원자 목록 로드 에러: $e');
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
            const AutoTranslateText(
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
              // 🌟 API 호출 중일 때는 로딩 표시, 데이터가 없을 때는 텍스트 표시
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.mainColor,
                      ),
                    )
                  : _applicants.isEmpty
                  ? const Center(
                      child: Text(
                        'No applicants yet.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      itemCount: _applicants.length,
                      itemBuilder: (context, index) {
                        final applicant = _applicants[index];
                        final isSelected = _selectedIndex == index;
                        return _buildApplicantTile(
                          index,
                          applicant,
                          isSelected,
                        );
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
                  onPressed: () async {
                    if (_selectedIndex == null || _applicants.isEmpty) return;

                    final applicant = _applicants[_selectedIndex!];

                    try {
                      String? token = await TokenStorage.readAccessToken();
                      final dioClient = dio.Dio();
                      final response = await dioClient.post(
                        'https://growvy.mirim-it-show.site/api/employer/posts/${widget.postId}/select',
                        data: {
                          'applicationIds': [applicant.applicationId],
                        }, // ← 객체로 감싸기
                        options: dio.Options(
                          headers: {
                            if (token != null) 'Authorization': 'Bearer $token',
                            'Content-Type': 'application/json',
                          },
                        ),
                      );

                      if (response.statusCode == 200) {
                        if (context.mounted) {
                          Navigator.pop(context, {
                            'name': applicant.name,
                            'profileImagePath': applicant.profileImagePath,
                          });
                        }
                      } else {
                        debugPrint('❌ select 실패: ${response.statusCode}');
                      }
                    } catch (e) {
                      debugPrint('❌ select 에러: $e');
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
                  child: Text(
                    'common.accept'.tr(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicantTile(
    int index,
    _ApplicantItem applicant,
    bool isSelected,
  ) {
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
                    // 🌟 URL인 경우 NetworkImage 사용
                    backgroundImage:
                        applicant.profileImagePath.startsWith('http')
                        ? NetworkImage(applicant.profileImagePath)
                              as ImageProvider
                        : AssetImage(applicant.profileImagePath),
                    onBackgroundImageError: (_, __) {},
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AutoTranslateText(
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
                            final filled = i < applicant.rating;
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
                  color: isSelected
                      ? const Color(0xFFFC6340)
                      : Colors.grey[400]!,
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
