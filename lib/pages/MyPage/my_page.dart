import 'dart:convert'; // 🌟 API 연동용
import 'package:http/http.dart' as http; // 🌟 API 연동용
import '../../services/token_storage.dart'; // 🌟 API 연동용
import '../../services/auth_repository.dart';
import '../../utils/image_url.dart'; // 🌟 이미지 경로 변환용
import '../../config/env.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/signup_data_controller.dart';
import '../../controllers/user_profile_controller.dart';
import '../../models/user_profile.dart';
import '../../services/user_profile_cache.dart';
import '../../utils/interest_i18n.dart';
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
  bool _fetchMyInfoInFlight = false;

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
    _syncFromProfileController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncFromProfileController(rebuild: true);
      _fetchMyInfo();
    });
  }

  /// [UserProfileController] 에 갱신 직후 값이 있으면 로컬 상태에 반영한다.
  void _syncFromProfileController({bool rebuild = false}) {
    if (!Get.isRegistered<UserProfileController>()) return;
    final profile = UserProfileController.to.profile.value;
    if (profile == null) return;
    _userName = profile.displayLabel;
    if (profile.gender != null && profile.gender!.isNotEmpty) {
      _gender = profile.gender!;
    }
    if (profile.profileImageId != null) {
      _fetchedImageId = profile.profileImageId;
    }
    final useAsset = profile.profileImageAsset != null &&
        profile.profileImageAsset!.isNotEmpty;
    _profileImageUrl = useAsset ? null : profile.profileImageUrl;
    if (rebuild && mounted) setState(() {});
  }

  /// 프로필 탭 재진입·갱신 완료 후 외부에서 호출.
  void refreshMyInfo() {
    if (!mounted) return;
    _syncFromProfileController(rebuild: true);
    _fetchMyInfo();
  }

  // 🌟 내 기본 정보 조회 API 연동
  Future<void> _fetchMyInfo() async {
    if (_fetchMyInfoInFlight) return;
    _fetchMyInfoInFlight = true;
    try {
      final token = await TokenStorage.readAccessToken();

      final response = await http
          .get(
            Uri.parse('${Env.apiBaseUrl}auth/me'),
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        if (mounted) {
          _applyMeData(data);
        }
      } else {
        debugPrint('❌ 내 정보 불러오기 실패: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ 내 정보 네트워크 에러: $e');
    } finally {
      _fetchMyInfoInFlight = false;
    }
  }

  void _applyMeData(Map<String, dynamic> data) {
    final fromApi = UserProfile.fromJson(data);
    UserProfile merged = fromApi;
    if (Get.isRegistered<UserProfileController>()) {
      final local = UserProfileController.to.profile.value;
      if (local != null) {
        final useLocalImage = local.profileImageAsset != null &&
            local.profileImageAsset!.isNotEmpty;
        merged = UserProfile(
          id: fromApi.id ?? local.id,
          email: fromApi.email ?? local.email,
          displayName: fromApi.displayName ?? local.displayName,
          name: fromApi.name ?? local.name,
          gender: fromApi.gender ?? local.gender,
          pronouns: fromApi.pronouns,
          phoneNumber: fromApi.phoneNumber ?? local.phoneNumber,
          birthDate: fromApi.birthDate ?? local.birthDate,
          isEmployer: fromApi.isEmployer,
          profileImageId: local.profileImageId ?? fromApi.profileImageId,
          profileImageAsset: local.profileImageAsset ?? fromApi.profileImageAsset,
          profileImageUrl: useLocalImage
              ? null
              : (fromApi.profileImageUrl ?? local.profileImageUrl),
          bannerImageId: fromApi.bannerImageId ?? local.bannerImageId,
          companyName: fromApi.companyName ?? local.companyName,
          businessAddress: fromApi.businessAddress ?? local.businessAddress,
          homeAddress: fromApi.homeAddress ?? local.homeAddress,
          career: local.career ?? fromApi.career,
          introduction: local.introduction ?? fromApi.introduction,
          interestIds: local.interestIds.isNotEmpty
              ? local.interestIds
              : fromApi.interestIds,
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (!Get.isRegistered<UserProfileController>()) return;
          UserProfileController.to.profile.value = merged;
          UserProfileCache.save(merged);
        });
      }
    }

    setState(() {
      _userName = merged.displayLabel;
      _gender = merged.gender ?? data['gender']?.toString() ?? 'Not Specified';
      _averageRating = (data['averageRating'] as num?)?.toDouble() ?? 0.0;
      _fetchedImageId = merged.profileImageId ?? data['profileImageId'] as int?;
      final useAsset = merged.profileImageAsset != null &&
          merged.profileImageAsset!.isNotEmpty;
      _profileImageUrl = useAsset
          ? null
          : (merged.profileImageUrl ?? data['profileImageUrl'] as String?);
    });
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

  /// 프로필 탭에 표시할 이미지. 방금 고른 asset/id 를 API URL 보다 우선한다.
  ImageProvider get _displayProfileImage {
    if (Get.isRegistered<UserProfileController>()) {
      final profile = UserProfileController.to.profile.value;
      if (profile != null) {
        return _profileImageFromUserProfile(profile);
      }
    }
    if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      return NetworkImage(resolveImageUrl(_profileImageUrl!));
    }
    return _profileImages[_currentProfileIndex];
  }

  ImageProvider _profileImageFromUserProfile(UserProfile profile) {
    if (profile.profileImageAsset != null &&
        profile.profileImageAsset!.isNotEmpty) {
      return AssetImage(profile.profileImageAsset!);
    }
    if (profile.profileImageId != null && profile.profileImageId! > 0) {
      final index =
          (profile.profileImageId! - 1).clamp(0, _profileImages.length - 1);
      return _profileImages[index];
    }
    if (profile.profileImageUrl != null &&
        profile.profileImageUrl!.isNotEmpty) {
      return NetworkImage(resolveImageUrl(profile.profileImageUrl!));
    }
    return _profileImages[_currentProfileIndex];
  }

  void _openProfileEdit() {
    setState(() => _isEditingProfile = true);
  }

  Map<String, dynamic> _profileEditInitials() {
    UserProfile? profile;
    if (Get.isRegistered<UserProfileController>()) {
      profile = UserProfileController.to.profile.value;
    }
    final interestKeys = profile != null && profile.interestIds.isNotEmpty
        ? InterestI18n.keysFromIds(profile.interestIds)
        : <String>[];
    return {
      'career': profile?.career ?? '',
      'introduction': profile?.introduction ?? '',
      'homeAddress': profile?.homeAddress ?? '',
      'phone': profile?.phoneNumber ?? '',
      'interestKeys': interestKeys,
    };
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
                      if (_isEditingProfile) ...[
                        Builder(
                          builder: (context) {
                            final initials = _profileEditInitials();
                            return ProfileEditContent(
                              profileImages: _profileImages,
                              initialProfileIndex: _currentProfileIndex,
                              initialUserName: _userName,
                              initialPronouns: _gender,
                              initialCareer: initials['career'] as String,
                              initialIntroduction:
                                  initials['introduction'] as String,
                              initialHomeAddress:
                                  initials['homeAddress'] as String,
                              initialPhone: initials['phone'] as String,
                              initialInterestKeys: Set<String>.from(
                                initials['interestKeys'] as List<String>,
                              ),
                              onApply: _applyProfileEdit,
                              onClose: () =>
                                  setState(() => _isEditingProfile = false),
                            );
                          },
                        ),
                      ]
                      else ...[
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: _openProfileEdit,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: _displayProfileImage,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        AutoTranslateText(
                          _userName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 2),
                        AutoTranslateText(
                          _gender,
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

    final wasSeeker = !AuthController.to.isEmployer.value;

    UserProfile? baseline;
    if (Get.isRegistered<UserProfileController>()) {
      baseline = UserProfileController.to.profile.value;
    }

    await Get.find<AuthController>().clearUserType();
    if (Get.isRegistered<UserProfileController>()) {
      await UserProfileController.to.clear();
    }

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
        if (idToken != null && idToken.isNotEmpty) {
          await TokenStorage.saveFirebaseIdToken(idToken);
          await AuthRepository.exchangeFirebaseTokenForAccess(idToken);
        }
      } catch (_) {}
    }

    if (wasSeeker) {
      signupData.enableSeekerProfileUpdate();
      if (baseline != null) {
        signupData.applyProfileUpdateBaseline(baseline);
      }
    }

    if (!mounted) return;

    Get.offAll(
      () => LanguagePickerPage(
        isExistingUser: false,
        isSeekerProfileUpdate: wasSeeker,
      ),
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
