import 'package:easy_localization/easy_localization.dart' hide StringTranslateExtension;
import '../../i18n/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import '../../controllers/signup_data_controller.dart';
import '../../styles/colors.dart';
import '../../widgets/next_button.dart';
import 'profile_picker_page.dart';

/// 구직자 회원가입 단계 - 관심사를 모를 때 진행하는 8단계 설문.
///
/// 1) Intro  : "Not sure what to choose? No worries!"
/// 2~7) 6개의 단일선택 질문 (Energy / Environment / Social / Comfort / Goal / Pace)
/// 8) All Done : "Let's Go!" 버튼으로 [ProfilePickerPage] 로 이동
///
/// 모든 단계의 스타일은 회원가입 흐름의 다른 페이지와 같은 분위기로 유지되며
/// (흰 배경, 단순한 < 뒤로가기, 큰 둥근 Next 버튼) 옵션 칩은 가로 가득 채우는
/// pill 형태로 통일한다.
class SeekerSurveyPage extends StatefulWidget {
  const SeekerSurveyPage({super.key});

  @override
  State<SeekerSurveyPage> createState() => _SeekerSurveyPageState();
}

class _SeekerSurveyPageState extends State<SeekerSurveyPage> {
  final PageController _pageController = PageController();
  int _step = 0;

  /// 질문 단계(1..6) 의 답변. key = 질문 인덱스(0..5), value = 선택된 옵션 인덱스.
  final Map<int, int> _answers = <int, int>{};

  static const Color _chipBorder = Color(0xFFE5E5E5);
  static const Color _subtitleGray = Color(0xFF747474);

  // 옵션은 (백엔드 매핑용 영어 라벨, 화면 표시용 i18n 키) 쌍으로 들고 다닌다.
  // - englishLabel 은 SignupDataController._interestIdByLabel 의 키와 1:1.
  // - 화면에는 i18n 키를 tr 로 변환해서 표시한다.
  static const List<_SurveyQuestion> _questions = [
    _SurveyQuestion(
      titleKey: 'signup.survey.q1_title',
      subtitleKey: 'signup.survey.q1_subtitle',
      options: [
        _SurveyOption(
          'I prefer thinking and planning',
          'survey_options.thinking_planning',
        ),
        _SurveyOption(
          'I prefer hands-on, physical work',
          'survey_options.hands_on',
        ),
        _SurveyOption(
          'A mix of both sounds good',
          'survey_options.mix_of_both',
        ),
      ],
    ),
    _SurveyQuestion(
      titleKey: 'signup.survey.q2_title',
      subtitleKey: 'signup.survey.q2_subtitle',
      options: [
        _SurveyOption(
          'Indoors (office, cafe, studio)',
          'survey_options.indoors',
        ),
        _SurveyOption(
          'Outdoors (nature, farm, field)',
          'survey_options.outdoors',
        ),
        _SurveyOption("I'm okay with either", 'survey_options.either_env'),
      ],
    ),
    _SurveyQuestion(
      titleKey: 'signup.survey.q3_title',
      subtitleKey: 'signup.survey.q3_subtitle',
      options: [
        _SurveyOption(
          'I enjoy meeting and talking to people',
          'survey_options.people_oriented',
        ),
        _SurveyOption('I prefer working on my own', 'survey_options.solo'),
        _SurveyOption('A balance of both', 'survey_options.balanced_social'),
      ],
    ),
    _SurveyQuestion(
      titleKey: 'signup.survey.q4_title',
      subtitleKey: 'signup.survey.q4_subtitle',
      options: [
        _SurveyOption(
          'Something new and exciting',
          'survey_options.new_exciting',
        ),
        _SurveyOption(
          'Something familiar and stable',
          'survey_options.familiar_stable',
        ),
        _SurveyOption("I'm open to anything", 'survey_options.open_anything'),
      ],
    ),
    _SurveyQuestion(
      titleKey: 'signup.survey.q5_title',
      subtitleKey: 'signup.survey.q5_subtitle',
      options: [
        _SurveyOption('Earning money', 'survey_options.earn_money'),
        _SurveyOption(
          'Gaining new experiences',
          'survey_options.new_experience',
        ),
        _SurveyOption('Building my career', 'survey_options.build_career'),
        _SurveyOption(
          'Taking a break and recharging',
          'survey_options.recharge',
        ),
      ],
    ),
    _SurveyQuestion(
      titleKey: 'signup.survey.q6_title',
      subtitleKey: 'signup.survey.q6_subtitle',
      options: [
        _SurveyOption('Fast-paced and active', 'survey_options.fast_paced'),
        _SurveyOption('Relaxed and steady', 'survey_options.relaxed_steady'),
        _SurveyOption('Depends on the day', 'survey_options.depends_day'),
      ],
    ),
  ];

