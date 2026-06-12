import 'package:flutter/widgets.dart';

/// 로그인된 사용자의 프로필 정보를 표현하는 immutable 모델.
///
/// 회원가입 직후엔 [SignupDataController] 의 값으로 채워지고,
/// 백엔드 연동 후엔 `GET /api/users/me` 같은 API 응답으로 채워지게 된다.
///
/// asset 기반 프로필 이미지를 쓰는 현재 단계에서는 [profileImageId] 가
/// 1-based 정수(1~9) 이고, [profileImageAsset] 이 그 id 에 대응하는
/// `assets/image/test_profileN.png` 경로다.
/// 백엔드에서 URL 을 받게 되면 [profileImageUrl] 만 채워지고
/// [profileImageAsset] 은 비어 있게 된다.
class UserProfile {
  const UserProfile({
    this.id,
    this.email,
    this.displayName,
    this.name,
    this.gender,
    this.pronouns = 'She/Her',
    this.phoneNumber,
    this.birthDate,
    this.isEmployer = false,
    this.profileImageId,
    this.profileImageAsset,
    this.profileImageUrl,
    this.bannerImageId,
    // employer 전용
    this.companyName,
    this.businessAddress,
    // seeker 전용
    this.homeAddress,
    this.career,
    this.introduction,
    this.interestIds = const <int>[],
  });

  /// 백엔드 PK (서버 응답에서 채워짐). 회원가입 직후엔 아직 null 일 수 있다.
  final int? id;
  final String? email;
  final String? displayName;
  final String? name;
  final String? gender; // 'MALE' | 'FEMALE'
  final String pronouns;
  final String? phoneNumber;
  final String? birthDate; // 'YYYY-MM-DD'
  final bool isEmployer;

  final int? profileImageId;
  final String? profileImageAsset;
  final String? profileImageUrl;
  final int? bannerImageId;

  final String? companyName;
  final String? businessAddress;

  final String? homeAddress;
  final String? career;
  final String? introduction;
  final List<int> interestIds;

  /// MyPage / ProfileEdit 에서 사용할 수 있는 ImageProvider.
  /// URL > asset > 기본 placeholder 순으로 선택한다.
  ImageProvider get profileImageProvider {
    if (profileImageUrl != null && profileImageUrl!.isNotEmpty) {
      return NetworkImage(profileImageUrl!);
    }
    if (profileImageAsset != null && profileImageAsset!.isNotEmpty) {
      return AssetImage(profileImageAsset!);
    }
    return const AssetImage('assets/image/test_profile1.png');
  }

  /// 표시용 이름. 백엔드 name 우선, 없으면 Google displayName, 그것도 없으면
  /// 이메일 앞 부분.
  String get displayLabel {
    if (name != null && name!.isNotEmpty) return name!;
    if (displayName != null && displayName!.isNotEmpty) return displayName!;
    if (email != null && email!.isNotEmpty) return email!.split('@').first;
    return 'User Name';
  }

  UserProfile copyWith({
    int? id,
    String? email,
    String? displayName,
    String? name,
    String? gender,
    String? pronouns,
    String? phoneNumber,
    String? birthDate,
    bool? isEmployer,
    int? profileImageId,
    String? profileImageAsset,
    String? profileImageUrl,
    int? bannerImageId,
    String? companyName,
    String? businessAddress,
    String? homeAddress,
    String? career,
    String? introduction,
    List<int>? interestIds,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      pronouns: pronouns ?? this.pronouns,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      birthDate: birthDate ?? this.birthDate,
      isEmployer: isEmployer ?? this.isEmployer,
      profileImageId: profileImageId ?? this.profileImageId,
      profileImageAsset: profileImageAsset ?? this.profileImageAsset,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      bannerImageId: bannerImageId ?? this.bannerImageId,
      companyName: companyName ?? this.companyName,
      businessAddress: businessAddress ?? this.businessAddress,
      homeAddress: homeAddress ?? this.homeAddress,
      career: career ?? this.career,
      introduction: introduction ?? this.introduction,
      interestIds: interestIds ?? this.interestIds,
    );
  }

  /// 백엔드 응답(JSON) → 모델.
  /// 응답 스펙이 확정되기 전이므로 잘 알려진 키들만 best-effort 로 매핑.
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int?,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      name: json['name'] as String?,
      gender: json['gender'] as String?,
      pronouns: (json['pronouns'] as String?) ?? 'She/Her',
      phoneNumber: json['phone'] as String?,
      birthDate: json['birthDate'] as String?,
      isEmployer: (json['userType'] as String?) == 'EMPLOYER' ||
          (json['isEmployer'] as bool? ?? false),
      profileImageId: json['profileImageId'] as int?,
      profileImageUrl: json['profileImageUrl'] as String?,
      bannerImageId: json['bannerImageId'] as int?,
      companyName: json['companyName'] as String?,
      businessAddress: json['businessAddress'] as String?,
      homeAddress: json['homeAddress'] as String?,
      career: json['career'] as String?,
      introduction: json['bio'] as String?,
      interestIds: (json['interestIds'] as List?)
              ?.whereType<int>()
              .toList(growable: false) ??
          const <int>[],
    );
  }

  /// 모델 → JSON (서버 업데이트 PATCH 용).
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (name != null) 'name': name,
      if (gender != null) 'gender': gender,
      if (pronouns.isNotEmpty) 'pronouns': pronouns,
      if (phoneNumber != null) 'phone': phoneNumber,
      if (birthDate != null) 'birthDate': birthDate,
      if (profileImageId != null) 'profileImageId': profileImageId,
      if (bannerImageId != null) 'bannerImageId': bannerImageId,
      if (companyName != null) 'companyName': companyName,
      if (businessAddress != null) 'businessAddress': businessAddress,
      if (homeAddress != null) 'homeAddress': homeAddress,
      if (career != null) 'career': career,
      if (introduction != null) 'bio': introduction,
      'interestIds': interestIds,
    };
  }
}
