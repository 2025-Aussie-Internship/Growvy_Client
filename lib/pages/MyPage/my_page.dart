import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/user_profile_controller.dart';
import '../../services/auth_repository.dart';
import '../../widgets/auto_translate_text.dart';
import '../../widgets/confirm_modal.dart';
import '../SignUpPage/signup_page.dart';
import 'profile_edit_page.dart';
import 'review_page.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => MyPageState();
}

class MyPageState extends State<MyPage> {
  /// 외부(예: 하단 nav바의 Profile 재선택)에서 리뷰 화면을 닫고
  /// 기본 프로필 화면으로 되돌아갈 때 호출한다.
  void closeReviews() {
    if (!mounted) return;
    if (_isViewingReviews) {
      setState(() => _isViewingReviews = false);
    }
  }

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

  /// 현재 사용자 프로필의 사진 index (1-based id - 1).
  /// 컨트롤러에 없으면 0.
  int get _currentProfileIndex {
    final id = UserProfileController.to.profile.value?.profileImageId;
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
    // 프로필 컨트롤러에 변경 사항 반영 → MyPage 전체가 Obx 로 자동 갱신.
    UserProfileController.to.applyEdit(
      profileImageId: newIndex + 1,
      profileImageAsset: 'assets/image/test_profile${newIndex + 1}.png',
      name: newName,
      pronouns: newPronouns,
    );
    setState(() => _isEditingProfile = false);
    // TODO: 백엔드 연동 후 UserRepository.updateMe(profile.toJson()) 호출.
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
            ? const KeyedSubtree(
                key: ValueKey('reviews'),
                child: ReviewPage(),
              )
            : KeyedSubtree(
                key: const ValueKey('profile'),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
          if (_isEditingProfile)
            Obx(() {
              final p = UserProfileController.to.profile.value;
              return ProfileEditContent(
                profileImages: _profileImages,
                initialProfileIndex: _currentProfileIndex,
                initialUserName: p?.displayLabel ?? 'User Name',
                initialPronouns: p?.pronouns ?? 'She/Her',
                onApply: _applyProfileEdit,
                onClose: () => setState(() => _isEditingProfile = false),
              );
            })
          else ...[
            // 시안: 사진 → 이름 → 부제 → 별점카드 가 위쪽으로 모이도록 간격 축소.
            // Edit Profile 진입 pill 버튼은 제거하고, 사진을 누르면 곧바로
            // 편집 화면으로 진입한다.
            const SizedBox(height: 16),
            Obx(() {
              final image = UserProfileController.to.profile.value
                      ?.profileImageProvider ??
                  _profileImages[_currentProfileIndex];
              return GestureDetector(
                onTap: _openProfileEdit,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(image: image, fit: BoxFit.cover),
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
            Obx(() {
              final p = UserProfileController.to.profile.value;
              return AutoTranslateText(
                p?.displayLabel ?? 'User Name',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              );
            }),
            const SizedBox(height: 2),
            // 구직자: She/Her 같은 성별 표시.
            // 구인자: 업종(Hospitality 등) 표시. 임시로 'Hospitality' 고정.
            Obx(() {
              final isEmployer = AuthController.to.isEmployer.value;
              final pronouns =
                  UserProfileController.to.profile.value?.pronouns ?? 'She/Her';
              final subtitle = isEmployer ? 'Hospitality' : pronouns;
              return AutoTranslateText(
                subtitle,
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              );
            }),
            const SizedBox(height: 18),
            _buildRatingCard(),
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
            const SizedBox(height: 120), // Bottom padding for nav bar
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
            children: [
              star('assets/icon/score_filled_icon.svg'),
              const SizedBox(width: 6),
              star('assets/icon/score_filled_icon.svg'),
              const SizedBox(width: 6),
              star('assets/icon/score_filled_icon.svg'),
              const SizedBox(width: 6),
              star('assets/icon/score_filled_icon.svg'),
              const SizedBox(width: 6),
              star('assets/icon/score_not_icon.svg'),
            ],
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

  /// MyPage 의 큰 섹션 사이를 나누는 옅은 회색 가로 라인.
  /// (시안의 사진/별점/메뉴/로그아웃을 구분하는 얇은 회색 선)
  /// — 외부 위젯 클래스로 분리해 SafeArea 안에서 const 로 재사용한다.
  /// 아래 [_SectionDivider] 참고.

  /// Log Out 텍스트 탭 → 확인 모달 → 로그아웃 진행.
  Future<void> _onLogOutTap() async {
    final confirmed = await ConfirmModal.show<bool>(
      context: context,
      message: 'Do you really want\nto Log out?',
      onCancel: () => Navigator.pop(context, false),
      onAccept: () => Navigator.pop(context, true),
    );
    if (confirmed != true || !mounted) return;
    // 1) 로컬 사용자 타입 + 프로필 캐시 비우기.
    await Get.find<AuthController>().clearUserType();
    await UserProfileController.to.clear();
    // 2) Firebase signOut + secure storage 토큰 폐기.
    await AuthRepository.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const SignUpPage()),
      (route) => false,
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
