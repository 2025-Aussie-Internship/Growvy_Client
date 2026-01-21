import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../pages/ChatPage/chat_page.dart'; 
import '../pages/MainPage/main_page.dart';
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 2; // 초기값을 채팅(2)으로 설정

  // 채팅 탭 전용 네비게이터 키 (네비 바 고정의 핵심)
  final GlobalKey<NavigatorState> _chatNavigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const Center(child: Text('Home')), // HomePageContent()
          const Center(child: Text('Map')),
          // 채팅 탭: 별도의 Navigator를 사용하여 내부에서 화면 이동
          Navigator(
            key: _chatNavigatorKey,
            onGenerateRoute: (settings) {
              return MaterialPageRoute(
                builder: (context) => const ChatListPage(),
              );
            },
          ),
          const Center(child: Text('Note')),
          const Center(child: Text('Profile')),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // 사용자님이 작성하신 네비 바 디자인 그대로 복구
  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF202020).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(4, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 80,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildNavItem(0, 'home'),
              _buildNavItem(1, 'map'),
              _buildNavItem(2, 'chat'),
              _buildNavItem(3, 'note'),
              _buildNavItem(4, 'profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String iconName) {
    final bool isSelected = _currentIndex == index;
    // 오류 해결: svgPath 로직 복구
    final String svgPath = isSelected
        ? 'assets/icon/${iconName}_filled.svg'
        : 'assets/icon/${iconName}_not.svg';

    return GestureDetector(
      onTap: () {
        if (_currentIndex == index && index == 2) {
          // 이미 채팅 탭인데 다시 누르면 리스트 첫 화면으로 이동
          _chatNavigatorKey.currentState?.popUntil((route) => route.isFirst);
        }
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.center,
        child: SvgPicture.asset(
          svgPath,
          width: 31,
          height: 44,
          // 에러 방지: 실제 파일이 없을 경우 대비
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.error,
            color: isSelected ? Colors.orange : Colors.grey,
          ),
        ),
      ),
    );
  }
}