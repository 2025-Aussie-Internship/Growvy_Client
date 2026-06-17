import 'dart:async';
import '../../i18n/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:growvy_client/pages/ChatPage/chat_detail_page.dart';
import '../../services/chat_repository.dart';
import '../../services/chat_realtime_service.dart';
import '../../widgets/auto_translate_text.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => ChatListPageState();
}

class ChatListPageState extends State<ChatListPage> {
  List<Map<String, dynamic>> _chatRooms = [];
  bool _isLoading = true;
  final Map<int, int> _localUnreadBoost = {};
  int? _activeRoomId;
  StreamSubscription<ChatIncomingEvent>? _realtimeSub;

  @override
  void initState() {
    super.initState();
    _realtimeSub = ChatRealtimeService.instance.messages.listen(
      _onRealtimeMessage,
    );
    ChatRealtimeService.instance.connect();
    _fetchChatRooms();
  }

  @override
  void dispose() {
    _realtimeSub?.cancel();
    super.dispose();
  }

  void refreshChatList() {
    _fetchChatRooms();
  }

  Future<void> _fetchChatRooms() async {
    final rooms = await ChatRepository.fetchRooms();
    if (!mounted) return;
    setState(() {
      _chatRooms = rooms;
      _isLoading = false;
      _localUnreadBoost.clear();
    });
    _syncRealtimeSubscriptions();
  }

  void _syncRealtimeSubscriptions() {
    final roomIds = _chatRooms
        .map(ChatRepository.roomIdOf)
        .whereType<int>()
        .toList();
    ChatRealtimeService.instance.updateRoomSubscriptions(roomIds);
  }

  void _onRealtimeMessage(ChatIncomingEvent event) {
    if (!mounted) return;
    _applyIncomingMessage(event.roomId, event.raw);
  }

  void _applyIncomingMessage(int roomId, Map<String, dynamic> msg) {
    final text = ChatRepository.messageText(msg);
    if (text.isEmpty) return;

    final isMine = ChatRepository.isMineMessage(msg);
    final timeStr = ChatRepository.messageTime(msg).toIso8601String();

    final idx = _chatRooms.indexWhere(
      (r) => ChatRepository.roomIdOf(r) == roomId,
    );
    if (idx < 0) {
      _fetchChatRooms();
      return;
    }

    final updated = Map<String, dynamic>.from(_chatRooms[idx]);
    updated['lastMessage'] = text;
    updated['lastMessageIsMine'] = isMine;
    updated['lastMessageTime'] = timeStr;

    final shouldCountUnread = !isMine && _activeRoomId != roomId;
    if (shouldCountUnread) {
      _localUnreadBoost[roomId] = (_localUnreadBoost[roomId] ?? 0) + 1;
    }

    setState(() {
      _chatRooms.removeAt(idx);
      _chatRooms.insert(0, updated);
    });
  }

  Future<void> _openChatRoom(Map<String, dynamic> room) async {
    final roomId = ChatRepository.roomIdOf(room);
    final partnerName = room['partnerName']?.toString() ?? 'Unknown';

    if (roomId == null) return;

    try {
      setState(() {
        _activeRoomId = roomId;
        _localUnreadBoost.remove(roomId);
      });

      final result = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(
          builder: (context) => ChatDetailPage(
            roomId: roomId,
            peerName: partnerName,
          ),
        ),
      );

      if (!mounted) return;
      setState(() => _activeRoomId = null);

      if (result != null && result['lastMessage'] != null) {
        final idx = _chatRooms.indexWhere(
          (r) => ChatRepository.roomIdOf(r) == roomId,
        );
        if (idx >= 0) {
          setState(() {
            _chatRooms[idx] = {
              ..._chatRooms[idx],
              'lastMessage': result['lastMessage'],
              'lastMessageIsMine': result['lastMessageIsMine'] == true,
              'lastMessageTime': result['lastMessageTime'],
              'unreadCount': 0,
            };
          });
        }
      }

      if (result?['refresh'] == true) {
        await _fetchChatRooms();
      }
    } catch (e, st) {
      debugPrint('[ChatList] open room error: $e\n$st');
      if (mounted) setState(() => _activeRoomId = null);
    }
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final dt = ChatRepository.parseToLocalDateTime(dateStr) ??
          DateTime.parse(dateStr).toLocal();
      final month = dt.month.toString().padLeft(2, '0');
      final day = dt.day.toString().padLeft(2, '0');
      final year = dt.year;
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      final min = dt.minute.toString().padLeft(2, '0');

      return '$month.$day.$year($hour:$min $ampm)';
    } catch (e) {
      return '';
    }
  }

  int _displayUnreadCount(Map<String, dynamic> room) {
    final roomId = ChatRepository.roomIdOf(room);
    if (roomId != null && _activeRoomId == roomId) return 0;
    final base = ChatRepository.unreadCount(room);
    final boost = roomId != null ? (_localUnreadBoost[roomId] ?? 0) : 0;
    return base + boost;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            MediaQuery.paddingOf(context).top + 12,
            20,
            16,
          ),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                const Icon(Icons.search, color: Colors.grey),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'chat.chats'.tr(),
                      hintStyle: const TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                SvgPicture.asset('assets/icon/mike_icon.svg', width: 32),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _chatRooms.isEmpty
              ? const Center(child: Text('채팅방이 없습니다.'))
              : ListView.builder(
                  itemCount: _chatRooms.length,
                  padding: const EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 16,
                    bottom: 12,
                  ),
                  itemBuilder: (context, index) {
                    return _buildChatTile(context, _chatRooms[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildChatTile(BuildContext context, Map<String, dynamic> room) {
    final partnerName = room['partnerName']?.toString() ?? 'Unknown';
    final preview = ChatRepository.lastMessagePreview(room);
    final lastMessageTime = _formatDateTime(
      ChatRepository.lastMessageTimeRaw(room),
    );
    final unread = _displayUnreadCount(room);

    return GestureDetector(
      onTap: () => _openChatRoom(room),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 25,
                  backgroundColor: Color(0xFFEEEEEE),
                  child: Icon(Icons.person, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AutoTranslateText(
                        partnerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        preview.isEmpty ? '새로운 채팅방이 생성되었습니다.' : preview,
                        style: const TextStyle(
                          color: Color(0xFF747474),
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const SizedBox(height: 35),
                    Text(
                      lastMessageTime,
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (unread > 0)
            Positioned(
              top: -5,
              right: -5,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7252),
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFD26B53), width: 1),
                ),
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                child: Center(
                  child: Text(
                    unread > 99 ? '99+' : '$unread',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
