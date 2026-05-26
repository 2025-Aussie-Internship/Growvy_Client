import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../controllers/note_page_controller.dart';
import '../../styles/colors.dart';
import '../../widgets/employer_note_tab_bar.dart';

/// Note 목록 View (GetX MVVM). write만 직업별(employer_note_write / seeker_note_write)로 분리.
/// employer/seeker 모두 동일한 NoteTabBar + My History + 카드 스타일을 공유한다.
class NotePage extends GetView<NotePageController> {
  const NotePage({super.key});

  static const _employerTabs = ['Hiring', 'Filled', 'Closed', 'Draft'];
  static const _seekerTabs = ['Applied', 'Ongoing', 'Done', 'Saved'];

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
                      fontFamily: 'Paperlogy',
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
    // Closed / Draft (구인자) 또는 Done (구직자) 탭에서는
    // 카드 배경을 #F9F9F9, 본문(employer)·태그를 회색 톤(#747474)으로 표시.
    // 제목은 항상 검정색 유지.
    final status = item['employerStatus'] as String?;
    final isMuted = item['muted'] == true ||
        (isEmployer && (status == 'closed' || status == 'draft'));

    return GestureDetector(
      onTap: () => _onCardTap(item, isEmployer: isEmployer),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isMuted ? const Color(0xFFF9F9F9) : Colors.white,
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
                _buildTag(item['dDay'] as String, muted: isMuted),
                const SizedBox(width: 10),
                _buildTag(item['tag'] as String, muted: isMuted),
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
    // Seeker: 구인자 스타일과 동일하게 trailing 없음.
    return const SizedBox.shrink();
  }

  Widget _buildApplicantBadge(int current, int total) {
    // 지원자가 다 차면 (Filled) 주황색, 그 외(Hiring 중)는 회색.
    final isFilled = total > 0 && current >= total;
    final fgColor =
        isFilled ? AppColors.subColor : const Color(0xFF747474);
    final bgColor = isFilled
        ? AppColors.subColor.withValues(alpha: 0.12)
        : const Color(0xFFF5F5F5);

    return Container(
      width: 64,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            'assets/icon/people_icon.svg',
            width: 14,
            height: 14,
            colorFilter: ColorFilter.mode(fgColor, BlendMode.srcIn),
          ),
          const SizedBox(width: 4),
          Text(
            '$current/$total',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: fgColor,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, {bool muted = false}) {
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: muted ? const Color(0xFFF5F5F5) : const Color(0xFFFEE9D8),
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: muted ? const Color(0xFF747474) : const Color(0xFF931515),
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 14 / 12,
        ),
      ),
    );
  }

}
