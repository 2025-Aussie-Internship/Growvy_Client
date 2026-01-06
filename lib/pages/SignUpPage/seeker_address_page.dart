import 'package:flutter/material.dart';
import '../../theme/color.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/next_button.dart';
import '../../widgets/signin_app_bar.dart';
import 'seeker_interest_page.dart';

class SeekerAddressPage extends StatelessWidget {
  const SeekerAddressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const SignInAppBar(),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // 컬럼 내부 요소들도 중앙 정렬
            children: [
              const Text(
                'About you',
                style: TextStyle(
                  color: AppColors.mainColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 34),

              const CustomTextField(
                label: '*Home Address', 
                hintText: 'Enter Home Address'
              ),

              const SizedBox(height: 24),

              NextButton(
                text: 'Next',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SeekerInterestPage()),
                  );
                },
              ),
              // 하단 여백 추가 (시각적 균형을 위해)
              const SizedBox(height: 40), 
            ],
          ),
        ),
      ),
    );
  }
}