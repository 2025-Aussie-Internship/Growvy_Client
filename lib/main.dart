import 'package:easy_localization/easy_localization.dart' hide StringTranslateExtension;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:get/get.dart' hide Trans;
import 'firebase_options.dart';
import 'i18n/app_translations.dart';
import 'services/user_service.dart';
import 'bindings/initial_binding.dart';
import 'routes/app_pages.dart';
import 'pages/SignUpPage/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // .env 를 가장 먼저 로드해야 Firebase 옵션이 키를 읽을 수 있다.
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('ko_KR', null);
  await UserService.init();
  // 다국어 초기화 (한국어 / 영어 두 가지 지원).
  await EasyLocalization.ensureInitialized();
  // easy_localization 의 사전 동작이 GetMaterialApp 환경에서 갱신되지 않는
  // 문제를 회피하기 위해, 우리 자체 사전을 추가로 메모리에 적재한다.
  await AppTranslations.init();
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ko')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      // 앱 시작 시 항상 영어로 고정한다.
      // - saveLocale: false 와 함께 쓰면 디바이스가 ko_KR 이어도
      //   "영어 → LanguagePicker → 사용자가 고른 언어" 로 깔끔히 전환된다.
      startLocale: const Locale('en'),
      // 재실행 때 매번 언어 선택 화면이 다시 보이도록 영구 저장을 끈다.
      // 다음 실행에도 직전 언어를 그대로 쓰고 싶으면 true 로 바꾸면 된다.
      saveLocale: false,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Growvy',
      theme: ThemeData(
        fontFamily: 'Pretendard',
        textTheme: ThemeData.light().textTheme.apply(
          fontFamily: 'Pretendard',
        ),
        primaryTextTheme: ThemeData.light().primaryTextTheme.apply(
          fontFamily: 'Pretendard',
        ),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      initialBinding: InitialBinding(),
      getPages: AppPages.routes,
      // EasyLocalization 위임자/로케일 주입.
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: const SplashPage(),
    );
  }
}