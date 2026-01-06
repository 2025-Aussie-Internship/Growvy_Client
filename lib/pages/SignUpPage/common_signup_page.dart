import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import '../../theme/color.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/next_button.dart';
import '../../widgets/signin_app_bar.dart';
import 'employer_signup_page.dart';
import 'seeker_address_page.dart';

class CommonSignUpPage extends StatefulWidget {
  final bool isEmployer;

  const CommonSignUpPage({super.key, required this.isEmployer});

  @override
  State<CommonSignUpPage> createState() => _CommonSignUpPageState();
}

class _CommonSignUpPageState extends State<CommonSignUpPage> {
  // 성별 선택 상태 (하나만 선택되도록 String으로 관리)
  String selectedGender = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const SignInAppBar(),
      // [수정 1] Center 위젯으로 감싸서 전체 내용을 화면 세로 중앙에 배치
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
              
              // 1. 이름
              CustomTextField(
                label: '*Name',
                hintText: 'Full Name',
                keyboardType: TextInputType.name,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Zㄱ-ㅎ가-힣\s]')),
                ],
              ),

              // 2. 생년월일
              CustomTextField(
                label: '*Date of Birth',
                hintText: 'YYYY/MM/DD',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  DateTextFormatter(),
                  LengthLimitingTextInputFormatter(10),
                ],
              ),

              // 3. 전화번호
              CustomTextField(
                label: '*Phone Number',
                hintText: '+61 0000 0000',
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
              ),

              const SizedBox(height: 10),
              
              // Gender 라벨 박스
              Container(
                width: 130, 
                height: 30, 
                alignment: Alignment.center, 
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF747474)),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const Text(
                  "Gender",
                  style: TextStyle(fontSize: 14, color: Color(0xFF747474)),
                ),
              ),
              const SizedBox(height: 10),
              
              // 성별 체크박스들
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildCheckbox("Male"),
                  const SizedBox(width: 20),
                  _buildCheckbox("Female"),
                ],
              ),
              // Prefer not to say 추가 (필요시 주석 해제하여 사용)
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.center,
              //   children: [
              //     _buildCheckbox("Prefer not to say"),
              //   ],
              // ),

              const SizedBox(height: 40),

              // Next 버튼
              NextButton(
                text: 'Next',
                onPressed: () {
                  if (widget.isEmployer) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EmployerSignupPage()),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SeekerAddressPage()),
                    );
                  }
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox(String genderValue) {
    return Row(
      children: [
        Checkbox(
          value: selectedGender == genderValue, 
          onChanged: (bool? value) {
            setState(() {
              if (value == true) {
                selectedGender = genderValue; // 하나만 선택되도록 업데이트
              } else {
                selectedGender = '';
              }
            });
          },
          activeColor: AppColors.subColor, 
          // [수정 2] 원형(CircleBorder) 제거하고 둥근 사각형으로 변경
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4), 
          ),
          side: MaterialStateBorderSide.resolveWith(
            (states) => const BorderSide(color: Colors.grey, width: 1.5),
          ),
        ),
        Text(genderValue),
      ],
    );
  }
}

class DateTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text;

    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex <= 4) {
        if (nonZeroIndex == 4 && text.length != nonZeroIndex) {
          buffer.write('/');
        }
      } else {
        if (nonZeroIndex == 6 && text.length != nonZeroIndex) {
          buffer.write('/');
        }
      }
    }

    var string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}