import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../pages/MainPage/job_detail_page.dart';
import '../pages/NotePage/employer_note_write_page.dart';
import '../pages/NotePage/seeker_note_detail_page.dart';
import '../pages/NotePage/seeker_note_write_page.dart';

/// Note 목록 화면 ViewModel (GetX MVVM)
class NotePageController extends GetxController {
  final selectedTab = 0.obs;
  final volunteerFilter = 1.obs; // 0: Draft, 1: most recent

  bool get isEmployer => AuthController.to.isEmployer.value;

  final List<Map<String, dynamic>> recruitmentHistory = [
    {
      'title': 'Pop-Up Store Crew',
      'employer': 'Happy Gumpy',
      'dDay': 'D-31',
      'tag': 'Rookie',
      'hasContent': false,
      'photos': [],
    },
    {
      'title': 'Festival Support Staff',
      'employer': 'Happy Gumpy',
      'dDay': 'D-12',
      'tag': 'Veteran',
      'hasContent': true,
      'body': 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.',
      'photos': [
        'https://images.unsplash.com/photo-1542208998-f6dbbb27a72f?w=100',
        'https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?w=100',
        'https://images.unsplash.com/photo-1505373877841-8d25f7d46678?w=100',
      ],
    },
    {
      'title': 'Event Helper',
      'employer': 'Happy Gumpy',
      'dDay': 'D-5',
      'tag': 'Rookie',
      'hasContent': true,
      'body': 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
      'photos': [
        'https://images.unsplash.com/photo-1542208998-f6dbbb27a72f?w=100',
      ],
    },
    {
      'title': 'Casual Bar Support Staff',
      'employer': 'Happy Gumpy',
      'dDay': 'D-20',
      'tag': 'Veteran',
      'hasContent': false,
      'photos': [],
    },
    {
      'title': 'Temporary Sales Assistant',
      'employer': 'Happy Gumpy',
      'dDay': 'D-8',
      'tag': 'Seasonal',
      'hasContent': true,
      'body': 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
      'photos': [
        'https://images.unsplash.com/photo-1542208998-f6dbbb27a72f?w=100',
        'https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?w=100',
      ],
    },
  ];

  final List<Map<String, dynamic>> completionHistoryWorks = [
    {
      'title': 'Weekend Market Assistant',
      'employer': 'Freshyyy',
      'dDay': 'Completed',
      'tag': 'Veteran',
      'hasContent': true,
      'body': 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
      'photos': [
        'https://images.unsplash.com/photo-1542208998-f6dbbb27a72f?w=100',
        'https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?w=100',
        'https://images.unsplash.com/photo-1505373877841-8d25f7d46678?w=100',
      ],
    },
    {
      'title': 'Casual Event Assistant',
      'employer': 'Central Art Concert Hall',
      'dDay': 'Completed',
      'tag': 'Rookie',
      'hasContent': true,
      'body': 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
      'photos': [
        'https://images.unsplash.com/photo-1542208998-f6dbbb27a72f?w=100',
        'https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?w=100',
      ],
    },
    {
      'title': 'Festival Support Staff',
      'employer': 'IngA Music Festival',
      'dDay': 'Completed',
      'tag': 'Rookie',
      'hasContent': true,
      'body': 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt.',
      'photos': [
        'https://images.unsplash.com/photo-1542208998-f6dbbb27a72f?w=100',
      ],
    },
  ];

  /// 구인자: 지금 하고 있는 공고만 (Recruitment history 탭)
  final List<Map<String, dynamic>> employerRecruitmentHistory = [
    {
      'title': 'Pop-Up Store Crew',
      'employer': 'Happy Gumpy',
      'dDay': 'D-31',
      'tag': 'Rookie',
      'hasContent': false,
      'photos': [],
    },
    {
      'title': 'Festival Support Staff',
      'employer': 'Happy Gumpy',
      'dDay': 'D-12',
      'tag': 'Veteran',
      'hasContent': true,
      'body': 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
      'photos': [
        'https://images.unsplash.com/photo-1542208998-f6dbbb27a72f?w=100',
        'https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?w=100',
      ],
    },
    {
      'title': 'Casual Bar Support Staff',
      'employer': 'Happy Gumpy',
      'dDay': 'D-20',
      'tag': 'Veteran',
      'hasContent': false,
      'photos': [],
    },
  ];

