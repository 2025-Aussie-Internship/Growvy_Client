import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';

/// 로그인 사용자 프로필을 디스크에 (SharedPreferences) JSON 으로 캐싱.
///
/// 앱 재시작 시 [UserProfileController.loadFromCache] 가 호출해서
/// 네트워크 응답이 오기 전이라도 곧바로 UI 를 그릴 수 있게 한다.
///
/// 민감 정보(토큰 등) 는 여기에 저장하지 않는다 — 그건 SecureStorage 에 둔다.
class UserProfileCache {
  UserProfileCache._();

  static const String _key = 'cached_user_profile_v1';

  static Future<void> save(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode({
        'id': profile.id,
        'email': profile.email,
        'displayName': profile.displayName,
        'name': profile.name,
        'gender': profile.gender,
        'pronouns': profile.pronouns,
        'phone': profile.phoneNumber,
        'birthDate': profile.birthDate,
        'isEmployer': profile.isEmployer,
        'profileImageId': profile.profileImageId,
        'profileImageAsset': profile.profileImageAsset,
        'profileImageUrl': profile.profileImageUrl,
        'bannerImageId': profile.bannerImageId,
        'companyName': profile.companyName,
        'businessAddress': profile.businessAddress,
        'homeAddress': profile.homeAddress,
        'career': profile.career,
        'bio': profile.introduction,
        'interestIds': profile.interestIds,
      });
      await prefs.setString(_key, json);
    } catch (e) {
      debugPrint('[UserProfileCache] save error: $e');
    }
  }

  static Future<UserProfile?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return UserProfile(
        id: map['id'] as int?,
        email: map['email'] as String?,
        displayName: map['displayName'] as String?,
        name: map['name'] as String?,
        gender: map['gender'] as String?,
        pronouns: (map['pronouns'] as String?) ?? 'She/Her',
        phoneNumber: map['phone'] as String?,
        birthDate: map['birthDate'] as String?,
        isEmployer: (map['isEmployer'] as bool?) ?? false,
        profileImageId: map['profileImageId'] as int?,
        profileImageAsset: map['profileImageAsset'] as String?,
        profileImageUrl: map['profileImageUrl'] as String?,
        bannerImageId: map['bannerImageId'] as int?,
        companyName: map['companyName'] as String?,
        businessAddress: map['businessAddress'] as String?,
        homeAddress: map['homeAddress'] as String?,
        career: map['career'] as String?,
        introduction: map['bio'] as String?,
        interestIds: (map['interestIds'] as List?)
                ?.whereType<int>()
                .toList(growable: false) ??
            const <int>[],
      );
    } catch (e) {
      debugPrint('[UserProfileCache] load error: $e');
      return null;
    }
  }

  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (e) {
      debugPrint('[UserProfileCache] clear error: $e');
    }
  }
}
