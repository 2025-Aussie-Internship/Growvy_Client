import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/note_page_controller.dart';
import '../../services/user_service.dart';
import '../../styles/colors.dart';
import '../../widgets/completion_modal.dart';
import '../../widgets/confirm_modal.dart';

/// 구직자가 활동 후 후기/노트를 작성하는 페이지.
class SeekerNoteWritePage extends StatefulWidget {
  const SeekerNoteWritePage({
    super.key,
    this.initialTitle,
    this.initialBody,
    this.initialPhotos,
    this.jobEmployer,
    this.sourceJob,
  });

  /// 수정 모드 / write_button 흐름에서 prefill 될 제목
  final String? initialTitle;

  /// 수정 모드일 때 기존 본문
  final String? initialBody;

  /// 수정 모드일 때 기존 사진 URL 목록
  final List<String>? initialPhotos;

  /// MyJobOpeningsModal 에서 선택된 회사명. Saved 카드 employer 표시에 사용.
  final String? jobEmployer;

  /// MyJobOpeningsModal 에서 선택된 원본 공고 항목.
  /// Save 가 끝나면 NotePageController.seekerDoneJobs 에서 이 항목을 제거하고
  /// Saved 탭으로 이동시킨다.
  final Map<String, dynamic>? sourceJob;

  @override
  State<SeekerNoteWritePage> createState() => _SeekerNoteWritePageState();
}

class _SeekerNoteWritePageState extends State<SeekerNoteWritePage> {
  static const Color _labelGray = Color(0xFFBDBDBD);
  static const Color _underlineGray = Color(0xFFE5E5E5);
  static const Color _chipBorderGray = Color(0xFFE5E5E5);
  static const Color _chipTextGray = Color(0xFFBDBDBD);
  static const int _bodyCharLimit = 1000;
  static const int _maxPhotos = 4;
  static const double _photoSlotSize = 78;

  /// 사용자가 직접 추가한 키워드까지 누적된 칩 목록. + 버튼으로 새 항목이 영구 추가된다.
  final List<String> _skills = [
    'Communication',
    'Teamwork',
    'Time Management',
    'Problem Solving',
    'Independence',
    'Adaptability',
    'Initiative',
    'Customer Interaction',
  ];

  static const List<String> _experienceLabels = [
    'Great',
    'Good',
    'Okay',
    'Challenging',
    'Tough',
  ];

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  final Set<String> _selectedSkills = <String>{};
  int _experienceIndex = 0;
  final List<String> _photos = <String>[];
  bool _isSeeker = false;
  bool _isLoading = true;

