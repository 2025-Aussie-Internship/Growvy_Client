import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../styles/colors.dart';

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

  int _currentStep = 0;
  bool _menuOpen = false;

  // Basic Info
  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _workLocationController = TextEditingController();
  String? _employmentType;
  final Set<String> _selectedIndustries = {'Events & Festivals'};

  // Job Details
  final TextEditingController _responsibilitiesController =
      TextEditingController();
  final TextEditingController _shiftDetailsController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _peopleCountController = TextEditingController();
  int? _selectedDayIndex = 0;
  TimeOfDay _fromTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _toTime = const TimeOfDay(hour: 12, minute: 0);

  @override
  void dispose() {
    _jobTitleController.dispose();
    _companyNameController.dispose();
    _workLocationController.dispose();
    _responsibilitiesController.dispose();
    _shiftDetailsController.dispose();
    _dateController.dispose();
    _peopleCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
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
            child: IndexedStack(
              index: _currentStep,
              children: [
                _buildBasicInfo(),
                _buildJobDetails(),
                _buildPlaceholder('Pay & Benefits'),
                _buildPlaceholder('Application Settings'),
                _buildPlaceholder('Publish'),
              ],
            ),
          ),
          Positioned(
            right: 16,
            bottom: 90,
            child: _buildStepMenuArea(),
          ),
        ],
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
          _buildLabel('Company Name'),
          _buildUnderlineField(
            controller: _companyNameController,
            hintText: 'Enter your business name',
          ),
          const SizedBox(height: 16),
          _buildLabel('Work Location'),
          _buildUnderlineField(
            controller: _workLocationController,
            hintText: 'Enter suburb, state (e.g. Fitzroy, VIC)',
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
                onTap: () => setState(() => _employmentType = type),
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
                onTap: () => setState(() {
                  if (isSelected) {
                    _selectedIndustries.remove(item);
                  } else {
                    _selectedIndustries.add(item);
                  }
                }),
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
          ),
          const SizedBox(height: 16),
          _buildLabel('Number of people'),
          _buildUnderlineField(
            controller: _peopleCountController,
            hintText: 'At least one person',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _buildLabel('Day of the Week'),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_weekDays.length, (index) {
              final isSelected = _selectedDayIndex == index;
              return _buildDayChip(
                label: _weekDays[index],
                selected: isSelected,
                onTap: () => setState(() => _selectedDayIndex = index),
              );
            }),
          ),
          const SizedBox(height: 16),
          _buildLabel('Time'),
          const SizedBox(height: 8),
          _buildTimeCard(),
        ],
      ),
    );
  }

  // ---------------- 3~5) Placeholder ----------------
  Widget _buildPlaceholder(String title) {
    return Center(
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: _labelGray,
        ),
      ),
    );
  }

  // ---------------- Common pieces ----------------
  Widget _buildLabel(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
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
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, color: Colors.black),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: _labelGray, fontSize: 14),
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
        child: Text(
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
          child: Text(
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

  Widget _buildTimeCard() {
    final dayLabel = _selectedDayIndex == null
        ? ''
        : _fullDayName(_selectedDayIndex!);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      width: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _underlineGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dayLabel,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text(
                'From',
                style: TextStyle(fontSize: 12, color: _labelGray),
              ),
              const SizedBox(width: 6),
              _buildTimePill(_formatTime(_fromTime), onTap: () => _pickTime(true)),
              const SizedBox(width: 6),
              const Text(
                'To',
                style: TextStyle(fontSize: 12, color: _labelGray),
              ),
              const SizedBox(width: 6),
              _buildTimePill(_formatTime(_toTime), onTap: () => _pickTime(false)),
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _underlineGray),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Future<void> _pickTime(bool isFrom) async {
    final initial = isFrom ? _fromTime : _toTime;
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromTime = picked;
        } else {
          _toTime = picked;
        }
      });
    }
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  String _fullDayName(int index) {
    const names = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];
    return names[index];
  }

  // ---------------- Step menu toggle ----------------
  Widget _buildStepMenuArea() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      alignment: Alignment.centerRight,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SizeTransition(
              sizeFactor: animation,
              axis: Axis.horizontal,
              axisAlignment: 1.0,
              child: child,
            ),
          );
        },
        layoutBuilder: (current, previous) {
          return Stack(
            alignment: Alignment.centerRight,
            children: [
              ...previous,
              ?current,
            ],
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
          children: [
            _buildLongToggleInner(),
            _buildStepMenuInner(),
          ],
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
        width: 76,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0x14FC6340) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.mainColor : const Color(0xFFF0F0F0),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              _steps[index]['icon']!,
              width: 22,
              height: 22,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
            const SizedBox(height: 4),
            Text(
              _steps[index]['label']!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: color,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
