import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart' hide Trans;
import '../../controllers/note_page_controller.dart';
import '../../styles/colors.dart';
import '../../widgets/auto_translate_text.dart';
import '../../widgets/employer_note_tab_bar.dart';
import '../../widgets/job_application_list_modal.dart';
import '../ChatPage/chat_detail_page.dart';
import '../MyPage/review_detail_page.dart';
import 'seeker_note_write_page.dart';

/// Note 목록 View (GetX MVVM). write만 직업별(employer_note_write / seeker_note_write)로 분리.
/// employer/seeker 모두 동일한 NoteTabBar + My History + 카드 스타일을 공유한다.
class NotePage extends GetView<NotePageController> {
  const NotePage({super.key});

  // 라벨은 i18n 키 → tr 로 변환해서 NoteTabBar 에 전달한다.
  // 구인자 측은 시안에 맞춰 3개 탭: Hiring / Ongoing / Done.
  static const _employerTabKeys = [
    'note.tabs.hiring',
    'note.tabs.ongoing',
    'note.tabs.done',
  ];
  static const _seekerTabKeys = [
    'note.tabs.applied',
    'note.tabs.ongoing',
    'note.tabs.done',
    'note.tabs.saved',
  ];

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
            tabs: (isEmployer ? _employerTabKeys : _seekerTabKeys)
                .map((k) => k.tr())
                .toList(),
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Text(
                    'note.my_history'.tr(),
                    style: const TextStyle(
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
                            isEmployer
                                ? 'note.no_postings'.tr()
                                : 'note.no_history'.tr(),
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
                              context,
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
    BuildContext context,
    Map<String, dynamic> item, {
    required bool isEmployer,
  }) {
    // Done (구인자) 또는 Done (구직자) 탭에서는
    // 카드 배경을 #F9F9F9, 본문(employer)·태그를 회색 톤(#747474)으로 표시.
    // 제목은 항상 검정색 유지.
    final status = item['employerStatus'] as String?;
    final isMuted = item['muted'] == true ||
        (isEmployer && status == 'done');

    return GestureDetector(
      onTap: () => _onCardTap(context, item, isEmployer: isEmployer),
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
            AutoTranslateText(
              item['title'] as String,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 2),
            AutoTranslateText(
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
                _buildTrailing(context, item, isEmployer: isEmployer),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _onCardTap(
    BuildContext context,
    Map<String, dynamic> item, {
    required bool isEmployer,
  }) {
    if (!isEmployer) {
      _onSeekerCardTap(item);
      return;
    }
    // 구인자 탭별 동작 분기.
    switch (controller.employerTabIndex.value) {
      case 0:
        // Hiring: 신청한 사람 선택 모달 → 수락 시 채팅 페이지로 이동.
        _openHiringApplicants(context);
        break;
      case 1:
      case 2:
      default:
        // Ongoing / Done 카드는 탭해도 반응 없음.
        // (Done 은 별도 Write Review 버튼이 trailing 에 노출됨)
        break;
    }
  }

  /// 구직자 탭별 카드 탭 흐름.
  /// - Applied(0) / Ongoing(1) / Done(2): 카드 자체 탭은 무반응
  ///   (Done 은 우측의 Write Note 주황 버튼이 작성 진입을 담당)
  /// - Saved(3): 작성된 노트 상세를 인라인으로 표시
  void _onSeekerCardTap(Map<String, dynamic> item) {
    switch (controller.seekerTabIndex.value) {
      case 0:
      case 1:
      case 2:
        break;
      case 3:
        // 더미 카드는 hasContent 가 없어 상세가 비어 보일 수 있지만,
        // 사용자가 직접 쓴 노트는 hasContent==true 로 들어와 상세가 정상 표시된다.
        controller.openViewingNote(item);
        break;
      default:
        break;
    }
  }

  Widget _buildTrailing(
    BuildContext context,
    Map<String, dynamic> item, {
    required bool isEmployer,
  }) {
    if (!isEmployer) {
      // Seeker: Done 탭(index 2)일 때만 우측에 Write Note 주황 버튼이 노출된다.
      if (controller.seekerTabIndex.value == 2) {
        return _buildWriteNoteButton(context, item);
      }
      return const SizedBox.shrink();
    }
    if (controller.showEmployerWriteReviewButton) {
      return _buildWriteReviewButton(context, item);
    }
    if (!controller.showEmployerApplicantBadge) return const SizedBox.shrink();
    final current = item['applicantsCurrent'] as int? ?? 0;
    final total = item['applicantsTotal'] as int? ?? 1;
    return _buildApplicantBadge(current, total);
  }

  /// 구직자 Done 탭 카드 우측에 표시되는 Write Note 주황 버튼.
  /// 누르면 해당 일자리에 prefill 된 SeekerNoteWritePage 로 이동.
  Widget _buildWriteNoteButton(
    BuildContext context,
    Map<String, dynamic> item,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Get.to(
          () => SeekerNoteWritePage(
            initialTitle: item['title'] as String?,
            jobEmployer: item['employer'] as String?,
            sourceJob: item,
          ),
        ),
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.mainColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const AutoTranslateText(
            'Write Note',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }

  /// Hiring 탭 카드 탭 시 노출되는 지원자 선택 모달 → 수락 시 채팅 페이지로 이동.
  Future<void> _openHiringApplicants(BuildContext context) async {
    final accepted = await JobApplicationListModal.show(context);
    if (!context.mounted) return;
    if (accepted == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatDetailPage(
          peerName: accepted['name'],
          peerProfileImagePath: accepted['profileImagePath'],
        ),
      ),
    );
  }

  /// Done 탭 카드 우측에 표시되는 Write Review 주황 버튼.
  /// 누르면 사람 선택 모달 → ReviewDetailPage(별점/본문 작성 페이지) 로 이동.
  ///
  /// `item['reviewedAll'] == true` 인 경우(=참여한 모든 사람에 대해 이미 리뷰
  /// 작성을 마친 카드) 는 회색 + 비활성으로 표시한다.
  Widget _buildWriteReviewButton(
    BuildContext context,
    Map<String, dynamic> item,
  ) {
    final isDone = item['reviewedAll'] == true;
    final bg = isDone ? const Color(0xFFE0E0E0) : AppColors.mainColor;
    final fg = isDone ? const Color(0xFF9A9A9A) : Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        // 모두 리뷰 완료된 카드는 탭 자체를 막아 추가 작성을 차단.
        onTap: isDone ? null : () => _openWriteReview(context, item),
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: AutoTranslateText(
            'Write Review',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: fg,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openWriteReview(
    BuildContext context,
    Map<String, dynamic> item,
  ) async {
    final applicant = await JobApplicationListModal.show(context);
    if (!context.mounted) return;
    if (applicant == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReviewDetailPage(
          title: item['title'] as String? ?? '',
          rating: 5,
          body: '',
          isEditable: true,
          peerName: applicant['name'],
          peerProfileImagePath: applicant['profileImagePath'],
        ),
      ),
    );
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
      child: AutoTranslateText(
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
