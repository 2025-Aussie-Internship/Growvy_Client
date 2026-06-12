import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/env.dart';
import 'token_storage.dart';

/// 백엔드 REST API 호출을 한 곳으로 모은 클라이언트.
///
/// 책임:
///   - baseUrl(.env API_BASE_URL) 자동 prefix
///   - 인증 토큰 자동 첨부 (Authorization: Bearer ...)
///   - 표준 에러 객체([ApiException]) 변환
///   - 30초 타임아웃
///
/// 사용 예:
/// ```dart
/// final me = await ApiClient.get('/api/users/me');
/// final body = await ApiClient.post('/api/users/seeker', body: signupPayload);
/// ```
///
/// 백엔드 스펙이 확정되면 endpoint 와 schema 만 repository 레이어에서
/// 정의하면 되도록 설계됨. ([SignupRepository] / [UserRepository] 참고)
class ApiClient {
  ApiClient._();

  static const Duration _timeout = Duration(seconds: 30);

  static Future<Map<String, dynamic>> get(String path) async {
    final res = await _send(() async => http.get(
          _uri(path),
          headers: await _headers(),
        ));
    return _decode(res);
  }

  static Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final res = await _send(() async => http.post(
          _uri(path),
          headers: await _headers(),
          body: body == null ? null : jsonEncode(body),
        ));
    return _decode(res);
  }

  static Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final res = await _send(() async => http.patch(
          _uri(path),
          headers: await _headers(),
          body: body == null ? null : jsonEncode(body),
        ));
    return _decode(res);
  }

  static Future<Map<String, dynamic>> delete(String path) async {
    final res = await _send(() async => http.delete(
          _uri(path),
          headers: await _headers(),
        ));
    return _decode(res);
  }

  // ────────────────────────── internals ──────────────────────────

  static Uri _uri(String path) {
    final base = Env.apiBaseUrl;
    final cleanedBase = base.endsWith('/')
        ? base.substring(0, base.length - 1)
        : base;
    final cleanedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$cleanedBase$cleanedPath');
  }

  /// 모든 요청에 공통으로 들어가는 header.
  /// 토큰이 있으면 Authorization 자동 첨부.
  static Future<Map<String, String>> _headers() async {
    final h = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    // 백엔드 자체 access_token 이 있으면 그걸 우선 사용.
    final access = await TokenStorage.readAccessToken();
    if (access != null && access.isNotEmpty) {
      h['Authorization'] = 'Bearer $access';
      return h;
    }
    // 없으면 Firebase ID Token 으로 fallback (백엔드가 Firebase Admin SDK
    // 로 검증하는 패턴일 때 유용).
    final firebase = await TokenStorage.readFirebaseIdToken();
    if (firebase != null && firebase.isNotEmpty) {
      h['Authorization'] = 'Bearer $firebase';
    }
    return h;
  }

  static Future<http.Response> _send(
    Future<http.Response> Function() request,
  ) async {
    try {
      return await request().timeout(_timeout);
    } on TimeoutException {
      throw const ApiException(
        statusCode: 0,
        message: 'Request timed out',
      );
    } catch (e) {
      throw ApiException(statusCode: 0, message: 'Network error: $e');
    }
  }

  /// 모든 응답을 `Map<String, dynamic>` 으로 정규화.
  /// - 2xx 가 아니면 [ApiException] throw.
  /// - 응답 body 가 비어 있거나 JSON 객체가 아니면 빈 map.
  static Map<String, dynamic> _decode(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      String message = 'HTTP ${res.statusCode}';
      try {
        final parsed = jsonDecode(res.body);
        if (parsed is Map && parsed['message'] is String) {
          message = parsed['message'] as String;
        }
      } catch (_) {}
      throw ApiException(statusCode: res.statusCode, message: message);
    }
    if (res.body.isEmpty) return <String, dynamic>{};
    try {
      final parsed = jsonDecode(res.body);
      if (parsed is Map<String, dynamic>) return parsed;
      return <String, dynamic>{'data': parsed};
    } catch (e) {
      debugPrint('[ApiClient] decode error: $e body=${res.body}');
      return <String, dynamic>{};
    }
  }
}

/// 모든 API 호출이 throw 하는 단일 예외 타입.
class ApiException implements Exception {
  const ApiException({required this.statusCode, required this.message});
  final int statusCode;
  final String message;

  bool get isUnauthorized => statusCode == 401 || statusCode == 403;
  bool get isNetwork => statusCode == 0;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
