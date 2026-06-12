import 'package:easy_localization/easy_localization.dart' hide StringTranslateExtension;
import 'package:flutter/material.dart';

import '../services/translation_service.dart';

/// 하드코딩 영문/DB 영문 데이터를 현재 앱 로케일로 자동 번역해 표시하는 Text 위젯.
///
/// - 현재 로케일이 영어이거나 [sourceLanguage] 와 같으면 즉시 원본을 그려준다.
/// - 캐시에 이미 번역이 있으면 첫 frame 부터 번역본을 그린다 → 깜빡임 없음.
/// - 캐시에 없으면 [TranslationService] 호출, 받아오는 동안은 원본을 표시.
/// - 결과는 텍스트+언어 단위로 캐시되므로 같은 문구는 두 번째부터 즉시 렌더.
class AutoTranslateText extends StatefulWidget {
  const AutoTranslateText(
    this.text, {
    super.key,
    this.sourceLanguage = 'en',
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.softWrap,
  });

  final String text;
  final String sourceLanguage;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;
  final bool? softWrap;

  @override
  State<AutoTranslateText> createState() => _AutoTranslateTextState();
}

class _AutoTranslateTextState extends State<AutoTranslateText> {
  String _display = '';
  String? _lastTranslatedFor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureTranslation();
  }

  @override
  void didUpdateWidget(covariant AutoTranslateText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.sourceLanguage != widget.sourceLanguage) {
      _lastTranslatedFor = null;
      _ensureTranslation();
    }
  }

  void _ensureTranslation() {
    final target = context.locale.languageCode;

    if (target == widget.sourceLanguage) {
      if (_display != widget.text) {
        _display = widget.text;
      }
      return;
    }

    final key = '${widget.sourceLanguage}>$target|${widget.text}';
    if (_lastTranslatedFor == key) return;
    _lastTranslatedFor = key;

    final cached = TranslationService.instance.cached(
      widget.text,
      sourceLanguage: widget.sourceLanguage,
      targetLanguage: target,
    );
    if (cached != null) {
      _display = cached;
      return;
    }

    _display = widget.text;

    TranslationService.instance
        .translate(
          widget.text,
          sourceLanguage: widget.sourceLanguage,
          targetLanguage: target,
        )
        .then((translated) {
      if (!mounted) return;
      if (_lastTranslatedFor != key) return;
      if (translated == _display) return;
      setState(() => _display = translated);
    });
  }

  @override
  Widget build(BuildContext context) {
    final display = _display.isEmpty ? widget.text : _display;
    return Text(
      display,
      style: widget.style,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
      textAlign: widget.textAlign,
      softWrap: widget.softWrap,
    );
  }
}
