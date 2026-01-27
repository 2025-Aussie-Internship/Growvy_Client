import 'package:flutter/material.dart';
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
    _pageController = PageController(
      viewportFraction: 0.18,
      initialPage: 10000,
    );
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page ?? 10000.0;
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const SignInAppBar(),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 1),

          const Text(
            'Pick Your Profile',
            style: TextStyle(
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
                text: 'Next',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SignupCompletePage(),
                    ),
                  );
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
