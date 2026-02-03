import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/note_page_controller.dart';

/// Note 목록 View (GetX MVVM). write만 직업별(employer_note_write / seeker_note_write)로 분리.
class NotePage extends GetView<NotePageController> {
  const NotePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 16),
            child: Obx(() => Row(
              children: [
                Expanded(
                  child: _buildTab(0, 'Recruitment history'),
                ),
                Expanded(
                  child: _buildTab(1, 'Completion history'),
                ),
              ],
            )),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isEmployer) {
                return controller.selectedTab.value == 0
                    ? _buildEmployerRecruitmentHistory()
                    : _buildEmployerCompletionHistory();
              }
              return controller.selectedTab.value == 0
                  ? _buildRecruitmentHistory()
                  : _buildCompletionHistory();
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String label) {
    final isSelected = controller.selectedTab.value == index;
    return GestureDetector(
      onTap: () => controller.setSelectedTab(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10.5),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFFF5F5F5),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    offset: const Offset(0, -3),
                    blurRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isSelected ? const Color(0xFF931515) : const Color(0xFF747474),
          ),
        ),
      ),
    );
  }

  Widget _buildRecruitmentHistory() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My History',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              Text(
                'most recent',
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFF931515),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: controller.recruitmentHistory.length,
            itemBuilder: (context, index) {
              return _buildHistoryCard(controller.recruitmentHistory[index]);
            },
          ),
        ),
      ],
    );
  }

  /// 구인자: Recruitment history (지금 하고 있는 공고만)
  Widget _buildEmployerRecruitmentHistory() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My History',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              Text(
                'most recent',
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFF931515),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: controller.employerRecruitmentHistory.length,
            itemBuilder: (context, index) {
              return _buildHistoryCard(
                  controller.employerRecruitmentHistory[index]);
            },
          ),
        ),
      ],
    );
  }

  /// 구인자: Completion history (끝난 공고만)
  Widget _buildEmployerCompletionHistory() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Completed',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              Text(
                'most recent',
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFF931515),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: controller.employerCompletionHistory.length,
            itemBuilder: (context, index) {
              return _buildHistoryCard(
                  controller.employerCompletionHistory[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionHistory() {
    return Obx(() {
      final filteredVolunteerList = controller.filteredVolunteerList;
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Works',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    'most recent',
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xFF931515),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: controller.completionHistoryWorks.length,
              itemBuilder: (context, index) {
                return _buildHistoryCard(
                    controller.completionHistoryWorks[index]);
              },
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Volunteer',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => controller.setVolunteerFilter(0),
                        child: Text(
                          'Draft',
                          style: TextStyle(
                            fontSize: 14,
                            color: controller.volunteerFilter.value == 0
                                ? const Color(0xFF931515)
                                : const Color(0xFF931515),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Container(
                          width: 1,
                          height: 14,
                          color: const Color(0xFF931515),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => controller.setVolunteerFilter(1),
                        child: Text(
                          'most recent',
                          style: TextStyle(
                            fontSize: 14,
                            color: controller.volunteerFilter.value == 1
                                ? const Color(0xFF931515)
                                : const Color(0xFF931515),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredVolunteerList.length,
              itemBuilder: (context, index) {
                return _buildHistoryCard(filteredVolunteerList[index]);
              },
            ),
          ],
        ),
      );
    });
  }

  Widget _buildHistoryCard(Map<String, dynamic> item) {
    final isRecruitmentTab = controller.selectedTab.value == 0;
    // 구인자 recruitment 탭: 모든 카드 탭 시 JobDetailPage. 구직자만 빈 공고 탭 시 write 페이지
    final shouldNavigateToWrite =
        isRecruitmentTab && (item['hasContent'] != true) && !controller.isEmployer;
    final shouldNavigateToDetail =
        (controller.isEmployer && isRecruitmentTab) || (item['hasContent'] == true);

    return GestureDetector(
      onTap: shouldNavigateToWrite
          ? () => controller.goToWritePage(item)
          : shouldNavigateToDetail
              ? () => controller.goToDetailPage(item)
              : null,
      child: Container(
        width: 358,
        height: 111,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF5F5F5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'] as String,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item['employer'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFF747474),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildTag(item['dDay'] as String),
                      const SizedBox(width: 10),
                      _buildTag(item['tag'] as String),
                    ],
                  ),
                ],
              ),
            ),
            // 구인자 노트 탭에서는 사진 썸네일 미표시
            if (!controller.isEmployer &&
                item['photos'] != null &&
                (item['photos'] as List).isNotEmpty)
              _buildPhotoThumbnails(item['photos'] as List<String>),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE9D8),
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF931515),
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 14 / 12,
        ),
      ),
    );
  }

  Widget _buildPhotoThumbnails(List<String> photos) {
    final displayPhotos = photos.take(3).toList();
    const double photoSize = 30;
    const double overlap = 8;

    return SizedBox(
      width: photoSize + (displayPhotos.length - 1) * (photoSize - overlap),
      height: photoSize,
      child: Stack(
        children: List.generate(displayPhotos.length, (index) {
          return Positioned(
            left: index * (photoSize - overlap),
            child: Container(
              width: photoSize,
              height: photoSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  displayPhotos[index],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, size: 20),
                    );
                  },
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
