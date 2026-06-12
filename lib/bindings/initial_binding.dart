import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/signup_data_controller.dart';
import '../controllers/user_profile_controller.dart';

/// 앱 최초 바인딩 (AuthController, SignupDataController, UserProfileController
/// 등 전역 의존성).
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<AuthController>(AuthController(), permanent: true);
    // 회원가입 흐름의 각 단계 입력값을 누적했다가 마지막에 한 번에 서버로 보내기 위한 컨트롤러.
    Get.put<SignupDataController>(SignupDataController(), permanent: true);
    // 로그인된 사용자 프로필을 앱 전역 single source-of-truth 로 보관.
    // 앱 시작 직후 디스크 캐시(SharedPreferences) 에서 복원하여 MyPage 등이
    // 곧바로 사진/이름을 그릴 수 있게 한다.
    final profileCtrl = Get.put<UserProfileController>(
      UserProfileController(),
      permanent: true,
    );
    profileCtrl.loadFromCache();
  }
}
