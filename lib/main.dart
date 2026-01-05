import 'package:flutter/material.dart';
import 'package:growvy_client/pages/SignUpPage/signup_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // 오른쪽 위 'Debug' 띠 없애기
      title: 'Growvy',
      theme: ThemeData(
        useMaterial3: true,
      ),
      // ★ 여기가 핵심입니다! 앱이 켜지자마자 SignUpPage를 보여주도록 설정
      home: const SignUpPage(),
    );
  }
}