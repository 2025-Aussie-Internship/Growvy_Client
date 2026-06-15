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

/// (백엔드 interest_id, 표시용 i18n 키, 로그용 영어 라벨) 묶음.
///
/// - [interestId] 는 백엔드 DB seed 의 id 와 1:1. 사용자가 어떤 언어로 보든
///   이 정수만 그대로 서버로 전송되므로 라벨 문자열의 apostrophe/대소문자/
///   공백 차이로 매핑이 깨질 일이 없다.
/// - [i18nKey] 는 화면 표시용. tr() 로 변환된다.
/// - [englishLabel] 은 디버그 로그/캐시 키 용도. 백엔드 매핑에는 사용하지 않는다.
class _InterestOption {
  final int interestId;
  final String i18nKey;
  final String englishLabel;
  const _InterestOption(this.interestId, this.i18nKey, this.englishLabel);
}

class _SeekerInterestPageState extends State<SeekerInterestPage> {
  // 시안 그대로 2열 배치를 위해 좌/우 컬럼을 분리해서 정의한다.
  // 숫자(id) 는 백엔드 DB seed 의 INDUSTRY (1~11) 와 정확히 매칭된다.
  static const List<_InterestOption> _leftColumn = [
    _InterestOption(1, 'interests.hospitality_fb', 'Hospitality & F&B'),
    _InterestOption(3, 'interests.farm_seasonal', 'Farm & Seasonal'),
    _InterestOption(5, 'interests.factory_work', 'Factory Work'),
    _InterestOption(7, 'interests.construction', 'Construction'),
    _InterestOption(9, 'interests.events_festivals', 'Events & Festivals'),
    _InterestOption(11, 'interests.other_jobs', 'Other Jobs'),
  ];
  static const List<_InterestOption> _rightColumn = [
    _InterestOption(2, 'interests.retail_sales', 'Retail & Sales'),
    _InterestOption(4, 'interests.manufacturing', 'Manufacturing'),
    _InterestOption(6, 'interests.cleaning_facilities', 'Cleaning & Facilities'),
    _InterestOption(8, 'interests.logistics_moving', 'Logistics & Moving'),
    _InterestOption(10, 'interests.customer_service', 'Customer Service'),
  ];

  /// 선택된 interest id 집합 (백엔드로 그대로 보낼 값).
  late final Set<int> _selectedIds;

  @override
  void initState() {
    super.initState();
    // 이전 단계에서 이미 선택했던 관심사가 있다면 그대로 prefill.
    _selectedIds = <int>{...Get.find<SignupDataController>().interestIds};
  }

  void _goNext() {
    // industry 분기로 확정. (setInterestIds 내부에서 설문 답변은 비워진다.)
    Get.find<SignupDataController>().setInterestIds(_selectedIds);
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
                  onPressed: _selectedIds.isEmpty ? null : _goNext,
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
    final selected = _selectedIds.contains(option.interestId);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() {
          if (selected) {
            _selectedIds.remove(option.interestId);
          } else {
            _selectedIds.add(option.interestId);
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
