import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/color.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final String hintText;
  final TextInputType? keyboardType;           // 키보드 타입 추가
  final List<TextInputFormatter>? inputFormatters; // 입력 제한 포맷터 추가

  const CustomTextField({
    super.key,
    required this.label,
    required this.hintText,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    // 라벨 텍스트 처리: '*'로 시작하면 빨간색 처리, 아니면 검정색
    Widget labelWidget;
    if (label.startsWith('*')) {
      labelWidget = RichText(
        text: TextSpan(
          text: '*',
          style: const TextStyle(color: Colors.red, fontSize: 16),
          children: [
            TextSpan(
              text: label.substring(1), // '*' 제외한 나머지 텍스트
              style: const TextStyle(color: Colors.black, fontSize: 16),
            ),
          ],
        ),
      );
    } else {
      labelWidget = Text(
        label,
        style: const TextStyle(color: Colors.black, fontSize: 16),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 23.0),
      child: Center(
        child: SizedBox(
          width: 318,
          height: 48,
          child: TextField(
            keyboardType: keyboardType,      // 키보드 타입 적용
            inputFormatters: inputFormatters,// 포맷터 적용
            textAlignVertical: TextAlignVertical.center,
            style: const TextStyle(fontSize: 14, color: Colors.black),
            decoration: InputDecoration(
              label: labelWidget, // 위에서 만든 커스텀 라벨 적용
              hintText: hintText,
              floatingLabelBehavior: FloatingLabelBehavior.always,
              contentPadding: const EdgeInsets.only(left: 20, right: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(26),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(26),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(26),
                borderSide: const BorderSide(color: AppColors.mainColor),
              ),
            ),
          ),
        ),
      ),
    );
  }
}