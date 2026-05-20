import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../controllers/note_page_controller.dart';
import '../../widgets/employer_note_tab_bar.dart';

/// Note 목록 View (GetX MVVM). write만 직업별(employer_note_write / seeker_note_write)로 분리.
/// employer/seeker 모두 동일한 NoteTabBar + My History + 카드 스타일을 공유한다.
class NotePage extends GetView<NotePageController> {
  const NotePage({super.key});

  static const _employerTabs = ['Hiring', 'Filled', 'Closed', 'Draft'];
  static const _seekerTabs = ['Applying', 'Done', 'Volunteer'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Obx(() {
          final isEmployer = controller.isEmployerObs.value;
          return isEmployer ? _buildBody(isEmployer: true) : _buildBody(isEmployer: false);
        }),
      ),
    );
  }

  Widget _buildBody({required bool isEmployer}) {
    return Column(
      children: [
        Obx(
          () => NoteTabBar(
            selectedIndex: isEmployer
                ? controller.employerTabIndex.value
                : controller.seekerTabIndex.value,
            onTabSelected: isEmployer
                ? controller.setEmployerTab
                : controller.setSeekerTab,
            tabs: isEmployer ? _employerTabs : _seekerTabs,
          ),
        ),
        Expanded(
          child: Obx(() {
            final jobs = isEmployer
                ? controller.employerJobsForCurrentTab
                : controller.seekerJobsForCurrentTab;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Text(
                    'My History',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
                Expanded(
                  child: jobs.isEmpty
                      ? Center(
                          child: Text(
                            isEmployer ? 'No postings yet' : 'No history yet',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: jobs.length,
                          itemBuilder: (context, index) {
                            return _buildHistoryCard(
                              jobs[index],
                              isEmployer: isEmployer,
                            );
                          },
                        ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _buildHistoryCard(
    Map<String, dynamic> item, {
    required bool isEmployer,
  }) {
    return GestureDetector(
      onTap: () => _onCardTap(item, isEmployer: isEmployer),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF5F5F5)),
        ),
        child: Column(
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
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF747474),
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildTag(item['dDay'] as String),
                const SizedBox(width: 10),
                _buildTag(item['tag'] as String),
                const Spacer(),
                _buildTrailing(item, isEmployer: isEmployer),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _onCardTap(Map<String, dynamic> item, {required bool isEmployer}) {
    if (isEmployer) {
      controller.goToDetailPage(item);
      return;
    }
    // Seeker: Applying 탭이면 작성/상세 분기, 그 외는 사진/상세
    final isApplyingTab = controller.seekerTabIndex.value == 0;
    if (isApplyingTab && (item['hasContent'] != true)) {
      controller.goToWritePage(item);
    } else if (item['hasContent'] == true || isApplyingTab) {
      controller.goToDetailPage(item);
    }
  }

  Widget _buildTrailing(
    Map<String, dynamic> item, {
    required bool isEmployer,
  }) {
    if (isEmployer) {
      if (!controller.showEmployerApplicantBadge) return const SizedBox.shrink();
      final current = item['applicantsCurrent'] as int? ?? 0;
      final total = item['applicantsTotal'] as int? ?? 1;
      return _buildApplicantBadge(current, total);
    }
    // Seeker: Done/Volunteer 탭에서 사진이 있을 때만 썸네일
    if (!controller.showSeekerPhotos) return const SizedBox.shrink();
    final photos = item['photos'];
    if (photos is! List || photos.isEmpty) return const SizedBox.shrink();
    return _buildPhotoThumbnails(List<String>.from(photos));
  }

  Widget _buildApplicantBadge(int current, int total) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            'assets/icon/people_icon.svg',
            width: 16,
            height: 16,
            colorFilter: const ColorFilter.mode(
              Color(0xFF747474),
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$current/$total',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF747474),
            ),
          ),
        ],
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
                    color: Colors.black.withValues(alpha: 0.1),
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
