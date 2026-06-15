import 'package:easy_localization/easy_localization.dart' hide StringTranslateExtension;
import '../../i18n/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import '../../controllers/signup_data_controller.dart';
import '../../styles/colors.dart';
import '../../widgets/next_button.dart';
import 'seeker_career_page.dart';

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

  // 옵션은 (백엔드 interest_id, 표시용 i18n 키, 디버그 라벨) 묶음으로 들고 다닌다.
  // id 는 백엔드 DB seed (ENERGY_STYLE 12~14, WORK_ENVIRONMENT 15~17,
  // SOCIAL_PREFERENCE 18~20, COMFORT_ZONE 21~23, MAIN_GOAL 24~27, WORK_PACE 28~30)
  // 와 정확히 1:1. 라벨 문자열 변경/번역과 무관하게 백엔드 매핑이 유지된다.
  static const List<_SurveyQuestion> _questions = [
    _SurveyQuestion(
      titleKey: 'signup.survey.q1_title',
      subtitleKey: 'signup.survey.q1_subtitle',
      options: [
        _SurveyOption(
          12,
          'survey_options.thinking_planning',
          'I prefer thinking and planning',
        ),
        _SurveyOption(
          13,
          'survey_options.hands_on',
          'I prefer hands-on, physical work',
        ),
        _SurveyOption(
          14,
          'survey_options.mix_of_both',
          'A mix of both sounds good',
        ),
      ],
    ),
    _SurveyQuestion(
      titleKey: 'signup.survey.q2_title',
      subtitleKey: 'signup.survey.q2_subtitle',
      options: [
        _SurveyOption(
          15,
          'survey_options.indoors',
          'Indoors (office, cafe, studio)',
        ),
        _SurveyOption(
          16,
          'survey_options.outdoors',
          'Outdoors (nature, farm, field)',
        ),
        _SurveyOption(
          17,
          'survey_options.either_env',
          "I'm okay with either",
        ),
      ],
    ),
    _SurveyQuestion(
      titleKey: 'signup.survey.q3_title',
      subtitleKey: 'signup.survey.q3_subtitle',
      options: [
        _SurveyOption(
          18,
          'survey_options.people_oriented',
          'I enjoy meeting and talking to people',
        ),
        _SurveyOption(
          19,
          'survey_options.solo',
          'I prefer working on my own',
        ),
        _SurveyOption(
          20,
          'survey_options.balanced_social',
          'A balance of both',
        ),
      ],
    ),
    _SurveyQuestion(
      titleKey: 'signup.survey.q4_title',
      subtitleKey: 'signup.survey.q4_subtitle',
      options: [
        _SurveyOption(
          21,
          'survey_options.new_exciting',
          'Something new and exciting',
        ),
        _SurveyOption(
          22,
          'survey_options.familiar_stable',
          'Something familiar and stable',
        ),
        _SurveyOption(
          23,
          'survey_options.open_anything',
          "I'm open to anything",
        ),
      ],
    ),
    _SurveyQuestion(
      titleKey: 'signup.survey.q5_title',
      subtitleKey: 'signup.survey.q5_subtitle',
      options: [
        _SurveyOption(
          24,
          'survey_options.earn_money',
          'Earning money',
        ),
        _SurveyOption(
          25,
          'survey_options.new_experience',
          'Gaining new experiences',
        ),
        _SurveyOption(
          26,
          'survey_options.build_career',
          'Building my career',
        ),
        _SurveyOption(
          27,
          'survey_options.recharge',
          'Taking a break and recharging',
        ),
      ],
    ),
    _SurveyQuestion(
      titleKey: 'signup.survey.q6_title',
      subtitleKey: 'signup.survey.q6_subtitle',
      options: [
        _SurveyOption(
          28,
          'survey_options.fast_paced',
          'Fast-paced and active',
        ),
        _SurveyOption(
          29,
          'survey_options.relaxed_steady',
          'Relaxed and steady',
        ),
        _SurveyOption(
          30,
          'survey_options.depends_day',
          'Depends on the day',
        ),
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
    // 각 질문의 선택된 옵션을 백엔드 interest_id 로 곧장 변환해서 저장.
    // 라벨 문자열을 거치지 않으므로 apostrophe / 공백 / 번역 차이로
    // 매핑이 깨질 일이 없다.
    final ids = <int>[
      for (final entry in _answers.entries)
        _questions[entry.key].options[entry.value].interestId,
    ];
    Get.find<SignupDataController>().setSurveyAnswerIds(
      _answers,
      interestIds: ids,
    );
    // 설문이 끝나면 곧장 프로필이 아니라, 커리어 / 한 줄 소개를 받는
    // SeekerCareerPage 를 거친 뒤 프로필 선택으로 이어진다.
    // (interest 분기와 동일한 흐름을 맞춰서, 결국 어느 분기로 들어와도
    //  career / bio 가 누락되지 않게 보장.)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SeekerCareerPage()),
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
  /// 백엔드 DB seed 의 interest id. 백엔드로는 이 정수만 전달된다.
  final int interestId;

  /// 화면에 표시될 때 tr 로 변환되는 i18n 키.
  final String i18nKey;

  /// 디버그 로그 / 캐시 키 용 영어 라벨. 백엔드 매핑에는 사용 X.
  final String englishLabel;
  const _SurveyOption(this.interestId, this.i18nKey, this.englishLabel);
}
