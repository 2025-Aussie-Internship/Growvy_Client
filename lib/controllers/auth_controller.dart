import 'package:get/get.dart';
import '../services/user_service.dart';

/// 인증/사용자 타입 ViewModel (GetX MVVM)
class AuthController extends GetxController {
  static AuthController get to => Get.find<AuthController>();

  final RxBool isLoading = true.obs;
  final RxBool isEmployer = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadUserType();
  }

  Future<void> loadUserType() async {
    isLoading.value = true;
    try {
      final result = await UserService.isEmployer();
      isEmployer.value = result;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveUserType(bool employer) async {
    await UserService.saveUserType(employer);
    isEmployer.value = employer;
  }

  Future<void> clearUserType() async {
    await UserService.clearUserType();
    isEmployer.value = false;
  }
}
