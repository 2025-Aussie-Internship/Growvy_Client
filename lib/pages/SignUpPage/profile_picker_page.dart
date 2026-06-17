import 'package:easy_localization/easy_localization.dart' hide StringTranslateExtension;
import '../../i18n/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import '../../controllers/signup_data_controller.dart';
import '../../styles/colors.dart';
import '../../widgets/signin_app_bar.dart';
import '../../widgets/next_button.dart';
import 'signup_complete_page.dart';

class ProfilePickerPage extends StatefulWidget {
  const ProfilePickerPage({super.key});

  @override
  State<ProfilePickerPage> createState() => _ProfilePickerPageState();
}

class _ProfilePickerPageState extends State<ProfilePickerPage> {
  late PageController _pageController;
  double _currentPage = 10000.0;

  final List<String> _profileImages = [
    'assets/image/test_profile1.png',
    'assets/image/test_profile2.png',
    'assets/image/test_profile3.png',
    'assets/image/test_profile4.png',
    'assets/image/test_profile5.png',
    'assets/image/test_profile6.png',
    'assets/image/test_profile7.png',
    'assets/image/test_profile8.png',
    'assets/image/test_profile9.png',
  ];

  @override
  void initState() {
    super.initState();
    final data = Get.find<SignupDataController>();
    final imageId = data.profileImageId ?? 1;
    final startPage = 10000 + (imageId - 1).clamp(0, _profileImages.length - 1);
    _currentPage = startPage.toDouble();
    _pageController = PageController(
      viewportFraction: 0.18,
      initialPage: startPage,
    );
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page ?? startPage.toDouble();
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int get _currentIndex => (_currentPage.round() % _profileImages.length);

  @override
  Widget build(BuildContext context) {
    context.locale; // setLocale 시 자동 rebuild 보장
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const SignInAppBar(),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 1),

          Text(
            'signup.pick_profile'.tr(),
            style: const TextStyle(
              color: AppColors.mainColor,
              fontSize: 28,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 50),

          SizedBox(
            height: 160,
            child: Stack(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: _buildProfileStack(constraints.maxWidth),
                    );
                  },
                ),
                PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    return const SizedBox();
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _profileImages.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: index == _currentIndex ? 16 : 8,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: index == _currentIndex
                      ? AppColors.mainColor
                      : Colors.grey[300],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
          Center(
            child: SizedBox(
              width: 320,
              child: NextButton(
                text: 'common.next'.tr(),
                onPressed: () {
                  // 현재 가운데에 보이는 프로필을 저장.
                  // 백엔드의 profileImageId 는 1-based 정수라서 index+1 로 보낸다.
                  // (정식 이미지 업로드 API 가 붙으면 그 응답으로 받은 id 로 교체.)
                  Get.find<SignupDataController>().setProfileImage(
                    _profileImages[_currentIndex],
                    id: _currentIndex + 1,
                  );
                  // GetX 라우터로 통일 — 이후 SignupCompletePage 에서
                  // Get.offAll 로 stack 을 비울 때 navigator 간 어긋남이 없도록 한다.
                  Get.to(() => const SignupCompletePage());
                },
              ),
            ),
          ),

          const Spacer(flex: 2),
        ],
      ),
    );
  }

  List<Widget> _buildProfileStack(double screenWidth) {
    List<Widget> items = [];
    int centerIndex = _currentPage.round();

    List<int> renderOrder = [-2, 2, -1, 1, 0];

    double edgePadding = 35;

    for (int offset in renderOrder) {
      int index = centerIndex + offset;
      int actualIndex = index % _profileImages.length;
      if (actualIndex < 0) actualIndex += _profileImages.length;

      double difference = index - _currentPage;

      double size = offset == 0 ? 120 : 80;

      double availableWidth = screenWidth - (edgePadding * 2);

      double centerX = screenWidth / 2;

      double horizontalSpacing = (availableWidth / 5);
      double xOffset = difference * horizontalSpacing;

      double yOffset = difference.abs() * 10;

      items.add(
        Positioned(
          left: centerX - (size / 2) + xOffset,
          top: (160 - size) / 2 + yOffset,
          child: GestureDetector(
            onTap: () {
              if (offset != 0) {
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            },
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage(_profileImages[actualIndex]),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(offset == 0 ? 0.2 : 0.1),
                    blurRadius: offset == 0 ? 15 : 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return items;
  }
}
