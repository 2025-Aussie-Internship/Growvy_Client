import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../bindings/main_binding.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/note_page_controller.dart';
import 'note_page.dart';
import 'seeker_note_detail_page.dart';

/// Note 탭 View (GetX MVVM) – 동일한 Note 페이지, write만 직업별 분리.
///
/// build 도중에 RxBool 을 쓰면 다른 Obx 가 다음 프레임에서 재빌드 되면서
/// seeker 진입 직후 race condition 으로 멈춤 현상이 발생할 수 있어,
/// 동기화는 post-frame 콜백으로 분리한다.
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

      // NotePageController 미등록인 경우에만 한 번 등록.
      if (!Get.isRegistered<NotePageController>()) {
        MainBinding().dependencies();
      }
      final noteCtrl = Get.find<NotePageController>();

      // 값이 다를 때만, 그것도 build 가 끝난 뒤에 안전하게 동기화.
      final desired = controller.isEmployer.value;
      if (noteCtrl.isEmployer != desired ||
          noteCtrl.isEmployerObs.value != desired) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          noteCtrl.isEmployer = desired;
          if (noteCtrl.isEmployerObs.value != desired) {
            noteCtrl.isEmployerObs.value = desired;
          }
        });
      }

      // viewingNote 가 설정되어 있으면 같은 탭 안에서 상세 화면을 표시.
      // 이렇게 하면 MainPage 의 BottomNavigationBar 가 계속 보인다.
      final viewing = noteCtrl.viewingNote.value;
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 240),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: viewing == null
            ? const KeyedSubtree(
                key: ValueKey('note-list'),
                child: NotePage(),
              )
            : KeyedSubtree(
                key: ValueKey(
                  'note-detail-${identityHashCode(viewing)}',
                ),
                child: NoteDetailPage(
                  item: viewing,
                  onBack: noteCtrl.closeViewingNote,
                ),
              ),
      );
    });
  }
}
