import 'package:get/get.dart';
import '../pages/SignUpPage/signup_page.dart';
import '../pages/MainPage/main_page.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../pages/NotePage/note_tab_page.dart';
import '../bindings/note_binding.dart';

abstract class Routes {
  static const signUp = '/signup';
  static const main = '/main';
  static const mainNav = '/mainNav';
  static const noteTab = '/noteTab';
}

abstract class AppPages {
  static final routes = [
    GetPage(
      name: Routes.signUp,
      page: () => const SignUpPage(),
    ),
    GetPage(
      name: Routes.main,
      page: () => const MainPage(),
    ),
    GetPage(
      name: Routes.mainNav,
      page: () => const MainNavigationScreen(),
    ),
    GetPage(
      name: Routes.noteTab,
      page: () => const NoteTabPage(),
      binding: NoteBinding(),
    ),
  ];
}
