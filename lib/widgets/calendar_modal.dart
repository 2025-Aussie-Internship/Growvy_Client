import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../styles/colors.dart';
import '../styles/modal_theme.dart';

class CalendarModal extends StatefulWidget {
  const CalendarModal({super.key});

  @override
  State<CalendarModal> createState() => _CalendarModalState();
}

class _CalendarModalState extends State<CalendarModal> {
  DateTime _selectedDate = DateTime.now();
  DateTime _currentMonth = DateTime.now();

  // 샘플 투두 데이터 (이미지: 2/19 선택 시 Today's To Do List)
  final Map<String, List<Map<String, String>>> _todoData = {
    '2026-02-19': [
      {'title': 'Café or Restaurant Staff', 'time': '12:00 PM ~ 4:00 PM'},
      {'title': 'Retail Assistant', 'time': '9:00 AM ~ 11:00 AM'},
    ],
    '2026-02-16': [
      {'title': 'Café or Restaurant Staff', 'time': '12:00 PM ~ 4:00 PM'},
      {'title': 'Retail Assistant', 'time': '9:00 AM ~ 11:00 AM'},
    ],
    '2025-01-28': [
      {'title': 'Delivery Driver', 'time': '2:00 PM ~ 6:00 PM'},
    ],
    '2025-02-15': [
      {'title': 'Warehouse Work', 'time': '8:00 AM ~ 5:00 PM'},
      {'title': 'Kitchen Helper', 'time': '6:00 PM ~ 9:00 PM'},
    ],
    '2025-03-15': [
      {'title': 'Team Meeting', 'time': '10:00 AM ~ 11:30 AM'},
    ],
    '2025-01-12': [
      {'title': 'Barista Training', 'time': '1:00 PM ~ 3:00 PM'},
    ],
  };

  List<Map<String, String>> _getTodosForDate(DateTime date) {
    String key =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return _todoData[key] ?? [];
  }

  void _showYearPicker() async {
    int selectedYear = _currentMonth.year;

    await showDialog(
      context: context,
      builder: (context) => Theme(
        data: modalTheme(context).copyWith(
          dialogBackgroundColor: Colors.white,
          colorScheme: Theme.of(context).colorScheme.copyWith(
            surface: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: Colors.white,
            title: const Text(
              'Select Year',
              style: TextStyle(color: Colors.black),
            ),
          content: SizedBox(
            height: 200,
            width: 200,
            child: ListView.builder(
              itemCount: 20,
              itemBuilder: (context, index) {
                final year = 2020 + index;
                final isSelected = year == selectedYear;
                return GestureDetector(
                  onTap: () {
                    setDialogState(() => selectedYear = year);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    color: isSelected
                        ? AppColors.mainColor.withOpacity(0.2)
                        : null,
                    child: Center(
                      child: Text(
                        '$year',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? AppColors.mainColor
                              : Colors.black,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.black)),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _currentMonth = DateTime(selectedYear, _currentMonth.month);
                  _selectedDate = DateTime(selectedYear, _currentMonth.month, 1);
                });
                Navigator.pop(context);
              },
              child: const Text('OK', style: TextStyle(color: AppColors.mainColor)),
            ),
          ],
        ),
        ),
      ),
    );
  }

