import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../styles/colors.dart';
import '../../services/user_service.dart';
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

class SeekerNoteWritePage extends StatefulWidget {
  const SeekerNoteWritePage({
    super.key,
    this.initialTitle,
    this.initialBody,
    this.initialPhotos,
  });

  /// 수정 모드일 때 기존 제목
  final String? initialTitle;
  /// 수정 모드일 때 기존 본문
  final String? initialBody;
  /// 수정 모드일 때 기존 사진 URL 목록
  final List<String>? initialPhotos;

  @override
  State<SeekerNoteWritePage> createState() => _SeekerNoteWritePageState();
}

class _SeekerNoteWritePageState extends State<SeekerNoteWritePage> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  final List<String> _photos = [];
  bool _isSeeker = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _descriptionController = TextEditingController(text: widget.initialBody ?? '');
    if (widget.initialPhotos != null) {
      _photos.addAll(widget.initialPhotos!);
    }
    _checkUserType();
  }

  Future<void> _checkUserType() async {
    final isEmployer = await UserService.isEmployer();
    if (isEmployer) {
      // Employer면 이전 페이지로 돌아가기
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Seeker 페이지'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      setState(() {
        _isSeeker = true;
        _isLoading = false;
      });
    }
  }

  bool _hasContent() {
    return _titleController.text.isNotEmpty ||
        _descriptionController.text.isNotEmpty ||
        _photos.isNotEmpty;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
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

    if (!_isSeeker) {
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
          title: const Text(
            'Note',
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
              const Text(
                'We are looking workers for my flower shop',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3B3B3B),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Jay's flower shop",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF747474),
                ),
              ),
              const SizedBox(height: 24),

              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Container(
                      height: 37,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.mainColor, width: 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: _titleController,
                        textAlignVertical: TextAlignVertical.center,
                        decoration: const InputDecoration(
                          hintText: 'Title',
                          hintStyle: TextStyle(color: Colors.grey),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      height: 37,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.mainColor,
                        borderRadius: BorderRadius.circular(52),
                      ),
                      child: const Center(
                        child: Text(
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
                height: 344,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFBDBDBD), width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _descriptionController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    hintText: 'Write about your experience',
                    hintStyle: TextStyle(color: Color(0xFFBDBDBD)),
                    contentPadding: EdgeInsets.all(16),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Photos
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
                onPressed: () {
                  if (_hasContent()) {
                    _showSaveDraftModal();
                  } else {
                    Navigator.pop(context);
                  }
                },
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showStopRecruitingModal() {
    ConfirmModal.show(
      context: context,
      message: 'Do you really want to stop recruiting?',
      cancelLabel: 'Cancel',
      acceptLabel: 'Accept',
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
      cancelLabel: 'Cancel',
      acceptLabel: 'Accept',
      onAccept: () {
        Navigator.pop(context);
        Navigator.pop(context);
      },
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
