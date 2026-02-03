import 'package:flutter/material.dart';
import '../styles/modal_theme.dart';

class ConfirmModal extends StatelessWidget {
  final String message;
  final String cancelLabel;
  final String acceptLabel;
  final VoidCallback? onCancel;
  final VoidCallback? onAccept;

  const ConfirmModal({
    super.key,
    required this.message,
    this.cancelLabel = 'Cancel',
    this.acceptLabel = 'Accept',
    this.onCancel,
    this.onAccept,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String message,
    String cancelLabel = 'Cancel',
    String acceptLabel = 'Accept',
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
                    child: Text(
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
                              child: Text(
                                cancelLabel,
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
                              child: Text(
                                acceptLabel,
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
