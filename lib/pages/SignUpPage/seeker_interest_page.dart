import 'package:flutter/material.dart';
import '../../styles/colors.dart'; // 색상 파일 경로 확인
import '../../widgets/next_button.dart';
import '../../widgets/signin_app_bar.dart';
// [추가] 메인 페이지 import
import '../MainPage/main_page.dart'; 

class SeekerInterestPage extends StatefulWidget {
  const SeekerInterestPage({super.key});

  @override
  State<SeekerInterestPage> createState() => _SeekerInterestPageState();
}

class _SeekerInterestPageState extends State<SeekerInterestPage> {
  final Map<String, bool> interests = {
    'Hospitality & F&B': false,
    'Retail & Sales': false,
    'Farm & Seasonal': false,
    'Manufacturing': false,
    'Factory Work': false,
    'Cleaning & Facilities': false,
    'Construction': false,
    'Logistics & Moving': false,
    'Events & Festivals': false,
    'Customer Service': false,
    'Other Jobs': false,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const SignInAppBar(),
      // [수정] 화면 수직 중앙 정렬
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // 내부 요소 중앙 정렬
            children: [
              const Text(
                'About you',
                style: TextStyle(
                  color: AppColors.mainColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              Container(
                width: 130, 
                height: 30, 
                alignment: Alignment.center, 
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF747474)),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const Text(
                  "Interest",
                  style: TextStyle(fontSize: 14, color: Color(0xFF747474)),
                ),
              ),
              const SizedBox(height: 20),

              // 체크박스 리스트 (2열 배치)
              Wrap(
                spacing: 10, 
                runSpacing: 0,
                children: interests.keys.map((key) {
                  return SizedBox(
                    width: MediaQuery.of(context).size.width / 2 - 30, // 화면 절반 너비
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: interests[key],
                          onChanged: (val) {
                            setState(() {
                              interests[key] = val!;
                            });
                          },
                          // [디자인 통일] 다른 페이지와 같게 스타일 적용
                          activeColor: AppColors.subColor, 
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          side: MaterialStateBorderSide.resolveWith(
                            (states) => const BorderSide(color: Colors.grey, width: 1.5),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            key,
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 40),

              NextButton(
                text: 'Next',
                onPressed: () {
                  // [수정] 메인 페이지로 이동 (이전 기록 삭제)
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const MainPage()),
                    (route) => false,
                  );
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}