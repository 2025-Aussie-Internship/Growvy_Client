import 'package:easy_localization/easy_localization.dart' hide StringTranslateExtension;
import 'package:flutter/material.dart';

import '../../i18n/app_translations.dart';
import '../../i18n/english_strings.dart';
import '../../services/translation_service.dart';
import '../../styles/colors.dart';
import 'welcome_page.dart';

/// LanguagePicker 에서 한국어를 선택한 직후 보여주는 사전 번역 로딩 화면.
///
/// `kStaticEnglishStrings` 목록을 백그라운드에서 번역기에 미리 캐시해두어,
/// Welcome 이후 모든 화면에서 영어가 한 순간도 보이지 않도록 만든다.
class TranslationLoadingPage extends StatefulWidget {
  const TranslationLoadingPage({
    super.key,
    this.isExistingUser = false,
    this.isSeekerProfileUpdate = false,
  });

  final bool isExistingUser;
  final bool isSeekerProfileUpdate;

  @override
  State<TranslationLoadingPage> createState() => _TranslationLoadingPageState();
}

class _TranslationLoadingPageState extends State<TranslationLoadingPage> {
  int _done = 0;
  int _total = 0;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _runPrewarm();
  }

  Future<void> _runPrewarm() async {
    final target = context.locale.languageCode;

    // 한국어가 아닐 땐 곧장 다음 화면으로.
    if (target == 'en') {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      _goNext();
      return;
    }

    try {
      await TranslationService.instance.prewarm(
        kStaticEnglishStrings,
        sourceLanguage: 'en',
        targetLanguage: target,
        concurrency: 8,
        onProgress: (done, total) {
          if (!mounted) return;
          setState(() {
            _done = done;
            _total = total;
          });
        },
      );
    } catch (_) {
      // 네트워크 이슈 등으로 prewarm 일부가 실패해도 다음 단계는 진행한다.
      // 화면별로 lazy 번역이 다시 시도된다.
    }

    if (!mounted) return;
    _goNext();
  }

  Future<void> _goNext() async {
    // 안전벨트: 혹시라도 prewarm 동안 locale 이 흔들렸다면 한국어로 다시 고정.
    // 자체 사전(AppTranslations) 의 활성 locale 도 한국어로 fixed.
    AppTranslations.setLocale(const Locale('ko'));
    if (context.locale.languageCode != 'ko') {
      await context.setLocale(const Locale('ko'));
      await WidgetsBinding.instance.endOfFrame;
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
    }
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 380),
        pageBuilder: (_, _, _) => WelcomePage(
          isExistingUser: widget.isExistingUser,
          isSeekerProfileUpdate: widget.isSeekerProfileUpdate,
        ),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = _total == 0 ? 0.0 : _done / _total;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation(AppColors.mainColor),
                ),
              ),
              const SizedBox(height: 28),
              // 이 화면은 "한국어를 선택한 직후" 에만 보이는 prewarm 로딩 화면이라
              // setLocale propagation 타이밍과 무관하게 항상 한국어 안내문을
              // 직접 그려서 영어 깜빡임을 원천 차단한다.
              const Text(
                '한국어로 번역하고 있어요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '앱 곳곳의 문구를 미리 번역하고 있어요.\n잠시만 기다려 주세요...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF747474),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _total == 0 ? null : progress,
                  minHeight: 6,
                  backgroundColor: const Color(0xFFEFEFEF),
                  valueColor: const AlwaysStoppedAnimation(
                    AppColors.mainColor,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _total == 0 ? '' : '$_done / $_total',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9A9A9A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
