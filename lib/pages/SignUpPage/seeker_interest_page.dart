import 'package:flutter/material.dart';
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

class _SeekerInterestPageState extends State<SeekerInterestPage> {
  // 시안 그대로 2열 배치를 위해 좌/우 컬럼을 분리해서 정의한다.
  static const List<String> _leftColumn = [
    'Hospitality & F&B',
    'Farm & Seasonal',
    'Factory Work',
    'Construction',
    'Events & Festivals',
    'Other Jobs',
  ];
  static const List<String> _rightColumn = [
    'Retail & Sales',
    'Manufacturing',
    'Cleaning & Facilities',
    'Logistics & Moving',
    'Customer Service',
  ];

  final Set<String> _selected = <String>{};

  void _goNext() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SeekerCareerPage()),
    );
  }

  /// "I don't know what I want to do.." 링크 → 8단계 설문 페이지로 이동.
  void _openSurvey() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SeekerSurveyPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              const Text(
                'About you',
                style: TextStyle(
                  color: AppColors.mainColor,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Choose your interests',
                style: TextStyle(
                  color: Color(0xFF747474),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 28),
              _buildInterestGrid(),
              const SizedBox(height: 36),
              Center(
                child: NextButton(text: 'Next', onPressed: _goNext),
              ),
              const SizedBox(height: 64),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _openSurvey,
                child: const Text(
                  "I don't know what I want to do...",
                  style: TextStyle(
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

  Widget _buildChipColumn(List<String> items) {
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

  Widget _buildChip(String label) {
    final selected = _selected.contains(label);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() {
          if (selected) {
            _selected.remove(label);
          } else {
            _selected.add(label);
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
          label,
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
