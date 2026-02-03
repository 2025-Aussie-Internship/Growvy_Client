import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:get/get.dart';
import 'firebase_options.dart';
import 'services/user_service.dart';
import 'bindings/initial_binding.dart';
import 'routes/app_pages.dart';
import 'pages/SignUpPage/signup_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('ko_KR', null);
  await UserService.init();
  runApp(const MyApp());
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
      home: const SignUpPage(),
    );
  }
}