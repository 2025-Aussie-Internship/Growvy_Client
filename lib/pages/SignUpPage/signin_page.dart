import 'package:flutter/material.dart';
import '../../theme/color.dart';
import '../../widgets/signup_button.dart';
import '../../widgets/signin_app_bar.dart';
import 'signup_page.dart';
import 'common_signup_page.dart'; 

class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const SignInAppBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Are you',
              style: TextStyle(
                color: AppColors.mainColor,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SignUpButton(
                  text: 'Employer',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CommonSignUpPage(isEmployer: true),
                      ),
                    );
                  },
                ),
                
                const SizedBox(width: 16),

                SignUpButton(
                  text: 'Job seeker',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CommonSignUpPage(isEmployer: false),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}