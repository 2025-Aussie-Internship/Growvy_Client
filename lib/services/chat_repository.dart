import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/env.dart';
import 'chat_message_time_cache.dart';
import 'token_storage.dart';

/// 채팅 REST API 공통 호출.
class ChatRepository {
  ChatRepository._();

  static String get _baseUrl => Env.apiBaseUrl;

  static Future<Map<String, String>> _authHeaders() async {
    final token = await TokenStorage.readAccessToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Future<List<Map<String, dynamic>>> fetchRooms() async {
    try {
      final resp = await http
          .get(
            Uri.parse('${_baseUrl}chat/rooms'),
            headers: await _authHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode != 200) {
        debugPrint('[Chat] rooms ${resp.statusCode}: ${resp.body}');
        return [];
      }

      final decoded = jsonDecode(utf8.decode(resp.bodyBytes));
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((e) => _normalizeRoom(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      debugPrint('[Chat] fetchRooms error: $e');
      return [];
    }
  }

  static Map<String, dynamic> _normalizeRoom(Map<String, dynamic> room) {
    final id = roomIdOf(room);
    if (id != null) room['roomId'] = id;
    return room;
  }

  static int? roomIdOf(Map<String, dynamic> raw) {
    final value = raw['roomId'] ?? raw['chatRoomId'] ?? raw['id'];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static Future<List<Map<String, dynamic>>> fetchMessages(int roomId) async {
    try {
      final resp = await http
          .get(
            Uri.parse('${_baseUrl}chat/rooms/$roomId/messages'),
            headers: await _authHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode != 200) {
        debugPrint('[Chat] messages ${resp.statusCode}: ${resp.body}');
        return [];
      }

      final decoded = jsonDecode(utf8.decode(resp.bodyBytes));
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      debugPrint('[Chat] fetchMessages error: $e');
      return [];
    }
  }

  static Future<bool> sendMessage(int roomId, String text) async {
    final result = await sendMessageWithResponse(roomId, text);
    return result != null;
  }

  static Future<Map<String, dynamic>?> sendMessageWithResponse(
    int roomId,
    String text,
  ) async {
    try {
      final sentAt = DateTime.now();
      final resp = await http
          .post(
            Uri.parse('${_baseUrl}chat/rooms/$roomId/messages'),
            headers: await _authHeaders(),
            body: jsonEncode({
              'chatRoomId': roomId,
              'message': text,
              'content': text,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        debugPrint('[Chat] send ${resp.statusCode}: ${resp.body}');
        return null;
      }

      Map<String, dynamic>? payload;
      if (resp.bodyBytes.isNotEmpty) {
        final decoded = jsonDecode(utf8.decode(resp.bodyBytes));
        if (decoded is Map) {
          payload = Map<String, dynamic>.from(decoded);
        }
      }

      final messageId = messageIdOf(payload ?? {});
      if (messageId != null) {
        await ChatMessageTimeCache.save(roomId, messageId, sentAt);
      }

      return payload ?? {'message': text, 'content': text};
    } catch (e) {
      debugPrint('[Chat] send error: $e');
      return null;
    }
  }

  /// 채팅방 입장 시 읽음 처리. 백엔드 엔드포인트 후보를 순서대로 시도한다.
  static Future<void> markRoomAsRead(int roomId) async {
    final paths = [
      'chat/rooms/$roomId/read',
      'chat/rooms/$roomId/messages/read',
    ];
    for (final path in paths) {
      try {
        final resp = await http
            .post(
              Uri.parse('$_baseUrl$path'),
              headers: await _authHeaders(),
            )
            .timeout(const Duration(seconds: 2));
        if (resp.statusCode >= 200 && resp.statusCode < 300) {
          debugPrint('[Chat] mark read ok: $path');
          return;
        }
      } catch (e) {
        debugPrint('[Chat] mark read try $path: $e');
      }
    }
  }

  static String messageText(Map<String, dynamic> raw) {
    final value = raw['content'] ?? raw['message'] ?? raw['text'];
    return value?.toString() ?? '';
  }

  static bool isMineMessage(Map<String, dynamic> raw) {
    final value = raw['isMine'] ?? raw['mine'] ?? raw['isMe'] ?? raw['myMessage'];
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase();
      return lower == 'true' || lower == '1';
    }
    return false;
  }

  static dynamic messageIdOf(Map<String, dynamic> raw) {
    return raw['messageId'] ?? raw['id'] ?? raw['chatMessageId'];
  }

  /// API 날짜 문자열을 기기 로컬 시각으로 변환한다.
  static DateTime? parseToLocalDateTime(dynamic value) {
    if (value == null) return null;

    if (value is int) {
      final ms = value > 9999999999 ? value : value * 1000;
      return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
    }

    if (value is List && value.length >= 3) {
      final year = value[0] as int;
      final month = value[1] as int;
      final day = value[2] as int;
      final hour = value.length > 3 ? value[3] as int : 0;
      final minute = value.length > 4 ? value[4] as int : 0;
      final second = value.length > 5 ? value[5] as int : 0;
      return DateTime(year, month, day, hour, minute, second);
    }

    final raw = value.toString().trim();
    if (raw.isEmpty) return null;

    DateTime? parsed = DateTime.tryParse(raw);
    parsed ??= DateTime.tryParse(raw.replaceFirst(' ', 'T'));

    if (parsed == null) return null;
    return parsed.isUtc ? parsed.toLocal() : parsed;
  }

  static DateTime messageTime(
    Map<String, dynamic> raw, {
    Map<String, DateTime>? cachedTimes,
  }) {
    final id = messageIdOf(raw);
    if (id != null && cachedTimes != null) {
      final cached = cachedTimes['$id'];
      if (cached != null) return cached.toLocal();
    }

    final parsed = parseToLocalDateTime(
      raw['createdAt'] ?? raw['sentAt'] ?? raw['sendAt'] ?? raw['timestamp'],
    );
    if (parsed != null) return parsed;

    return DateTime.now();
  }

  static int unreadCount(Map<String, dynamic> room) {
    final value = room['unreadCount'] ?? room['unread'] ?? room['unreadMessages'];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String lastMessagePreview(Map<String, dynamic> room) {
    final text = (room['lastMessage'] ??
            room['lastMessageContent'] ??
            room['message'] ??
            room['content'])
        ?.toString()
        .trim() ??
        '';

    if (text.isEmpty) return '';

    final isMine = room['lastMessageIsMine'] == true ||
        room['isMyLastMessage'] == true ||
        room['mine'] == true;
    if (isMine) return 'You: $text';
    return text;
  }

  static String? lastMessageTimeRaw(Map<String, dynamic> room) {
    final raw = room['lastMessageTime'] ??
        room['lastMessageAt'] ??
        room['updatedAt'];
    final parsed = parseToLocalDateTime(raw);
    return parsed?.toIso8601String() ?? raw?.toString();
  }
}
