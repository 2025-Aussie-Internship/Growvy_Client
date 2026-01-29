import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

/// 앱 최초 바인딩 (AuthController 등 전역 의존성)
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<AuthController>(AuthController(), permanent: true);
  }
}
