import 'package:flutter/material.dart';

/// 로고 없이 뒤로가기만 있는 상단 바 (상태바 바로 아래)
class SafeBackAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SafeBackAppBar({
    super.key,
    this.onBack,
    this.backgroundColor = Colors.white,
    this.showDivider = true,
  });

  final VoidCallback? onBack;
  final Color backgroundColor;
  final bool showDivider;

  static const double toolbarHeight = 48;

  @override
  Size get preferredSize => const Size.fromHeight(toolbarHeight);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SafeArea(
            bottom: false,
            child: SizedBox(
              height: toolbarHeight,
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
                  onPressed: onBack ?? () => Navigator.maybePop(context),
                ),
              ),
            ),
          ),
          if (showDivider)
            const Divider(height: 1, thickness: 0.5, color: Color(0x1A000000)),
        ],
      ),
    );
  }
}
