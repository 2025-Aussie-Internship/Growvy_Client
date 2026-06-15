import 'dart:async';
import 'dart:io';

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

class JobDetailPage extends StatefulWidget {
  const JobDetailPage({
    super.key,
    this.postId,
    this.title,
    this.companyName,
    this.description,
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

  /// 공고 ID. Apply 성공 시 이 값을 pop하여 호출측에서 리스트에서 제거할 수 있음.
  final dynamic postId;

  /// 공고 작성 페이지에서 전달되는 값들. null일 경우 기본 더미 값을 보여준다.
  final String? title;
  final String? companyName;
  final String? description;
  final List<String>? tags;
  final String? scheduleDate;

  /// 요일별 근무 시간 리스트. null 이면 dummy 7일 데이터 사용.
  /// JobDetailPage 의 시계 영역이 이 리스트를 펼쳐 보여준다.
  final List<JobShift>? scheduleShifts;

  final String? location;
  final String? payText;
  final String? openingsText;

  /// true 면 본인이 작성한 공고로 간주하고:
  ///  - 상단 우측 share/bookmark 자리에 수정/삭제 아이콘 노출
  ///  - 하단 버튼이 "Apply" 가 아니라 **"Hiring"** 으로 표시되어
  ///    누르면 [onHiringTap] 콜백을 호출 (지원자 선택 모달 등에 사용).
  final bool isOwner;

  /// true 면 구직자가 이미 지원한 공고로 간주하고,
  /// 하단 버튼이 "Apply" 가 아니라 **"Cancel application"** 으로 표시된다.
  /// 누르면 확인 모달 → Yes 시 [onCancelApplication] 콜백 호출.
  ///
  /// [isOwner] 와 동시에 true 면 isOwner 가 우선한다.
  final bool isApplied;

  /// 수정 아이콘 탭. null 이면 기본 placeholder snackbar.
  final VoidCallback? onEdit;

  /// 삭제 아이콘 탭. null 이면 기본 ConfirmModal 후 [postId] 와 함께 pop.
  final VoidCallback? onDelete;

  /// "Hiring" 버튼(=isOwner 일 때 하단 버튼) 콜백.
  /// 일반적으로 지원자 선택 모달 → 채팅 페이지 흐름을 호출 측에서 주입한다.
  final VoidCallback? onHiringTap;

  /// "Cancel application" 버튼 (=isApplied 일 때 하단 버튼) 콜백.
  /// 호출자가 controller 에서 지원 목록에서 제거 등 처리.
  /// null 이면 단순히 [postId] 와 함께 pop 한다.
  final VoidCallback? onCancelApplication;

  /// 상단 자동 슬라이드 영역에 보여 줄 사진 목록.
  /// 항목은 `http(s)://` URL 이거나 단말 local 파일 경로(둘 다 지원).
  /// null 또는 빈 리스트면 기본 더미 이미지가 노출된다.
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

  /// 북마크(저장하기) 토글 상태.
  bool _isBookmarked = false;

  /// 시계 영역(요일별 시간) 펼침 여부. 기본 펼쳐진 상태로 표시.
  bool _scheduleExpanded = true;

  // ---------------- 화면 표시용 mutable 상태 ----------------
  // 수정 모달이 닫힌 직후 화면을 즉시 갱신하기 위해 widget.X 대신 이 변수들을
  // 그린다. initState 에서 widget 값으로 초기화하고, 수정 결과(map)가 들어오면
  // setState 로 교체한다.
  String? _title;
  String? _companyName;
  String? _description;
  List<String>? _tags;
  String? _scheduleDate;
  String? _location;
  String? _payText;
  String? _openingsText;
  int? _numberOfHires;

  /// 호출 측에서 photoUrls 가 들어오면 그것만, 비어 있으면 기본 더미 4장.
  static const List<String> _defaultImageUrls = [
    "https://images.unsplash.com/photo-1542208998-f6dbbb27a72f?w=400",
    "https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?w=400",
    "https://images.unsplash.com/photo-1505373877841-8d25f7d46678?w=400",
    "https://images.unsplash.com/photo-1519750783826-e2420f4d687f?w=400",
  ];

  List<String> get _imageUrls {
    final injected = widget.photoUrls;
    if (injected != null && injected.isNotEmpty) return injected;
    return _defaultImageUrls;
  }

  /// URL/파일 경로 모두 받아 자동 슬라이드용 한 장을 그린다.
  /// http 면 NetworkImage, 그 외(=local 파일 경로) 면 FileImage.
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
    _tags = widget.tags;
    _scheduleDate = widget.scheduleDate;
    _location = widget.location;
    _payText = widget.payText;
    _openingsText = widget.openingsText;
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
      _imageController.animateToPage(
        _imageCurrentPage,
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeInOut,
      );
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
                              for (int i = 0;
                                  i <
                                      (_tags ??
                                              const ['D-10', 'Veteran'])
                                          .length;
                                  i++) ...[
                                if (i != 0) const SizedBox(width: 8),
                                _buildTag(
                                  (_tags ??
                                      const ['D-10', 'Veteran'])[i],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        AutoTranslateText(
                          _description ??
                              "Looking for someone to try my Malatang.",
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
                    // Cancel 모드(isApplied=true) 일 때는 상단 액션은 viewer 와 동일.
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

  /// 상단 우측: 일반 시청자(구직자/타 employer) 용. 공유 + 북마크.
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

  /// 상단 우측: 본인 공고용. 디자인 자체가 흰 원 배경 + 그림자까지 포함되어
  /// 있으므로 별도 컨테이너 없이 SVG/PNG 를 그대로 보여 준다.
  ///
  /// 주의: `jobdetail_delete_icon.svg` 파일은 확장자만 .svg 이고 실제 내용이
  /// PNG (Figma export 누락) 이므로 `Image.asset` 으로 그려야 한다.
  /// `SvgPicture.asset` 으로 PNG 를 파싱하면 build 도중 예외가 발생해
  /// 화면이 멈춘 것처럼 보일 수 있다.
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

  /// 원형 InkWell 로 감싸 탭 영역을 만들어 주는 단순 helper.
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

  /// 수정 흐름.
  /// 1) 호출 측이 [JobDetailPage.onEdit] 콜백을 주면 그것을 우선 호출
  ///    (NotePage 에서 들어온 경우 처럼 외부 컨트롤러를 갱신해야 할 때).
  /// 2) 콜백이 없으면 (= StartHiringPage 직후 등) 곧장 EmployerNoteWritePage
  ///    를 prefill 된 수정 모드로 띄우고, 결과 map 으로 화면을 즉시 갱신한다.
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
    // 삭제 완료 모달 → JobDetailPage 자체 pop. 호출 측이 결과로 알 수 있게.
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

  /// 요일별 시간 섹션. 헤더(시계 + 첫 줄 + 펼침 토글) + 펼침 시 7일 리스트.
  Widget _buildScheduleSection() {
    final shifts = widget.scheduleShifts == null || widget.scheduleShifts!.isEmpty
        ? JobShift.sevenDayDummy
        : widget.scheduleShifts!;
    final headLabel = shifts.first.rangeLabel;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더: 시계 아이콘 + 대표 시간 + 펼침 토글
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
    // 1) 본인 공고(isOwner) → "Hiring" 버튼.
    if (widget.isOwner) {
      return _bottomBar(
        label: 'Hiring',
        enabled: widget.onHiringTap != null,
        onPressed: widget.onHiringTap ?? () {},
      );
    }
    // 2) 이미 지원한 공고(isApplied) → "Cancel application" 버튼.
    if (widget.isApplied) {
      return _bottomBar(
        label: 'job_detail.cancel_application'.tr(),
        enabled: true,
        onPressed: () => _onCancelPressed(context),
      );
    }
    // 3) 그 외 → 기존 "Apply" 흐름. employer 가 남의 공고를 보면 비활성.
    final isEmployer = AuthController.to.isEmployer.value;
    return _bottomBar(
      label: 'job_detail.apply'.tr(),
      enabled: !isEmployer,
      onPressed: () => _onApplyPressed(context),
    );
  }

  /// "Cancel application" 버튼 → 확인 모달 → Yes 시 콜백 호출.
  /// 콜백이 없으면 단순히 postId 와 함께 pop 한다.
  void _onCancelPressed(BuildContext context) {
    ConfirmModal.show(
      context: context,
      message: 'job_detail.cancel_confirm'.tr(),
      cancelLabel: 'common.no'.tr(),
      acceptLabel: 'common.yes'.tr(),
      onAccept: () {
        Navigator.pop(context); // 모달 닫기
        if (!context.mounted) return;
        if (widget.onCancelApplication != null) {
          widget.onCancelApplication!();
          return;
        }
        Navigator.pop(context, {
          'cancelled': true,
          'postId': widget.postId,
        });
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
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
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
