import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../models/job_shift.dart';
import '../../styles/colors.dart';
import '../../utils/auto_localize.dart';
import '../../widgets/auto_translate_text.dart';
import '../MainPage/job_detail_page.dart';

/// 구인자가 새로운 공고를 작성하기 위한 다단계 입력 페이지.
///
/// 우측 하단의 토글 버튼을 누르면 5개 스텝 메뉴(Basic Info, Job Details,
/// Pay & Benefits, Application Settings, Publish)가 우측에서 펼쳐진다.
/// 메뉴 항목을 누르면 해당 스텝으로 본문이 전환되며, 현재 스텝은 mainColor로 표시된다.
class StartHiringPage extends StatefulWidget {
  const StartHiringPage({super.key});

  @override
  State<StartHiringPage> createState() => _StartHiringPageState();
}

class _StartHiringPageState extends State<StartHiringPage> {
  static const Color _labelGray = Color(0xFFBDBDBD);
  static const Color _underlineGray = Color(0xFFE5E5E5);

  static const List<Map<String, String>> _steps = [
    {'label': 'Basic Info', 'icon': 'assets/icon/basicinfo_icon.svg'},
    {'label': 'Job Details', 'icon': 'assets/icon/jobdetail_icon.svg'},
    {'label': 'Pay &\nBenefits', 'icon': 'assets/icon/salary_icon.svg'},
    {'label': 'Application\nSettings', 'icon': 'assets/icon/settings_icon.svg'},
    {'label': 'Publish', 'icon': 'assets/icon/publish_icon.svg'},
  ];

  static const List<String> _employmentTypes = [
    'Casual',
    'Part-time',
    'Full-time',
    'Contract',
    'Temporary',
  ];

  static const List<String> _industries = [
    'Hospitality & F&B',
    'Retail & Sales',
    'Farm & Seasonal',
    'Manufacturing',
    'Factory Work',
    'Cleaning & Facilities',
    'Construction',
    'Logistics & Moving',
    'Events & Festivals',
    'Customer Service',
    'Other Jobs',
  ];

  static const List<String> _weekDays = [
    'SUN',
    'MON',
    'TUE',
    'WED',
    'THU',
    'FRI',
    'SAT',
  ];

  static const List<String> _fullDayNames = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  static const List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const List<String> _superannuationOptions = [
    'Paid separately',
    'Included in rate',
  ];

  int _currentStep = 0;
  bool _menuOpen = false;

  /// (과거에는 입력이 완료되면 다음 단계로 자동 진행했지만,
  ///  사용자가 자기 페이스로 우측 step 메뉴를 눌러 이동하도록 자동 진행은 비활성화.
  ///  남겨둔 set 은 호환을 위해 유지하지만 더 이상 채워지지 않는다.)
  final Set<int> _autoAdvancedSteps = {};

  // Basic Info
  final TextEditingController _jobTitleController = TextEditingController();
  String? _employmentType;
  final Set<String> _selectedIndustries = <String>{};

  // Job Details
  final TextEditingController _responsibilitiesController =
      TextEditingController();
  final TextEditingController _shiftDetailsController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _peopleCountController = TextEditingController();
  final Set<int> _selectedDayIndices = {0};
  // 요일별 시간 저장. 키는 0~6 (Sun~Sat).
  final Map<int, _TimeRange> _dayTimes = {
    0: const _TimeRange(
      from: TimeOfDay(hour: 9, minute: 0),
      to: TimeOfDay(hour: 12, minute: 0),
    ),
  };

  static const _TimeRange _defaultRange = _TimeRange(
    from: TimeOfDay(hour: 9, minute: 0),
    to: TimeOfDay(hour: 12, minute: 0),
  );

  // Pay & Benefits
  final TextEditingController _hourlyRateController = TextEditingController();
  final TextEditingController _penaltyRateController = TextEditingController();
  String? _superannuation;

  // Application Settings
  DateTime _calendarMonth = DateTime(2026, 2, 1);
  DateTime? _selectedDate = DateTime(2026, 2, 19);

  @override
  void initState() {
    super.initState();
    // 자동 진행을 비활성화했으므로 컨트롤러 listener 등록도 필요 없다.
  }

  @override
  void dispose() {
    _jobTitleController.dispose();
    _responsibilitiesController.dispose();
    _shiftDetailsController.dispose();
    _dateController.dispose();
    _peopleCountController.dispose();
    _hourlyRateController.dispose();
    _penaltyRateController.dispose();
    super.dispose();
  }

