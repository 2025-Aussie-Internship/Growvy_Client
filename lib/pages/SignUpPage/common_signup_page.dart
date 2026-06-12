import 'package:easy_localization/easy_localization.dart' hide StringTranslateExtension;
import '../../i18n/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../styles/colors.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/next_button.dart';
import '../../widgets/signin_app_bar.dart';
import 'package:get/get.dart' hide Trans;
import '../../controllers/auth_controller.dart';
import '../../controllers/signup_data_controller.dart';
import 'employer_signup_page.dart';
import 'seeker_address_page.dart';

class CommonSignUpPage extends StatefulWidget {
  final bool isEmployer;

  const CommonSignUpPage({super.key, required this.isEmployer});

  @override
  State<CommonSignUpPage> createState() => _CommonSignUpPageState();
}

class _CommonSignUpPageState extends State<CommonSignUpPage> {
  String selectedGender = '';

  // 이전 단계로 돌아갔다 다시 들어왔을 때 입력값이 유지되도록 초기값은
  // SignupDataController 에 누적된 값을 사용한다.
  late final TextEditingController _nameController;
  late final TextEditingController _dobController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final data = Get.find<SignupDataController>();
    _nameController = TextEditingController(text: data.name ?? '');
    _dobController = TextEditingController(text: data.dateOfBirth ?? '');
    _phoneController = TextEditingController(text: data.phoneNumber ?? '');
    selectedGender = data.gender ?? '';
    // 입력값이 바뀔 때마다 NextButton 활성/비활성 갱신.
    _nameController.addListener(_onFieldChanged);
    _dobController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onFieldChanged);
    _dobController.removeListener(_onFieldChanged);
    _phoneController.removeListener(_onFieldChanged);
    _nameController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  /// 모든 필수 필드가 채워졌는지. NextButton onPressed 분기에 그대로 사용.
  bool get _isFormValid {
    return _nameController.text.trim().isNotEmpty &&
        _phoneController.text.trim().isNotEmpty &&
        selectedGender.isNotEmpty &&
        _dobController.text.length == 10; // YYYY/MM/DD 10자
  }

  @override
  Widget build(BuildContext context) {
    // 명시적으로 locale 구독 → setLocale 발생 시 자동 rebuild.
    context.locale;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const SignInAppBar(),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'signup.about_you'.tr(),
                style: const TextStyle(
                  color: AppColors.mainColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 34),

              CustomTextField(
                controller: _nameController,
                label: '*${'signup.name'.tr()}',
                hintText: 'signup.name_hint'.tr(),
                keyboardType: TextInputType.name,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'[a-zA-Zㄱ-ㅎ가-힣\s]'),
                  ),
                ],
              ),

              CustomTextField(
                controller: _dobController,
                label: '*${'signup.date_of_birth'.tr()}',
                hintText: 'signup.date_of_birth_hint'.tr(),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  DateTextFormatter(),
                  LengthLimitingTextInputFormatter(10),
                ],
              ),

              CustomTextField(
                controller: _phoneController,
                label: '*${'signup.phone_number'.tr()}',
                hintText: 'signup.phone_number_hint'.tr(),
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),

              const SizedBox(height: 10),

              Container(
                width: 130,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF747474)),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Text(
                  'signup.gender'.tr(),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF747474),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildCheckbox("Male", 'signup.male'.tr()),
                  const SizedBox(width: 20),
                  _buildCheckbox("Female", 'signup.female'.tr()),
                ],
              ),

              const SizedBox(height: 40),

              NextButton(
                text: 'common.next'.tr(),
                // 필수값 모두 입력되기 전엔 NextButton 이 회색 비활성으로 표시된다.
                onPressed: _isFormValid
                    ? () async {
                        // 1) 현재 단계 입력값을 컨트롤러에 누적
                        final signupData = Get.find<SignupDataController>();
                        signupData.setUserType(widget.isEmployer);
                        signupData.setBasicInfo(
                          name: _nameController.text.trim(),
                          dateOfBirth: _dobController.text.trim(),
                          phoneNumber: _phoneController.text.trim(),
                          gender: selectedGender,
                        );

                        // 2) 기존대로 사용자 타입 저장 후 다음 화면으로 이동
                        await Get.find<AuthController>()
                            .saveUserType(widget.isEmployer);
                        if (!context.mounted) return;
                        if (widget.isEmployer) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EmployerSignupPage(),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SeekerAddressPage(),
                            ),
                          );
                        }
                      }
                    : null,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox(String genderValue, String label) {
    return Row(
      children: [
        Checkbox(
          value: selectedGender == genderValue,
          onChanged: (bool? value) {
            setState(() {
              if (value == true) {
                selectedGender = genderValue;
              } else {
                selectedGender = '';
              }
            });
          },
          activeColor: AppColors.subColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          side: MaterialStateBorderSide.resolveWith(
            (states) => const BorderSide(color: Colors.grey, width: 1.5),
          ),
        ),
        Text(label),
      ],
    );
  }
}

class DateTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
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
