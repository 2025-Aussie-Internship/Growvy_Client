import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../controllers/auth_controller.dart';
import '../../styles/colors.dart';
import '../../widgets/confirm_modal.dart';
import '../../widgets/completion_modal.dart';

class JobDetailPage extends StatefulWidget {
  const JobDetailPage({super.key, this.postId});

  /// 공고 ID. Apply 성공 시 이 값을 pop하여 호출측에서 리스트에서 제거할 수 있음.
  final dynamic postId;

  @override
  State<JobDetailPage> createState() => _JobDetailPageState();
}

class _JobDetailPageState extends State<JobDetailPage> {
  static const double imageHeight = 300;
  static const double overlap = 20.0;

  late PageController _imageController;
  late Timer _imageTimer;
  int _imageCurrentPage = 1000;

  final List<String> _imageUrls = [
    "https://images.unsplash.com/photo-1542208998-f6dbbb27a72f?w=400",
    "https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?w=400",
    "https://images.unsplash.com/photo-1505373877841-8d25f7d46678?w=400",
    "https://images.unsplash.com/photo-1519750783826-e2420f4d687f?w=400",
  ];

  @override
  void initState() {
    super.initState();
    _imageController = PageController(initialPage: _imageCurrentPage);
    _startImageTimer();
  }

  @override
  void dispose() {
    _imageTimer.cancel();
    _imageController.dispose();
    super.dispose();
  }

  void _startImageTimer() {
    _imageTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _imageCurrentPage++;
      _imageController.animateToPage(
        _imageCurrentPage,
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: imageHeight,
            child: Stack(
              children: [
                Positioned.fill(
                  child: PageView.builder(
                    controller: _imageController,
                    itemBuilder: (context, index) {
                      return Image.network(
                        _imageUrls[index % _imageUrls.length],
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                ),
                Positioned.fill(
                  child: Container(color: Colors.black.withOpacity(0.11)),
                ),
              ],
            ),
          ),

          Positioned.fill(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    height: imageHeight - overlap,
                  ),

                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 524),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Sadie's HotPot",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'My Awesome Company',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Divider(
                              height: 1,
                              thickness: 1,
                              color: Color(0xFFF2F4F7),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        Row(
                          children: [
                            _buildTag('D-10'),
                            const SizedBox(width: 8),
                            _buildTag('Veteran'),
                          ],
                        ),
                        const SizedBox(height: 24),

                        Text(
                          "Looking for someone to try my Malatang.",
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: const Color(0xFF696969),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: Color(0xFFF2F4F7),
                        ),
                        const SizedBox(height: 14),

                        _buildInfoRow(
                          'assets/icon/calendar_icon.svg',
                          'Feb 15, 2026 - Feb 16, 2026',
                        ),
                        _buildInfoRow(
                          'assets/icon/time_icon.svg',
                          '10:00 AM - 11:00 AM (1-hour)',
                        ),
                        _buildInfoRow(
                          'assets/icon/address_icon.svg',
                          '123 Swanston St, Melbourne, VIC, Australia',
                        ),
                        _buildInfoRow(
                          'assets/icon/salary_icon.svg',
                          '\$1000 per day',
                        ),
                        _buildInfoRow(
                          'assets/icon/people_icon.svg',
                          '1 openings.',
                        ),

                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: SvgPicture.asset(
                            'assets/icon/share_icon.svg',
                            colorFilter: const ColorFilter.mode(
                              AppColors.mainColor,
                              BlendMode.srcIn,
                            ),
                            width: 24,
                            height: 24,
                          ),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: SvgPicture.asset(
                            'assets/icon/bookmark_icon.svg',
                            colorFilter: const ColorFilter.mode(
                              AppColors.mainColor,
                              BlendMode.srcIn,
                            ),
                            width: 24,
                            height: 24,
                          ),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: _buildBottomButton(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFF5F3D),
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 1.0,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvgPicture.asset(
            icon,
            width: 20,
            height: 20,
            colorFilter: const ColorFilter.mode(
              Color(0xFFBDBDBD),
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFFBDBDBD),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context) {
    final isEmployer = AuthController.to.isEmployer.value;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isEmployer
                ? null
                : () {
                    ConfirmModal.show(
                      context: context,
                      message: 'Submit Application?',
                      cancelLabel: 'Cancel',
                      acceptLabel: 'Apply',
                      onAccept: () {
                        Navigator.pop(context);
                        if (!context.mounted) return;
                        CompletionModal.show(
                          context,
                          message: 'Application submitted successfully!',
                          onDismiss: () {
                            if (context.mounted) {
                              Navigator.pop(context, widget.postId);
                            }
                          },
                        );
                      },
                    );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: isEmployer ? Colors.grey : AppColors.mainColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey,
              disabledForegroundColor: Colors.white70,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'apply',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}
