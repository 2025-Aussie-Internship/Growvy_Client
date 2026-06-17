import 'dart:convert'; // 🌟 API 연동용
import 'package:http/http.dart' as http; // 🌟 API 연동용
import '../../services/token_storage.dart'; // 🌟 API 연동용
import '../../utils/image_url.dart'; // 🌟 이미지 경로 변환용
import '../../config/env.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/signup_data_controller.dart';
import '../../controllers/user_profile_controller.dart';
import '../../widgets/auto_translate_text.dart';
import '../../widgets/confirm_modal.dart';
import '../SignUpPage/language_picker_page.dart';
import 'profile_edit_page.dart';
import 'review_page.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => MyPageState();
}

class MyPageState extends State<MyPage> {
  // 🌟 API에서 받아올 내 정보 상태 변수
  String _userName = 'User Name';
  String _gender = '';
  double _averageRating = 0.0;
  int? _fetchedImageId;
  String? _profileImageUrl;

  bool _isEditingProfile = false;
  bool _isViewingReviews = false;

  /// 회원가입 시 선택 가능한 9종 프로필 사진. 인덱스는 1-based id - 1.
  /// ProfileEdit 모달에서 동일 목록을 carousel 로 보여준다.
  final List<ImageProvider> _profileImages = const [
    AssetImage('assets/image/test_profile1.png'),
    AssetImage('assets/image/test_profile2.png'),
    AssetImage('assets/image/test_profile3.png'),
    AssetImage('assets/image/test_profile4.png'),
    AssetImage('assets/image/test_profile5.png'),
    AssetImage('assets/image/test_profile6.png'),
    AssetImage('assets/image/test_profile7.png'),
    AssetImage('assets/image/test_profile8.png'),
    AssetImage('assets/image/test_profile9.png'),
  ];

  @override
  void initState() {
    super.initState();
    _fetchMyInfo(); // 🌟 초기화 시 API 호출
  }

