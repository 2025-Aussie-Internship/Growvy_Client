import 'package:flutter/material.dart';

/// 공고에 등록된 요일별 근무 시간 한 칸.
///
/// JobDetailPage 의 시계 영역이 이 객체 리스트로 표시된다.
/// 백엔드 응답에서 받을 때엔 시간 문자열을 직접 파싱하지 않고
/// [JobShift.fromHourMinutes] 같은 factory 로 만들면 된다.
class JobShift {
  const JobShift({
    required this.dayIndex,
    required this.from,
    required this.to,
  });

  /// 0=일요일, 1=월요일, ... 6=토요일. ([_dayShorts] / [_dayLongs] 매핑).
  final int dayIndex;
  final TimeOfDay from;
  final TimeOfDay to;

  static const List<String> _dayShorts = [
    'SUN',
    'MON',
    'TUE',
    'WED',
    'THU',
    'FRI',
    'SAT',
  ];

  static const List<String> _dayLongs = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  String get dayShort => _dayShorts[dayIndex.clamp(0, 6)];
  String get dayLong => _dayLongs[dayIndex.clamp(0, 6)];

  /// "9:00 AM - 12:00 PM (3-hour shift)" 형식.
  String get rangeLabel =>
      '${_formatTime(from)} - ${_formatTime(to)} ${_durationLabel()}';

  /// "9:00 AM - 12:00 PM" 만 (시간 표시 없이).
  String get rangeLabelShort => '${_formatTime(from)} - ${_formatTime(to)}';

  String _durationLabel() {
    final fromMin = from.hour * 60 + from.minute;
    var toMin = to.hour * 60 + to.minute;
    // 다음 날까지 이어지는 야간 근무 보정.
    if (toMin <= fromMin) toMin += 24 * 60;
    final diffMin = toMin - fromMin;
    final hours = diffMin ~/ 60;
    final mins = diffMin % 60;
    if (mins == 0) {
      return hours == 1 ? '(1-hour shift)' : '($hours-hour shift)';
    }
    return '($hours-hour $mins-min shift)';
  }

  static String _formatTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  /// 시안에 보이는 7일 동일 시간 dummy. JobDetailPage 의 호출자가
  /// shifts 를 따로 제공하지 않을 때 fallback 으로 사용한다.
  static const List<JobShift> sevenDayDummy = <JobShift>[
    JobShift(dayIndex: 0, from: TimeOfDay(hour: 9, minute: 0), to: TimeOfDay(hour: 12, minute: 0)),
    JobShift(dayIndex: 1, from: TimeOfDay(hour: 9, minute: 0), to: TimeOfDay(hour: 12, minute: 0)),
    JobShift(dayIndex: 2, from: TimeOfDay(hour: 9, minute: 0), to: TimeOfDay(hour: 12, minute: 0)),
    JobShift(dayIndex: 3, from: TimeOfDay(hour: 9, minute: 0), to: TimeOfDay(hour: 12, minute: 0)),
    JobShift(dayIndex: 4, from: TimeOfDay(hour: 9, minute: 0), to: TimeOfDay(hour: 12, minute: 0)),
    JobShift(dayIndex: 5, from: TimeOfDay(hour: 9, minute: 0), to: TimeOfDay(hour: 12, minute: 0)),
    JobShift(dayIndex: 6, from: TimeOfDay(hour: 9, minute: 0), to: TimeOfDay(hour: 12, minute: 0)),
  ];
}
