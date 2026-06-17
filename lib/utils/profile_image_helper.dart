import 'package:flutter/widgets.dart';

import '../models/user_profile.dart';
import 'image_url.dart';

const String kDefaultProfileAsset = 'assets/image/test_profile1.png';

const List<String> kProfileImageAssets = [
  'assets/image/test_profile1.png',
  'assets/image/test_profile2.png',
  'assets/image/test_profile3.png',
  'assets/image/test_profile4.png',
  'assets/image/test_profile5.png',
  'assets/image/test_profile6.png',
  'assets/image/test_profile7.png',
  'assets/image/test_profile8.png',
  'assets/image/test_profile9.png',
];

/// 가입 시 선택한 1-based profileImageId → asset 경로.
String assetFromProfileImageId(int? id) {
  if (id == null || id < 1) return kDefaultProfileAsset;
  final index = (id - 1).clamp(0, kProfileImageAssets.length - 1);
  return kProfileImageAssets[index];
}

/// API/캐시 맵에서 프로필 이미지 경로를 추출한다.
String? profileImagePathFromMap(Map<String, dynamic> raw) {
  final url = raw['profileImageUrl'] ??
      raw['partnerProfileImageUrl'] ??
      raw['profileImage'] ??
      raw['partnerProfileImage'] ??
      raw['partnerImage'] ??
      raw['imageUrl'];
  if (url != null && url.toString().trim().isNotEmpty) {
    final value = url.toString().trim();
    if (value.startsWith('assets/')) return value;
    return resolveImageUrl(value);
  }

  final id = raw['profileImageId'] ??
      raw['partnerProfileImageId'] ??
      raw['partnerImageId'];
  if (id is int) return assetFromProfileImageId(id);
  if (id is num) return assetFromProfileImageId(id.toInt());
  final parsed = int.tryParse(id?.toString() ?? '');
  if (parsed != null) return assetFromProfileImageId(parsed);

  return null;
}

String pathFromUserProfile(UserProfile profile) {
  if (profile.profileImageUrl != null &&
      profile.profileImageUrl!.trim().isNotEmpty) {
    return resolveImageUrl(profile.profileImageUrl!);
  }
  if (profile.profileImageAsset != null &&
      profile.profileImageAsset!.trim().isNotEmpty) {
    return profile.profileImageAsset!;
  }
  return assetFromProfileImageId(profile.profileImageId);
}

ImageProvider profileImageProvider(String? path) {
  final resolved = (path == null || path.isEmpty)
      ? kDefaultProfileAsset
      : path;
  if (resolved.startsWith('assets/')) {
    return AssetImage(resolved);
  }
  return NetworkImage(resolveImageUrl(resolved));
}
