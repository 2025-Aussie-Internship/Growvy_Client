import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../styles/colors.dart';
import '../../widgets/confirm_modal.dart';
import '../../widgets/completion_modal.dart';
import '../../widgets/note_image_carousel.dart';
import 'seeker_note_write_page.dart';

class NoteDetailPage extends StatelessWidget {
  const NoteDetailPage({
    super.key,
    required this.title,
    required this.employer,
    required this.body,
    required this.photos,
  });

  final String title;
  final String employer;
  final String body;
  final List<String> photos;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: SvgPicture.asset('assets/icon/back_icon.svg'),
          onPressed: () => Navigator.of(context).pop(),
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
        actions: [
          IconButton(
            icon: SvgPicture.asset('assets/icon/share_icon.svg'),
            onPressed: () => _onShare(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 82),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.mainColor, width: 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3B3B3B),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                NoteImageCarousel(imageUrls: photos, width: 358, height: 200),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFBDBDBD), width: 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    body,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: Color(0xFF000000),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16 + MediaQuery.of(context).padding.bottom,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () => _onDelete(context),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          offset: const Offset(0, 2),
                          blurRadius: 49,

                        ),
                      ],
                    ),
                    child: SvgPicture.asset(
                      'assets/icon/delete_button.svg',
                      width: 50,
                      height: 50,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () => _onEdit(context),
                  child: SvgPicture.asset(
                    'assets/icon/edit_button.svg',
                    width: 50,
                    height: 50,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onDelete(BuildContext context) {
    ConfirmModal.show(
      context: context,
      message: 'Do you really want to delete your note?',
      cancelLabel: 'Cancel',
      acceptLabel: 'Accept',
      onCancel: () => Navigator.of(context).pop(),
      onAccept: () {
        Navigator.of(context).pop();
        CompletionModal.show(
          context,
          message: 'Delete Complete!',
          onDismiss: () => Navigator.of(context).pop(),
        );
      },
    );
  }

  void _onEdit(BuildContext context) {
    Get.to(() => SeekerNoteWritePage(
          initialTitle: title,
          initialBody: body,
          initialPhotos: List<String>.from(photos),
        ));
  }

  void _onShare(BuildContext context) {
    ConfirmModal.show(
      context: context,
      message: 'Do you want to share your note?',
      cancelLabel: 'Cancel',
      acceptLabel: 'Accept',
      onCancel: () => Navigator.of(context).pop(),
      onAccept: () {
        Navigator.of(context).pop();
        CompletionModal.show(context, message: 'Share Complete!');
      },
    );
  }
}
