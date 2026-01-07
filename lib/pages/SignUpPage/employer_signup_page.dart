import 'package:flutter/material.dart';
import '../../styles/colors.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/next_button.dart';
import '../../widgets/signin_app_bar.dart';

class EmployerSignupPage extends StatefulWidget {
  const EmployerSignupPage({super.key});

  @override
  State<EmployerSignupPage> createState() => _EmployerSignupPageState();
}

class _EmployerSignupPageState extends State<EmployerSignupPage> {
  bool isSoleProprietorship = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const SignInAppBar(),
      // [수정 1] 화면 전체 요소를 수직 중앙 정렬하기 위해 Center로 감쌈
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 36.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'About you',
                style: TextStyle(
                  color: AppColors.mainColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 40),

              const CustomTextField(
                label: 'Company Name', 
                hintText: 'Enter Company Name'
              ),

              Row(
                children: [
                  Checkbox(
                    value: isSoleProprietorship,
                    onChanged: (val) {
                      setState(() {
                        isSoleProprietorship = val!;
                      });
                    },
                    activeColor: AppColors.subColor, 
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    side: MaterialStateBorderSide.resolveWith(
                      (states) => const BorderSide(color: Colors.grey, width: 1.5),
                    ),
                  ),
                  const Text('Sole Proprietorship'),
                ],
              ),
              const SizedBox(height: 7),

              const CustomTextField(
                label: '*Business Address', 
                hintText: 'Enter Business Address'
              ),

              const SizedBox(height: 24),
              
              NextButton(
                text: 'Next',
                onPressed: () {
                  // Employer 회원가입 완료 로직 또는 다음 단계
                  debugPrint("Employer Signup Finished");
                },
              ),
              const SizedBox(height: 40), // 하단 여백 추가
            ],
          ),
        ),
      ),
    );
  }
}