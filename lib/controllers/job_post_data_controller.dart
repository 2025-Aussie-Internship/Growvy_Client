import 'dart:io';
import 'dart:convert';

import 'package:dio/dio.dart' as dio;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // TimeOfDay
import 'package:get/get.dart';
import '../services/token_storage.dart';
import '../config/env.dart';

/// 공고 작성 다단계 폼의 단일 진실 원천(SSOT).
/// StartHiringPage 각 step 에서 set* 메서드로 값을 누적하고,
/// Publish 버튼에서 submitToBackend() 를 한 번만 호출한다.
class JobPostDataController extends GetxController {
  static String get _uploadUrl => "${Env.apiBaseUrl}posts/upload";

  // ── Basic Info ──────────────────────────────────────────────
  String _title = '';
  int? _employmentTypeId;
  Set<int> _industryIds = {};

  // ── Job Details ─────────────────────────────────────────────
  String _responsibilities = '';
  String _shiftDetails = '';
  String _scheduleDateRange = '';
  int? _numberOfHires;
  Set<int> _selectedDayIndices = {};
  Map<int, ({TimeOfDay from, TimeOfDay to})> _dayTimes = {};

  // ── Pay & Benefits ──────────────────────────────────────────
  String _hourlyRate = '';
  String _penaltyRate = '';
  String? _superannuation;

  // ── Application Settings ────────────────────────────────────
  DateTime? _deadline;

  // ── Photos ──────────────────────────────────────────────────
  List<String> _photoUrls = [];

  // ── Setters ─────────────────────────────────────────────────

  void setBasicInfo({
    String? title,
    int? employmentTypeId,
    Set<int>? industryIds,
  }) {
    if (title != null) _title = title;
    if (employmentTypeId != null) _employmentTypeId = employmentTypeId;
    if (industryIds != null) _industryIds = Set.from(industryIds);
  }

  void setJobDetails({
    String? responsibilities,
    String? shiftDetails,
    String? scheduleDateRange,
    int? numberOfHires,
    Set<int>? selectedDayIndices,
    Map<int, ({TimeOfDay from, TimeOfDay to})>? dayTimes,
  }) {
    if (responsibilities != null) _responsibilities = responsibilities;
    if (shiftDetails != null) _shiftDetails = shiftDetails;
    if (scheduleDateRange != null) _scheduleDateRange = scheduleDateRange;
    if (numberOfHires != null) _numberOfHires = numberOfHires;
    if (selectedDayIndices != null) {
      _selectedDayIndices = Set.from(selectedDayIndices);
    }
    if (dayTimes != null) _dayTimes = Map.from(dayTimes);
  }

  void setPayBenefits({
    String? hourlyRate,
    String? penaltyRate,
    String? superannuation,
  }) {
    if (hourlyRate != null) _hourlyRate = hourlyRate;
    if (penaltyRate != null) _penaltyRate = penaltyRate;
    if (superannuation != null) _superannuation = superannuation;
  }

  void setApplicationDeadline(DateTime? deadline) {
    _deadline = deadline;
  }

  void setPhotos(List<String> photos) {
    _photoUrls = List.from(photos);
  }