  // 🌟 내 기본 정보 조회 API 연동
  Future<void> _fetchMyInfo() async {
    try {
      final token = await TokenStorage.readAccessToken();

      final response = await http.get(
        Uri.parse('${Env.apiBaseUrl}auth/me'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (mounted) {
          setState(() {
            _userName = data['name'] ?? 'User Name';
            // 성별 텍스트 변환 (MALE -> He/Him, FEMALE -> She/Her 등 필요시 수정 가능)
            _gender = data['gender'] ?? 'Not Specified';
            _averageRating = (data['averageRating'] as num?)?.toDouble() ?? 0.0;
            _fetchedImageId = data['profileImageId'];
            _profileImageUrl = data['profileImageUrl'];
          });
        }
      } else {
        debugPrint('❌ 내 정보 불러오기 실패: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ 내 정보 네트워크 에러: $e');
    }
  }

  /// 외부(예: 하단 nav바의 Profile 재선택)에서 리뷰 화면을 닫고
  /// 기본 프로필 화면으로 되돌아갈 때 호출한다.
  void closeReviews() {
    if (!mounted) return;
    if (_isViewingReviews) {
      setState(() => _isViewingReviews = false);
    }
  }

  /// 현재 사용자 프로필의 사진 index (1-based id - 1).
  int get _currentProfileIndex {
    final id = _fetchedImageId;
    if (id == null || id <= 0) return 0;
    return (id - 1).clamp(0, _profileImages.length - 1);
  }

  void _openProfileEdit() {
    setState(() => _isEditingProfile = true);
  }

  void _applyProfileEdit(Map<String, dynamic> result) {
    final newIndex = result['profileIndex'] as int? ?? _currentProfileIndex;
    final newName = result['userName'] as String?;
    final newPronouns = result['pronouns'] as String?;

    setState(() {
      _fetchedImageId = newIndex + 1;
      if (newName != null) _userName = newName;
      if (newPronouns != null) _gender = newPronouns;
      _isEditingProfile = false;
    });
    // TODO: 백엔드 연동 후 프로필 수정 API 호출 로직 추가.
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: true,
      bottom: false,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final offset = Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(animation);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: offset, child: child),
          );
        },
        child: _isViewingReviews
            ? const KeyedSubtree(key: ValueKey('reviews'), child: ReviewPage())
            : KeyedSubtree(
                key: const ValueKey('profile'),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      if (_isEditingProfile)
                        ProfileEditContent(
                          profileImages: _profileImages,
                          initialProfileIndex: _currentProfileIndex,
                          initialUserName: _userName,
                          initialPronouns: _gender,
                          onApply: _applyProfileEdit,
                          onClose: () =>
                              setState(() => _isEditingProfile = false),
                        )
                      else ...[
                        const SizedBox(height: 16),
                        // 🌟 API 데이터로 렌더링 (분기 제거됨)
                        GestureDetector(
                          onTap: _openProfileEdit,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image:
                                    _profileImageUrl != null &&
                                        _profileImageUrl!.isNotEmpty
                                    ? NetworkImage(
                                            resolveImageUrl(_profileImageUrl!),
                                          )
                                          as ImageProvider
                                    : _profileImages[_currentProfileIndex],
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        AutoTranslateText(
                          _userName, // 🌟 API 이름 적용
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 2),
                        AutoTranslateText(
                          _gender, // 🌟 API 성별 적용 (분기 제거)
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 18),
                        _buildRatingCard(), // 🌟 별점 렌더링 함수에 API 평점 반영
                        const SizedBox(height: 16),
                        // 메뉴 항목: 구인자/구직자에 따라 다르게 노출.
                        Obx(() {
                          final isEmployer = AuthController.to.isEmployer.value;
                          final items = isEmployer
                              ? const [
                                  'My Job Posts',
                                  'Applicants',
                                  'Interviews',
                                  'Billing',
                                  'Support',
                                ]
                              : const [
                                  'Customer Service Center',
                                  'Notice',
                                  'Settings',
                                  'Account Deletion',
                                ];
                          return _buildMenuCard(items);
                        }),
                        const SizedBox(height: 20),
                        const _SectionDivider(),
                        const SizedBox(height: 14),
                        GestureDetector(
                          onTap: _onLogOutTap,
                          child: AutoTranslateText(
                            'Log Out',
                            style: TextStyle(
                              decoration: TextDecoration.underline,
                              color: Colors.grey[400],
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 120,
                        ), // Bottom padding for nav bar
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildRatingCard() {
    Widget star(String asset) => SvgPicture.asset(asset, width: 28, height: 28);
    // 🌟 API로 받아온 평점(_averageRating)을 반올림하여 별 렌더링
    final int filledStars = _averageRating.round().clamp(0, 5);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5), // 시안과 유사한 연한 회색
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final isFilled = index < filledStars;
              return Padding(
                padding: EdgeInsets.only(right: index < 4 ? 6 : 0),
                child: star(
                  isFilled
                      ? 'assets/icon/score_filled_icon.svg'
                      : 'assets/icon/score_not_icon.svg',
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _isViewingReviews = true),
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Center(
                  child: AutoTranslateText(
                    'Check reviews',
                    style: TextStyle(
                      color: Colors.black87,
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

  /// 시안의 한 묶음 카드 형태 메뉴 (둥근 모서리 + 내부 divider).
  Widget _buildMenuCard(List<String> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _buildMenuOption(items[i]),
            if (i != items.length - 1) _buildDivider(),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuOption(String title) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      visualDensity: const VisualDensity(vertical: -1),
      title: AutoTranslateText(
        title,
        style: const TextStyle(
          fontSize: 15,
          color: Colors.black,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 16,
        color: Colors.grey[400],
      ),
      onTap: () {
        // Navigate logic
      },
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFFF2F4F7),
      indent: 16,
      endIndent: 16,
    );
  }

  Future<void> _onLogOutTap() async {
    final confirmed = await ConfirmModal.show<bool>(
      context: context,
      message: 'Do you really want\nto Log out?',
      onCancel: () => Navigator.pop(context, false),
      onAccept: () => Navigator.pop(context, true),
    );
    if (confirmed != true || !mounted) return;

    await Get.find<AuthController>().clearUserType();
    await UserProfileController.to.clear();

    final signupData = Get.find<SignupDataController>();
    signupData.reset();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final idToken = await user.getIdToken();
        signupData.setGoogleAuth(
          email: user.email,
          displayName: user.displayName,
          uid: user.uid,
          idToken: idToken,
        );
      } catch (_) {}
    }
    if (!mounted) return;

    Get.offAll(
      () => const LanguagePickerPage(isExistingUser: false),
      transition: Transition.fadeIn,
      duration: const Duration(milliseconds: 320),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      color: const Color(0xFFEFEFEF),
    );
  }
}
