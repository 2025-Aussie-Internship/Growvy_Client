import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../styles/colors.dart';

/// 홈·맵·검색 화면에서 동일한 'search for jobs' 바 스타일을 씁니다.
class JobSearchBar extends StatelessWidget {
  static const double barWidth = 290;
  static const double barHeight = 48;
  /// 구분선·타이틀 직후 검색 바까지 동일한 상단 간격(홈·맵·검색).
  static const double topSpacing = 12;
  const JobSearchBar.tappable({
    super.key,
    required this.onTap,
    this.width,
    this.hintText = 'search for jobs',
  })  : controller = null,
        isSearching = false,
        onSubmitted = null,
        onChanged = null,
        autofocus = false;

  const JobSearchBar.field({
    super.key,
    required this.controller,
    this.isSearching = false,
    this.onSubmitted,
    this.onChanged,
    this.autofocus = false,
    this.width,
    this.hintText = 'search for jobs',
  }) : onTap = null;

  final VoidCallback? onTap;
  final TextEditingController? controller;
  final bool isSearching;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final double? width;
  final String hintText;

  static const TextStyle hintStyle = TextStyle(
    fontSize: 14,
    height: 1.2,
    color: Color(0xFF9E9E9E),
    fontWeight: FontWeight.w400,
  );

  @override
  Widget build(BuildContext context) {
    final inner = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          _leading(),
          const SizedBox(width: 10),
          Expanded(
            child: onTap != null ? _fakeHint() : _textField(),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: SvgPicture.asset(
              'assets/icon/mike_icon.svg',
              width: 32,
              height: 32,
            ),
          ),
        ],
      ),
    );

    return SizedBox(
      width: width ?? barWidth,
      height: barHeight,
      child: onTap != null
          ? Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(24),
                child: inner,
              ),
            )
          : inner,
    );
  }

  Widget _fakeHint() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(hintText, style: hintStyle),
    );
  }

  Widget _textField() {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      textAlignVertical: TextAlignVertical.center,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: hintStyle,
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
      ),
      style: const TextStyle(fontSize: 14, height: 1.2),
      textInputAction: TextInputAction.search,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
    );
  }

  Widget _leading() {
    if (isSearching) {
      return SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.mainColor,
        ),
      );
    }
    return SvgPicture.asset(
      'assets/icon/search_icon.svg',
      width: 18,
      height: 18,
    );
  }
}