  bool _showLimitToast = false;
  Timer? _limitToastTimer;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _descriptionController = TextEditingController(
      text: widget.initialBody ?? '',
    );
    if (widget.initialPhotos != null && widget.initialPhotos!.isNotEmpty) {
      _photos.addAll(widget.initialPhotos!.take(_maxPhotos));
    }
    _descriptionController.addListener(_onBodyChanged);
    _checkUserType();
  }

  @override
  void dispose() {
    _limitToastTimer?.cancel();
    _descriptionController.removeListener(_onBodyChanged);
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _checkUserType() async {
    final isEmployer = await UserService.isEmployer();
    if (!mounted) return;
    if (isEmployer) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seeker 페이지'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() {
      _isSeeker = true;
      _isLoading = false;
    });
  }

  bool _hasContent() {
    return _titleController.text.isNotEmpty ||
        _descriptionController.text.isNotEmpty ||
        _selectedSkills.isNotEmpty ||
        _photos.isNotEmpty;
  }

  void _onBodyChanged() {
    // 글자 수가 한계에 도달했을 때만 toast 노출.
    if (_descriptionController.text.characters.length >= _bodyCharLimit) {
      _triggerLimitToast();
    }
  }

  void _triggerLimitToast() {
    _limitToastTimer?.cancel();
    if (!_showLimitToast) {
      setState(() => _showLimitToast = true);
    }
    _limitToastTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() => _showLimitToast = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isSeeker) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Text('접근 권한이 없습니다.')),
      );
    }

    return PopScope(
      canPop: !_hasContent(),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _onBackPressed();
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
          title: const Text(
            'Note',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Title', required: true),
              _buildUnderlineField(
                controller: _titleController,
                hintText: 'Enter the Job Title',
              ),
              const SizedBox(height: 24),

              _buildLabel('What did you learn?'),
              const SizedBox(height: 12),
              _buildSkillsChips(),
              const SizedBox(height: 28),

              _buildLabel('Overall Experience'),
              const SizedBox(height: 16),
              _buildExperienceSelector(),
              const SizedBox(height: 28),

              _buildLabel('Tell us about your experience', required: true),
              const SizedBox(height: 12),
              _buildBodyField(),
              const SizedBox(height: 28),

              _buildLabel('Paste your photos'),
              const SizedBox(height: 12),
              _buildPhotoBox(),
              const SizedBox(height: 16),
            ],
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          child: SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _onSavePressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mainColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- 라벨 / 입력 / 칩 helpers ----------------
  Widget _buildLabel(String text, {bool required = false}) {
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
        if (required) ...[
          const SizedBox(width: 2),
          const Text(
            '*',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.mainColor,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildUnderlineField({
    required TextEditingController controller,
    required String hintText,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 14, color: Colors.black),
      cursorColor: AppColors.mainColor,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: _labelGray, fontSize: 14),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.mainColor),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.mainColor, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildSkillsChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ..._skills.map((skill) {
          final selected = _selectedSkills.contains(skill);
          return _buildChoiceChip(
            label: skill,
            selected: selected,
            onTap: () {
              setState(() {
                if (selected) {
                  _selectedSkills.remove(skill);
                } else {
                  _selectedSkills.add(skill);
                }
              });
            },
          );
        }),
        _buildAddSkillChip(),
      ],
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.mainColor : _chipBorderGray,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected ? AppColors.mainColor : _chipTextGray,
          ),
        ),
      ),
    );
  }

  Widget _buildAddSkillChip() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _showAddSkillDialog,
      child: Container(
        width: 36,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _chipBorderGray),
        ),
        child: const Center(
          child: Icon(Icons.add, size: 14, color: _chipTextGray),
        ),
      ),
    );
  }

  Future<void> _showAddSkillDialog() async {
    final controller = TextEditingController();
    final added = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Add Skill',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            cursorColor: AppColors.mainColor,
            decoration: const InputDecoration(
              hintText: 'Enter a skill',
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: _underlineGray),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.mainColor),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.black54),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text(
                'Add',
                style: TextStyle(color: AppColors.mainColor),
              ),
            ),
          ],
        );
      },
    );
    if (added != null && added.isNotEmpty) {
      setState(() {
        if (!_skills.contains(added)) {
          _skills.add(added);
        }
        _selectedSkills.add(added);
      });
    }
  }

  // ---------------- Overall Experience ----------------
  Widget _buildExperienceSelector() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double dotSize = 14;
        final width = constraints.maxWidth;
        final segmentWidth = (width - dotSize) / (_experienceLabels.length - 1);
        final filledWidth = segmentWidth * _experienceIndex + dotSize;

        return Column(
          children: [
            SizedBox(
              height: dotSize,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: dotSize / 2),
                    height: 2,
                    decoration: BoxDecoration(
                      color: _underlineGray,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  Positioned(
                    left: dotSize / 2,
                    child: Container(
                      width: (filledWidth - dotSize).clamp(
                        0.0,
                        width - dotSize,
                      ),
                      height: 2,
                      decoration: BoxDecoration(
                        color: AppColors.mainColor,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(_experienceLabels.length, (i) {
                      final filled = i <= _experienceIndex;
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => setState(() => _experienceIndex = i),
                        child: Container(
                          width: dotSize,
                          height: dotSize,
                          decoration: BoxDecoration(
                            color: filled
                                ? AppColors.mainColor
                                : _underlineGray,
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(_experienceLabels.length, (i) {
                final filled = i <= _experienceIndex;
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _experienceIndex = i),
                    child: Text(
                      _experienceLabels[i],
                      textAlign: i == 0
                          ? TextAlign.left
                          : i == _experienceLabels.length - 1
                          ? TextAlign.right
                          : TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: filled ? AppColors.mainColor : _chipTextGray,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }

  // ---------------- 본문 textarea + Limit reached toast ----------------
  Widget _buildBodyField() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: 220,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _underlineGray),
          ),
          child: TextField(
            controller: _descriptionController,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            cursorColor: AppColors.mainColor,
            inputFormatters: [
              LengthLimitingTextInputFormatter(_bodyCharLimit),
            ],
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black,
              height: 1.45,
            ),
            decoration: const InputDecoration(
              hintText: 'How was the job?',
              hintStyle: TextStyle(color: _labelGray, fontSize: 14),
              contentPadding: EdgeInsets.all(14),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
            ),
          ),
        ),
        IgnorePointer(
          child: AnimatedOpacity(
            opacity: _showLimitToast ? 1 : 0,
            duration: const Duration(milliseconds: 180),
            child: Container(
              width: 227,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                'Limit reached',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF747474),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------- Photo slots (최대 _maxPhotos 장) ----------------
  Widget _buildPhotoBox() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (int i = 0; i < _photos.length; i++) _buildPhotoThumb(i),
        if (_photos.length < _maxPhotos) _buildAddPhotoSlot(),
      ],
    );
  }

  Widget _buildAddPhotoSlot() {
    return GestureDetector(
      onTap: _pickPhoto,
      child: Container(
        width: _photoSlotSize,
        height: _photoSlotSize,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _underlineGray),
        ),
        alignment: Alignment.center,
        child: SvgPicture.asset(
          'assets/icon/add_photo_icon.svg',
          width: 34,
          height: 34,
          colorFilter: const ColorFilter.mode(
            _chipTextGray,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoThumb(int index) {
    final photoUrl = _photos[index];
    return SizedBox(
      width: _photoSlotSize,
      height: _photoSlotSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: photoUrl.startsWith('http')
                  ? Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _thumbFallback(),
                    )
                  : Image.file(
                      File(photoUrl),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _thumbFallback(),
                    ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => setState(() => _photos.removeAt(index)),
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: AppColors.mainColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _thumbFallback() => Container(
    color: Colors.grey.shade200,
    child: const Icon(Icons.image, size: 24),
  );

  Future<void> _pickPhoto() async {
    if (_photos.length >= _maxPhotos) return;
    final picker = ImagePicker();
    final remaining = _maxPhotos - _photos.length;

    // 갤러리에서 여러 장 한 번에 선택할 수 있도록 multi-image picker 사용.
    final images = await picker.pickMultiImage(limit: remaining);
    if (images.isEmpty) return;
    setState(() {
      for (final img in images) {
        if (_photos.length >= _maxPhotos) break;
        _photos.add(img.path);
      }
    });
  }

  // ---------------- 흐름: 뒤로가기 / 저장 ----------------
  void _onBackPressed() {
    if (_hasContent()) {
      _showStopRecruitingModal();
    } else {
      Navigator.pop(context);
    }
  }

  /// 뒤로가기 시 첫 번째 확인 모달. Accept 시 두 번째(save draft) 모달로 이어진다.
  void _showStopRecruitingModal() {
    ConfirmModal.show(
      context: context,
      message: 'Do you really want\nto stop recruiting?',
      cancelLabel: 'Cancel',
      acceptLabel: 'Accept',
      onCancel: () => Navigator.pop(context),
      onAccept: () {
        Navigator.pop(context);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showSaveDraftModal();
        });
      },
    );
  }

  /// 두 번째 모달: draft 저장 여부 확인. Accept 시 완료 모달(2초)로 이어지고 페이지 종료.
  void _showSaveDraftModal() {
    ConfirmModal.show(
      context: context,
      message: 'Do you want\nto save draft it?',
      cancelLabel: 'Cancel',
      acceptLabel: 'Accept',
      onCancel: () {
        Navigator.pop(context);
        if (mounted) Navigator.pop(context);
      },
      onAccept: () {
        Navigator.pop(context);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showSaveCompleteModal();
        });
      },
    );
  }

  /// Save 버튼 또는 Save Draft Accept 후 표시되는 2초 완료 모달.
  /// 모달이 사라지면 입력한 값으로 NotePageController에 노트를 추가하고 페이지를 닫는다.
  void _showSaveCompleteModal() {
    _persistNote();
    CompletionModal.show(
      context,
      message: 'Save Complete!',
      onDismiss: () {
        if (mounted) Navigator.pop(context);
      },
    );
  }

  /// 현재 입력값으로 Saved 탭에 표시될 노트를 만들어 controller에 등록하고,
  /// 원본 공고가 있다면 Done 목록에서 제거한 뒤 Saved 탭으로 이동시킨다.
  void _persistNote() {
    final title = _titleController.text.trim().isEmpty
        ? (widget.initialTitle ?? 'Untitled Note')
        : _titleController.text.trim();
    final employer = widget.jobEmployer?.trim().isNotEmpty == true
        ? widget.jobEmployer!.trim()
        : _experienceLabels[_experienceIndex];
    final note = <String, dynamic>{
      'title': title,
      'employer': employer,
      'dDay': 'Saved',
      'tag': _experienceLabels[_experienceIndex],
      'body': _descriptionController.text.trim(),
      'photos': List<String>.from(_photos),
      'skills': _selectedSkills.toList(),
      'hasContent': true,
      // 후속 동기화/중복 방지를 위해 어느 공고로부터 작성된 노트인지 기록.
      if (widget.sourceJob?['id'] != null) 'sourceId': widget.sourceJob!['id'],
    };
    if (Get.isRegistered<NotePageController>()) {
      final controller = Get.find<NotePageController>();
      controller.addSeekerWrittenNote(note);
      if (widget.sourceJob != null) {
        controller.consumeSeekerDoneJob(widget.sourceJob!);
      }
      controller.setSeekerTab(3);
    }
  }

  void _onSavePressed() {
    _showSaveCompleteModal();
  }
}
