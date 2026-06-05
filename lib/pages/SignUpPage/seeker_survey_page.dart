import 'package:flutter/material.dart';
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

  static const List<_SurveyQuestion> _questions = [
    _SurveyQuestion(
      title: 'Energy Style',
      subtitle: '"What kind of work feels more comfortable for you?"',
      options: [
        'I prefer thinking and planning',
        'I prefer hands-on, physical work',
        'A mix of both sounds good',
      ],
    ),
    _SurveyQuestion(
      title: 'Work Environment',
      subtitle: '"Where would you rather work?"',
      options: [
        'Indoors (office, cafe, studio)',
        'Outdoors (nature, farm, field)',
        "I'm okay with either",
      ],
    ),
    _SurveyQuestion(
      title: 'Social Preference',
      subtitle: '"How do you feel about interacting with people at work?"',
      options: [
        'I enjoy meeting and talking to people',
        'I prefer working on my own',
        'A balance of both',
      ],
    ),
    _SurveyQuestion(
      title: 'Comfort Zone',
      subtitle: '"What kind of experience are you looking for?"',
      options: [
        'Something new and exciting',
        'Something familiar and stable',
        "I'm open to anything",
      ],
    ),
    _SurveyQuestion(
      title: 'Main Goal',
      subtitle: '"What matters most to you right now?"',
      options: [
        'Earning money',
        'Gaining new experiences',
        'Building my career',
        'Taking a break and recharging',
      ],
    ),
    _SurveyQuestion(
      title: 'Work Pace / Lifestyle',
      subtitle: '"What kind of daily pace do you prefer?"',
      options: [
        'Fast-paced and active',
        'Relaxed and steady',
        'Depends on the day',
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
          const Text(
            'Not sure what to choose?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'No worries!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Answer a few quick questions and\nwe\u2019ll find something that fits you.\u201D',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: _subtitleGray,
              height: 1.5,
            ),
          ),
          const Spacer(flex: 2),
          NextButton(text: 'Next', onPressed: _goNext),
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
          const Text(
            'All Done!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Now let\u2019s look what kind of experience\nwe found it just for you',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: _subtitleGray,
              height: 1.5,
            ),
          ),
          const Spacer(flex: 3),
          NextButton(text: "Let's Go!", onPressed: _finish),
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
              q.title,
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
              q.subtitle,
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
              label: q.options[i],
              selected: selected == i,
              onTap: () => setState(() => _answers[qIndex] = i),
            ),
            if (i != q.options.length - 1) const SizedBox(height: 14),
          ],
          const Spacer(),
          NextButton(
            text: 'Next',
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
  final String title;
  final String subtitle;
  final List<String> options;
  const _SurveyQuestion({
    required this.title,
    required this.subtitle,
    required this.options,
  });
}
