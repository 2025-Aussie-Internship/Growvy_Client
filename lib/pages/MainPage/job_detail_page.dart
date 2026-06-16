import 'dart:async';
import 'dart:io';
import 'dart:convert'; // 🌟 API JSON 파싱용 추가
import 'package:http/http.dart' as http; // 🌟 API 통신용 추가
import '../../config/env.dart';
import '../../utils/image_url.dart';
import '../../i18n/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../controllers/auth_controller.dart';
import '../../models/job_shift.dart';
import '../../styles/colors.dart';
import '../../widgets/auto_translate_text.dart';
import '../../widgets/confirm_modal.dart';
import '../../widgets/completion_modal.dart';
import '../NotePage/employer_note_write_page.dart';
import '../../services/token_storage.dart'; // 🌟 토큰 스토리지 (경로가 다르면 수정해주세요)

class JobDetailPage extends StatefulWidget {
  const JobDetailPage({
    super.key,
    this.postId,
    this.title,
    this.companyName,
    this.description,
    this.responsibility,
    this.tags,
    this.scheduleDate,
    this.scheduleShifts,
    this.location,
    this.payText,
    this.openingsText,
    this.isOwner = false,
    this.isApplied = false,
    this.onEdit,
    this.onDelete,
    this.onHiringTap,
    this.onCancelApplication,
    this.photoUrls,
  });

  final dynamic postId;
  final String? title;
  final String? companyName;
  final String? description;
  final String? responsibility;
  final List<String>? tags;
  final String? scheduleDate;
  final List<JobShift>? scheduleShifts;
  final String? location;
  final String? payText;
  final String? openingsText;
  final bool isOwner;
  final bool isApplied;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onHiringTap;
  final VoidCallback? onCancelApplication;
  final List<String>? photoUrls;

  @override
  State<JobDetailPage> createState() => _JobDetailPageState();
}

class _JobDetailPageState extends State<JobDetailPage> {
  static const double imageHeight = 300;
  static const double overlap = 20.0;

  late PageController _imageController;
  late Timer _imageTimer;
  int _imageCurrentPage = 1000;

  bool _isBookmarked = false;
  bool _scheduleExpanded = true;

  // ---------------- 화면 표시용 mutable 상태 ----------------
  String? _title;
  String? _companyName;
  String? _description;
  String? _responsibility;
  List<String>? _tags;
  String? _scheduleDate;
  String? _location;
  String? _payText;
  String? _openingsText;
  int? _numberOfHires;

  // 🌟 API에서 받아올 사진 리스트 보관용
  List<String>? _fetchedPhotoUrls;
  List<JobShift>? _scheduleShifts;

  static const List<String> _defaultImageUrls = [
    "https://images.unsplash.com/photo-1542208998-f6dbbb27a72f?w=400",
    "https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?w=400",
    "https://images.unsplash.com/photo-1505373877841-8d25f7d46678?w=400",
    "https://images.unsplash.com/photo-1519750783826-e2420f4d687f?w=400",
  ];

  List<String> get _imageUrls {
    // 🌟 API에서 사진을 받아왔다면 최우선으로 보여줌
    if (_fetchedPhotoUrls != null && _fetchedPhotoUrls!.isNotEmpty)
      return _fetchedPhotoUrls!;
    final injected = widget.photoUrls;
    if (injected != null && injected.isNotEmpty) return injected;
    return _defaultImageUrls;
  }

  Widget _slideImage(String path) {
    if (path.startsWith('http')) {
      return Image.network(path, fit: BoxFit.cover);
    }
    return Image.file(File(path), fit: BoxFit.cover);
  }

  @override
  void initState() {
    super.initState();

    _imageController = PageController(initialPage: _imageCurrentPage);
    _startImageTimer();

    _title = widget.title;
    _companyName = widget.companyName;
    _description = widget.description;
    _responsibility = widget.responsibility;
    _tags = widget.tags;
    _scheduleDate = widget.scheduleDate;
    _location = widget.location;
    _payText = widget.payText;
    _openingsText = widget.openingsText;
    _scheduleShifts = widget.scheduleShifts;

    // photoUrls: 로컬 파일 경로는 그대로, 서버 상대 경로만 resolve
    if (widget.photoUrls != null && widget.photoUrls!.isNotEmpty) {
      _fetchedPhotoUrls = widget.photoUrls!.map(resolveImageUrl).toList();
    }

    // 공고 상세 데이터 API 호출
    _fetchJobDetail();
  }

