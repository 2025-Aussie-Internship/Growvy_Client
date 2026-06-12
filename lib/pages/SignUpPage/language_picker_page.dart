import 'package:easy_localization/easy_localization.dart' hide StringTranslateExtension;
import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
import '../../i18n/app_translations.dart';
import '../../styles/colors.dart';
import '../../widgets/next_button.dart';
import 'translation_loading_page.dart';
import 'welcome_page.dart';

/// 스플래시 직후 가장 먼저 보이는 언어 선택 화면.
///
/// - 한국어 / 영어 두 가지 옵션을 제공한다.
/// - 확정하면 setLocale 로 전체 위젯 트리를 새 언어로 갱신한 뒤
///   [WelcomePage] (인사말) → SignUp(Google) → SignIn 으로 이어진다.
/// - 현재는 저장 로직을 의도적으로 비활성화해서, 앱을 재실행하면
///   매번 이 화면이 다시 노출된다.
class LanguagePickerPage extends StatefulWidget {
  const LanguagePickerPage({super.key});

  // ----- 저장 로직 (잠시 꺼둠) -----
  // 다음 실행에도 같은 언어를 자동 적용하고 싶어지면 아래 주석을 풀고
  // _onContinue 에서 markPicked() 도 다시 호출하면 된다.
  //
  // static const String _prefsKey = 'language_picked';
  //
  // static Future<bool> hasPickedLanguage() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   return prefs.getBool(_prefsKey) ?? false;
  // }
  //
  // static Future<void> markPicked() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.setBool(_prefsKey, true);
  // }

  @override
  State<LanguagePickerPage> createState() => _LanguagePickerPageState();
}

class _LanguagePickerPageState extends State<LanguagePickerPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  /// null = 아직 미선택. NextButton 비활성 상태.
  Locale? _selected;
  bool _didInitLocale = false;

  @override
  void initState() {
    super.initState();
    // 진입 시 살짝 페이드 + 아래에서 위로 슬라이드.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.forward());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // EasyLocalization 의 InheritedWidget 은 initState 에선 읽을 수 없으므로
    // 여기서 한 번만 기본 선택값으로 현재 locale 을 잡아둔다.
    if (!_didInitLocale) {
      _selected = context.locale;
      _didInitLocale = true;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 옵션을 누르는 순간 곧장 setLocale 을 호출해서 이 화면(타이틀/서브타이틀/
  /// "시작하기" 버튼) 자체가 즉시 새 언어로 다시 그려지게 한다.
  Future<void> _pickLocale(Locale locale) async {
    if (_selected == locale) return;
    // 1) 우리 자체 사전의 활성 locale 먼저 갱신 (이걸로 .tr() 가 즉시
    //    새 locale 의 값 반환). easy_localization 의 context.locale 도
    //    같이 갱신해서 페이지에서 InheritedWidget 구독이 자동 rebuild
    //    하도록 만든다.
    AppTranslations.setLocale(locale);
    setState(() => _selected = locale);
    if (context.locale != locale) {
      try {
        await context.setLocale(locale);
      } catch (_) {
        // setLocale 가 어떤 이유로 실패해도 AppTranslations 는 이미 갱신됐다.
      }
    }
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _onContinue() async {
    final picked = _selected;
    if (picked == null) return;
    // 1) 언어 적용 (이번 세션에만 반영. 영구 저장은 의도적으로 끔.)
    await context.setLocale(picked);
    // 2) 다음 실행 시에도 같은 언어를 자동 적용하고 싶으면 아래 주석을 푼다.
    // await LanguagePickerPage.markPicked();
    if (!mounted) return;
    // 3) setLocale 호출 후 GetMaterialApp / EasyLocalization 의 트리가
    //    실제 새 locale 로 rebuild 되는 frame 들을 충분히 기다린다.
    //    이전엔 Duration.zero microtask 만 기다려서 종종 다음 화면이
    //    이전 locale(en) 로 한 frame 그려지는 문제가 있었다.
    //    1) endOfFrame: 현재 진행 중인 frame 이 끝날 때까지
    //    2) endOfFrame 한 번 더: EasyLocalization → MyApp → GetMaterialApp
    //       체인이 새 locale 로 다시 빌드된 다음 frame 까지
    //    3) 약간의 delay: 일부 디바이스에서 GetX 의 navigator 트리가
    //       완전히 propagation 되는 데 시간이 더 걸리는 경우의 안전마진
    await WidgetsBinding.instance.endOfFrame;
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;
    // 4) 한국어를 선택했다면 모든 정적 영어를 미리 번역 → 캐시에 채워둔다.
    //    그 사이엔 로딩 화면을 보여주고, 끝나면 자동으로 Welcome 으로 이동.
    //    영어를 선택했을 땐 prewarm 이 필요 없으니 바로 Welcome 으로.
    if (picked.languageCode == 'ko') {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 380),
          pageBuilder: (_, _, _) => const TranslationLoadingPage(),
          transitionsBuilder: (_, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 380),
          pageBuilder: (_, _, _) => const WelcomePage(),
          transitionsBuilder: (_, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  Text(
                    'language_picker.title'.tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.mainColor,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'language_picker.subtitle'.tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF747474),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 48),
                  _LanguageOption(
                    label: 'language_picker.korean'.tr(),
                    flag: '🇰🇷',
                    selected: _selected?.languageCode == 'ko',
                    onTap: () => _pickLocale(const Locale('ko')),
                  ),
                  const SizedBox(height: 14),
                  _LanguageOption(
                    label: 'language_picker.english'.tr(),
                    flag: '🇺🇸',
                    selected: _selected?.languageCode == 'en',
                    onTap: () => _pickLocale(const Locale('en')),
                  ),
                  const Spacer(flex: 4),
                  NextButton(
                    text: 'language_picker.continue'.tr(),
                    onPressed: _selected == null ? null : _onContinue,
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.label,
    required this.flag,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String flag;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: double.infinity,
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.mainColor.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: selected
                ? AppColors.mainColor
                : const Color(0xFFE5E5E5),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: selected
                      ? AppColors.mainColor
                      : const Color(0xFF3B3B3B),
                ),
              ),
            ),
            AnimatedOpacity(
              opacity: selected ? 1 : 0,
              duration: const Duration(milliseconds: 180),
              child: const Icon(
                Icons.check_circle,
                color: AppColors.mainColor,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
