import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../styles/colors.dart';
import '../../services/user_service.dart';
import '../../utils/auto_localize.dart';
import '../../widgets/auto_translate_text.dart';
import '../../widgets/confirm_modal.dart';

class DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const double dashWidth = 4;
    const double dashSpace = 4;
    final radius = 8.0;

    // Draw dashed rectangle
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    _drawDashedRRect(canvas, rect, radius, paint, dashWidth, dashSpace);
  }

  void _drawDashedRRect(Canvas canvas, Rect rect, double radius, Paint paint,
      double dashWidth, double dashSpace) {
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));

    final dashPath = Path();
    double distance = 0;
    for (final pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        final segment = pathMetric.extractPath(distance, distance + dashWidth);
        dashPath.addPath(segment, Offset.zero);
        distance += dashWidth + dashSpace;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(DashedBorderPainter oldDelegate) => false;
}

class EmployerNoteWritePage extends StatefulWidget {
  const EmployerNoteWritePage({
    super.key,
    this.initialTitle,
    this.initialDescription,
    this.initialScheduleDate,
    this.initialScheduleTime,
    this.initialLocation,
    this.initialPay,
    this.initialNumberOfHires,
    this.initialTags,
    this.isEditMode = false,
  });

  /// 아래 prop 들은 수정 모드일 때 prefill 에 사용된다. 신규 작성 모드면 모두 null.
  final String? initialTitle;
  final String? initialDescription;
  final String? initialScheduleDate;
  final String? initialScheduleTime;
  final String? initialLocation;
  final String? initialPay;
  final int? initialNumberOfHires;
  final List<String>? initialTags;

  /// true 면 Save 버튼이 draft 모달을 거치지 않고 곧바로 결과 Map 을 반환하며
  /// 페이지가 닫힌다. (호출 측에서 controller.updateEmployerJob 으로 전달)
  final bool isEditMode;

  @override
  State<EmployerNoteWritePage> createState() => _EmployerNoteWritePageState();
}

