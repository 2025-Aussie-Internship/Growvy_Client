import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../styles/colors.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/auto_translate_text.dart';
import '../../widgets/confirm_modal.dart';
import '../SignUpPage/signup_page.dart';
import 'review_page.dart';
import 'profile_edit_page.dart';

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

  int _currentProfileIndex = 0;
  ImageProvider get _currentProfileImage =>
      _profileImages[_currentProfileIndex];
  String _userName = 'User Name';
  String _editPronouns = 'She/Her';
  bool _isEditingProfile = false;
  bool _isViewingReviews = false;
  late final TextEditingController _nameController;

  final List<ImageProvider> _profileImages = [
    const AssetImage('assets/image/test_profile1.png'),
    const AssetImage('assets/image/test_profile2.png'),
    const AssetImage('assets/image/test_profile3.png'),
    const AssetImage('assets/image/test_profile4.png'),
    const AssetImage('assets/image/test_profile5.png'),
    const AssetImage('assets/image/test_profile6.png'),
    const AssetImage('assets/image/test_profile7.png'),
    const AssetImage('assets/image/test_profile8.png'),
    const AssetImage('assets/image/test_profile9.png'),
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _userName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _openProfileEdit() {
    setState(() => _isEditingProfile = true);
  }

  void _applyProfileEdit(Map<String, dynamic> result) {
    setState(() {
      _currentProfileIndex =
          result['profileIndex'] as int? ?? _currentProfileIndex;
      if (result['userName'] != null) _userName = result['userName'] as String;
      if (result['pronouns'] != null) _editPronouns = result['pronouns'] as String;
      _isEditingProfile = false;
    });
    _nameController.text = _userName;
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
            ProfileEditContent(
              profileImages: _profileImages,
              initialProfileIndex: _currentProfileIndex,
              initialUserName: _userName,
              initialPronouns: _editPronouns,
              onApply: _applyProfileEdit,
              onClose: () => setState(() => _isEditingProfile = false),
            )
          else ...[
            const SizedBox(height: 24),
            // 시안: 큰 원형 프로필 사진(편집 아이콘 없음 - 누르면 편집 화면 진입)
            GestureDetector(
              onTap: _openProfileEdit,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: _currentProfileImage,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            AutoTranslateText(
              _userName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            // 구직자: She/Her 같은 성별 표시.
            // 구인자: 업종(Hospitality 등) 표시. 임시로 'Hospitality' 고정.
            Obx(() {
              final isEmployer = AuthController.to.isEmployer.value;
              final subtitle = isEmployer ? 'Hospitality' : _editPronouns;
              return AutoTranslateText(
                subtitle,
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              );
            }),
            const SizedBox(height: 14),
            _buildEditProfilePillButton(),
            const SizedBox(height: 24),
            const _SectionDivider(),
            const SizedBox(height: 20),
            _buildRatingCard(),
            const SizedBox(height: 20),
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
            const SizedBox(height: 28),
            const _SectionDivider(),
            const SizedBox(height: 20),
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

  /// 시안의 주황 outline pill 모양 "Edit Profile" 버튼.
  Widget _buildEditProfilePillButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openProfileEdit,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.mainColor, width: 1.4),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/icon/profile_edit_icon.svg',
                width: 14,
                height: 14,
                colorFilter: const ColorFilter.mode(
                  AppColors.mainColor,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 6),
              const AutoTranslateText(
                'Edit Profile',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainColor,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
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
    await Get.find<AuthController>().clearUserType();
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
