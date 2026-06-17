import 'package:get/get.dart';

import '../models/user_profile.dart';
import '../services/user_profile_cache.dart';
import 'auth_controller.dart';
import 'signup_data_controller.dart';

/// 로그인된 사용자의 프로필을 앱 전역에서 단일 source-of-truth 로 보관.
///
/// 화면들은 `Obx(() => Text(UserProfileController.to.profile.value.displayLabel))`
/// 처럼 reactive 하게 구독한다.
///
/// 데이터 라이프사이클:
///   1) 회원가입 완료 직후 → [hydrateFromSignup] 으로 SignupDataController 값 이관
///   2) 앱 시작 시(이미 로그인된 상태) → [loadFromCache] 로 디스크 캐시 복원
///   3) 백엔드 붙으면 → [refreshFromServer] 로 `GET /api/users/me` 호출하여 동기화
///   4) 프로필 편집 → [applyEdit] 로 in-memory 갱신 (서버 PATCH 는 별도 단계)
///   5) 로그아웃 → [clear] 로 메모리 + 디스크 캐시 비움
class UserProfileController extends GetxController {
  static UserProfileController get to => Get.find<UserProfileController>();

  final Rxn<UserProfile> profile = Rxn<UserProfile>();

  /// 가입 흐름에서 누적해 둔 값을 한 번에 옮긴다.
  /// SignupCompletePage 가 백엔드 submit 직후 호출.
  void hydrateFromSignup(SignupDataController s) {
    final idx = (s.profileImageId ?? 1) - 1;
    final asset =
        s.profileImageAsset ??
        'assets/image/test_profile${idx.clamp(0, 8) + 1}.png';
    profile.value = UserProfile(
      email: s.googleEmail,
      displayName: s.googleDisplayName,
      name: s.name,
      gender: _normalizeGender(s.gender),
      phoneNumber: s.phoneNumber,
      birthDate: _formatBirthDate(s.dateOfBirth),
      isEmployer: s.isEmployer == true,
      profileImageId: s.profileImageId,
      profileImageAsset: asset,
      companyName: s.companyName,
      businessAddress: s.businessAddress,
      homeAddress: s.homeAddress,
      career: s.career,
      introduction: s.introduction,
      // 가입 단계에서 모은 백엔드 interest id 들을 그대로 in-memory 프로필로.
      interestIds: List<int>.unmodifiable(
        (s.interestIds.toSet().toList()..sort()),
      ),
    );
    UserProfileCache.save(profile.value!);
  }

  /// 구직자 프로필 갱신 흐름 완료 시: 기존 프로필 + 새 관심사·경력·소개·프사 병합.
  void hydrateFromProfileUpdate(SignupDataController s) {
    final base = s.profileUpdateBaseline ?? profile.value ?? const UserProfile();
    final imageId = s.profileImageId ?? base.profileImageId;
    final idx = (imageId ?? 1) - 1;
    final asset =
        s.profileImageAsset ??
        base.profileImageAsset ??
        'assets/image/test_profile${idx.clamp(0, 8) + 1}.png';
    final ids = s.interestIds.isNotEmpty
        ? (s.interestIds.toSet().toList()..sort())
        : base.interestIds;
    final pickedNewImage = s.profileImageId != null;
    profile.value = UserProfile(
      id: base.id,
      email: s.googleEmail ?? base.email,
      displayName: s.googleDisplayName ?? base.displayName,
      name: base.name,
      gender: base.gender,
      pronouns: base.pronouns,
      phoneNumber: base.phoneNumber,
      birthDate: base.birthDate,
      isEmployer: false,
      profileImageId: imageId,
      profileImageAsset: asset,
      profileImageUrl: pickedNewImage ? null : base.profileImageUrl,
      bannerImageId: base.bannerImageId,
      companyName: base.companyName,
      businessAddress: base.businessAddress,
      homeAddress: base.homeAddress,
      career: s.career ?? base.career,
      introduction: s.introduction ?? base.introduction,
      interestIds: List<int>.unmodifiable(ids),
    );
    UserProfileCache.save(profile.value!);
  }

