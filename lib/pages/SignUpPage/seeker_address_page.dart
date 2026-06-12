import 'package:easy_localization/easy_localization.dart' hide StringTranslateExtension;
import '../../i18n/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import '../../controllers/signup_data_controller.dart';
import '../../styles/colors.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/next_button.dart';
import '../../widgets/signin_app_bar.dart';
import 'seeker_interest_page.dart';

class SeekerAddressPage extends StatefulWidget {
  const SeekerAddressPage({super.key});

  @override
  State<SeekerAddressPage> createState() => _SeekerAddressPageState();
}

class _SeekerAddressPageState extends State<SeekerAddressPage> {
  late final TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(
      text: Get.find<SignupDataController>().homeAddress ?? '',
    );
    _addressController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _addressController.removeListener(_onFieldChanged);
    _addressController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  bool get _isFormValid => _addressController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    context.locale; // setLocale 시 자동 rebuild 보장
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
                controller: _addressController,
                label: '*${'signup.home_address'.tr()}',
                hintText: 'signup.home_address_hint'.tr(),
              ),

              const SizedBox(height: 24),

              NextButton(
                text: 'common.next'.tr(),
                onPressed: _isFormValid
                    ? () {
                        Get.find<SignupDataController>().setHomeAddress(
                          _addressController.text.trim(),
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SeekerInterestPage(),
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