  bool _isStepComplete(int step) {
    switch (step) {
      case 0: // Basic Info
        return _jobTitleController.text.trim().isNotEmpty &&
            _employmentType != null &&
            _selectedIndustries.isNotEmpty;
      case 1: // Job Details
        return _responsibilitiesController.text.trim().isNotEmpty &&
            _shiftDetailsController.text.trim().isNotEmpty &&
            _dateController.text.trim().isNotEmpty &&
            _peopleCountController.text.trim().isNotEmpty &&
            _selectedDayIndices.isNotEmpty;
      case 2: // Pay & Benefits
        return _hourlyRateController.text.trim().isNotEmpty &&
            _penaltyRateController.text.trim().isNotEmpty &&
            _superannuation != null;
      case 3: // Application Settings
        return _selectedDate != null;
      default:
        return false;
    }
  }

  /// 자동 진행 비활성화: 사용자가 우측 step 메뉴를 직접 눌러 다음 단계로
  /// 이동하도록 한다. 기존 호출처(`onTap` 등)는 그대로 두지만 no-op 으로 작동.
  void _maybeAdvance() {}

  void _onBackPressed() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.maybePop(context);
    }
  }

  /// 현재 단계에 해당하는 본문 위젯을 반환한다. AnimatedSwitcher 의 child 로 사용된다.
  Widget _buildStepBody() {
    switch (_currentStep) {
      case 0:
        return _buildBasicInfo();
      case 1:
        return _buildJobDetails();
      case 2:
        return _buildPayBenefits();
      case 3:
        return _buildApplicationSettings();
      case 4:
        return _buildPublish();
      default:
        return _buildBasicInfo();
    }
  }

  /// Publish 버튼 핸들러.
  ///
  /// - 0~3 단계 중 필수값이 비어있는 첫 단계가 있으면 그 단계로 되돌아간다.
  /// - 모두 채워졌으면 입력값을 [JobDetailPage] 로 전달하면서 화면을 교체한다.
  ///   ([Navigator.pushReplacement] 로 작성 페이지를 스택에서 제거하므로,
  ///   상세 페이지의 뒤로가기 시 곧바로 MainPage 로 돌아간다.)
  void _onPublishPressed() {
    for (int i = 0; i < _steps.length - 1; i++) {
      if (!_isStepComplete(i)) {
        setState(() {
          _currentStep = i;
          _menuOpen = false;
          _autoAdvancedSteps.remove(i);
        });
        final stepLabel = _steps[i]['label']!.replaceAll('\n', ' ');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 2),
            backgroundColor: AppColors.mainColor,
            content: Text(
              autoLocalize(context, 'Please complete "$stepLabel" first.'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
        return;
      }
    }

    final tags = <String>[?_employmentType, ..._selectedIndustries];

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => JobDetailPage(
          title: _jobTitleController.text.trim(),
          companyName: '',
          description: _responsibilitiesController.text.trim(),
          tags: tags,
          scheduleDate: _dateController.text.trim(),
          scheduleShifts: _buildShiftList(),
          location: '',
          payText: _buildPayText(),
          openingsText: _buildOpeningsText(),
          // 본인이 방금 작성/게시한 공고이므로 상단 우측에 수정/삭제 아이콘 노출.
          isOwner: true,
        ),
      ),
    );
  }

  /// 작성한 요일별 시간을 [JobShift] 리스트로 변환. JobDetailPage 의 시계
  /// 영역이 이 리스트를 펼쳐서 SUN~SAT 같은 행으로 보여준다.
  List<JobShift> _buildShiftList() {
    final indices = _selectedDayIndices.toList()..sort();
    return [
      for (final i in indices)
        JobShift(
          dayIndex: i,
          from: (_dayTimes[i] ?? _defaultRange).from,
          to: (_dayTimes[i] ?? _defaultRange).to,
        ),
    ];
  }

  String _buildPayText() {
    final rate = _hourlyRateController.text.trim();
    if (rate.isEmpty) return '';
    return '\$$rate per hour';
  }

  String _buildOpeningsText() {
    final count = _peopleCountController.text.trim();
    if (count.isEmpty) return '';
    final isOne = count == '1';
    return '$count ${isOne ? 'opening' : 'openings'}.';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentStep == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_currentStep > 0) {
          setState(() => _currentStep--);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.white,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.black,
              size: 20,
            ),
            onPressed: _onBackPressed,
          ),
          title: const AutoTranslateText(
            'Start Hiring',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  final slideIn = Tween<Offset>(
                    begin: const Offset(0, 0.04),
                    end: Offset.zero,
                  ).animate(animation);
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(position: slideIn, child: child),
                  );
                },
                layoutBuilder: (current, previous) {
                  return Stack(
                    alignment: Alignment.topCenter,
                    children: [...previous, ?current],
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey<int>(_currentStep),
                  child: _buildStepBody(),
                ),
              ),
            ),
            Positioned(right: 16, bottom: 90, child: _buildStepMenuArea()),
          ],
        ),
      ),
    );
  }

  // ---------------- 1) Basic Info ----------------
  Widget _buildBasicInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('Job Title'),
          _buildUnderlineField(
            controller: _jobTitleController,
            hintText: 'Enter the Job Title',
          ),
          const SizedBox(height: 16),
          _buildLabel('Employment Type'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _employmentTypes.map((type) {
              return _buildChoiceChip(
                label: type,
                selected: _employmentType == type,
                onTap: () {
                  setState(() => _employmentType = type);
                  _maybeAdvance();
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          _buildLabel('Industry'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _industries.map((item) {
              final isSelected = _selectedIndustries.contains(item);
              return _buildChoiceChip(
                label: item,
                selected: isSelected,
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedIndustries.remove(item);
                    } else {
                      _selectedIndustries.add(item);
                    }
                  });
                  _maybeAdvance();
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ---------------- 2) Job Details ----------------
  Widget _buildJobDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('Responsibilities'),
          _buildUnderlineField(
            controller: _responsibilitiesController,
            hintText: 'Write the Job Title',
          ),
          const SizedBox(height: 16),
          _buildLabel('Shift Details'),
          _buildUnderlineField(
            controller: _shiftDetailsController,
            hintText: 'Write the Job Title',
          ),
          const SizedBox(height: 16),
          _buildLabel('Date'),
          _buildUnderlineField(
            controller: _dateController,
            hintText: 'DD/MM/YYYY - DD/MM/YYYY',
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _DateRangeInputFormatter(),
            ],
          ),
          const SizedBox(height: 16),
          _buildLabel('Number of people'),
          _buildUnderlineField(
            controller: _peopleCountController,
            hintText: 'At least one person',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 16),
          _buildLabel('Day of the Week'),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_weekDays.length, (index) {
              final isSelected = _selectedDayIndices.contains(index);
              return _buildDayChip(
                label: _weekDays[index],
                selected: isSelected,
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedDayIndices.remove(index);
                      _dayTimes.remove(index);
                    } else {
                      _selectedDayIndices.add(index);
                      _dayTimes.putIfAbsent(index, () => _defaultRange);
                    }
                  });
                  _maybeAdvance();
                },
              );
            }),
          ),
          const SizedBox(height: 16),
          _buildLabel('Time'),
          const SizedBox(height: 8),
          ...(_selectedDayIndices.toList()..sort()).map(
            (dayIndex) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildTimeCard(dayIndex),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- 3) Pay & Benefits ----------------
  Widget _buildPayBenefits() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('Hourly Rate'),
          _buildUnderlineField(
            controller: _hourlyRateController,
            hintText: '0000.00',
            prefixText: '\$ ',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [_DecimalAmountFormatter()],
          ),
          const SizedBox(height: 16),
          _buildLabel('Penalty Rates'),
          _buildUnderlineField(
            controller: _penaltyRateController,
            hintText: '0000.00',
            prefixText: '\$ ',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [_DecimalAmountFormatter()],
          ),
          const SizedBox(height: 16),
          _buildLabel('Superannuation'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _superannuationOptions.map((option) {
              return _buildChoiceChip(
                label: option,
                selected: _superannuation == option,
                onTap: () {
                  setState(() => _superannuation = option);
                  _maybeAdvance();
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ---------------- 4) Application Settings ----------------
  Widget _buildApplicationSettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('Application Deadline'),
          const SizedBox(height: 8),
          Row(
            children: [
              const AutoTranslateText(
                'When is the Application Deadline?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF747474),
                ),
              ),
              const SizedBox(width: 2),
              const Text(
                '*',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.mainColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCalendarIconBox(),
          const SizedBox(height: 12),
          _buildCalendarCard(),
        ],
      ),
    );
  }

  // ---------------- 5) Publish ----------------
  Widget _buildPublish() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AutoTranslateText(
              'Ready To Start Hiring?',
              style: TextStyle(
                fontFamily: 'Paperlogy',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.mainColor,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 294,
              height: 51,
              child: ElevatedButton(
                onPressed: _onPublishPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mainColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                child: const AutoTranslateText(
                  'Publish',
                  style: TextStyle(
                    fontFamily: 'Paperlogy',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- Common pieces ----------------
  Widget _buildLabel(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AutoTranslateText(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(width: 2),
        const Text(
          '*',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.mainColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildUnderlineField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? prefixText,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(fontSize: 14, color: Colors.black),
      decoration: InputDecoration(
        hintText: autoLocalize(context, hintText),
        hintStyle: const TextStyle(color: _labelGray, fontSize: 14),
        prefixText: prefixText,
        prefixStyle: const TextStyle(color: Colors.black, fontSize: 14),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.mainColor, width: 1),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.mainColor, width: 1.2),
        ),
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.mainColor, width: 1),
        ),
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(200),
          border: Border.all(
            color: selected ? AppColors.mainColor : _underlineGray,
          ),
        ),
        child: AutoTranslateText(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected ? AppColors.mainColor : _labelGray,
          ),
        ),
      ),
    );
  }

  Widget _buildDayChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: selected ? const Color(0x1AFC6340) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.mainColor : _underlineGray,
          ),
        ),
        child: Center(
          child: AutoTranslateText(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.mainColor : _labelGray,
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- Time card ----------------
  Widget _buildTimeCard(int dayIndex) {
    final dayLabel = _fullDayNames[dayIndex];
    final range = _dayTimes[dayIndex] ?? _defaultRange;
    return Container(
      width: 238,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _underlineGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AutoTranslateText(
            dayLabel,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AutoTranslateText(
                    'From',
                    style: TextStyle(fontSize: 12, color: _labelGray),
                  ),
                  const SizedBox(width: 4),
                  _buildTimePill(
                    _formatTime(range.from),
                    onTap: () => _pickTime(dayIndex, true),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AutoTranslateText(
                    'To',
                    style: TextStyle(fontSize: 12, color: _labelGray),
                  ),
                  const SizedBox(width: 4),
                  _buildTimePill(
                    _formatTime(range.to),
                    onTap: () => _pickTime(dayIndex, false),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimePill(String label, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 68,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _underlineGray),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickTime(int dayIndex, bool isFrom) async {
    final current = _dayTimes[dayIndex] ?? _defaultRange;
    final initial = isFrom ? current.from : current.to;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        final base = Theme.of(context);
        return Theme(
          data: base.copyWith(
            colorScheme: base.colorScheme.copyWith(
              primary: AppColors.mainColor,
              onPrimary: Colors.white,
              secondary: AppColors.mainColor,
              onSecondary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              hourMinuteTextColor: Colors.black,
              hourMinuteColor: const Color(0xFFF5F5F5),
              hourMinuteTextStyle: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w600,
              ),
              dayPeriodTextColor: Colors.black,
              dayPeriodColor: const Color(0xFFFFF1ED),
              dialHandColor: AppColors.mainColor,
              dialBackgroundColor: const Color(0xFFFFF1ED),
              dialTextColor: Colors.black,
              entryModeIconColor: AppColors.mainColor,
              helpTextStyle: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppColors.mainColor),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dayTimes[dayIndex] = isFrom
            ? _TimeRange(from: picked, to: current.to)
            : _TimeRange(from: current.from, to: picked);
      });
    }
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  // ---------------- Calendar (Application Settings) ----------------
  Widget _buildCalendarIconBox() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _underlineGray),
      ),
      child: const Icon(
        Icons.calendar_today_outlined,
        size: 18,
        color: _labelGray,
      ),
    );
  }

  Widget _buildCalendarCard() {
    final year = _calendarMonth.year;
    final month = _calendarMonth.month;
    final selected = _selectedDate;
    final selectedHeader = selected != null
        ? '${_monthNames[selected.month - 1]} ${_ordinal(selected.day)}'
        : '';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _underlineGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            selectedHeader,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildCalendarPill(
                label: '$year',
                onTap: _pickYear,
                withIcon: true,
              ),
              const SizedBox(width: 8),
              _buildCalendarPill(
                label: _monthNames[month - 1],
                onTap: _pickMonth,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildWeekHeader(),
          const SizedBox(height: 4),
          _buildDayGrid(year, month),
        ],
      ),
    );
  }

  Widget _buildCalendarPill({
    required String label,
    required VoidCallback onTap,
    bool withIcon = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (withIcon) ...[
              const Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: Colors.black,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: Colors.black,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekHeader() {
    const labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return Row(
      children: labels
          .map(
            (l) => Expanded(
              child: Center(
                child: AutoTranslateText(
                  l,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildDayGrid(int year, int month) {
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7; // Sun=0, Mon=1, ... Sat=6
    final prevMonthLastDay = DateTime(year, month, 0).day;

    final cells = <_DayCell>[];
    // 이전 달 꼬리
    for (int i = startWeekday - 1; i >= 0; i--) {
      cells.add(_DayCell(prevMonthLastDay - i, true));
    }
    // 이번 달
    for (int i = 1; i <= daysInMonth; i++) {
      cells.add(_DayCell(i, false));
    }
    // 다음 달 머리 (한 주 마무리 + 마지막 줄까지 채우기)
    int next = 1;
    while (cells.length % 7 != 0) {
      cells.add(_DayCell(next++, true));
    }

    final rows = <Widget>[];
    for (int i = 0; i < cells.length; i += 7) {
      final week = cells.sublist(i, i + 7);
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: week
                .map((c) => Expanded(child: _buildDayCell(c, year, month)))
                .toList(),
          ),
        ),
      );
    }
    return Column(children: rows);
  }

  Widget _buildDayCell(_DayCell cell, int year, int month) {
    final selected = _selectedDate;
    final isSelected =
        !cell.isOtherMonth &&
        selected != null &&
        selected.year == year &&
        selected.month == month &&
        selected.day == cell.day;
    final textColor = cell.isOtherMonth
        ? const Color(0xFFD1D1D1)
        : Colors.black;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: cell.isOtherMonth
          ? null
          : () {
              setState(() {
                _selectedDate = DateTime(year, month, cell.day);
              });
              _maybeAdvance();
            },
      child: SizedBox(
        height: 32,
        child: Center(
          child: Container(
            width: 28,
            height: 28,
            decoration: isSelected
                ? const BoxDecoration(
                    color: AppColors.mainColor,
                    shape: BoxShape.circle,
                  )
                : null,
            alignment: Alignment.center,
            child: Text(
              '${cell.day}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Colors.white : textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickYear() async {
    final now = DateTime.now();
    final years = List<int>.generate(11, (i) => now.year - 5 + i);
    final picked = await _showSimplePicker<int>(
      items: years,
      itemBuilder: (y) => '$y',
      initial: _calendarMonth.year,
    );
    if (picked != null) {
      setState(() {
        _calendarMonth = DateTime(picked, _calendarMonth.month, 1);
      });
    }
  }

  Future<void> _pickMonth() async {
    final picked = await _showSimplePicker<int>(
      items: List<int>.generate(12, (i) => i + 1),
      itemBuilder: (m) => _monthNames[m - 1],
      initial: _calendarMonth.month,
    );
    if (picked != null) {
      setState(() {
        _calendarMonth = DateTime(_calendarMonth.year, picked, 1);
      });
    }
  }

  Future<T?> _showSimplePicker<T>({
    required List<T> items,
    required String Function(T) itemBuilder,
    required T initial,
  }) async {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SizedBox(
            height: 280,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: items.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: Color(0xFFF0F0F0)),
              itemBuilder: (_, i) {
                final item = items[i];
                final isCurrent = item == initial;
                return ListTile(
                  title: Text(
                    itemBuilder(item),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                      color: isCurrent ? AppColors.mainColor : Colors.black,
                    ),
                  ),
                  onTap: () => Navigator.of(ctx).pop(item),
                );
              },
            ),
          ),
        );
      },
    );
  }

  String _ordinal(int day) {
    if (day >= 11 && day <= 13) return '${day}th';
    switch (day % 10) {
      case 1:
        return '${day}st';
      case 2:
        return '${day}nd';
      case 3:
        return '${day}rd';
      default:
        return '${day}th';
    }
  }

  // ---------------- Step menu toggle ----------------
  Widget _buildStepMenuArea() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      alignment: Alignment.bottomRight,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        reverseDuration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final scaleAnim = Tween<double>(
            begin: 0.85,
            end: 1.0,
          ).animate(animation);
          final slideAnim = Tween<Offset>(
            begin: const Offset(0.08, 0),
            end: Offset.zero,
          ).animate(animation);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: slideAnim,
              child: ScaleTransition(
                scale: scaleAnim,
                alignment: Alignment.bottomRight,
                child: child,
              ),
            ),
          );
        },
        layoutBuilder: (current, previous) {
          return Stack(
            alignment: Alignment.bottomRight,
            children: [...previous, ?current],
          );
        },
        child: _menuOpen
            ? KeyedSubtree(
                key: const ValueKey('open'),
                child: _buildOpenLayout(),
              )
            : KeyedSubtree(
                key: const ValueKey('closed'),
                child: _buildSmallToggle(),
              ),
      ),
    );
  }

  Widget _buildSmallToggle() {
    return GestureDetector(
      onTap: () => setState(() => _menuOpen = true),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.arrow_back_ios_new,
          color: Color(0xFF747474),
          size: 14,
        ),
      ),
    );
  }

  /// 펼침 레이아웃: 닫기 토글과 메뉴 카드를 하나의 컨테이너로 묶어
  /// 둘이 시각적으로 한 덩어리처럼 보이게 한다.
  Widget _buildOpenLayout() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [_buildLongToggleInner(), _buildStepMenuInner()],
        ),
      ),
    );
  }

  Widget _buildLongToggleInner() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _menuOpen = false),
      child: const SizedBox(
        width: 24,
        child: Center(
          child: Icon(
            Icons.arrow_forward_ios,
            color: Color(0xFF747474),
            size: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildStepMenuInner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(_steps.length, (index) {
          return Padding(
            padding: EdgeInsets.only(top: index == 0 ? 0 : 8),
            child: _buildStepMenuItem(index),
          );
        }),
      ),
    );
  }

  Widget _buildStepMenuItem(int index) {
    final isSelected = _currentStep == index;
    final color = isSelected ? AppColors.mainColor : Colors.black;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _currentStep = index),
      child: Container(
        width: 48,
        height: 48,
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0x14FC6340) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.mainColor : const Color(0xFFF0F0F0),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              _steps[index]['icon']!,
              width: 18,
              height: 18,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
            const SizedBox(height: 2),
            AutoTranslateText(
              _steps[index]['label']!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 7,
                fontWeight: FontWeight.w500,
                color: color,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeRange {
  const _TimeRange({required this.from, required this.to});
  final TimeOfDay from;
  final TimeOfDay to;
}

class _DayCell {
  const _DayCell(this.day, this.isOtherMonth);
  final int day;
  final bool isOtherMonth;
}

/// 화폐 금액 입력용. 사용자가 숫자만 눌러도 마지막 두 자리를 소수점 이하로
/// 자동 배치한다. 예: "1" → "0.01", "12" → "0.12", "1234" → "12.34".
class _DecimalAmountFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }
    // 너무 큰 값은 17자리(int 안전 범위)로 자름.
    final trimmed = digits.length > 17 ? digits.substring(0, 17) : digits;
    final cents = int.parse(trimmed);
    final integerPart = cents ~/ 100;
    final fractionalPart = (cents % 100).toString().padLeft(2, '0');
    final formatted = '$integerPart.$fractionalPart';
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// "DD/MM/YYYY - DD/MM/YYYY" 형식으로 자동 마스킹.
/// 입력은 숫자만 받고, 위치에 따라 '/', ' - ' 구분자를 자동 삽입한다.
class _DateRangeInputFormatter extends TextInputFormatter {
  static const int _maxDigits = 16;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final trimmed = digits.length > _maxDigits
        ? digits.substring(0, _maxDigits)
        : digits;
    final buf = StringBuffer();
    for (int i = 0; i < trimmed.length; i++) {
      if (i == 2 || i == 4) {
        buf.write('/');
      } else if (i == 8) {
        buf.write(' - ');
      } else if (i == 10 || i == 12) {
        buf.write('/');
      }
      buf.write(trimmed[i]);
    }
    final formatted = buf.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
