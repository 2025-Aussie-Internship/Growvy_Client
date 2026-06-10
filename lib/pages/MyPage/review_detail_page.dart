import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../styles/colors.dart';
import '../../widgets/auto_translate_text.dart';
import '../../widgets/confirm_modal.dart';
import '../../widgets/completion_modal.dart';
import '../../widgets/safe_back_app_bar.dart';

/// My Review 수정 페이지. 티켓 배경 위에 별점·리뷰 내용 표시·수정.
/// [isEditable] false면 Received Reviews용 읽기 전용.
///
/// [peerName] 이 주어지면 구인자가 특정 지원자에 대한 리뷰를 새로 작성하는
/// 흐름(Note → Done → Write Review)으로 간주해 제목 위에 작은 헤더로
/// "Reviewing  <프로필 사진>  <이름>" 행을 보여준다.
/// 이 인자는 nullable 이라 기존 MyPage 리뷰 보기/수정 흐름은 영향 없음.
class ReviewDetailPage extends StatefulWidget {
  const ReviewDetailPage({
    super.key,
    required this.title,
    required this.rating,
    required this.body,
    this.index,
    this.isEditable = true,
    this.peerName,
    this.peerProfileImagePath,
  });

  final String title;
  final int rating;
  final String body;
  final int? index;
  final bool isEditable;

  /// 누구에 대한 리뷰인지 (구인자 → 지원자 리뷰 흐름에서만 사용).
  final String? peerName;
  final String? peerProfileImagePath;

  @override
  State<ReviewDetailPage> createState() => _ReviewDetailPageState();
}

class _ReviewDetailPageState extends State<ReviewDetailPage> {
  TextEditingController? _bodyController;
  late final String _initialBody;
  int _rating = 1;

  @override
  void initState() {
    super.initState();
    _initialBody = widget.body;
    _rating = widget.rating.clamp(1, 5);
    if (widget.isEditable) {
      _bodyController = TextEditingController(text: widget.body);
    }
  }

  @override
  void dispose() {
    _bodyController?.dispose();
    super.dispose();
  }

  bool get _hasChanges =>
      widget.isEditable &&
      (_bodyController != null && _bodyController!.text != _initialBody ||
          _rating != widget.rating);

  void _onSaveChanges() {
    if (!widget.isEditable || _bodyController == null) return;
    final result = <String, dynamic>{
      if (widget.index != null) 'index': widget.index,
      'body': _bodyController!.text,
      'rating': _rating,
    };
    CompletionModal.show(
      context,
      message: 'Change Saved!',
      onDismiss: () => Navigator.of(context).pop(result),
    );
  }

  void _onClose() {
    if (!widget.isEditable) {
      Navigator.of(context).pop();
      return;
    }
    if (_hasChanges) {
      ConfirmModal.show(
        context: context,
        message: 'Changes you made may not be saved',
        acceptLabel: 'common.discard'.tr(),
        onCancel: () => Navigator.of(context).pop(),
        onAccept: () {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        },
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final maxTicketWidth = width - 32.0;

    return Scaffold(
      backgroundColor: const Color(0xFFFC6340),
      appBar: const SafeBackAppBar(),
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 24),
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxTicketWidth),
                  child: ClipRect(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.asset(
                          'assets/image/review_background.png',
                          fit: BoxFit.contain,
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.peerName != null) ...[
                              _buildPeerHeader(),
                              const SizedBox(height: 8),
                            ],
                            Center(
                              child: AutoTranslateText(
                                widget.title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: _buildStarRating(
                                widget.isEditable ? _rating : widget.rating,
                                isEditable: widget.isEditable,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              width: 294,
                              height: 298,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: const Color(0xFFF5F5F5),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.all(12),
                              child: widget.isEditable
                                  ? TextField(
                                      controller: _bodyController,
                                      maxLines: null,
                                      expands: true,
                                      textAlignVertical: TextAlignVertical.top,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        height: 1.5,
                                        color: Color(0xFF4E2121),
                                        fontWeight: FontWeight.w400,
                                      ),
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                      ),
                                    )
                                  : SingleChildScrollView(
                                      child: AutoTranslateText(
                                        widget.body,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          height: 1.5,
                                          color: Color(0xFF4E2121),
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                            ),
                            if (widget.isEditable) ...[
                              const SizedBox(height: 16),
                              Center(
                                child: SizedBox(
                                  width: 294,
                                  height: 43,
                                  child: FilledButton(
                                    onPressed: _onSaveChanges,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.mainColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(26),
                                      ),
                                    ),
                                    child: const AutoTranslateText('Save Changes'),
                                  ),
                                ),
                              ),
                              // 티켓 바닥과 Save Changes 버튼 사이 여백.
                              // 기존엔 버튼이 티켓 하단 가장자리에 거의 붙어 있었다.
                              const SizedBox(height: 36),
                            ],
                          ],
                        ),
                      ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: _onClose,
                  child: SvgPicture.asset(
                    'assets/icon/close_button.svg',
                    width: 50,
                    height: 50,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
    );
  }

  /// 구인자→지원자 리뷰 흐름에서 제목 위에 노출되는
  /// "Reviewing  <프로필>  <이름>" 칩 형태의 헤더.
  Widget _buildPeerHeader() {
    final name = widget.peerName ?? '';
    final imagePath = widget.peerProfileImagePath;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AutoTranslateText(
            'Reviewing',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF747474),
            ),
          ),
          const SizedBox(width: 8),
          if (imagePath != null && imagePath.isNotEmpty)
            CircleAvatar(
              radius: 11,
              backgroundColor: const Color(0xFFEFEFEF),
              backgroundImage: AssetImage(imagePath),
              onBackgroundImageError: (_, __) {},
            ),
          if (imagePath != null && imagePath.isNotEmpty)
            const SizedBox(width: 6),
          AutoTranslateText(
            name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarRating(int rating, {bool isEditable = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (starIndex) {
        final filled = starIndex < rating;
        final star = Padding(
          padding: const EdgeInsets.only(right: 4),
          child: SvgPicture.asset(
            filled ? 'assets/icon/score_filled_icon.svg' : 'assets/icon/score_not_icon.svg',
            width: 44,
            height: 44,
            colorFilter: ColorFilter.mode(
              filled ? AppColors.mainColor : const Color(0xFFBDBDBD),
              BlendMode.srcIn,
            ),
          ),
        );
        if (isEditable) {
          return GestureDetector(
            onTap: () => setState(() => _rating = starIndex + 1),
            behavior: HitTestBehavior.opaque,
            child: star,
          );
        }
        return star;
      }),
    );
  }
}
