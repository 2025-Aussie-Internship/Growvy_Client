import 'package:easy_localization/easy_localization.dart' hide StringTranslateExtension;
import '../../i18n/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import '../../controllers/signup_data_controller.dart';
import '../../styles/colors.dart';
import '../../widgets/next_button.dart';
import '../../widgets/signin_app_bar.dart';
import 'seeker_career_page.dart';
import 'seeker_survey_page.dart';

/// 구직자 회원가입 단계 - 관심 직군 선택.
///
/// 시안: 상단에 "About you" 타이틀과 "Choose your interests" 부제,
/// 그 아래로 두 줄에 걸쳐 둥근 pill 형태의 칩들이 배치된다.
/// 선택된 칩은 mainColor 배경(투명도 적용) + mainColor 테두리 + mainColor 텍스트로 강조되고,
/// 하단에 Next 버튼과 "I don't know what I want to do.." 링크가 있다.
/// 관심사 선택은 필수가 아니며, 비선택 상태에서도 Next 로 다음 단계로 진행할 수 있다.
class SeekerInterestPage extends StatefulWidget {
  const SeekerInterestPage({super.key});

  @override
  State<SeekerInterestPage> createState() => _SeekerInterestPageState();
}

/// (백엔드에 전송되는 영어 라벨, 화면에 표시되는 i18n 키) 쌍.
/// - [englishLabel] 은 [SignupDataController._interestIdByLabel] 의 키와 1:1.
///   사용자가 어떤 언어로 보든 이 값으로 저장되어야 백엔드 매핑이 깨지지 않는다.
/// - [i18nKey] 는 화면에 표시될 때 [tr] 로 변환된다.
class _InterestOption {
  final String englishLabel;
  final String i18nKey;
  const _InterestOption(this.englishLabel, this.i18nKey);
}

class _SeekerInterestPageState extends State<SeekerInterestPage> {
  // 시안 그대로 2열 배치를 위해 좌/우 컬럼을 분리해서 정의한다.
  static const List<_InterestOption> _leftColumn = [
    _InterestOption('Hospitality & F&B', 'interests.hospitality_fb'),
    _InterestOption('Farm & Seasonal', 'interests.farm_seasonal'),
    _InterestOption('Factory Work', 'interests.factory_work'),
    _InterestOption('Construction', 'interests.construction'),
    _InterestOption('Events & Festivals', 'interests.events_festivals'),
    _InterestOption('Other Jobs', 'interests.other_jobs'),
  ];
  static const List<_InterestOption> _rightColumn = [
    _InterestOption('Retail & Sales', 'interests.retail_sales'),
    _InterestOption('Manufacturing', 'interests.manufacturing'),
    _InterestOption('Cleaning & Facilities', 'interests.cleaning_facilities'),
    _InterestOption('Logistics & Moving', 'interests.logistics_moving'),
    _InterestOption('Customer Service', 'interests.customer_service'),
  ];

  late final Set<String> _selected;

  @override
  void initState() {
    super.initState();
    // 이전 단계에서 이미 선택했던 관심사가 있다면 그대로 prefill.
    _selected = <String>{...Get.find<SignupDataController>().interests};
  }

  void _goNext() {
    // industry 분기로 확정. (setInterests 내부에서 설문 답변은 비워진다.)
    Get.find<SignupDataController>().setInterests(_selected);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SeekerCareerPage()),
    );
  }

  /// "I don't know what I want to do..." 링크 → 8단계 설문 페이지로 이동.
  /// 설문 분기로 빠지므로 그동안 골라 둔 industry 선택은 폐기한다.
  void _openSurvey() {
    Get.find<SignupDataController>().clearInterests();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SeekerSurveyPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.locale; // setLocale 시 자동 rebuild 보장
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const SignInAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Text(
                'signup.interest_title'.tr(),
                style: const TextStyle(
                  color: AppColors.mainColor,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'signup.interest_subtitle'.tr(),
                style: const TextStyle(
                  color: Color(0xFF747474),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 28),
              _buildInterestGrid(),
              const SizedBox(height: 36),
              Center(
                child: NextButton(
                  text: 'common.next'.tr(),
                  // 칩을 하나도 안 골랐으면 비활성. 관심사가 정말 없는 사용자는
                  // 아래 "I don't know what I want to do.." 링크로 설문 우회.
                  onPressed: _selected.isEmpty ? null : _goNext,
                ),
              ),
              const SizedBox(height: 64),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _openSurvey,
                child: Text(
                  'signup.interest_not_sure'.tr(),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF747474),
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0xFF747474),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// 시안과 동일하게 좌/우 두 컬럼으로 칩들을 배치한다.
  /// 좌측 컬럼이 1개 더 많아 마지막 줄에는 좌측 칩만 보인다.
  Widget _buildInterestGrid() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildChipColumn(_leftColumn),
        const SizedBox(width: 16),
        _buildChipColumn(_rightColumn),
      ],
    );
  }

  Widget _buildChipColumn(List<_InterestOption> items) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < items.length; i++) ...[
          if (i != 0) const SizedBox(height: 10),
          _buildChip(items[i]),
        ],
      ],
    );
  }

  Widget _buildChip(_InterestOption option) {
    final selected = _selected.contains(option.englishLabel);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() {
          if (selected) {
            _selected.remove(option.englishLabel);
          } else {
            _selected.add(option.englishLabel);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        width: 134.5,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.mainColor.withValues(alpha: 0.12)
              : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? AppColors.mainColor : const Color(0xFFE5E5E5),
          ),
        ),
        child: Text(
          option.i18nKey.tr(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: selected ? AppColors.mainColor : const Color(0xFF747474),
          ),
        ),
      ),
    );
  }
}
