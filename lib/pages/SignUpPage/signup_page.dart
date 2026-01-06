import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'signin_page.dart'; 

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  static const Color mainColor = Color(0xFFFC6340);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: mainColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              const Text(
                'Welcome To',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 10),

              SvgPicture.asset(
                'assets/icon/logo_white.svg',
                width: 228, 
              ),

              const Spacer(),

              Center(
                child: SizedBox(
                  width: 318, 
                  height: 48, 
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignInPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black54,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 20), 
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SvgPicture.asset(
                          'assets/icon/google_logo.svg',
                          height: 27,
                        ),
                        
                        const Text(
                          'Continue With Google',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFB2B2B2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}