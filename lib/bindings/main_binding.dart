import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/note_page_controller.dart';

/// MainPage 진입 시 NotePageController 등 메인 화면 의존성 등록
class MainBinding extends Bindings {
  @override
  void dependencies() {
    _ensureNotePageController();
  }

  static void _ensureNotePageController() {
    final NotePageController noteController;
    if (Get.isRegistered<NotePageController>()) {
      noteController = Get.find<NotePageController>();
    } else {
      noteController = Get.put(NotePageController(), permanent: true);
    }
    if (Get.isRegistered<AuthController>()) {
      noteController.isEmployer = AuthController.to.isEmployer.value;
    }
  }
}
