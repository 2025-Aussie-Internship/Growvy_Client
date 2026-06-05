import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../controllers/note_page_controller.dart';
import '../../styles/colors.dart';
import '../../widgets/completion_modal.dart';
import '../../widgets/confirm_modal.dart';

/// 구직자가 작성한 노트(후기) 상세 페이지.
///
/// 상단에 큰 이미지와 작은 썸네일들, 흰색 카드 안에 제목·skills·overall experience·본문을
/// 배치한다. Share / Delete 는 우상단 원형 버튼이며 누르면 다른 페이지에서 사용한
/// [ConfirmModal] / [CompletionModal] 스타일을 그대로 사용한다.
/// 새 노트 작성·수정 진입은 외부의 write_button(FAB) 으로 일원화한다.
class NoteDetailPage extends StatefulWidget {
  const NoteDetailPage({
    super.key,
    required this.item,
    this.onBack,
  });

  /// NotePageController 가 만든 노트 데이터 한 건.
  /// (title / employer / body / photos / skills / tag(=experience) 등을 담는다.)
  final Map<String, dynamic> item;

  /// 인라인으로 사용될 때 뒤로가기 콜백.
  /// null 이면 [Navigator.pop] 으로 동작한다.
  final VoidCallback? onBack;

  @override
  State<NoteDetailPage> createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends State<NoteDetailPage> {
  static const double _imageHeight = 330;
  static const double _cardOverlap = 24;

  static const List<String> _experienceLabels = [
    'Great',
    'Good',
    'Okay',
    'Challenging',
    'Tough',
  ];

  /// 현재 hero(큰 이미지) 로 보여줄 사진의 인덱스. 썸네일을 누르면 갱신된다.
  int _selectedHeroIndex = 0;

  @override
  void didUpdateWidget(covariant NoteDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.item, widget.item)) {
      _selectedHeroIndex = 0;
    }
  }

  void _handleBack(BuildContext context) {
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  String get _title => widget.item['title'] as String? ?? '';
  String get _employer => widget.item['employer'] as String? ?? '';
  String get _body => widget.item['body'] as String? ?? '';
  List<String> get _photos =>
      List<String>.from(widget.item['photos'] as List? ?? const []);
  List<String> get _skills =>
      List<String>.from(widget.item['skills'] as List? ?? const []);

  /// 작성 시 저장한 experience 레이블 (Great / Good / Okay / Challenging / Tough).
  String get _experience {
    final tag = widget.item['tag'] as String?;
    if (tag != null && _experienceLabels.contains(tag)) return tag;
    return _experienceLabels[1];
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ---------- 1) 상단 큰 이미지 ----------
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: _imageHeight,
            child: _buildHeroImage(),
          ),

          // ---------- 2) 본문 카드 ----------
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(top: _imageHeight - _cardOverlap),
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _employer,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF747474),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_skills.isNotEmpty) ...[
                      _buildSkillsRow(),
                      const SizedBox(height: 18),
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFF2F4F7),
                      ),
                      const SizedBox(height: 18),
                    ],
                    const Text(
                      'Overall Experience',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildExperienceChip(),
                    const SizedBox(height: 18),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFF2F4F7),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'My experience',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildBodyBox(),
                  ],
                ),
              ),
            ),
          ),

          // ---------- 3) 좌상단 뒤로가기 / 우상단 share·delete ----------
          Positioned(
            top: topInset + 8,
            left: 16,
            child: _CircleIconButton(
              onTap: () => _handleBack(context),
              child: SvgPicture.asset(
                'assets/icon/back_icon.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  AppColors.mainColor,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          Positioned(
            top: topInset + 8,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _CircleIconButton(
                  onTap: () => _onShare(context),
                  child: SvgPicture.asset(
                    'assets/icon/share_icon.svg',
                    width: 24,
                    height: 24,
                    colorFilter: const ColorFilter.mode(
                      AppColors.mainColor,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _CircleIconButton(
                  onTap: () => _onDelete(context),
                  child: SvgPicture.asset(
                    'assets/icon/delete_icon.svg',
                    width: 24,
                    height: 24,
                    colorFilter: const ColorFilter.mode(
                      AppColors.mainColor,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ---------- 4) 이미지 하단 작은 썸네일 (가로 스크롤) ----------
          if (_photos.length > 1)
            Positioned(
              top: _imageHeight - 88,
              left: 16,
              right: 16,
              child: _buildThumbnailStrip(),
            ),
          // 우하단 edit FAB 는 MainPage 의 write_button FAB 와 시각적으로 겹쳐
          // 이중으로 보였기 때문에 제거. 노트 작성/수정은 외부 write_button 으로 진입한다.
        ],
      ),
    );
  }

  // ---------------- 이미지/썸네일 ----------------
  Widget _buildHeroImage() {
    if (_photos.isEmpty) {
      return Container(
        color: const Color(0xFFF2F2F2),
        alignment: Alignment.center,
        child: const Icon(
          Icons.image_outlined,
          size: 48,
          color: Color(0xFFBDBDBD),
        ),
      );
    }
    final safeIndex = _selectedHeroIndex.clamp(0, _photos.length - 1);
    final hero = _photos[safeIndex];
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: KeyedSubtree(
        key: ValueKey<String>('hero-$safeIndex-$hero'),
        child: _buildImage(hero, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildThumbnailStrip() {
    const double size = 56;
    // hero 로 표시되고 있는 사진을 제외한 나머지 = 작은 썸네일.
    final indices = <int>[
      for (int i = 0; i < _photos.length; i++)
        if (i != _selectedHeroIndex) i,
    ];
    if (indices.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: size,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        reverse: true, // 우측 정렬 후 왼쪽으로 스크롤되는 자연스러운 동선
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < indices.length; i++) ...[
              if (i != 0) const SizedBox(width: 8),
              _buildThumbnail(indices[i], size: size),
            ],
          ],
        ),
      ),
    );
  }

  /// 흰색 프레임(padding=2) + 안쪽 둥근 모서리로 깔끔하게 잘리는 썸네일.
  /// 탭하면 해당 인덱스가 hero 로 승격된다.
  Widget _buildThumbnail(int index, {required double size}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _selectedHeroIndex = index),
      child: Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: _buildImage(_photos[index], fit: BoxFit.cover),
        ),
      ),
    );
  }

  Widget _buildImage(String path, {BoxFit fit = BoxFit.cover}) {
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: fit,
        errorBuilder: (_, _, _) => _imageFallback(),
      );
    }
    return Image.file(
      File(path),
      fit: fit,
      errorBuilder: (_, _, _) => _imageFallback(),
    );
  }

  Widget _imageFallback() => Container(
    color: const Color(0xFFEFEFEF),
    alignment: Alignment.center,
    child: const Icon(Icons.image, color: Color(0xFFBDBDBD)),
  );

  // ---------------- Skills / Experience ----------------
  Widget _buildSkillsRow() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _skills
          .map(
            (s) => Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.mainColor),
              ),
              child: Text(
                s,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.mainColor,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildExperienceChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.mainColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _experience,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  // ---------------- 본문 박스 ----------------
  Widget _buildBodyBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Text(
        _body.isEmpty ? '' : _body,
        style: const TextStyle(
          fontSize: 13,
          height: 1.55,
          color: Color(0xFF3B3B3B),
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  // ---------------- 액션 핸들러 ----------------
  void _onShare(BuildContext context) {
    ConfirmModal.show(
      context: context,
      message: 'Do you want\nShare your note?',
      cancelLabel: 'Cancel',
      acceptLabel: 'Sure',
      onCancel: () => Navigator.of(context).pop(),
      onAccept: () {
        Navigator.of(context).pop();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          CompletionModal.show(context, message: 'Share Complete!');
        });
      },
    );
  }

  void _onDelete(BuildContext context) {
    ConfirmModal.show(
      context: context,
      message: 'Do you want\nDelete your note?',
      cancelLabel: 'Cancel',
      acceptLabel: 'Sure',
      onCancel: () => Navigator.of(context).pop(),
      onAccept: () {
        Navigator.of(context).pop();
        // 컨트롤러에서 즉시 제거 → Saved 탭에서 사라짐.
        if (Get.isRegistered<NotePageController>()) {
          Get.find<NotePageController>().deleteSeekerWrittenNote(widget.item);
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          CompletionModal.show(
            context,
            message: 'Delete Complete!',
            onDismiss: () => _handleBack(context),
          );
        });
      },
    );
  }
}

/// 상단 액션용 흰색 원형 버튼 (그림자 포함).
class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
