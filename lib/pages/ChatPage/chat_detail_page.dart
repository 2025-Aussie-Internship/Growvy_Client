import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 채팅 메시지 데이터
class ChatMessage {
  final String text;
  final bool isMe;
  final DateTime time;
  final bool isUnread; // 본인 메시지 중 상대가 안 읽었을 때 true

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
    this.peerName,
    this.peerProfileImagePath,
  });

  /// 선택한 지원자(채팅 상대) 이름. 없으면 'Name'.
  final String? peerName;
  /// 선택한 지원자 프로필 이미지 경로.
  final String? peerProfileImagePath;

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [
    ChatMessage(
      text: 'Text',
      isMe: false,
      time: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    ChatMessage(
      text: 'Text',
      isMe: false,
      time: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    ChatMessage(
      text: 'Text',
      isMe: true,
      time: DateTime.now().subtract(const Duration(minutes: 50)),
      isUnread: false,
    ),
    ChatMessage(
      text: 'Text',
      isMe: false,
      time: DateTime.now().subtract(const Duration(minutes: 40)),
    ),
    ChatMessage(
      text: 'Text',
      isMe: true,
      time: DateTime.now().subtract(const Duration(minutes: 30)),
      isUnread: true,
    ),
  ];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  /// 말풍선 옆: 시간만 (예: 3:08 PM)
  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '$hour:$min $ampm';
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 헤더
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
                  Text(
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
            // 이름 아래 구분선
            const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),

            // 채팅 메시지 리스트 (날짜 바뀔 때 구분선)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 24,
                  bottom: 8,
                ),
                children: _buildMessageListWithDateDividers(),
              ),
            ),

            // 입력 영역
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildInputArea(),
            ),
          ],
        ),
      ),
    );
  }

  /// 날짜 구분선: yyyy.mm.dd
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
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      '1',
                      style: TextStyle(
                        color: const Color(0xFF931515),
                        fontSize: 10,
                      ),
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
                  child: Text(
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
                        decoration: const InputDecoration(
                          hintText: 'Type a Message',
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
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
