import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 검색창 영역
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                const Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'search for chats',
                      hintStyle: TextStyle(color: Colors.grey),
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

        // 채팅방 목록
        Expanded(
          child: ListView.builder(
            itemCount: 30, // 테스트용 데이터 갯수
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemBuilder: (context, index) {
              return _buildChatTile(context);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChatTile(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ChatDetailPage()),
        );
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 메인 카드 컨테이너
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
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'User Name',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Last Message text...',
                        style: TextStyle(
                          color: Color(0xFF747474),
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const SizedBox(height: 35),
                    const Text(
                      'Month, Date, Year(Time)',
                      style: TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
          //오른쪽 위 주황색 알림 배지
          Positioned(
            top: -5,
            right: -5,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFFFF7252),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              child: const Center(
                child: Text(
                  '1',
                  style: TextStyle(
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

class ChatDetailPage extends StatelessWidget {
  const ChatDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 중앙 정렬 타이틀 헤더
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
                  const Text(
                    'Name',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // 채팅 메시지 리스트 더미 값
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                children: [
                  _buildMessage(false, "Text", "00:00 AM/PM"),
                  _buildMessage(false, "Text", "00:00 AM/PM"),
                  _buildMessage(true, "Text", "00:00 AM/PM"),
                  _buildMessage(false, "Text", "00:00 AM/PM"),
                  _buildMessage(true, "Text", "00:00 AM/PM"),
                ],
              ),
            ),

            // 입력 영역 (318x42, 전송버튼 외부)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildInputArea(),
            ),
          ],
        ),
      ),
    );
  }

  // 메시지 말풍선
  Widget _buildMessage(bool isMe, String text, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (!isMe) ...[
            const CircleAvatar(
              radius: 20, // 지름 40
              backgroundColor: Color(0xFFD9D9D9),
              child: Icon(Icons.person, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 8),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isMe) ...[
                Text(
                  time,
                  style: const TextStyle(color: Color(0xFF747474), fontSize: 9),
                ),
                const SizedBox(width: 6),
              ],
              Container(
                height: 30, // 말풍선 높이 h:30
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isMe
                      ? const Color(0xFFFF7252)
                      : const Color(0xFFD9D9D9),
                  borderRadius: isMe
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
                child: Text(
                  text,
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black,
                    fontSize: 13,
                  ),
                ),
              ),
              if (!isMe) ...[
                const SizedBox(width: 6),
                Text(
                  time,
                  style: const TextStyle(color: Color(0xFF747474), fontSize: 9),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  //입력

  Widget _buildInputArea() {
    return Center(
      child: SizedBox(
        width: 350,
        height: 42,
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

                    const Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Type a Message',
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.only(bottom: 12),
                        ),
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

            Container(
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
          ],
        ),
      ),
    );
  }
}
