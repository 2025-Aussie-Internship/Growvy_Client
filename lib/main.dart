import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'services/user_service.dart';
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
    return MaterialApp(
      debugShowCheckedModeBanner: false, 
      title: 'Growvy',
      theme: ThemeData(
        fontFamily: 'Pretendard', 
        
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: const SignUpPage(), 
    );
  }
}