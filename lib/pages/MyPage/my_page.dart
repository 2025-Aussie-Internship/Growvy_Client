import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../styles/colors.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../SignUpPage/signup_page.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  // Current profile image provider
  ImageProvider _currentProfileImage = const AssetImage(
    'assets/image/test_profile.png',
  );

  final List<ImageProvider> _profileImages = [
    const AssetImage('assets/image/test_profile1.png'),
    const AssetImage('assets/image/test_profile2.png'),
    const AssetImage('assets/image/test_profile3.png'),
    const AssetImage('assets/image/test_profile4.png'),
    const AssetImage('assets/image/test_profile5.png'),
    const AssetImage('assets/image/test_profile6.png'),
    const AssetImage('assets/image/test_profile7.png'),
    const AssetImage('assets/image/test_profile8.png'),
    const AssetImage('assets/image/test_profile9.png'),
  ];

  void _showProfilePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _ProfilePickerBottomSheetContent(
          profileImages: _profileImages,
          onImageSelected: (image) {
            setState(() {
              _currentProfileImage = image;
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 12),
          const Text(
            'My Name',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'She/Her',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          _buildRatingCard(),
          const SizedBox(height: 24),
          _buildMenuOption('Customer Service Center'),
          _buildDivider(),
          _buildMenuOption('Notice'),
          _buildDivider(),
          _buildMenuOption('Settings'),
          _buildDivider(),
          _buildMenuOption('Account Deletion'),
          const SizedBox(height: 40),
          GestureDetector(
            onTap: () async {
              await Get.find<AuthController>().clearUserType();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const SignUpPage()),
                (route) => false,
              );
            },
            child: Text(
              'Log Out',
              style: TextStyle(
                decoration: TextDecoration.underline,
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 120), // Bottom padding for nav bar
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SizedBox(
      height: 200,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Green Background
          Container(
            height: 140,
            width: double.infinity,
            color: AppColors.mainColor,
          ),
          // Profile Image
          Positioned(
            bottom: 0,
            child: Stack(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    image: DecorationImage(
                      image: _currentProfileImage,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: _showProfilePicker,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: AppColors.mainColor, // Using main orange color
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4EE), // Light orange/peach
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/icon/score_filled_icon.svg',
                width: 32,
                height: 32,
              ),
              const SizedBox(width: 8),
              SvgPicture.asset(
                'assets/icon/score_filled_icon.svg',
                width: 32,
                height: 32,
              ),
              const SizedBox(width: 8),
              SvgPicture.asset(
                'assets/icon/score_filled_icon.svg',
                width: 32,
                height: 32,
              ),
              const SizedBox(width: 8),
              SvgPicture.asset(
                'assets/icon/score_filled_icon.svg',
                width: 32,
                height: 32,
              ),
              const SizedBox(width: 8),
              SvgPicture.asset(
                'assets/icon/score_not_icon.svg',
                width: 32,
                height: 32,
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              // Navigate to reviews
            },
            child: const Text(
              'Check reviews',
              style: TextStyle(
                color: Color(0xFF931515),
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOption(String title) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey[700],
          fontWeight: FontWeight.w400,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 16,
        color: Colors.grey[400],
      ),
      onTap: () {
        // Navigate logic
      },
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFFF2F4F7),
      indent: 20,
      endIndent: 20,
    );
  }
}

class _ProfilePickerBottomSheetContent extends StatefulWidget {
  final List<ImageProvider> profileImages;
  final Function(ImageProvider) onImageSelected;

  const _ProfilePickerBottomSheetContent({
    required this.profileImages,
    required this.onImageSelected,
  });

  @override
  State<_ProfilePickerBottomSheetContent> createState() =>
      _ProfilePickerBottomSheetContentState();
}

class _ProfilePickerBottomSheetContentState
    extends State<_ProfilePickerBottomSheetContent> {
  late PageController _pageController;
  double _currentPage = 10000.0;

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

  int get _currentIndex => (_currentPage.round() % widget.profileImages.length);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 480,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 20),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF7252), // Orange close button
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
          const Text(
            'Pick Your Profile',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Color(0xFFFF7252), // Orange text
            ),
          ),
          const SizedBox(height: 40),
          // Overlapping Carousel with 5 visible profiles
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
          // Dot indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.profileImages.length,
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  widget.onImageSelected(widget.profileImages[_currentIndex]);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mainColor, // Orange
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Save Changes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
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
      int actualIndex = index % widget.profileImages.length;
      if (actualIndex < 0) actualIndex += widget.profileImages.length;

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
                  image: widget.profileImages[actualIndex],
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