  // ── Submit ───────────────────────────────────────────────────
  // ── Submit ───────────────────────────────────────────────────
  Future<Map<String, dynamic>> submitToBackend() async {
    try {
      final formData = dio.FormData();

      // ── 1. 백엔드 'request' 파트에 보낼 JSON 데이터 구성 ────────────────────────
      final Map<String, dynamic> requestData = {
        'title': _title,
        'responsibility': _responsibilities,
      };

      if (_shiftDetails.isNotEmpty) {
        requestData['description'] = _shiftDetails;
      }
      if (_numberOfHires != null) {
        requestData['count'] = _numberOfHires; // int 타입 그대로 전송
      }
      if (_hourlyRate.isNotEmpty) {
        requestData['hourlyRates'] = _hourlyRate;
      }
      if (_penaltyRate.isNotEmpty) {
        requestData['penaltyRates'] = _penaltyRate;
      }
      if (_superannuation != null) {
        requestData['superannuation'] = _superannuationToEnum(_superannuation!);
      }

      // 날짜 (백엔드 LocalDateTime 형식에 맞게 T00:00:00 추가)
      final dates = _parseDateRange(_scheduleDateRange);
      if (dates != null) {
        requestData['startDate'] = '${dates[0]}T00:00:00';
        requestData['endDate'] = '${dates[1]}T00:00:00';
      }

      if (_deadline != null) {
        final y = _deadline!.year;
        final m = _deadline!.month.toString().padLeft(2, '0');
        final d = _deadline!.day.toString().padLeft(2, '0');
        requestData['recruitmentDeadline'] = '$y-$m-${d}T00:00:00';
      }

      // interestIds (리스트 형태)
      final allIds = <int>[
        if (_employmentTypeId != null) _employmentTypeId!,
        ..._industryIds,
      ];
      requestData['interestIds'] = allIds;

      // schedules (객체 배열 형태)
      const dayNames = [
        'SUNDAY',
        'MONDAY',
        'TUESDAY',
        'WEDNESDAY',
        'THURSDAY',
        'FRIDAY',
        'SATURDAY',
      ];

      final List<Map<String, dynamic>> schedules = [];
      for (final dayIndex in _selectedDayIndices) {
        final range = _dayTimes[dayIndex];
        if (range == null) continue;
        schedules.add({
          'dayOfWeek': dayNames[dayIndex],
          'startTime': _toLocalTime(range.from),
          'endTime': _toLocalTime(range.to),
        });
      }
      requestData['schedules'] = schedules;

      // ── 2. JSON 데이터를 'request' 파트로 FormData에 추가 ────────────────────
      formData.files.add(
        MapEntry(
          'request',
          dio.MultipartFile.fromString(
            jsonEncode(requestData),
            contentType: dio.DioMediaType('application', 'json'),
          ),
        ),
      );

      // ── 3. 이미지 파일 추가 (최대 4장) ─────────────────────────────────────────
      int imgOrder = 0;
      for (final path in _photoUrls) {
        if (imgOrder >= 4) break;
        if (path.startsWith('http')) {
          debugPrint('[JobPost] remote URL skipped: $path');
          continue;
        }
        final file = File(path);
        if (!file.existsSync()) {
          debugPrint('[JobPost] 파일 없음, 스킵: $path');
          continue;
        }
        final ext = path.split('.').last.toLowerCase();
        formData.files.add(
          MapEntry(
            'images',
            await dio.MultipartFile.fromFile(
              path,
              contentType: dio.DioMediaType('image', _imgSubtype(ext)),
            ),
          ),
        );
        imgOrder++;
      }

      // ── 4. 전송 ─────────────────────────────────────────────────────────────
      debugPrint('[JobPost] POST $_uploadUrl');
      debugPrint('[JobPost] request JSON: ${jsonEncode(requestData)}');
      debugPrint(
        '[JobPost] files : ${formData.files.map((e) => e.value.filename)}',
      );

      // ★ [수정 완료된 부분] TokenStorage에서 직접 토큰을 꺼내옵니다.
      String? jwtToken = await TokenStorage.readAccessToken();

      if (jwtToken == null || jwtToken.isEmpty) {
        jwtToken = await TokenStorage.readFirebaseIdToken();
      }

      debugPrint('[JobPost] 헤더에 들어갈 토큰 확인: $jwtToken');

      final dioClient = dio.Dio(
        dio.BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
          validateStatus: (_) => true,
          // ★ 여기서 헤더에 토큰이 들어갑니다.
          headers: {
            if (jwtToken != null && jwtToken.isNotEmpty)
              'Authorization': 'Bearer $jwtToken',
          },
        ),
      );

      final response = await dioClient.post(_uploadUrl, data: formData);

      debugPrint('[JobPost] status: ${response.statusCode}');
      debugPrint('[JobPost] body  : ${response.data}');

      final status = response.statusCode ?? 0;
      if (status >= 200 && status < 300) {
        if (response.data is Map<String, dynamic>) {
          return response.data as Map<String, dynamic>;
        }
        return {'raw': response.data};
      } else {
        debugPrint('[JobPost] 서버 오류 $status: ${response.data}');
        return {};
      }
    } catch (e, st) {
      debugPrint('[JobPost] 예외: $e\n$st');
      return {};
    }
  }
  // ── reset ────────────────────────────────────────────────────

  void reset() {
    _title = '';
    _employmentTypeId = null;
    _industryIds = {};
    _responsibilities = '';
    _shiftDetails = '';
    _scheduleDateRange = '';
    _numberOfHires = null;
    _selectedDayIndices = {};
    _dayTimes = {};
    _hourlyRate = '';
    _penaltyRate = '';
    _superannuation = null;
    _deadline = null;
    _photoUrls = [];
  }

  // ── Debug ─────────────────────────────────────────────────────

  String describeForDebug() =>
      'title=$_title, emp=$_employmentTypeId, industries=$_industryIds, '
      'days=$_selectedDayIndices, rate=$_hourlyRate, deadline=$_deadline, '
      'photos=${_photoUrls.length}장';

  // ── Helpers ───────────────────────────────────────────────────

  String _superannuationToEnum(String display) =>
      display.toUpperCase().replaceAll(' ', '_');

  List<String>? _parseDateRange(String raw) {
    final parts = raw.split(' - ');
    if (parts.length != 2) return null;
    final s = _dmyToIso(parts[0].trim());
    final e = _dmyToIso(parts[1].trim());
    if (s == null || e == null) return null;
    return [s, e];
  }

  String? _dmyToIso(String dmy) {
    final parts = dmy.split('/');
    if (parts.length != 3) return null;
    return '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
  }

  String _toLocalTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m:00';
  }

  String _imgSubtype(String ext) {
    switch (ext) {
      case 'png':
        return 'png';
      case 'gif':
        return 'gif';
      case 'webp':
        return 'webp';
      default:
        return 'jpeg';
    }
  }
}
