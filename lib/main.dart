import 'package:flutter/material.dart';
import 'pages/SignUpPage/signup_page.dart'; 

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, 
      title: 'Growvy', // 앱 이름 수정
      theme: ThemeData(
        // [중요] pubspec.yaml에 정의한 폰트 패밀리 이름과 똑같이 써야 합니다.
        fontFamily: 'Pretendard', 
        
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: const SignUpPage(), 
    );
  }
}