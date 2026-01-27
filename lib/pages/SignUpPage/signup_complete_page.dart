import 'package:flutter/material.dart';
import '../../styles/colors.dart';
import '../../widgets/signin_app_bar.dart';
import '../../widgets/next_button.dart';
import '../MainPage/main_page.dart';

class SignupCompletePage extends StatelessWidget {
  const SignupCompletePage({super.key});

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
              'All Done!',
              style: TextStyle(
                color: AppColors.mainColor,
                fontSize: 32,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 40),

            Center(
              child: SizedBox(
                width: 320,
                child: NextButton(
                  text: 'Ready to Start!',
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const MainPage()),
                      (route) => false,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
