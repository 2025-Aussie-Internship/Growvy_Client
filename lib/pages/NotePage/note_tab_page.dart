import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/note_page_controller.dart';
import 'note_page.dart';

/// Note 탭 View (GetX MVVM) – 동일한 Note 페이지, write만 직업별 분리
class NoteTabPage extends GetView<AuthController> {
  const NoteTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Scaffold(
          backgroundColor: Colors.white,
          body: Center(child: CircularProgressIndicator()),
        );
      }
      if (!Get.isRegistered<NotePageController>()) {
        Get.put(NotePageController());
      }
      return const NotePage();
    });
  }
}
