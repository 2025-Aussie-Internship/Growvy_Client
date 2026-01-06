import 'package:flutter/material.dart';

class SignInAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool canBack; // 뒤로가기 버튼 표시 여부 (기본값 true)
  final VoidCallback? onBack; // 뒤로가기 눌렀을 때 특정 동작이 필요하면 사용

  const SignInAppBar({
    super.key,
    this.canBack = true,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      // 뒤로가기 버튼
      leading: canBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
              onPressed: () {
                if (onBack != null) {
                  onBack!(); // 직접 지정한 동작이 있으면 실행
                } else {
                  Navigator.pop(context); // 없으면 기본 뒤로가기
                }
              },
            )
          : null,
      title: const Text(
        'Sign In',
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}