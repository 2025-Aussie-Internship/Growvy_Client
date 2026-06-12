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
    final asset = s.profileImageAsset ??
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
      bannerImageId: s.bannerImageId,
      companyName: s.companyName,
      businessAddress: s.businessAddress,
      homeAddress: s.homeAddress,
      career: s.career,
      introduction: s.introduction,
    );
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
