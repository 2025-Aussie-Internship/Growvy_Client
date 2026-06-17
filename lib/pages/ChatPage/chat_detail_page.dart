import 'dart:convert';
import 'package:http/http.dart' as http;
// 🌟 추가된 STOMP 패키지
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../../services/token_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../utils/auto_localize.dart';
import '../../widgets/auto_translate_text.dart';
import '../../config/env.dart';

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
    this.peerProfileImagePath,
  });

  final int? roomId;
  final String? peerName;
  final String? peerProfileImagePath;

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = true;

  // 🌟 실시간 수신을 위한 STOMP 클라이언트와 중복 방지 리스트
  StompClient? _stompClient;
  final List<String> _recentlySent = [];

  static String get _baseUrl => Env.apiBaseUrl;
  // 🌟 백엔드 웹소켓 주소 (SockJS를 사용할 경우 뒤에 /websocket을 붙이는 것이 플러터 표준입니다)
  static const String _wsUrl =
      'wss://growvy.mirim-it-show.site/ws-stomp/websocket';

  @override
  void initState() {
    super.initState();
    if (widget.roomId != null) {
      _fetchMessages().then((_) {
        _initStomp(); // 과거 메시지를 다 불러온 뒤 웹소켓 연결!
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
          final receivedText = msg['content']?.toString() ?? '';

          // 내가 방금 보낸 메시지가 웹소켓으로 돌아온 경우 무시 (화면에 두 번 뜨는 것 방지)
          if (_recentlySent.contains(receivedText)) {
            _recentlySent.remove(receivedText);
            return;
          }

          // 상대방이 보낸 새로운 메시지라면 화면에 즉시 추가!
          if (mounted) {
            setState(() {
              _messages.add(
                ChatMessage(
                  text: receivedText,
                  isMe: false, // 상대방 메시지
                  time: DateTime.now(),
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
    try {
      final token = await TokenStorage.readAccessToken();
      final resp = await http
          .get(
            Uri.parse('${_baseUrl}chat/rooms/${widget.roomId}/messages'),
            headers: {
              'Content-Type': 'application/json',
              if (token != null && token.isNotEmpty)
                'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final List<dynamic> data = jsonDecode(resp.body);
        if (mounted) {
          setState(() {
            _messages.clear();
            _messages.addAll(
              data.map(
                (m) => ChatMessage(
                  text: (m['content'] as String?) ?? '',
                  // 🌟 앞서 해결한 isMe 파싱 유지
                  isMe: (m['isMine'] ?? m['mine'] ?? false) as bool,
                  time:
                      DateTime.tryParse(m['createdAt'] ?? '') ?? DateTime.now(),
                  isUnread: false,
                ),
              ),
            );
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('❌ 메시지 fetch 에러: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _stompClient?.deactivate(); // 🌟 페이지 나갈 때 웹소켓 연결 해제
    _textController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '$hour:$min $ampm';
  }

  // ==========================================
  // 🚀 [수정됨] HTTP API로 메시지 전송 로직
  // ==========================================
  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || widget.roomId == null) return;

    // 1. 화면에 내 메시지 즉시 띄우기 (Optimistic UI - 기다림 없이 바로 보여줌!)
    _recentlySent.add(text);
    setState(() {
      _messages.add(
        ChatMessage(
          text: text,
          isMe: true,
          time: DateTime.now(),
          isUnread: true,
        ),
      );
      _textController.clear();
    });

    // 2. 서버 DB에 저장 요청 (이후 서버가 구독자들에게 웹소켓을 쏴줌)
    try {
      final token = await TokenStorage.readAccessToken();
      await http.post(
        Uri.parse('$_baseUrl/chat/rooms/${widget.roomId}/messages'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'chatRoomId': widget.roomId, 'message': text}),
      );
    } catch (e) {
      debugPrint('❌ 메시지 전송 API 에러: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // UI 로직 100% 동일 유지 (수정 없음)
    return Scaffold(
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
                      onPressed: () => Navigator.pop(context),
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
                  : ListView(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 24,
                        bottom: 8,
                      ),
                      children: _buildMessageListWithDateDividers(),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildInputArea(),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final y = dt.year;
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y.$m.$d';
  }

  List<Widget> _buildMessageListWithDateDividers() {
    final list = <Widget>[];
    DateTime? lastDate;
    for (final msg in _messages) {
      final msgDate = DateTime(msg.time.year, msg.time.month, msg.time.day);
      if (lastDate == null || msgDate != lastDate) {
        list.add(_buildDateDivider(msg.time));
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
                if (msg.isUnread)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Text(
                      '1',
                      style: TextStyle(color: Color(0xFF931515), fontSize: 10),
                    ),
                  ),
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
