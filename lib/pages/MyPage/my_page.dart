import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../styles/colors.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../SignUpPage/signup_page.dart';
import 'review_page.dart';
import 'profile_edit_page.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  int _currentProfileIndex = 0;
  ImageProvider get _currentProfileImage =>
      _profileImages[_currentProfileIndex];
  Color _bannerColor = AppColors.mainColor;
  String _userName = 'My Name';
  String _editPronouns = 'She/Her';
  late final TextEditingController _nameController;

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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _userName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _openProfileEdit() async {
    if (!mounted) return;
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => ProfileEditPage(
          profileImages: _profileImages,
          initialProfileIndex: _currentProfileIndex,
          initialBannerColor: _bannerColor,
          initialUserName: _userName,
          initialPronouns: _editPronouns,
        ),
      ),
    );
    if (!mounted) return;
    if (result != null) {
      setState(() {
        _currentProfileIndex =
            result['profileIndex'] as int? ?? _currentProfileIndex;
        _bannerColor = result['bannerColor'] as Color? ?? _bannerColor;
        if (result['userName'] != null)
          _userName = result['userName'] as String;
        if (result['pronouns'] != null)
          _editPronouns = result['pronouns'] as String;
      });
      _nameController.text = _userName;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 12),
          Text(
            _userName,
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
          Container(height: 140, width: double.infinity, color: _bannerColor),
          Positioned(
            bottom: 0,
            child: Stack(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
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
                    onTap: _openProfileEdit,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: AppColors.mainColor,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(6.5),
                      child: SvgPicture.asset(
                        'assets/icon/profile_edit_icon.svg',
                        width: 11,
                        height: 11,
                        fit: BoxFit.contain,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
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
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const ReviewPage()),
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Center(
                  child: Text(
                    'Check reviews',
                    style: TextStyle(
                      color: const Color(0xFF931515),
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
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
