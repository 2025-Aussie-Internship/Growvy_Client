import 'dart:async';
import 'dart:convert';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../services/chat_repository.dart';
import '../../services/chat_message_time_cache.dart';
import '../../utils/auto_localize.dart';
import '../../widgets/auto_translate_text.dart';

/// 채팅 메시지 데이터
class ChatMessage {
  final String text;
  final bool isMe;
  final DateTime time;
  final bool isUnread;

  ChatMessage({
    required this.text,
    required this.isMe,
    required this.time,
    this.isUnread = false,
  });
}

class ChatDetailPage extends StatefulWidget {
  const ChatDetailPage({
    super.key,
    this.roomId,
    this.peerName,
  });

  final int? roomId;
  final String? peerName;

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _listNeedsRefresh = false;

  StompClient? _stompClient;
  final List<String> _recentlySent = [];

  static const String _wsUrl =
      'wss://growvy.mirim-it-show.site/ws-stomp/websocket';

  @override
  void initState() {
    super.initState();
    if (widget.roomId != null) {
      _fetchMessages().then((_) {
        if (mounted) _initStomp();
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  // ==========================================
  // 🚀 [추가됨] 웹소켓(STOMP) 연결 및 수신 로직
  // ==========================================
  void _initStomp() {
    _stompClient = StompClient(
      config: StompConfig(
        url: _wsUrl,
        onConnect: _onConnect,
        onWebSocketError: (dynamic error) => debugPrint('❌ 웹소켓 에러: $error'),
      ),
    );
    _stompClient?.activate();
  }

  void _onConnect(StompFrame frame) {
    debugPrint('✅ STOMP 연결 성공!');
    // 내 채팅방 번호 구독 시작
    _stompClient?.subscribe(
      destination: '/sub/chat/room/${widget.roomId}',
      callback: (StompFrame frame) {
        if (frame.body != null) {
          final Map<String, dynamic> msg = jsonDecode(frame.body!);
          final receivedText = ChatRepository.messageText(msg);

          if (receivedText.isEmpty) return;

          if (_recentlySent.contains(receivedText)) {
            _recentlySent.remove(receivedText);
            return;
          }

          if (mounted) {
            setState(() {
              _listNeedsRefresh = true;
              _messages.add(
                ChatMessage(
                  text: receivedText,
                  isMe: ChatRepository.isMineMessage(msg),
                  time: ChatRepository.messageTime(msg),
                ),
              );
            });
          }
        }
      },
    );
  }

  // ==========================================
  // 기존 로직들 유지
  // ==========================================
  Future<void> _fetchMessages() async {
    if (widget.roomId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final roomId = widget.roomId!;

    try {
      final data = await ChatRepository.fetchMessages(roomId);
      final cachedTimes = await ChatMessageTimeCache.loadRoom(roomId);
      final now = DateTime.now();

      _applyTimeCacheCorrections(data, roomId, cachedTimes, now);

      data.sort(
        (a, b) => ChatRepository.messageTime(
          a,
          cachedTimes: cachedTimes,
        ).compareTo(
          ChatRepository.messageTime(b, cachedTimes: cachedTimes),
        ),
      );

      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(
            data.map(
              (m) => ChatMessage(
                text: ChatRepository.messageText(m),
                isMe: ChatRepository.isMineMessage(m),
                time: ChatRepository.messageTime(
                  m,
                  cachedTimes: cachedTimes,
                ),
              ),
            ),
          );
        _isLoading = false;
        _listNeedsRefresh = true;
      });

      unawaited(ChatRepository.markRoomAsRead(roomId));
    } catch (e, st) {
      debugPrint('[ChatDetail] fetch error: $e\n$st');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyTimeCacheCorrections(
    List<Map<String, dynamic>> data,
    int roomId,
    Map<String, DateTime> cachedTimes,
    DateTime now,
  ) {
    final uniformCreatedAt = _uniformCreatedAt(data);
    if (uniformCreatedAt != null &&
        !_isSameDay(uniformCreatedAt, now) &&
        uniformCreatedAt.isBefore(_localDateOnly(now))) {
      for (final m in data) {
        if (!ChatRepository.isMineMessage(m)) continue;
        final id = ChatRepository.messageIdOf(m);
        if (id == null || cachedTimes.containsKey('$id')) continue;
        cachedTimes['$id'] = now;
        unawaited(ChatMessageTimeCache.save(roomId, id, now));
      }
    }

    for (final m in data) {
      final id = ChatRepository.messageIdOf(m);
      if (id == null || !ChatRepository.isMineMessage(m)) continue;
      final parsed = ChatRepository.parseToLocalDateTime(
        m['createdAt'] ?? m['sentAt'] ?? m['sendAt'],
      );
      if (parsed != null && _isSameDay(parsed, now)) {
        cachedTimes['$id'] = parsed;
        unawaited(ChatMessageTimeCache.save(roomId, id, parsed));
      }
    }
  }

  Map<String, dynamic> _popResult() {
    final last = _messages.isNotEmpty ? _messages.last : null;
    return {
      'refresh': _listNeedsRefresh,
      'roomId': widget.roomId,
      if (last != null) ...{
        'lastMessage': last.text,
        'lastMessageIsMine': last.isMe,
        'lastMessageTime': last.time.toIso8601String(),
      },
    };
  }

  void _popWithRefresh() {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.pop(context, _popResult());
  }

  @override
  void dispose() {
    _stompClient?.deactivate();
    _textController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final hour =
        local.hour > 12 ? local.hour - 12 : (local.hour == 0 ? 12 : local.hour);
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    final min = local.minute.toString().padLeft(2, '0');
    return '$hour:$min $ampm';
  }

  // ==========================================
  // 🚀 [수정됨] HTTP API로 메시지 전송 로직
  // ==========================================
  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || widget.roomId == null) return;

    final sentAt = DateTime.now();
    _recentlySent.add(text);
    setState(() {
      _listNeedsRefresh = true;
      _messages.add(
        ChatMessage(
          text: text,
          isMe: true,
          time: sentAt,
        ),
      );
      _textController.clear();
    });

    final response =
        await ChatRepository.sendMessageWithResponse(widget.roomId!, text);
    if (!mounted) return;

    if (response == null) {
      setState(() {
        _messages.removeLast();
        _recentlySent.remove(text);
        _textController.text = text;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('메시지 전송에 실패했습니다.')),
      );
      return;
    }

    final messageId = ChatRepository.messageIdOf(response);
    if (messageId != null) {
      await ChatMessageTimeCache.save(widget.roomId!, messageId, sentAt);
    }

    final serverTime = ChatRepository.messageTime(
      response,
      cachedTimes: {if (messageId != null) '$messageId': sentAt},
    );
    final idx = _messages.lastIndexWhere((m) => m.text == text && m.isMe);
    if (idx >= 0) {
      setState(() {
        _messages[idx] = ChatMessage(
          text: text,
          isMe: true,
          time: serverTime,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // UI 로직 100% 동일 유지 (수정 없음)
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        FocusManager.instance.primaryFocus?.unfocus();
        Navigator.pop(context, _popResult());
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: 8,
                  right: 8,
                  top: 4,
                  bottom: 0,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.black,
                          size: 20,
                        ),
                        onPressed: _popWithRefresh,
                      ),
                    ),
                    AutoTranslateText(
                      widget.peerName ?? 'Name',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 24,
                          bottom: 8,
                        ),
                        itemCount: _messageListItems.length,
                        itemBuilder: (context, index) {
                          return _messageListItems[index];
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildInputArea(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> get _messageListItems => _buildMessageListWithDateDividers();

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final y = local.year;
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y.$m.$d';
  }

  DateTime _localDateOnly(DateTime dt) {
    final local = dt.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    final la = a.toLocal();
    final lb = b.toLocal();
    return la.year == lb.year && la.month == lb.month && la.day == lb.day;
  }

  DateTime? _uniformCreatedAt(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return null;
    final first = (data.first['createdAt'] ?? data.first['sentAt'] ?? '')
        .toString();
    if (first.isEmpty) return null;
    final allSame = data.every(
      (m) => (m['createdAt'] ?? m['sentAt'] ?? '').toString() == first,
    );
    if (!allSame) return null;
    return ChatRepository.parseToLocalDateTime(first);
  }

  List<Widget> _buildMessageListWithDateDividers() {
    final list = <Widget>[];
    DateTime? lastDate;
    for (final msg in _messages) {
      final msgDate = _localDateOnly(msg.time);
      if (lastDate == null || msgDate != lastDate) {
        list.add(_buildDateDivider(msgDate));
      }
      lastDate = msgDate;
      list.add(_buildMessage(msg));
    }
    return list;
  }

  Widget _buildDateDivider(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Divider(height: 1, thickness: 1, color: Colors.grey[300]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _formatDate(date),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ),
          Expanded(
            child: Divider(height: 1, thickness: 1, color: Colors.grey[300]),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage msg) {
    final timeStr = _formatTime(msg.time);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: msg.isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (!msg.isMe) ...[
            const CircleAvatar(
              radius: 20,
              backgroundColor: Color(0xFFD9D9D9),
              child: Icon(Icons.person, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 8),
          ],
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (msg.isMe) ...[
                Text(
                  timeStr,
                  style: const TextStyle(color: Color(0xFF747474), fontSize: 9),
                ),
                const SizedBox(width: 6),
              ],
              IntrinsicWidth(
                child: Container(
                  constraints: const BoxConstraints(
                    maxWidth: 260,
                    minHeight: 30,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: msg.isMe
                        ? const Color(0xFFFF937A)
                        : const Color(0xFFD9D9D9),
                    borderRadius: msg.isMe
                        ? const BorderRadius.only(
                            topLeft: Radius.circular(15),
                            topRight: Radius.circular(15),
                            bottomLeft: Radius.circular(15),
                          )
                        : const BorderRadius.only(
                            topRight: Radius.circular(15),
                            bottomRight: Radius.circular(15),
                            topLeft: Radius.circular(15),
                          ),
                  ),
                  alignment: Alignment.center,
                  child: AutoTranslateText(
                    msg.text,
                    style: TextStyle(
                      color: msg.isMe ? Colors.white : Colors.black,
                      fontSize: 13,
                    ),
                    maxLines: 10,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (!msg.isMe) ...[
                const SizedBox(width: 6),
                Text(
                  timeStr,
                  style: const TextStyle(color: Color(0xFF747474), fontSize: 9),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Center(
      child: SizedBox(
        width: 358,
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(115),
                  border: Border.all(color: const Color(0xFFB2B2B2)),
                ),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      'assets/icon/plus_icon.svg',
                      width: 16,
                      height: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        textAlignVertical: TextAlignVertical.center,
                        decoration: InputDecoration(
                          hintText: autoLocalize(context, 'Type a Message'),
                          hintStyle: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFC6340),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mic,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFFFC6340),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/icon/sent_icon.svg',
                    width: 32,
                    height: 32,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
