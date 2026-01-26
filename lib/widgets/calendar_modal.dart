import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../styles/colors.dart';

class CalendarModal extends StatefulWidget {
  const CalendarModal({super.key});

  @override
  State<CalendarModal> createState() => _CalendarModalState();
}

class _CalendarModalState extends State<CalendarModal> {
  DateTime _selectedDate = DateTime.now();
  DateTime _currentMonth = DateTime.now();

  // 샘플 투두 데이터
  final Map<String, List<Map<String, String>>> _todoData = {
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

  void _showMonthYearPicker() async {
    int selectedYear = _currentMonth.year;
    int selectedMonth = _currentMonth.month;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Select Month and Year'),
          content: SizedBox(
            height: 200,
            width: 300,
            child: Row(
              children: [
                // Year picker
                Expanded(
                  child: ListView.builder(
                    itemCount: 20,
                    itemBuilder: (context, index) {
                      final year = 2020 + index;
                      final isSelected = year == selectedYear;
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            selectedYear = year;
                          });
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
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
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
                const SizedBox(width: 20),
                // Month picker
                Expanded(
                  child: ListView.builder(
                    itemCount: 12,
                    itemBuilder: (context, index) {
                      final month = index + 1;
                      final isSelected = month == selectedMonth;
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            selectedMonth = month;
                          });
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
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
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
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _currentMonth = DateTime(selectedYear, selectedMonth);
                  // 선택한 달로 이동하면서 해당 달의 첫날로 선택일 변경
                  _selectedDate = DateTime(selectedYear, selectedMonth, 1);
                });
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 300,
        constraints: const BoxConstraints(maxHeight: 500),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 월/년도 선택 버튼
            Row(
              children: [
                GestureDetector(
                  onTap: _showMonthYearPicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '${_getMonthName(_currentMonth.month)} ${_currentMonth.year}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down, size: 16),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                // 닫기 버튼
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppColors.mainColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

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

            // Today's To Do List
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Today's To Do List",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 80,
                  child: _getTodosForDate(_selectedDate).isEmpty
                      ? Text(
                          "No tasks for this day",
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 왼쪽 컬럼
                            if (_getTodosForDate(_selectedDate).isNotEmpty)
                              Expanded(
                                child: _buildTodoItem(
                                  _getTodosForDate(_selectedDate)[0],
                                ),
                              ),
                            // 구분선
                            if (_getTodosForDate(_selectedDate).length > 1)
                              Container(
                                width: 1,
                                height: 50,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                color: const Color(0xFFE0E0E0),
                              ),
                            // 오른쪽 컬럼
                            if (_getTodosForDate(_selectedDate).length > 1)
                              Expanded(
                                child: _buildTodoItem(
                                  _getTodosForDate(_selectedDate)[1],
                                ),
                              ),
                          ],
                        ),
                ),
              ],
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
          margin: const EdgeInsets.only(top: 4, right: 6),
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
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                todo['time']!,
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
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
    final isToday =
        date.year == DateTime.now().year &&
        date.month == DateTime.now().month &&
        date.day == DateTime.now().day;

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
