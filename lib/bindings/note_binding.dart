import 'package:get/get.dart';
import '../controllers/note_page_controller.dart';

/// Note 탭/페이지 바인딩
class NoteBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NotePageController>(() => NotePageController());
  }
}
