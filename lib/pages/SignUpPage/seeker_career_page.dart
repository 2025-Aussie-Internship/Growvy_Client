import 'package:flutter/material.dart';
import '../../styles/colors.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/next_button.dart';
import '../../widgets/signin_app_bar.dart';
import 'profile_picker_page.dart';

class SeekerCareerPage extends StatefulWidget {
  const SeekerCareerPage({super.key});

  @override
  State<SeekerCareerPage> createState() => _SeekerCareerPageState();
}

class _SeekerCareerPageState extends State<SeekerCareerPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const SignInAppBar(),
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
                label: 'Career',
                hintText: 'Enter Your Career',
              ),
              const SizedBox(height: 16),

              const CustomTextField(
                label: 'One Line Introduction',
                hintText: 'Enter Your Introduction',
              ),

              const SizedBox(height: 48),

              NextButton(
                text: 'Next',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfilePickerPage(),
                    ),
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