  /// 서버 응답과 로컬(방금 갱신한) 값을 병합. 갱신 직후 필드는 로컬 우선.
  Future<void> refreshFromServerMergingLocal(
    Future<Map<String, dynamic>> Function() fetcher,
  ) async {
    final local = profile.value;
    final json = await fetcher();
    if (json.isEmpty) return;
    final fresh = UserProfile.fromJson(json);
    if (local == null) {
      profile.value = fresh;
    } else {
      final useLocalImage = local.profileImageAsset != null &&
          local.profileImageAsset!.isNotEmpty;
      profile.value = UserProfile(
        id: fresh.id ?? local.id,
        email: fresh.email ?? local.email,
        displayName: fresh.displayName ?? local.displayName,
        name: fresh.name ?? local.name,
        gender: fresh.gender ?? local.gender,
        pronouns: fresh.pronouns,
        phoneNumber: fresh.phoneNumber ?? local.phoneNumber,
        birthDate: fresh.birthDate ?? local.birthDate,
        isEmployer: fresh.isEmployer,
        profileImageId: local.profileImageId ?? fresh.profileImageId,
        profileImageAsset: local.profileImageAsset ?? fresh.profileImageAsset,
        profileImageUrl: useLocalImage ? null : (fresh.profileImageUrl ?? local.profileImageUrl),
        bannerImageId: fresh.bannerImageId ?? local.bannerImageId,
        companyName: fresh.companyName ?? local.companyName,
        businessAddress: fresh.businessAddress ?? local.businessAddress,
        homeAddress: fresh.homeAddress ?? local.homeAddress,
        career: local.career ?? fresh.career,
        introduction: local.introduction ?? fresh.introduction,
        interestIds: local.interestIds.isNotEmpty
            ? local.interestIds
            : fresh.interestIds,
      );
    }
    UserProfileCache.save(profile.value!);
  }

  /// 디스크 캐시에서 프로필 복원. AuthController 의 isEmployer 와도 sync.
  Future<void> loadFromCache() async {
    final cached = await UserProfileCache.load();
    if (cached != null) {
      profile.value = cached;
      if (Get.isRegistered<AuthController>()) {
        AuthController.to.isEmployer.value = cached.isEmployer;
      }
    }
  }

  /// 백엔드 동기화 (API 연동 후 호출). 현재는 placeholder.
  /// [fetcher] 는 `Map<String, dynamic>` 을 반환하는 함수.
  Future<void> refreshFromServer(
    Future<Map<String, dynamic>> Function() fetcher,
  ) async {
    final json = await fetcher();
    final fresh = UserProfile.fromJson(json);
    profile.value = fresh;
    UserProfileCache.save(fresh);
  }

  /// 프로필 편집 적용. UI 가 즉시 갱신되고, 디스크 캐시도 갱신된다.
  /// 백엔드 PATCH 는 호출자가 별도로 수행.
  void applyEdit({
    int? profileImageId,
    String? profileImageAsset,
    String? name,
    String? pronouns,
    String? phoneNumber,
    String? homeAddress,
    String? career,
    String? introduction,
    String? companyName,
    String? businessAddress,
    List<int>? interestIds,
  }) {
    final current = profile.value ?? const UserProfile();
    profile.value = current.copyWith(
      profileImageId: profileImageId,
      profileImageAsset: profileImageAsset,
      name: name,
      pronouns: pronouns,
      phoneNumber: phoneNumber,
      homeAddress: homeAddress,
      career: career,
      introduction: introduction,
      companyName: companyName,
      businessAddress: businessAddress,
      interestIds: interestIds,
    );
    UserProfileCache.save(profile.value!);
  }

  /// 로그아웃 시 호출.
  Future<void> clear() async {
    profile.value = null;
    await UserProfileCache.clear();
  }

  String? _normalizeGender(String? g) {
    if (g == null || g.isEmpty) return null;
    return g.toUpperCase();
  }

  String? _formatBirthDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return raw.replaceAll('/', '-');
  }
}
