import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// 앱 자체 i18n 사전.
///
/// 배경: GetMaterialApp + easy_localization 조합에서 `setLocale` 가 호출돼
/// `context.locale = ko` 가 되어도, easy_localization 의 글로벌 사전 인스턴스
/// (`Localization.instance`) 가 갱신되지 않아 `.tr()` 가 영어 사전 그대로
/// 반환하는 문제가 있었다. (디버그 로그로 확인:
///   `[MyApp] build locale=ko tr(title)=Choose your language`)
///
/// 그래서 easy_localization 의 사전 동작에 의존하지 않고, 우리가 직접
/// `assets/translations/en.json` / `ko.json` 을 메모리에 들고 매핑한다.
///
/// 사용 흐름:
///   1) `main()` 에서 `await AppTranslations.init()` 호출 (rootBundle 로
///      두 JSON 로딩).
///   2) 사용자가 언어를 바꾸는 지점(LanguagePicker, TranslationLoadingPage)
///      에서 `AppTranslations.setLocale(locale)` 호출.
///   3) 페이지의 `'key'.tr()` 호출은 이 파일의 `AppStringTr.tr()` extension
///      을 통해 우리 사전을 조회한다. (easy_localization 의 동일 extension
///      은 import 시 `hide StringTranslateExtension` 로 가린다.)
class AppTranslations {
  AppTranslations._();

  static Map<String, dynamic> _en = <String, dynamic>{};
  static Map<String, dynamic> _ko = <String, dynamic>{};
  static Locale _current = const Locale('en');

  static Locale get currentLocale => _current;
  static String get currentLanguage => _current.languageCode;

  /// 두 사전을 한 번에 메모리에 적재한다. 앱 시작 시 한 번만 호출하면 충분.
  static Future<void> init() async {
    final enStr = await rootBundle.loadString('assets/translations/en.json');
    final koStr = await rootBundle.loadString('assets/translations/ko.json');
    _en = json.decode(enStr) as Map<String, dynamic>;
    _ko = json.decode(koStr) as Map<String, dynamic>;
  }

  /// 활성 locale 만 갱신한다. UI rebuild 는 별도(setLocale 호출 직전/직후의
  /// setState 또는 easy_localization 의 context.setLocale 이 일으키는
  /// InheritedWidget 갱신) 으로 처리된다.
  static void setLocale(Locale locale) {
    _current = locale;
  }

  /// 'a.b.c' 같은 dot-path 키를 현재 locale 의 문자열로 변환.
  /// - 현재 locale 에 키가 없으면 영어 사전에서 fallback.
  /// - 그것도 없으면 키 그대로 반환 (디버깅용).
  static String t(String key) {
    final primary = _current.languageCode == 'ko' ? _ko : _en;
    final fromPrimary = _lookup(primary, key);
    if (fromPrimary != null) return fromPrimary;
    final fromEn = _lookup(_en, key);
    if (fromEn != null) return fromEn;
    return key;
  }

  static String? _lookup(Map<String, dynamic> map, String key) {
    final parts = key.split('.');
    dynamic v = map;
    for (final p in parts) {
      if (v is Map<String, dynamic>) {
        v = v[p];
      } else {
        return null;
      }
    }
    return v is String ? v : null;
  }
}

/// 페이지의 `'key'.tr()` 호출이 이 extension 으로 연결되게 한다.
/// easy_localization 의 동일한 `String tr({...})` 는 import 시
/// `hide StringTranslateExtension` 로 가린다.
extension AppStringTr on String {
  String tr() => AppTranslations.t(this);
}
