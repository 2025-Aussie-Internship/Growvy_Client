import 'package:easy_localization/easy_localization.dart' hide StringTranslateExtension;
import 'package:flutter/widgets.dart';

import '../services/translation_service.dart';

/// 영어 정적 문자열을 현재 로케일에 맞춰 즉시 한국어로 바꿔주는 헬퍼.
///
/// - 위젯이 아니라 String 인자(`hintText`, `labelText`, `tooltip`, SnackBar 내용 등)
///   를 자동 번역하고 싶을 때 사용한다.
/// - `TranslationService` 의 **메모리 캐시** 만 동기로 조회한다. (네트워크 호출 X)
///   따라서 `kStaticEnglishStrings` 가 [TranslationService.prewarm] 으로 미리
///   채워져 있어야 깜빡임 없이 한국어가 나온다.
/// - 캐시에 없으면 ▶︎ background 로 lazy 번역을 trigger 하고 일단 원본을 반환한다.
///   다음 rebuild 부터는 캐시가 채워져 있어 한국어로 그려진다.
String autoLocalize(BuildContext context, String englishText) {
  final target = context.locale.languageCode;
  if (target == 'en') return englishText;

  final cached = TranslationService.instance.cached(
    englishText,
    targetLanguage: target,
  );
  if (cached != null) return cached;

  // fire-and-forget. 다음 frame 에 setState 가 호출될 수 있도록 캐시만 채워준다.
  TranslationService.instance.translate(
    englishText,
    targetLanguage: target,
  );
  return englishText;
}

/// String 확장 형태. `'Enter your name'.autoLocalize(context)` 처럼 쓰면 짧다.
extension AutoLocalizeStringX on String {
  String autoLocalize(BuildContext context) {
    return autoLocalizeString(context, this);
  }
}

/// 호출 사이드에서 의도가 더 잘 드러나도록 alias.
String autoLocalizeString(BuildContext context, String englishText) =>
    autoLocalize(context, englishText);