  void _showMonthPicker() async {
    int selectedMonth = _currentMonth.month;

    await showDialog(
      context: context,
      builder: (context) => Theme(
        data: modalTheme(context).copyWith(
          dialogBackgroundColor: Colors.white,
          colorScheme: Theme.of(context).colorScheme.copyWith(
            surface: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: Colors.white,
            title: const Text(
              'Select Month',
              style: TextStyle(color: Colors.black),
            ),
          content: SizedBox(
            height: 280,
            width: 200,
            child: ListView.builder(
              itemCount: 12,
              itemBuilder: (context, index) {
                final month = index + 1;
                final isSelected = month == selectedMonth;
                return GestureDetector(
                  onTap: () {
                    setDialogState(() => selectedMonth = month);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    color: isSelected
                        ? AppColors.mainColor.withOpacity(0.2)
                        : null,
                    child: Center(
                      child: Text(
                        _getMonthName(month),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? AppColors.mainColor
                              : Colors.black,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.black)),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _currentMonth = DateTime(_currentMonth.year, selectedMonth);
                  _selectedDate = DateTime(_currentMonth.year, selectedMonth, 1);
                });
                Navigator.pop(context);
              },
              child: const Text('OK', style: TextStyle(color: AppColors.mainColor)),
            ),
          ],
        ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Theme(
        data: modalTheme(context),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // 흰색 캘린더 모달 박스
            Container(
            width: 300,
            height: 344,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 년/월 선택: w 86 h 26, 캘린더 SVG(년도), 년·월 각각 피커
                  Row(
                  children: [
                    GestureDetector(
                      onTap: _showYearPicker,
                      child: SizedBox(
                        width: 86,
                        height: 26,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F0F0),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFE5E5E5),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                'assets/icon/calendar_icon.svg',
                                width: 14,
                                height: 14,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '${_currentMonth.year}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.keyboard_arrow_down,
                                size: 16,
                                color: Colors.grey[700],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _showMonthPicker,
                      child: SizedBox(
                        width: 86,
                        height: 26,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F0F0),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFE5E5E5),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  _getMonthName(_currentMonth.month),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.keyboard_arrow_down,
                                size: 16,
                                color: Colors.grey[700],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

            // 요일 헤더
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                  .map(
                    (day) => SizedBox(
                      width: 36,
                      child: Center(
                        child: Text(
                          day,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),

            // 달력 그리드
            _buildCalendarGrid(),

            const SizedBox(height: 12),

            // 구분선
            Container(width: 276, height: 1, color: const Color(0xFFF5F5F5)),

            const SizedBox(height: 12),

                // Today's To Do List (이미지 스타일: 제목 굵게, 두 항목 가로 배치, 세로 구분선)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Today's To Do List",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[900],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _getTodosForDate(_selectedDate).isEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              "No tasks for this day",
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_getTodosForDate(_selectedDate).isNotEmpty)
                                Expanded(
                                  child: _buildTodoItem(
                                    _getTodosForDate(_selectedDate)[0],
                                  ),
                                ),
                              if (_getTodosForDate(_selectedDate).length > 1) ...[
                                Container(
                                  width: 1,
                                  height: 44,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  color: const Color(0xFFE8E8E8),
                                ),
                                Expanded(
                                  child: _buildTodoItem(
                                    _getTodosForDate(_selectedDate)[1],
                                  ),
                                ),
                              ],
                            ],
                          ),
                  ],
                ),
                ],
              ),
            ),
          ),
          // X 버튼: 모달 밖 우상단, 크기 32
          Positioned(
            top: -8,
            right: -8,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.mainColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildTodoItem(Map<String, String> todo) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 5, right: 6),
          decoration: const BoxDecoration(
            color: AppColors.mainColor,
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                todo['title']!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[900],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                todo['time']!,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.normal,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month,
      1,
    );
    final lastDayOfMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
    );
    final firstWeekday = firstDayOfMonth.weekday % 7; // 0 = Sunday
    final daysInMonth = lastDayOfMonth.day;

    List<Widget> dayWidgets = [];

    // 이전 달 날짜 (회색으로 표시)
    final prevMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    final daysInPrevMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month,
      0,
    ).day;

    for (int i = firstWeekday - 1; i >= 0; i--) {
      final day = daysInPrevMonth - i;
      final date = DateTime(prevMonth.year, prevMonth.month, day);
      dayWidgets.add(_buildDayCell(date, isCurrentMonth: false));
    }

    // 현재 달 날짜
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      dayWidgets.add(_buildDayCell(date, isCurrentMonth: true));
    }

    // 다음 달 날짜 (6주 채우기)
    final remainingCells = (7 - (dayWidgets.length % 7)) % 7;
    if (remainingCells > 0) {
      for (int i = 1; i <= remainingCells; i++) {
        final date = DateTime(_currentMonth.year, _currentMonth.month + 1, i);
        dayWidgets.add(_buildDayCell(date, isCurrentMonth: false));
      }
    }

    // 행 수 계산
    final rows = (dayWidgets.length / 7).ceil();

    return SizedBox(
      height: rows * 42.0, // 각 행의 높이 증가 (원이 잘리지 않도록)
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 7,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        children: dayWidgets,
      ),
    );
  }

  Widget _buildDayCell(DateTime date, {required bool isCurrentMonth}) {
    final isSelected =
        date.year == _selectedDate.year &&
        date.month == _selectedDate.month &&
        date.day == _selectedDate.day;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDate = date;
          // 다른 달의 날짜를 클릭하면 해당 달로 이동
          if (!isCurrentMonth) {
            _currentMonth = DateTime(date.year, date.month);
          }
        });
      },
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.mainColor : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '${date.day}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : isCurrentMonth
                  ? Colors.black
                  : Colors.grey[400],
            ),
          ),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
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
    return months[month - 1];
  }
}
