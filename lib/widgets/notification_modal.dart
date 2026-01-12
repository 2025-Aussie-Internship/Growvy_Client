import 'package:flutter/material.dart';
import '../styles/colors.dart';

class NotificationModal extends StatelessWidget {
  const NotificationModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: 316,
        height: 360,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.mainColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 스크롤 가능한 알림 리스트
            Expanded(
              child: Theme(
                data: ThemeData(
                  scrollbarTheme: ScrollbarThemeData(
                    thumbColor: WidgetStateProperty.all(AppColors.mainColor),
                    thickness: WidgetStateProperty.all(6),
                    radius: const Radius.circular(10),
                    thumbVisibility: WidgetStateProperty.all(true),
                  ),
                ),
                child: Scrollbar(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Today 섹션
                          const Text(
                            'Today',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.mainColor,
                            ),
                          ),
                          const SizedBox(height: 16),

                          _buildNotificationItem(
                            icon: Icons.circle,
                            iconColor: AppColors.mainColor,
                            title: 'Start today! Part-time café job in Sydney',
                            time: '12:00 PM ~ 2:00 PM',
                          ),

                          const SizedBox(height: 12),

                          _buildNotificationItem(
                            icon: Icons.circle,
                            iconColor: const Color(0xFFFFD7A8),
                            title: 'Resort housekeeping jobs near the beach',
                            subtitle: 'AD',
                          ),

                          const SizedBox(height: 12),

                          _buildNotificationItem(
                            icon: Icons.circle,
                            iconColor: const Color(0xFFFFD7A8),
                            title: 'High-paying seasonal farm work',
                            subtitle: 'AD',
                          ),

                          const SizedBox(height: 24),

                          // 구분선
                          Container(
                            width: double.infinity,
                            height: 1,
                            color: const Color(0xFFF5F5F5),
                          ),

                          const SizedBox(height: 24),

                          // This Week 섹션
                          const Text(
                            'This Week',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),

                          _buildNotificationItem(
                            icon: Icons.circle,
                            iconColor: AppColors.mainColor,
                            title: 'Morning farm shift reminder',
                            time: '5:30 AM ~ 8:30 PM',
                            date: 'Mon, Aug 18',
                          ),

                          const SizedBox(height: 12),

                          _buildNotificationItem(
                            icon: Icons.circle,
                            iconColor: AppColors.mainColor,
                            title: 'Restaurant serving shift reminder',
                            time: '5:00 PM ~ 10:00 PM',
                            date: 'Mon, Aug 18',
                          ),

                          const SizedBox(height: 12),

                          _buildNotificationItem(
                            icon: Icons.circle,
                            iconColor: AppColors.mainColor,
                            title: 'Warehouse packing job opportunity',
                            time: '9:00 AM ~ 5:00 PM',
                            date: 'Tue, Aug 19',
                          ),

                          const SizedBox(height: 12),

                          _buildNotificationItem(
                            icon: Icons.circle,
                            iconColor: AppColors.mainColor,
                            title: 'Café shift opening available',
                            time: '2:00 PM ~ 6:00 PM',
                            date: 'Wed, Aug 20',
                          ),

                          const SizedBox(height: 12),

                          _buildNotificationItem(
                            icon: Icons.circle,
                            iconColor: AppColors.mainColor,
                            title: 'Delivery driver needed urgently',
                            time: '11:00 AM ~ 3:00 PM',
                            date: 'Thu, Aug 21',
                          ),

                          const SizedBox(height: 12),

                          _buildNotificationItem(
                            icon: Icons.circle,
                            iconColor: AppColors.mainColor,
                            title: 'Kitchen helper position open',
                            time: '6:00 PM ~ 10:00 PM',
                            date: 'Thu, Aug 21',
                          ),

                          const SizedBox(height: 12),

                          _buildNotificationItem(
                            icon: Icons.circle,
                            iconColor: AppColors.mainColor,
                            title: 'Barista training session',
                            time: '10:00 AM ~ 12:00 PM',
                            date: 'Fri, Aug 22',
                          ),

                          const SizedBox(height: 12),

                          _buildNotificationItem(
                            icon: Icons.circle,
                            iconColor: AppColors.mainColor,
                            title: 'Weekend retail position available',
                            time: '9:00 AM ~ 5:00 PM',
                            date: 'Sat, Aug 23',
                          ),

                          const SizedBox(height: 12),

                          _buildNotificationItem(
                            icon: Icons.circle,
                            iconColor: const Color(0xFFFFD7A8),
                            title: 'Part-time jobs for students',
                            subtitle: 'AD',
                          ),

                          const SizedBox(height: 12),

                          _buildNotificationItem(
                            icon: Icons.circle,
                            iconColor: AppColors.mainColor,
                            title: 'Night shift warehouse work',
                            time: '10:00 PM ~ 6:00 AM',
                            date: 'Sun, Aug 24',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? time,
    String? date,
    String? subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 아이콘
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Icon(
            icon,
            size: 8,
            color: iconColor,
          ),
        ),
        const SizedBox(width: 12),

        // 텍스트 내용
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (time != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (date != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        date,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}