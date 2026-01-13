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
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePageContent(),         // 홈
    const Center(child: Text('Map')), // 지도
    const ChatListPage(),            // 채팅
    const Center(child: Text('Note')),// 노트
    const Center(child: Text('Profile')), // 프로필
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 현재 선택된 페이지 표시 
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      // 하단 네비게이션 바 디자인
      bottomNavigationBar: _buildBottomBar(),
    );
  }

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
            color: const Color(0xFF202020).withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(4, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
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
    final String svgPath = isSelected
        ? 'assets/icon/${iconName}_filled.svg'
        : 'assets/icon/${iconName}_not.svg';

    return GestureDetector(
      onTap: () {
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
        ),
      ),
    );
  }
}