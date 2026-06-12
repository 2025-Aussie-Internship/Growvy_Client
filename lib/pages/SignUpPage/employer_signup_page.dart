import 'package:easy_localization/easy_localization.dart' hide StringTranslateExtension;
import '../../i18n/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import '../../controllers/signup_data_controller.dart';
import '../../styles/colors.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/next_button.dart';
import '../../widgets/signin_app_bar.dart';
import 'profile_picker_page.dart';

class EmployerSignupPage extends StatefulWidget {
  const EmployerSignupPage({super.key});

  @override
  State<EmployerSignupPage> createState() => _EmployerSignupPageState();
}

class _EmployerSignupPageState extends State<EmployerSignupPage> {
  late final TextEditingController _companyNameController;
  late final TextEditingController _businessAddressController;
  bool isSoleProprietorship = false;

  @override
  void initState() {
    super.initState();
    final data = Get.find<SignupDataController>();
    _companyNameController = TextEditingController(
      text: data.companyName ?? '',
    );
    _businessAddressController = TextEditingController(
      text: data.businessAddress ?? '',
    );
    isSoleProprietorship = data.isSoleProprietorship ?? false;
    _companyNameController.addListener(_onFieldChanged);
    _businessAddressController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _companyNameController.removeListener(_onFieldChanged);
    _businessAddressController.removeListener(_onFieldChanged);
    _companyNameController.dispose();
    _businessAddressController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  bool get _isFormValid {
    return _companyNameController.text.trim().isNotEmpty &&
        _businessAddressController.text.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    context.locale; // setLocale 시 자동 rebuild 보장
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const SignInAppBar(),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 36.0),
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
              const SizedBox(height: 40),

              CustomTextField(
                controller: _companyNameController,
                label: '*${'signup.company_name'.tr()}',
                hintText: 'signup.company_name_hint'.tr(),
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
                      (states) =>
                          const BorderSide(color: Colors.grey, width: 1.5),
                    ),
                  ),
                  Text('signup.sole_proprietorship'.tr()),
                ],
              ),
              const SizedBox(height: 7),

              CustomTextField(
                controller: _businessAddressController,
                label: '*${'signup.business_address'.tr()}',
                hintText: 'signup.business_address_hint'.tr(),
              ),

              const SizedBox(height: 24),

              NextButton(
                text: 'common.next'.tr(),
                onPressed: _isFormValid
                    ? () {
                        Get.find<SignupDataController>().setEmployerInfo(
                          companyName: _companyNameController.text.trim(),
                          isSoleProprietorship: isSoleProprietorship,
                          businessAddress:
                              _businessAddressController.text.trim(),
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfilePickerPage(),
                          ),
                        );
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
}
