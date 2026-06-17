import 'package:shared_preferences/shared_preferences.dart';

/// 서버가 잘못된 createdAt 을 줄 때, 실제 전송 시각을 보존한다.
class ChatMessageTimeCache {
  ChatMessageTimeCache._();

  static String _prefix(int roomId) => 'chat_msg_time_${roomId}_';

  static Future<void> save(int roomId, dynamic messageId, DateTime time) async {
    if (messageId == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '${_prefix(roomId)}$messageId',
      time.toIso8601String(),
    );
  }

  static Future<Map<String, DateTime>> loadRoom(int roomId) async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = _prefix(roomId);
    final result = <String, DateTime>{};

    for (final key in prefs.getKeys()) {
      if (!key.startsWith(prefix)) continue;
      final raw = prefs.getString(key);
      if (raw == null) continue;
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) {
        result[key.substring(prefix.length)] = parsed;
      }
    }
    return result;
  }
}
