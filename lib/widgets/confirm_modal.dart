import 'package:flutter/material.dart';
import '../styles/modal_theme.dart';
import 'auto_translate_text.dart';

class ConfirmModal extends StatelessWidget {
  final String message;
  final String? cancelLabel;
  final String? acceptLabel;
  final VoidCallback? onCancel;
  final VoidCallback? onAccept;

  const ConfirmModal({
    super.key,
    required this.message,
    this.cancelLabel,
    this.acceptLabel,
    this.onCancel,
    this.onAccept,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String message,
    String? cancelLabel,
    String? acceptLabel,
    bool barrierDismissible = false,
    VoidCallback? onCancel,
    VoidCallback? onAccept,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => Theme(
        data: modalTheme(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ConfirmModal(
          message: message,
          cancelLabel: cancelLabel,
          acceptLabel: acceptLabel,
          onCancel: onCancel ?? () => Navigator.pop(context),
          onAccept: onAccept ?? () => Navigator.pop(context),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 시안에 맞춰 모든 확인 모달의 기본 라벨을 통일한다.
    //   - Cancel = "No, I don't"
    //   - Accept = "Yes, I do"
    // 호출처에서 `cancelLabel` / `acceptLabel` 을 명시하면 그 값이 우선한다.
    final resolvedCancel = cancelLabel ?? "No, I don't";
    final resolvedAccept = acceptLabel ?? 'Yes, I do';
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
            children: [
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: AutoTranslateText(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onCancel ?? () => Navigator.pop(context),
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(20),
                          ),
                          child: Container(
                            height: 60,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(20),
                              ),
                            ),
                            child: Center(
                              child: AutoTranslateText(
                                resolvedCancel,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 60,
                      color: const Color(0xFFE0E0E0),
                    ),
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onAccept ?? () => Navigator.pop(context),
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          borderRadius: const BorderRadius.only(
                            bottomRight: Radius.circular(20),
                          ),
                          child: Container(
                            height: 60,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF2643A),
                              borderRadius: BorderRadius.only(
                                bottomRight: Radius.circular(20),
                              ),
                            ),
                            child: Center(
                              child: AutoTranslateText(
                                resolvedAccept,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