class _EmployerNoteWritePageState extends State<EmployerNoteWritePage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _scheduleDateController = TextEditingController();
  final TextEditingController _scheduleTimeController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _payController = TextEditingController();
  
  int _numberOfHires = 1;
  final List<String> _selectedTags = [];
  final List<String> _photos = [];
  bool _isEmployer = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // 수정 모드 prefill — 빈 문자열도 그대로 적용해 사용자가 비울 수 있게.
    if (widget.initialTitle != null) _titleController.text = widget.initialTitle!;
    if (widget.initialDescription != null) {
      _descriptionController.text = widget.initialDescription!;
    }
    if (widget.initialScheduleDate != null) {
      _scheduleDateController.text = widget.initialScheduleDate!;
    }
    if (widget.initialScheduleTime != null) {
      _scheduleTimeController.text = widget.initialScheduleTime!;
    }
    if (widget.initialLocation != null) {
      _locationController.text = widget.initialLocation!;
    }
    if (widget.initialPay != null) _payController.text = widget.initialPay!;
    if (widget.initialNumberOfHires != null && widget.initialNumberOfHires! > 0) {
      _numberOfHires = widget.initialNumberOfHires!;
    }
    if (widget.initialTags != null && widget.initialTags!.isNotEmpty) {
      _selectedTags
        ..clear()
        ..addAll(widget.initialTags!);
    }
    _checkUserType();
  }

  Future<void> _checkUserType() async {
    final isEmployer = await UserService.isEmployer();
    if (!isEmployer) {
      // Employer가 아니면 이전 페이지로 돌아가기
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Employer 회원만 접근할 수 있습니다.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      setState(() {
        _isEmployer = true;
        _isLoading = false;
      });
    }
  }

  // 내용이 입력되어 있는지 확인하는 메서드
  bool _hasContent() {
    return _titleController.text.isNotEmpty ||
        _descriptionController.text.isNotEmpty ||
        _scheduleDateController.text.isNotEmpty ||
        _scheduleTimeController.text.isNotEmpty ||
        _locationController.text.isNotEmpty ||
        _payController.text.isNotEmpty ||
        _selectedTags.isNotEmpty ||
        _photos.isNotEmpty;
  }

  final List<String> _availableTags = [
    'Rookie',
    'Veteran',
    'Seasonal',
    'Flexible',
    'Volunteer',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _scheduleDateController.dispose();
    _scheduleTimeController.dispose();
    _locationController.dispose();
    _payController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_isEmployer) {
      return const Scaffold(
        body: Center(
          child: Text('접근 권한이 없습니다.'),
        ),
      );
    }

    return PopScope(
      canPop: !_hasContent(),
      onPopInvoked: (didPop) {
        if (!didPop && _hasContent()) {
          _showStopRecruitingModal();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
            onPressed: () {
              if (_hasContent()) {
                _showStopRecruitingModal();
              } else {
                Navigator.pop(context);
              }
            },
          ),
          title: const AutoTranslateText(
            'Post a Job',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.white,
        ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 제목 입력 필드와 Save Draft 버튼
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Container(
                    height: 34,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.mainColor, width: 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _titleController,
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        hintText: autoLocalize(context, 'title'),
                        hintStyle: const TextStyle(color: Colors.grey),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    if (_hasContent()) {
                      _showSaveDraftModal();
                    }
                  },
                  child: Container(
                    height: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.mainColor,
                      borderRadius: BorderRadius.circular(52),
                    ),
                    child: const Center(
                      child: AutoTranslateText(
                        'Save Draft',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 상세 내용 입력 필드
            Container(
              height: 220,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFBDBDBD), width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _descriptionController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: autoLocalize(context, 'Write about your experience'),
                  hintStyle: const TextStyle(color: Color(0xFFBDBDBD)),
                  contentPadding: const EdgeInsets.all(16),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                ),
              ),
            ),
            const SizedBox(height: 26),

            // Schedule (날짜, 시간 두 필드)
            _buildSectionLabel('Schedule'),
            const SizedBox(height: 6),
            _buildTextField(
              controller: _scheduleDateController,
              hintText: 'DD/MM/YYYY - DD/MM/YYYY',
            ),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _scheduleTimeController,
              hintText: 'Shift: 00:00 - 00:00',
            ),
            const SizedBox(height: 16),

            // Location
            _buildSectionLabel('Location'),
            const SizedBox(height: 6),
            _buildTextField(
              controller: _locationController,
              hintText: 'Enter the Location',
            ),
            const SizedBox(height: 16),

            // Pay
            _buildSectionLabel('Pay'),
            const SizedBox(height: 6),
            _buildTextField(
              controller: _payController,
              hintText: 'Enter the daily rate',
            ),
            const SizedBox(height: 16),

            // Number of Hires
            _buildSectionLabel('Number of Hires'),
            const SizedBox(height: 6),
            Container(
              height: 30,
              width: 106,
              decoration: BoxDecoration(
                color: AppColors.mainColor,
                borderRadius: BorderRadius.circular(21),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, color: Colors.white, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      if (_numberOfHires > 1) {
                        setState(() {
                          _numberOfHires--;
                        });
                      }
                    },
                  ),
                  Text(
                    '$_numberOfHires',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.white, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      setState(() {
                        _numberOfHires++;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tags
            _buildSectionLabel('Tags'),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _availableTags.map((tag) {
                  final isSelected = _selectedTags.contains(tag);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedTags.remove(tag);
                        } else {
                          _selectedTags.add(tag);
                        }
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFFEE9D8)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: AutoTranslateText(
                          tag,
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFFFC6340)
                                : Colors.grey[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Photos
            _buildSectionLabel('Photos'),
            const SizedBox(height: 6),
            Row(
              children: [
                ...List.generate(4, (index) {
                  if (index < _photos.length) {
                    return _buildPhotoSlot(_photos[index], index);
                  }
                  return _buildEmptyPhotoSlot(index);
                }),
              ],
            ),
          ],
        ),
      ),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            height: 48,
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
              child: AutoTranslateText(
                widget.isEditMode ? 'Save Changes' : 'Save',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }

  /// Save 버튼: 수정 모드면 변경 데이터를 호출자에 돌려주고 페이지를 닫는다.
  /// 신규 모드는 기존 흐름(draft 모달) 유지.
  void _onSavePressed() {
    if (widget.isEditMode) {
      Navigator.pop(context, _collectFormResult());
      return;
    }
    if (_hasContent()) {
      _showSaveDraftModal();
    } else {
      Navigator.pop(context);
    }
  }

  /// 폼에 입력된 값들을 NotePageController.updateEmployerJob 에서 그대로
  /// 카드 갱신에 쓸 수 있는 형태로 묶어 반환한다.
  /// 비어있는 값은 prefill 값을 fallback 으로 사용 — 부분 수정 케이스 대응.
  Map<String, dynamic> _collectFormResult() {
    String pick(String value, String? fallback) =>
        value.trim().isEmpty ? (fallback ?? '') : value.trim();

    return <String, dynamic>{
      'title': pick(_titleController.text, widget.initialTitle),
      'description': pick(
        _descriptionController.text,
        widget.initialDescription,
      ),
      'scheduleDate': pick(
        _scheduleDateController.text,
        widget.initialScheduleDate,
      ),
      'scheduleTime': pick(
        _scheduleTimeController.text,
        widget.initialScheduleTime,
      ),
      'location': pick(_locationController.text, widget.initialLocation),
      'payText': pick(_payController.text, widget.initialPay),
      'numberOfHires': _numberOfHires,
      'tags': List<String>.from(_selectedTags),
    };
  }

  void _showStopRecruitingModal() {
    ConfirmModal.show(
      context: context,
      message: 'Do you really want to stop recruiting?',
      onAccept: () {
        Navigator.pop(context);
        Navigator.pop(context);
      },
    );
  }

  void _showSaveDraftModal() {
    ConfirmModal.show(
      context: context,
      message: 'Do you want to save draft it?',
      onAccept: () {
        Navigator.pop(context);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildSectionLabel(String label) {
    return AutoTranslateText(
      label,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
  }) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.mainColor, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          hintText: autoLocalize(context, hintText),
          hintStyle: const TextStyle(color: Colors.grey),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
        ),
      ),
    );
  }

  Widget _buildPhotoSlot(String photoUrl, int index) {
    return Container(
      width: 78,
      height: 78,
      margin: index < 3 ? const EdgeInsets.only(right: 15) : null,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: photoUrl.startsWith('http')
                ? Image.network(
                    photoUrl,
                    width: 78,
                    height: 78,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.image, size: 30),
                      );
                    },
                  )
                : Image.file(
                    File(photoUrl),
                    width: 78,
                    height: 78,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.image, size: 30),
                      );
                    },
                  ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _photos.removeAt(index);
                });
              },
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Colors.red,
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

  Widget _buildEmptyPhotoSlot(int index) {
    return GestureDetector(
      onTap: () async {
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(source: ImageSource.gallery);
        
        if (image != null) {
          setState(() {
            _photos.add(image.path);
          });
        }
      },
      child: Container(
        width: 78,
        height: 78,
        margin: index < 3 ? const EdgeInsets.only(right: 15) : null,
        child: CustomPaint(
          painter: DashedBorderPainter(),
          child: Center(
            child: const Icon(
              Icons.add,
              color: Colors.grey,
              size: 30,
            ),
          ),
        ),
      ),
    );
  }
}
