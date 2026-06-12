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

class SeekerCareerPage extends StatefulWidget {
  const SeekerCareerPage({super.key});

  @override
  State<SeekerCareerPage> createState() => _SeekerCareerPageState();
}

class _SeekerCareerPageState extends State<SeekerCareerPage> {
  late final TextEditingController _careerController;
  late final TextEditingController _introController;

  @override
  void initState() {
    super.initState();
    final data = Get.find<SignupDataController>();
    _careerController = TextEditingController(text: data.career ?? '');
    _introController = TextEditingController(text: data.introduction ?? '');
    _careerController.addListener(_onFieldChanged);
    _introController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _careerController.removeListener(_onFieldChanged);
    _introController.removeListener(_onFieldChanged);
    _careerController.dispose();
    _introController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  bool get _isFormValid {
    return _careerController.text.trim().isNotEmpty &&
        _introController.text.trim().isNotEmpty;
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
                controller: _careerController,
                label: '*${'signup.career'.tr()}',
                hintText: 'signup.career_hint'.tr(),
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _introController,
                label: '*${'signup.introduction'.tr()}',
                hintText: 'signup.introduction_hint'.tr(),
              ),

              const SizedBox(height: 48),

              NextButton(
                text: 'common.next'.tr(),
                onPressed: _isFormValid
                    ? () {
                        Get.find<SignupDataController>().setCareerInfo(
                          career: _careerController.text.trim(),
                          introduction: _introController.text.trim(),
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
