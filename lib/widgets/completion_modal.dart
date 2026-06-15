import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../styles/modal_theme.dart';
import 'auto_translate_text.dart';

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
      builder: (context) => Theme(
        data: modalTheme(context),
        child: CompletionModal(
          message: message,
          onDismiss: onDismiss,
        ),
      ),
    );
  }

  @override
  State<CompletionModal> createState() => _CompletionModalState();
}

class _CompletionModalState extends State<CompletionModal> {
  /// 자동 dismiss / 탭 dismiss 중 먼저 발생한 한 쪽만 실제로 닫도록 가드.
  bool _dismissed = false;
  Timer? _autoTimer;

  @override
  void initState() {
    super.initState();
    // 사용자가 탭하지 않더라도 2초 후 자동으로 닫히도록 fallback.
    _autoTimer = Timer(const Duration(seconds: 2), _dismiss);
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    super.dispose();
  }

  /// 자동 타이머 또는 사용자 탭에서 호출. 중복 호출은 무시.
  void _dismiss() {
    if (_dismissed) return;
    _dismissed = true;
    _autoTimer?.cancel();
    if (!mounted) return;
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onDismiss?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    // 화면 어디를 눌러도 (모달 외부 포함) 즉시 닫히도록 풀 스크린 GestureDetector 로 감싼다.
    // - HitTestBehavior.opaque 로 빈 영역까지 탭 흡수.
    // - Material 카드 자체 onTap 도 있어서, 카드 안을 눌러도 동일하게 닫힘.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _dismiss,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: _dismiss,
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
                    child: AutoTranslateText(
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
        ),
      ),
    );
  }
}
