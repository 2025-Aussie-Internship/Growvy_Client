import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../styles/colors.dart';
import '../../widgets/confirm_modal.dart';

/// My Review 수정 페이지. 티켓 배경 위에 별점·리뷰 내용 표시·수정.
/// [isEditable] false면 Received Reviews용 읽기 전용.
class ReviewDetailPage extends StatefulWidget {
  const ReviewDetailPage({
    super.key,
    required this.title,
    required this.rating,
    required this.body,
    this.index,
    this.isEditable = true,
  });

  final String title;
  final int rating;
  final String body;
  final int? index;
  final bool isEditable;

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
    Navigator.of(context).pop(<String, dynamic>{
      if (widget.index != null) 'index': widget.index,
      'body': _bodyController!.text,
      'rating': _rating,
    });
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
        cancelLabel: 'Cancel',
        acceptLabel: 'Discard',
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
    const maxTicketHeight = 520.0;

    return Scaffold(
      backgroundColor: const Color(0xFFFC6340),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: AppBar(
          automaticallyImplyLeading: false,
          title: SvgPicture.asset('assets/icon/logo_orange.svg', height: 36),
          centerTitle: true,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0.5,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 78),
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: maxTicketWidth,
                    maxHeight: maxTicketHeight,
                  ),
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
                            Center(
                              child: Text(
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
                                      child: Text(
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
                                    child: const Text('Save Changes'),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
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