  /// 전체 step 수 = Intro(1) + 질문(6) + Done(1)
  int get _totalSteps => _questions.length + 2;

  void _goPrev() {
    if (_step == 0) {
      Navigator.of(context).maybePop();
      return;
    }
    _animateTo(_step - 1);
  }

  void _goNext() {
    if (_step >= _totalSteps - 1) {
      // 마지막 단계 - Let's Go! 핸들러에서 이미 이동.
      return;
    }
    _animateTo(_step + 1);
  }

  void _animateTo(int next) {
    _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
    setState(() => _step = next);
  }

  void _finish() {
    // 설문 답변(qIndex → optIndex) 과 답변 라벨을 함께 컨트롤러에 저장한다.
    // 라벨은 SignupDataController 의 id 매핑 테이블을 거쳐
    // 최종 payload 의 interestIds 배열로 변환된다.
    final labels = <String>[
      for (final entry in _answers.entries)
        _questions[entry.key].options[entry.value].englishLabel,
    ];
    Get.find<SignupDataController>().setSurveyAnswers(
      _answers,
      answerLabels: labels,
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ProfilePickerPage()),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.locale; // setLocale 시 자동 rebuild 보장
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: PageView.builder(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _totalSteps,
          itemBuilder: (context, index) {
            if (index == 0) return _buildIntro();
            if (index == _totalSteps - 1) return _buildDone();
            return _buildQuestion(_questions[index - 1], index - 1);
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
            size: 20,
          ),
          onPressed: _goPrev,
        ),
      ),
    );
  }

  // ---------------- Step 빌더 ----------------

  Widget _buildIntro() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(flex: 3),
          Text(
            'signup.survey.intro_title_1'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'signup.survey.intro_title_2'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'signup.survey.intro_subtitle'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: _subtitleGray,
              height: 1.5,
            ),
          ),
          const Spacer(flex: 2),
          NextButton(text: 'common.next'.tr(), onPressed: _goNext),
          const Spacer(flex: 4),
        ],
      ),
    );
  }

  Widget _buildDone() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(flex: 4),
          Text(
            'signup.survey.done_title'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'signup.survey.done_subtitle'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: _subtitleGray,
              height: 1.5,
            ),
          ),
          const Spacer(flex: 3),
          NextButton(text: 'signup.survey.lets_go'.tr(), onPressed: _finish),
          const Spacer(flex: 4),
        ],
      ),
    );
  }

  Widget _buildQuestion(_SurveyQuestion q, int qIndex) {
    final selected = _answers[qIndex];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          Center(
            child: Text(
              q.titleKey.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              q.subtitleKey.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: _subtitleGray,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 56),
          for (int i = 0; i < q.options.length; i++) ...[
            _buildOption(
              label: q.options[i].i18nKey.tr(),
              selected: selected == i,
              onTap: () => setState(() => _answers[qIndex] = i),
            ),
            if (i != q.options.length - 1) const SizedBox(height: 14),
          ],
          const Spacer(),
          NextButton(
            text: 'common.next'.tr(),
            onPressed: selected == null ? null : _goNext,
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildOption({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.mainColor.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: selected ? AppColors.mainColor : _chipBorder,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: selected ? AppColors.mainColor : _subtitleGray,
          ),
        ),
      ),
    );
  }
}

class _SurveyQuestion {
  final String titleKey;
  final String subtitleKey;
  final List<_SurveyOption> options;
  const _SurveyQuestion({
    required this.titleKey,
    required this.subtitleKey,
    required this.options,
  });
}

class _SurveyOption {
  /// 백엔드 매핑(SignupDataController._interestIdByLabel) 의 키. 절대 번역 X.
  final String englishLabel;

  /// 화면에 표시될 때 tr 로 변환되는 i18n 키.
  final String i18nKey;
  const _SurveyOption(this.englishLabel, this.i18nKey);
}
