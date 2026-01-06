import 'package:flutter/material.dart';
// SignInPage가 있는 경로를 import 합니다.
import 'pages/SignUpPage/signin_page.dart'; 

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // 오른쪽 위 디버그 띠 제거
      title: 'Sign In Demo',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      // 앱을 켰을 때 처음 보여줄 화면을 설정합니다.
      home: const SignInPage(), 
    );
  }
}