import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../styles/colors.dart';
import '../../widgets/confirm_modal.dart';

class JobDetailPage extends StatelessWidget {
  const JobDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Image height
    const double imageHeight = 300;
    // Overlap amount to show some rounded corners effect
    const double overlap = 20;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: SvgPicture.asset('assets/icon/logo_orange.svg', height: 36),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        surfaceTintColor: Colors.white,
      ),
      body: Stack(
        children: [
          // 1. Image with 11% Black Opacity Overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: imageHeight,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.network(
                    'https://images.unsplash.com/photo-1542208998-f6dbbb27a72f?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(
                      0.11,
                    ), // 11% opacity black overlay
                  ),
                ),
              ],
            ),
          ),

          // 2. Scrollable Content Sheet
          Positioned.fill(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Invisible Spacer so text starts below image
                  // Since icons are FIXED now, we just need space for image.
                  Container(
                    width: double.infinity,
                    height: imageHeight - overlap,
                  ),

                  // White Content Sheet
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
                          'Record Shop Employee',
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
                              'People needs Rabbit!',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Divider below description summary
                            const Divider(
                              height: 1,
                              thickness: 1,
                              color: Color(0xFFF2F4F7),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Tags
                        Row(
                          children: [
                            _buildTag('D-24'),
                            const SizedBox(width: 8),
                            _buildTag('Veteran'),
                            const SizedBox(width: 8),
                            _buildTag('Veteran'),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Long Description
                        Text(
                          'People Needs Rabbit! is looking for a friendly, reliable team member who loves music, enjoys talking with customers, and has a positive, responsible attitude.\nThis is a part-time position with flexible shifts (around 3–5 days a week, 4–6 hours per shift), perfect for someone who wants to work in a relaxed, community-focused record shop.',
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

                        // Info Rows
                        _buildInfoRow(
                          'assets/icon/calendar_icon.svg',
                          '3–5 days a week',
                        ),
                        _buildInfoRow(
                          'assets/icon/time_icon.svg',
                          '4–6 hours per shift (flexible schedule)',
                        ),
                        _buildInfoRow(
                          'assets/icon/address_icon.svg',
                          '27 Willow Street, Newtown NSW 2042, Australia',
                        ),
                        _buildInfoRow(
                          'assets/icon/salary_icon.svg',
                          '\$600 per week',
                        ),
                        _buildInfoRow(
                          'assets/icon/people_icon.svg',
                          '3 openings.',
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
            top: 10,
            left: 0,
            right: 0,
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
                      // Share Icon
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
                      // Bookmark Icon
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

          // 4. Sticky Bottom Button
          Align(alignment: Alignment.bottomCenter, child: _buildBottomButton(context)),
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFF5F3D), // Primary Orange
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
            onPressed: () {
              ConfirmModal.show(
                context: context,
                message: 'Submit Application?',
                cancelLabel: 'Cancel',
                acceptLabel: 'Apply',
                onAccept: () {
                  Navigator.pop(context);
                  // TODO: 지원 제출 로직
                },
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mainColor,
              foregroundColor: Colors.white,
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
