import 'dart:async';

import 'package:flutter/foundation.dart';

import 'api_client.dart';

/// 구직자 프로필 수정 API (`PATCH auth/jobseeker/profile`).
class JobSeekerProfileRepository {
  JobSeekerProfileRepository._();

  static const String _path = 'auth/jobseeker/profile';

  /// 프로필 이미지·경력·소개·관심사를 갱신한다. 실패해도 throw 하지 않는다.
  static Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> payload,
  ) async {
    if (payload.isEmpty) {
      debugPrint('[JobSeekerProfile] empty payload, skip');
      return <String, dynamic>{};
    }

    try {
      final res = await ApiClient.patch(
        _path,
        body: payload,
      ).timeout(const Duration(seconds: 12));
      debugPrint('[JobSeekerProfile] update ok');
      return res;
    } on TimeoutException catch (e) {
      debugPrint('[JobSeekerProfile] timeout: $e');
      return <String, dynamic>{};
    } on ApiException catch (e) {
      debugPrint('[JobSeekerProfile] api error: $e');
      return <String, dynamic>{};
    } catch (e) {
      debugPrint('[JobSeekerProfile] unexpected: $e');
      return <String, dynamic>{};
    }
  }
}
