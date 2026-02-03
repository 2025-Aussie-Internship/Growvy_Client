import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 확인 후 2초 뒤 자동으로 닫히는 완료 모달 (Share Complete! / Delete Complete! 등).
/// ConfirmModal과 동일 크기 324x181, 가운데 check_icon.svg 77.
class CompletionModal extends StatefulWidget {
  const CompletionModal({
    super.key,
    required this.message,
    this.onDismiss,
  });

  final String message;
  final VoidCallback? onDismiss;

  /// 2초 표시 후 자동 닫고 [onDismiss] 호출.
  static Future<void> show(
    BuildContext context, {
    required String message,
    VoidCallback? onDismiss,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => CompletionModal(
        message: message,
        onDismiss: onDismiss,
      ),
    );
  }

  @override
  State<CompletionModal> createState() => _CompletionModalState();
}

class _CompletionModalState extends State<CompletionModal> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.of(context).pop();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onDismiss?.call();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 324,
          height: 181,
          margin: const EdgeInsets.symmetric(horizontal: 30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/icon/check_icon.svg',
                width: 77,
                height: 77,
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
