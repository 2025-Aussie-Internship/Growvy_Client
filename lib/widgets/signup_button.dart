import 'package:flutter/material.dart';
import '../styles/colors.dart';

class SignUpButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const SignUpButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        fixedSize: const Size(170, 46),
        side: const BorderSide(color: AppColors.subColor, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(56),
        ),
        foregroundColor: AppColors.subColor,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.subColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}