  // 🌟 API 호출 및 데이터 매핑 메서드
  Future<void> _fetchJobDetail() async {
    if (widget.postId == null) return;

    try {
      final String? accessToken = await TokenStorage.readAccessToken();

      final response = await http.get(
        Uri.parse('${Env.apiBaseUrl}posts/posts/${widget.postId}'),
        headers: {
          if (accessToken != null) "Authorization": "Bearer $accessToken",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));

        if (!mounted) return;

        setState(() {
          _title = data['title'] ?? _title;

          if (data['companyName'] != null &&
              data['companyName'].toString().trim().isNotEmpty) {
            _companyName = data['companyName'].toString().trim();
          } else if (data['employer'] is Map &&
              data['employer']['name'] != null) {
            _companyName = data['employer']['name'].toString().trim();
          }

          _description = data['description'] ?? _description;
          _responsibility = data['responsibility'] ?? _responsibility;
          _location = data['jobAddress'] ?? _location;

          final wage = data['hourlyRates'];
          if (wage != null) {
            _payText = wage == 0 ? 'Volunteer' : '\$$wage per hour';
          }

          final count = data['count'];
          if (count != null && count is int) {
            _numberOfHires = count;
            _openingsText =
                '$_numberOfHires ${_numberOfHires == 1 ? "opening" : "openings"}.';
          }

          if (data['tags'] != null && (data['tags'] as List).isNotEmpty) {
            _tags = (data['tags'] as List)
                .map((t) => t is Map ? t['name'].toString() : t.toString())
                .toList();
          }

          // 🌟 사진 이미지 리스트 파싱
          if (data['imageUrls'] != null &&
              (data['imageUrls'] as List).isNotEmpty) {
            _fetchedPhotoUrls = (data['imageUrls'] as List)
                .map((e) => resolveImageUrl(e.toString()))
                .toList();
          }

          final start = data['startDate']?.toString();
          final end = data['endDate']?.toString();

          String formatDate(String? dateStr) {
            if (dateStr == null || dateStr.isEmpty) return '';
            return dateStr.split('T')[0].replaceAll('-', '.');
          }

          if (start != null && end != null) {
            _scheduleDate = '${formatDate(start)} - ${formatDate(end)}';
          }

          if (data['schedules'] != null &&
              (data['schedules'] as List).isNotEmpty) {
            _scheduleShifts = (data['schedules'] as List).map((s) {
              String rawDay =
                  s['dayOfWeek']?.toString().toUpperCase() ?? 'MONDAY';

              int dayIndex = 1;

              switch (rawDay) {
                case 'SUNDAY':
                  dayIndex = 0;
                  break;
                case 'MONDAY':
                  dayIndex = 1;
                  break;
                case 'TUESDAY':
                  dayIndex = 2;
                  break;
                case 'WEDNESDAY':
                  dayIndex = 3;
                  break;
                case 'THURSDAY':
                  dayIndex = 4;
                  break;
                case 'FRIDAY':
                  dayIndex = 5;
                  break;
                case 'SATURDAY':
                  dayIndex = 6;
                  break;
              }

              TimeOfDay parseTime(String? timeStr) {
                if (timeStr == null || timeStr.isEmpty) {
                  return const TimeOfDay(hour: 0, minute: 0);
                }

                final parts = timeStr.split(':');

                int hour = parts.isNotEmpty ? int.parse(parts[0]) : 0;

                int minute = parts.length > 1 ? int.parse(parts[1]) : 0;

                return TimeOfDay(hour: hour, minute: minute);
              }

              return JobShift(
                dayIndex: dayIndex,
                from: parseTime(s['startTime']?.toString()),
                to: parseTime(s['endTime']?.toString()),
              );
            }).toList();
          }
        });
      } else {
        print("Detail Fetch Error: Status Code ${response.statusCode}");
      }
    } catch (e) {
      print("Detail Fetch Exception: $e");
    }
  }

  @override
  void dispose() {
    _imageTimer.cancel();
    _imageController.dispose();
    super.dispose();
  }

  void _startImageTimer() {
    _imageTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _imageCurrentPage++;
      if (_imageController.hasClients) {
        _imageController.animateToPage(
          _imageCurrentPage,
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: imageHeight,
            child: Stack(
              children: [
                Positioned.fill(
                  child: PageView.builder(
                    controller: _imageController,
                    itemBuilder: (context, index) {
                      final urls = _imageUrls;
                      return _slideImage(urls[index % urls.length]);
                    },
                  ),
                ),
                Positioned.fill(
                  child: Container(color: Colors.black.withOpacity(0.11)),
                ),
              ],
            ),
          ),

          Positioned.fill(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    height: imageHeight - overlap,
                  ),

                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 524),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AutoTranslateText(
                          _title ?? "Sadie's HotPot",
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AutoTranslateText(
                              _companyName ?? 'My Awesome Company',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Divider(
                              height: 1,
                              thickness: 1,
                              color: Color(0xFFF2F4F7),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              for (
                                int i = 0;
                                i < (_tags ?? const ['D-10', 'Veteran']).length;
                                i++
                              ) ...[
                                if (i != 0) const SizedBox(width: 8),
                                _buildTag(
                                  (_tags ?? const ['D-10', 'Veteran'])[i],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        if (_responsibility != null &&
                            _responsibility!.trim().isNotEmpty) ...[
                          const AutoTranslateText(
                            'Responsibilities',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          AutoTranslateText(
                            _responsibility!,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.6,
                              color: Color(0xFF696969),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                        if (_description != null &&
                            _description!.trim().isNotEmpty)
                          AutoTranslateText(
                            _description!,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.6,
                              color: Color(0xFF696969),
                            ),
                          ),
                        const SizedBox(height: 14),
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: Color(0xFFF2F4F7),
                        ),
                        const SizedBox(height: 14),

                        _buildInfoRow(
                          'assets/icon/calendar_icon.svg',
                          _scheduleDate ?? 'Feb 15, 2026 - Feb 16, 2026',
                        ),
                        _buildScheduleSection(),
                        _buildInfoRow(
                          'assets/icon/address_icon.svg',
                          _location ??
                              '123 Swanston St, Melbourne, VIC, Australia',
                        ),
                        _buildInfoRow(
                          'assets/icon/salary_icon.svg',
                          _payText ?? '\$1000 per day',
                        ),
                        _buildInfoRow(
                          'assets/icon/people_icon.svg',
                          _openingsText ?? '1 openings.',
                        ),

                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    widget.isOwner
                        ? _buildOwnerActions()
                        : _buildViewerActions(),
                  ],
                ),
              ),
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: _buildBottomButton(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 3.5, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFF5F3D),
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: AutoTranslateText(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 1.0,
        ),
      ),
    );
  }

  Widget _buildViewerActions() {
    return Row(
      children: [
        IconButton(
          icon: SvgPicture.asset(
            'assets/icon/share_icon.svg',
            colorFilter: const ColorFilter.mode(
              AppColors.mainColor,
              BlendMode.srcIn,
            ),
            width: 24,
            height: 24,
          ),
          onPressed: () {},
        ),
        IconButton(
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: SvgPicture.asset(
              _isBookmarked
                  ? 'assets/icon/bookmark_filled_icon.svg'
                  : 'assets/icon/bookmark_icon.svg',
              key: ValueKey<bool>(_isBookmarked),
              colorFilter: const ColorFilter.mode(
                AppColors.mainColor,
                BlendMode.srcIn,
              ),
              width: 24,
              height: 24,
            ),
          ),
          onPressed: () {
            setState(() => _isBookmarked = !_isBookmarked);
          },
        ),
      ],
    );
  }

  Widget _buildOwnerActions() {
    return Row(
      children: [
        _circleAssetButton(
          onTap: _handleEditTap,
          child: SvgPicture.asset(
            'assets/icon/jobdetail_edit_icon.svg',
            width: 44,
            height: 44,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: 6),
        _circleAssetButton(
          onTap: _handleDeleteTap,
          child: Image.asset(
            'assets/icon/jobdetail_delete_icon.svg',
            width: 44,
            height: 44,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }

  Widget _circleAssetButton({
    required Widget child,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Center(child: child),
        ),
      ),
    );
  }

  Future<void> _handleEditTap() async {
    if (widget.onEdit != null) {
      widget.onEdit!();
      return;
    }
    final updated = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => EmployerNoteWritePage(
          isEditMode: true,
          initialTitle: _title,
          initialDescription: _description,
          initialScheduleDate: _scheduleDate,
          initialLocation: _location,
          initialPay: _payText,
          initialNumberOfHires: _numberOfHires,
          initialTags: _tags == null ? null : List<String>.from(_tags!),
        ),
      ),
    );
    if (!mounted || updated == null) return;
    setState(() {
      _title = (updated['title'] as String?)?.trim().isNotEmpty == true
          ? updated['title'] as String
          : _title;
      _description =
          (updated['description'] as String?)?.trim().isNotEmpty == true
          ? updated['description'] as String
          : _description;
      _scheduleDate =
          (updated['scheduleDate'] as String?)?.trim().isNotEmpty == true
          ? updated['scheduleDate'] as String
          : _scheduleDate;
      _location = (updated['location'] as String?)?.trim().isNotEmpty == true
          ? updated['location'] as String
          : _location;
      _payText = (updated['payText'] as String?)?.trim().isNotEmpty == true
          ? updated['payText'] as String
          : _payText;
      if (updated['numberOfHires'] is int) {
        _numberOfHires = updated['numberOfHires'] as int;
        final isOne = _numberOfHires == 1;
        _openingsText = '$_numberOfHires ${isOne ? 'opening' : 'openings'}.';
      }
      if (updated['tags'] is List && (updated['tags'] as List).isNotEmpty) {
        _tags = List<String>.from(updated['tags'] as List);
      }
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 2),
          backgroundColor: AppColors.mainColor,
          content: AutoTranslateText(
            'Posting updated.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  Future<void> _handleDeleteTap() async {
    if (widget.onDelete != null) {
      widget.onDelete!();
      return;
    }
    final confirmed = await ConfirmModal.show<bool>(
      context: context,
      message: 'Do you really want\nto delete this posting?',
      onCancel: () => Navigator.pop(context, false),
      onAccept: () => Navigator.pop(context, true),
    );
    if (confirmed != true || !mounted) return;
    CompletionModal.show(
      context,
      message: 'Delete Complete!',
      onDismiss: () {
        if (mounted) {
          Navigator.pop(context, {'deleted': true, 'postId': widget.postId});
        }
      },
    );
  }

  Widget _buildScheduleSection() {
    // 🌟 수정됨: widget.scheduleShifts 대신 상태값 _scheduleShifts를 바라봄
    final shifts = _scheduleShifts == null || _scheduleShifts!.isEmpty
        ? JobShift.sevenDayDummy
        : _scheduleShifts!;

    final headLabel = shifts.map((s) => s.dayShort).join(', ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _scheduleExpanded = !_scheduleExpanded),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/icon/time_icon.svg',
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFFBDBDBD),
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AutoTranslateText(
                    headLabel,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFFBDBDBD),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: _scheduleExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 180),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 22,
                    color: Color(0xFFBDBDBD),
                  ),
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: !_scheduleExpanded
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 6, left: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final s in shifts)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 38,
                                  child: AutoTranslateText(
                                    s.dayShort,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFFBDBDBD),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: AutoTranslateText(
                                    s.rangeLabel,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFFBDBDBD),
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvgPicture.asset(
            icon,
            width: 20,
            height: 20,
            colorFilter: const ColorFilter.mode(
              Color(0xFFBDBDBD),
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AutoTranslateText(
              text,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFFBDBDBD),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context) {
    if (widget.isOwner) {
      return _bottomBar(
        label: 'Hiring',
        enabled: widget.onHiringTap != null,
        onPressed: widget.onHiringTap ?? () {},
      );
    }
    if (widget.isApplied) {
      return _bottomBar(
        label: 'job_detail.cancel_application'.tr(),
        enabled: true,
        onPressed: () => _onCancelPressed(context),
      );
    }
    final isEmployer = AuthController.to.isEmployer.value;
    return _bottomBar(
      label: 'job_detail.apply'.tr(),
      enabled: !isEmployer,
      onPressed: () => _onApplyPressed(context),
    );
  }

  void _onCancelPressed(BuildContext context) {
    ConfirmModal.show(
      context: context,
      message: 'job_detail.cancel_confirm'.tr(),
      cancelLabel: 'common.no'.tr(),
      acceptLabel: 'common.yes'.tr(),
      onAccept: () {
        Navigator.pop(context);
        if (!context.mounted) return;
        if (widget.onCancelApplication != null) {
          widget.onCancelApplication!();
          return;
        }
        Navigator.pop(context, {'cancelled': true, 'postId': widget.postId});
      },
    );
  }

  Widget _bottomBar({
    required String label,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: enabled ? onPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: enabled ? AppColors.mainColor : Colors.grey,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey,
              disabledForegroundColor: Colors.white70,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: AutoTranslateText(
              label,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }

  void _onApplyPressed(BuildContext context) {
    ConfirmModal.show(
      context: context,
      message: 'job_detail.submit_application'.tr(),
      cancelLabel: 'common.cancel'.tr(),
      acceptLabel: 'common.apply'.tr(),
      onAccept: () {
        Navigator.pop(context);
        if (!context.mounted) return;
        CompletionModal.show(
          context,
          message: 'job_detail.application_submitted'.tr(),
          onDismiss: () {
            if (context.mounted) {
              Navigator.pop(context, widget.postId);
            }
          },
        );
      },
    );
  }
}
