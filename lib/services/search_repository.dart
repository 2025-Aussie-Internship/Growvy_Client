import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/env.dart';
import '../utils/image_url.dart';
import 'token_storage.dart';

/// `GET /api/search?keyword=` 검색 API.
///
/// 백엔드가 JWT 사용자 타입에 따라 필터링한다.
/// - 구직자: 이미 지원한 공고 제외
/// - 구인자: 전체 공고
class SearchRepository {
  SearchRepository._();

  static Future<List<Map<String, dynamic>>> search(String keyword) async {
    final q = keyword.trim();
    if (q.isEmpty) return [];

    try {
      final token = await TokenStorage.readAccessToken();
      final uri = Uri.parse('${Env.apiBaseUrl}search').replace(
        queryParameters: {'keyword': q},
      );

      final response = await http
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              if (token != null && token.isNotEmpty)
                'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        debugPrint('[Search] HTTP ${response.statusCode}: ${response.body}');
        return [];
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final List<dynamic> rawList;
      if (decoded is List) {
        rawList = decoded;
      } else if (decoded is Map<String, dynamic>) {
        final data = decoded['data'];
        if (data is List) {
          rawList = data;
        } else if (data is Map<String, dynamic>) {
          rawList =
              (data['content'] as List?) ??
              (data['results'] as List?) ??
              const [];
        } else {
          rawList =
              (decoded['content'] as List?) ??
              (decoded['results'] as List?) ??
              const [];
        }
      } else {
        return [];
      }

      return rawList
          .whereType<Map>()
          .map((e) => _mapItem(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e, st) {
      debugPrint('[Search] error: $e\n$st');
      return [];
    }
  }

  /// [JobSeekerJobPostResponse] → 검색 UI용 Map (main `_mapPost` 와 동일 태그 규칙)
  static Map<String, dynamic> _mapItem(Map<String, dynamic> item) {
    final dDay = (item['dday'] ?? item['dDay'])?.toString() ?? '';
    final empTag = item['employmentTag']?.toString() ?? '';
    final tagsRaw = item['tags'];

    final List<String> tags = [
      if (dDay.isNotEmpty) dDay,
      if (empTag.isNotEmpty) empTag,
      if (empTag.isEmpty && tagsRaw is List)
        ...tagsRaw
            .map((e) => e.toString())
            .where((t) => t.isNotEmpty && t != dDay),
    ];

    final wage = item['hourlyWage'] ?? item['hourlyRates'];
    String? payText;
    if (wage != null) {
      final parsed = wage is num ? wage.toDouble() : double.tryParse('$wage');
      if (parsed != null) {
        payText = parsed == 0 ? 'Volunteer' : '\$${parsed.toStringAsFixed(0)} per hour';
      }
    }

    final photos = (item['imageUrls'] as List?)
            ?.map((e) => resolveImageUrl(e.toString()))
            .toList() ??
        const <String>[];

    return {
      'id': item['id'],
      'title': item['title']?.toString() ?? '',
      'company': item['companyName']?.toString() ?? '',
      'tags': tags,
      'dDay': dDay,
      'description': item['description']?.toString(),
      'payText': payText,
      'photoUrls': photos,
    };
  }
}