  /// 구인자: 끝난 공고만 (Completion history 탭)
  final List<Map<String, dynamic>> employerCompletionHistory = [
    {
      'title': 'Weekend Market Assistant',
      'employer': 'Freshyyy',
      'dDay': 'Completed',
      'tag': 'Veteran',
      'hasContent': true,
      'body': 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
      'photos': [
        'https://images.unsplash.com/photo-1542208998-f6dbbb27a72f?w=100',
      ],
    },
    {
      'title': 'Festival Support Staff',
      'employer': 'IngA Music Festival',
      'dDay': 'Completed',
      'tag': 'Rookie',
      'hasContent': true,
      'body': 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
      'photos': [
        'https://images.unsplash.com/photo-1542208998-f6dbbb27a72f?w=100',
        'https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?w=100',
      ],
    },
  ];

  final List<Map<String, dynamic>> completionHistoryVolunteer = [
    {
      'title': 'Youth Program Support Assistant',
      'employer': 'You and Us',
      'dDay': 'Completed',
      'tag': 'Rookie',
      'hasContent': true,
      'isDraft': false,
      'body': 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
      'photos': [
        'https://images.unsplash.com/photo-1542208998-f6dbbb27a72f?w=100',
        'https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?w=100',
      ],
    },
    {
      'title': 'Animal Care Volunteer Assistant',
      'employer': 'W.H.A (Animal Care Center)',
      'dDay': 'Completed',
      'tag': 'Veteran',
      'hasContent': true,
      'isDraft': false,
      'body': 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
      'photos': [
        'https://images.unsplash.com/photo-1542208998-f6dbbb27a72f?w=100',
        'https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?w=100',
        'https://images.unsplash.com/photo-1505373877841-8d25f7d46678?w=100',
      ],
    },
    {
      'title': 'Horse Care Volunteer Assistant',
      'employer': 'Hehe Farm',
      'dDay': 'Completed',
      'tag': 'Rookie',
      'hasContent': true,
      'isDraft': false,
      'body': 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
      'photos': [
        'https://images.unsplash.com/photo-1542208998-f6dbbb27a72f?w=100',
      ],
    },
  ];

  void setSelectedTab(int index) => selectedTab.value = index;
  void setVolunteerFilter(int value) => volunteerFilter.value = value;

  /// 구인자: 내가 올린 공고 전체 (My Job Openings 모달용)
  List<Map<String, dynamic>> get employerJobOpenings => [
        ...employerRecruitmentHistory,
        ...employerCompletionHistory,
      ];

  List<Map<String, dynamic>> get filteredVolunteerList =>
      volunteerFilter.value == 0
          ? completionHistoryVolunteer
              .where((item) => item['isDraft'] == true)
              .toList()
          : completionHistoryVolunteer
              .where((item) => item['isDraft'] == false)
              .toList();

  void goToWritePage(Map<String, dynamic> item) {
    final isRecruitmentTab = selectedTab.value == 0;
    final shouldNavigate = isRecruitmentTab && (item['hasContent'] != true);
    if (!shouldNavigate) return;

    if (isEmployer) {
      Get.to(() => const EmployerNoteWritePage());
    } else {
      Get.to(() => const SeekerNoteWritePage());
    }
  }

  void goToDetailPage(Map<String, dynamic> item) {
    // 구인자 recruitment 탭: 리스트 눌러도 항상 JobDetailPage
    if (isEmployer) {
      Get.to(() => const JobDetailPage());
      return;
    }
    if (item['hasContent'] != true) return;
    final photos = item['photos'] != null
        ? List<String>.from(item['photos'] as List)
        : <String>[];
    final body = item['body'] as String? ?? '';
    Get.to(() => NoteDetailPage(
          title: item['title'] as String,
          employer: item['employer'] as String,
          body: body,
          photos: photos,
        ));
  }
}
