import 'package:flutter/material.dart';
import '../styles/colors.dart';

/// 회원가입/온보딩 전반에서 쓰이는 큰 라운드 Next/Confirm 버튼.
///
/// [onPressed] 가 null 이면 비활성 상태로 표시되어 시안의 회색 비활성 스타일이 된다.
class NextButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;

  const NextButton({
    super.key,
    required this.text,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 318,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.mainColor,
          disabledBackgroundColor: const Color(0xFFE0E0E0),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}