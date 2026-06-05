import 'package:get/get.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/env.dart';
import '../controllers/auth_controller.dart';
import '../pages/MainPage/job_detail_page.dart';
import '../pages/NotePage/employer_note_write_page.dart';
import '../pages/NotePage/seeker_note_write_page.dart';

class NotePageController extends GetxController {
  final selectedTab = 0.obs;
  /// 구인자 Note 상단 탭: 0 Hiring, 1 Filled, 2 Closed, 3 Draft
  final employerTabIndex = 0.obs;
  /// 구직자 Note 상단 탭: 0 Applying, 1 Done, 2 Volunteer
  final seekerTabIndex = 0.obs;
  final volunteerFilter = 1.obs; // 0: Draft, 1: Most recent
  final isLoading = false.obs;

  bool isEmployer = false;
  final RxBool isEmployerObs = false.obs;

  Worker? _employerTypeWorker;

  // --- 관찰 가능한 리스트 (RxList) ---
  // 구직자용 (Job Seeker)
  final RxList<Map<String, dynamic>> recruitmentHistory =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> completionHistoryWorks =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> completionHistoryVolunteer =
      <Map<String, dynamic>>[].obs;

  // 구인자용 (Employer)
  final RxList<Map<String, dynamic>> employerRecruitmentHistory =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> employerCompletionHistory =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> employerCompletionVolunteer =
      <Map<String, dynamic>>[].obs;

  /// 구직자가 직접 작성한 노트(후기) 목록. SeekerNoteWritePage의 Save 흐름에서
  /// 추가되며, Note 페이지 Saved 탭 최상단에 누적되어 표시된다.
  final RxList<Map<String, dynamic>> seekerWrittenNotes =
      <Map<String, dynamic>>[].obs;

  /// 구직자 Done 탭과 write_button 모달이 함께 참조하는 "후기 작성 가능 목록".
  /// API 데이터가 들어오면 그것으로 교체되고, 비어있을 동안은 더미로 채워진다.
  /// 사용자가 한 건을 저장하면 [consumeSeekerDoneJob] 으로 여기서 제거되고
  /// Saved 탭으로 이동한다.
  late final RxList<Map<String, dynamic>> seekerDoneJobs =
      <Map<String, dynamic>>[
        for (final e in _seekerDoneDummy) Map<String, dynamic>.from(e),
      ].obs;

  /// 현재 인라인으로 표시되고 있는 노트 상세. null 이면 일반 Note 페이지가 표시되고,
  /// 값이 있으면 그 노트의 [NoteDetailPage] 가 같은 탭 안에 표시되어
  /// 하단 BottomNavigationBar 가 계속 보이도록 한다.
  final Rxn<Map<String, dynamic>> viewingNote = Rxn<Map<String, dynamic>>();

  void openViewingNote(Map<String, dynamic> note) {
    viewingNote.value = note;
  }

  void closeViewingNote() {
    viewingNote.value = null;
  }

  /// 새 노트를 Saved 탭 가장 위에 추가한다.
  void addSeekerWrittenNote(Map<String, dynamic> note) {
    seekerWrittenNotes.insert(0, note);
  }

  /// 사용자가 작성한 노트를 Saved 탭에서 제거한다.
  /// 같은 참조가 있으면 그것을, 없으면 동일한 id 또는 title+createdAt 으로 매칭한다.
  void deleteSeekerWrittenNote(Map<String, dynamic> note) {
    final removed = seekerWrittenNotes.remove(note);
    if (!removed) {
      seekerWrittenNotes.removeWhere(
        (n) => identical(n, note) || n['title'] == note['title'],
      );
    }
  }

  /// 후기 작성이 끝난 공고를 Done 목록에서 제거한다.
  /// 같은 참조가 있으면 그것을 제거하고, 없으면 id 또는 title+employer 로 매칭한다.
  void consumeSeekerDoneJob(Map<String, dynamic> item) {
    final removed = seekerDoneJobs.remove(item);
    if (removed) return;
    seekerDoneJobs.removeWhere((e) {
      if (item['id'] != null && e['id'] != null) {
        return e['id'] == item['id'];
      }
      return e['title'] == item['title'] && e['employer'] == item['employer'];
    });
  }

  @override
  void onInit() {
    super.onInit();
    _syncEmployerFlag();
    if (Get.isRegistered<AuthController>()) {
      _employerTypeWorker?.dispose();
      _employerTypeWorker = ever(AuthController.to.isEmployer, (_) {
        _syncEmployerFlag();
        fetchAllData();
      });
    }
    fetchAllData();
  }

  @override
  void onClose() {
    _employerTypeWorker?.dispose();
    super.onClose();
  }

  void _syncEmployerFlag() {
    if (Get.isRegistered<AuthController>()) {
      isEmployer = AuthController.to.isEmployer.value;
      isEmployerObs.value = isEmployer;
    }
  }

  /// 모든 탭의 데이터 새로고침
  Future<void> fetchAllData() async {
    isLoading.value = true;
    if (isEmployer) {
      await fetchEmployerRecruitment();
      await fetchEmployerCompletion();
    } else {
      await fetchSeekerRecruitment();
      await fetchSeekerCompletion();
    }
    isLoading.value = false;
  }

  // 1. 구직자 - 모집 중 (Recruitment)
  Future<void> fetchSeekerRecruitment() async {
    final data = await _fetchFromApi(
      "${Env.apiBaseUrl}/api/jobseeker/posts",
    );
    if (data != null) recruitmentHistory.assignAll(_mapApiData(data));
  }

  // 2. 구직자 - 완료 (Completion)
  Future<void> fetchSeekerCompletion() async {
    final data = await _fetchFromApi(
      "${Env.apiBaseUrl}/api/jobseeker/posts/done",
    );
    if (data != null) {
      final allDone = _mapApiData(data, isDone: true);
      final works = allDone.where((e) => e['hourlyWage'] > 0).toList();
      completionHistoryWorks.assignAll(works);
      completionHistoryVolunteer.assignAll(
        allDone.where((e) => e['hourlyWage'] == 0).toList(),
      );
      // Done 탭과 write_button 모달이 공유하는 단일 소스 갱신.
      // (이미 사용자가 후기를 작성한 항목이 있다면 그것은 유지)
      if (works.isNotEmpty) {
        final existingIds = seekerWrittenNotes
            .map((n) => n['sourceId'])
            .whereType<Object>()
            .toSet();
        seekerDoneJobs.assignAll(
          works.where((e) => !existingIds.contains(e['id'])),
        );
      }
    }
  }

  // 3. 구인자 - 모집 중 (Recruitment)
  Future<void> fetchEmployerRecruitment() async {
    final data = await _fetchFromApi(
      "${Env.apiBaseUrl}/api/employer/posts",
    );
    if (data != null) {
      employerRecruitmentHistory.assignAll(
        _mapApiData(data, forEmployer: true),
      );
    }
  }

  // 4. 구인자 - 완료 (Completion)
  Future<void> fetchEmployerCompletion() async {
    final data = await _fetchFromApi(
      "${Env.apiBaseUrl}/api/employer/posts/done",
    );
    if (data != null) {
      final allDone = _mapApiData(data, isDone: true, forEmployer: true);
      employerCompletionHistory.assignAll(
        allDone.where((e) => e['hourlyWage'] > 0).toList(),
      );
      employerCompletionVolunteer.assignAll(
        allDone.where((e) => e['hourlyWage'] == 0).toList(),
      );
    }
  }

  // --- 공통 API 호출 로직 ---
  Future<List<dynamic>?> _fetchFromApi(String url) async {
    final storage = FlutterSecureStorage();
    final String? accessToken = await storage.read(key: 'accessToken');
    if (accessToken == null) return null;

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $accessToken",
          "Content-Type": "application/json",
        },
      );
      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      }
    } catch (e) {
      print("API Error ($url): $e");
    }
    return null;
  }

  // --- API 데이터를 UI용 Map으로 변환 ---
  List<Map<String, dynamic>> _mapApiData(
    List<dynamic> data, {
    bool isDone = false,
    bool forEmployer = false,
  }) {
    return data.map((raw) {
      final item = raw is Map<String, dynamic>
          ? raw
          : Map<String, dynamic>.from(raw as Map);
      final wage = item['hourlyWage'] ?? 0;
      final applicantsCurrent = _applicantsCurrent(item);
      final applicantsTotal = _applicantsTotal(item);
      final isDraft = _isDraftItem(item);

      // [중요 수정] imageUrls를 안전하게 List<String>으로 변환
      // List<dynamic>을 바로 cast하지 않고, map을 통해 String으로 변환합니다.
      final List<String> safePhotos =
          (item['imageUrls'] as List?)?.map((e) => e.toString()).toList() ?? [];

      final map = <String, dynamic>{
        'id': item['id'],
        'title': item['title'] ?? '',
        'employer': item['companyName'] ?? '',
        'dDay': isDone ? 'Completed' : _calculateDDay(item['endDate']),
        'tag': (item['tags'] != null && (item['tags'] as List).isNotEmpty)
            ? item['tags'][0]
            : (wage == 0 ? 'Volunteer' : 'Rookie'),
        'hasContent':
            item['description'] != null && item['description'].toString().isNotEmpty,
        'body': item['description'] ?? '',
        'photos': safePhotos, // 이제 확실한 List<String>이 저장됩니다.
        'hourlyWage': wage,
        'isDraft': isDraft,
      };

      if (forEmployer) {
        map.addAll({
          'applicantsCurrent': applicantsCurrent,
          'applicantsTotal': applicantsTotal,
          'employerStatus': _resolveEmployerStatus(
            item,
            isDone: isDone,
            isDraft: isDraft,
            applicantsCurrent: applicantsCurrent,
            applicantsTotal: applicantsTotal,
          ),
        });
      }

      return map;
    }).toList();
  }

  int _applicantsCurrent(Map<String, dynamic> item) {
    final value = item['acceptedCount'] ??
        item['applicantCount'] ??
        item['currentApplicants'] ??
        item['filledCount'];
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _applicantsTotal(Map<String, dynamic> item) {
    final value = item['headcount'] ??
        item['maxApplicants'] ??
        item['openings'] ??
        item['recruitmentCount'] ??
        item['totalOpenings'];
    if (value is int && value > 0) return value;
    final parsed = int.tryParse(value?.toString() ?? '');
    return (parsed != null && parsed > 0) ? parsed : 1;
  }

  bool _isDraftItem(Map<String, dynamic> item) {
    if (item['isDraft'] == true) return true;
    final status = (item['status'] ?? item['postStatus'] ?? '')
        .toString()
        .toLowerCase();
    return status == 'draft';
  }

  String _resolveEmployerStatus(
    Map<String, dynamic> item, {
    required bool isDone,
    required bool isDraft,
    required int applicantsCurrent,
    required int applicantsTotal,
  }) {
    final status = (item['status'] ?? item['postStatus'] ?? '')
        .toString()
        .toLowerCase();
    if (isDraft || status == 'draft') return 'draft';
    if (isDone || status == 'closed' || status == 'completed') return 'closed';
    if (status == 'filled') return 'filled';
    if (status == 'hiring' || status == 'open' || status == 'active') {
      return 'hiring';
    }
    if (applicantsTotal > 0 && applicantsCurrent >= applicantsTotal) {
      return 'filled';
    }
    return 'hiring';
  }

  String _calculateDDay(String? endDateStr) {
    if (endDateStr == null) return "D-?";
    try {
      final endDate = DateTime.parse(endDateStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final target = DateTime(endDate.year, endDate.month, endDate.day);
      final diff = target.difference(today).inDays;
      if (diff == 0) return "D-Day";
      return diff < 0 ? "Expired" : "D-$diff";
    } catch (e) {
      return "D-?";
    }
  }

  // --- UI 구조 통일화를 위한 Getter ---

  /// UI에서 모집 중 리스트를 부를 때 사용 (Recruitment 탭)
  List<Map<String, dynamic>> get currentRecruitmentHistory {
    return isEmployer ? employerRecruitmentHistory : recruitmentHistory;
  }

  /// UI에서 완료된 유급 업무 리스트를 부를 때 사용 (Completion 탭 - Works 섹션)
  List<Map<String, dynamic>> get currentCompletionWorks {
    return isEmployer ? employerCompletionHistory : completionHistoryWorks;
  }

  /// UI에서 자원봉사 리스트를 부를 때 사용 (Completion 탭 - Volunteer 섹션)
  List<Map<String, dynamic>> get filteredVolunteerList {
    final sourceList = isEmployer
        ? employerCompletionVolunteer
        : completionHistoryVolunteer;

    if (volunteerFilter.value == 0) {
      return sourceList.where((item) => item['isDraft'] == true).toList();
    } else {
      return sourceList.where((item) => item['isDraft'] == false).toList();
    }
  }

  /// 구인자 전용: 내 모든 공고 (모달 등에서 사용)
  List<Map<String, dynamic>> get employerJobOpenings => [
    ...employerRecruitmentHistory,
    ...employerCompletionHistory,
    ...employerCompletionVolunteer,
  ];

  static const _employerStatusByTab = ['hiring', 'filled', 'closed', 'draft'];

  /// 현재 구인자 탭에 해당하는 공고 목록.
  /// API 데이터가 비어 있을 때(디자인/개발용)는 더미를 반환한다.
  List<Map<String, dynamic>> get employerJobsForCurrentTab {
    final tab = employerTabIndex.value.clamp(0, 3);
    final status = _employerStatusByTab[tab];
    final filtered = employerJobOpenings
        .where((job) => job['employerStatus'] == status)
        .toList();
    if (filtered.isNotEmpty) return filtered;
    switch (tab) {
      case 0:
        return _employerHiringDummy;
      case 1:
        return _employerFilledDummy;
      case 2:
        return _employerClosedDummy;
      case 3:
        return _employerDraftDummy;
    }
    return const [];
  }

  /// Hiring 탭 (구인자) - API 데이터 없을 때 사용하는 더미.
  static const List<Map<String, dynamic>> _employerHiringDummy = [
    {
      'title': 'Food Delivery Rider',
      'employer': 'Hungry Panda',
      'dDay': 'D-31',
      'tag': 'Rookie',
      'applicantsCurrent': 1,
      'applicantsTotal': 3,
      'employerStatus': 'hiring',
    },
    {
      'title': 'Temporary Sales Assistant',
      'employer': 'Happy Gumpy',
      'dDay': 'D-31',
      'tag': 'Rookie',
      'applicantsCurrent': 2,
      'applicantsTotal': 5,
      'employerStatus': 'hiring',
    },
    {
      'title': 'Pop-Up Store Crew',
      'employer': 'Red Bull Australia',
      'dDay': 'D-31',
      'tag': 'Rookie',
      'applicantsCurrent': 4,
      'applicantsTotal': 7,
      'employerStatus': 'hiring',
    },
    {
      'title': 'Festival Support Staff',
      'employer': 'Boost Juice',
      'dDay': 'D-31',
      'tag': 'Rookie',
      'applicantsCurrent': 2,
      'applicantsTotal': 5,
      'employerStatus': 'hiring',
    },
    {
      'title': 'Event Helper',
      'employer': 'Boost Juice',
      'dDay': 'D-31',
      'tag': 'Rookie',
      'applicantsCurrent': 0,
      'applicantsTotal': 4,
      'employerStatus': 'hiring',
    },
  ];

  /// Filled 탭 (구인자) - API 데이터 없을 때 사용하는 더미.
  /// 지원자가 모두 차서 applicantsCurrent == applicantsTotal.
  static const List<Map<String, dynamic>> _employerFilledDummy = [
    {
      'title': 'Cashier',
      'employer': 'Blue Wattle Coffee',
      'dDay': 'D-31',
      'tag': 'Rookie',
      'applicantsCurrent': 1,
      'applicantsTotal': 1,
      'employerStatus': 'filled',
    },
    {
      'title': 'Barista',
      'employer': 'Blue Wattle Coffee',
      'dDay': 'D-31',
      'tag': 'Rookie',
      'applicantsCurrent': 2,
      'applicantsTotal': 2,
      'employerStatus': 'filled',
    },
    {
      'title': 'Brand Ambassador',
      'employer': 'UGG (AU)',
      'dDay': 'D-31',
      'tag': 'Rookie',
      'applicantsCurrent': 1,
      'applicantsTotal': 1,
      'employerStatus': 'filled',
    },
    {
      'title': 'Pop-Up Store Crew',
      'employer': 'UGG (AU)',
      'dDay': 'D-31',
      'tag': 'Rookie',
      'applicantsCurrent': 8,
      'applicantsTotal': 8,
      'employerStatus': 'filled',
    },
    {
      'title': 'Office Assistant',
      'employer': "Browing'",
      'dDay': 'D-31',
      'tag': 'Rookie',
      'applicantsCurrent': 3,
      'applicantsTotal': 3,
      'employerStatus': 'filled',
    },
  ];

  /// Closed 탭 (구인자) - 완전히 끝난 공고 더미.
  static const List<Map<String, dynamic>> _employerClosedDummy = [
    {
      'title': 'Pop-Up Store Crew',
      'employer': 'Happy Gumpy',
      'dDay': 'D-31',
      'tag': 'Rookie',
      'employerStatus': 'closed',
    },
    {
      'title': 'Pop-Up Store Crew',
      'employer': 'Happy Gumpy',
      'dDay': 'D-31',
      'tag': 'Rookie',
      'employerStatus': 'closed',
    },
    {
      'title': 'Pop-Up Store Crew',
      'employer': 'Happy Gumpy',
      'dDay': 'D-31',
      'tag': 'Rookie',
      'employerStatus': 'closed',
    },
    {
      'title': 'Pop-Up Store Crew',
      'employer': 'Happy Gumpy',
      'dDay': 'D-31',
      'tag': 'Rookie',
      'employerStatus': 'closed',
    },
    {
      'title': 'Pop-Up Store Crew',
      'employer': 'Happy Gumpy',
      'dDay': 'D-31',
      'tag': 'Rookie',
      'employerStatus': 'closed',
    },
  ];

  /// Draft 탭 (구인자) - 임시 저장된 공고 더미.
  static const List<Map<String, dynamic>> _employerDraftDummy = [
    {
      'title': 'Pop-Up Store Crew',
      'employer': 'Happy Gumpy',
      'dDay': 'D-31',
      'tag': 'Rookie',
      'employerStatus': 'draft',
    },
    {
      'title': 'Pop-Up Store Crew',
      'employer': 'Happy Gumpy',
      'dDay': 'D-31',
      'tag': 'Rookie',
      'employerStatus': 'draft',
    },
    {
      'title': 'Pop-Up Store Crew',
      'employer': 'Happy Gumpy',
      'dDay': 'D-31',
      'tag': 'Rookie',
      'employerStatus': 'draft',
    },
    {
      'title': 'Pop-Up Store Crew',
      'employer': 'Happy Gumpy',
      'dDay': 'D-31',
      'tag': 'Rookie',
      'employerStatus': 'draft',
    },
    {
      'title': 'Pop-Up Store Crew',
      'employer': 'Happy Gumpy',
      'dDay': 'D-31',
      'tag': 'Rookie',
      'employerStatus': 'draft',
    },
  ];

  bool get showEmployerApplicantBadge {
    final tab = employerTabIndex.value;
    return tab == 0 || tab == 1;
  }

  void setSelectedTab(int index) => selectedTab.value = index;
  void setEmployerTab(int index) => employerTabIndex.value = index;
  void setSeekerTab(int index) {
    seekerTabIndex.value = index;
    // 기존 로직(goToWritePage/goToDetailPage)에서 selectedTab을 사용하므로 동기화한다.
    // 0: Applying → 작성 페이지 분기, 1·2 → 상세 페이지 분기
    selectedTab.value = index == 0 ? 0 : 1;
  }

  /// 구직자 탭별 데이터 (0 Applied / 1 Ongoing / 2 Done / 3 Saved).
  /// API 데이터가 비어있을 때(디자인/개발용)는 더미를 반환한다.
  /// Done 탭은 [seekerDoneJobs] 를 그대로 사용하며 write_button 모달과 동일한 소스다.
  /// Saved 탭은 사용자가 직접 작성한 노트가 최상단에 누적되고,
  /// 아래로는 디자인 시안용 더미가 따라온다.
  List<Map<String, dynamic>> get seekerJobsForCurrentTab {
    final tab = seekerTabIndex.value.clamp(0, 3);
    switch (tab) {
      case 0:
        return recruitmentHistory.isNotEmpty
            ? recruitmentHistory
            : _seekerAppliedDummy;
      case 1:
        return _seekerOngoingDummy;
      case 2:
        return seekerDoneJobs;
      case 3:
        return [...seekerWrittenNotes, ..._seekerSavedDummy];
    }
    return const [];
  }

  /// 구직자가 write_button을 눌렀을 때 My Job Openings 모달에 보여줄 후보 목록.
  /// Done 탭과 동일한 [seekerDoneJobs] 를 그대로 사용한다.
  List<Map<String, dynamic>> get seekerWritableJobs => seekerDoneJobs;

  /// Applied 탭 (구직자) - 지원한 공고 더미.
  static const List<Map<String, dynamic>> _seekerAppliedDummy = [
    {
      'title': 'Food Delivery Rider',
      'employer': 'Hungry Panda',
      'dDay': 'D-31',
      'tag': 'Rookie',
    },
    {
      'title': 'Temporary Sales Assistant',
      'employer': 'Happy Gumpy',
      'dDay': 'D-31',
      'tag': 'Rookie',
    },
    {
      'title': 'Café Job',
      'employer': "Bunny's",
      'dDay': 'D-15',
      'tag': 'Rookie',
    },
    {
      'title': 'Restaurant Staff',
      'employer': 'Aussie Bite',
      'dDay': 'D-32',
      'tag': 'Veteran',
    },
    {
      'title': 'Babysitter',
      'employer': "Jake's mom",
      'dDay': 'D-8',
      'tag': 'Rookie',
    },
  ];

  /// Ongoing 탭 (구직자) - 진행 중인 일 더미.
  static const List<Map<String, dynamic>> _seekerOngoingDummy = [
    {
      'title': 'Cashier',
      'employer': 'Blue Wattle Coffee',
      'dDay': 'D-12',
      'tag': 'Rookie',
    },
    {
      'title': 'Barista',
      'employer': 'Blue Wattle Coffee',
      'dDay': 'D-9',
      'tag': 'Rookie',
    },
    {
      'title': 'Brand Ambassador',
      'employer': 'UGG (AU)',
      'dDay': 'D-6',
      'tag': 'Veteran',
    },
  ];

  /// Done 탭 (구직자) - 완료한 일 더미. 카드 전체 muted 처리.
  static const List<Map<String, dynamic>> _seekerDoneDummy = [
    {
      'title': 'Pop-Up Store Crew',
      'employer': 'Happy Gumpy',
      'dDay': 'D-31',
      'tag': 'Rookie',
      'muted': true,
    },
    {
      'title': 'Pop-Up Store Crew',
      'employer': 'Happy Gumpy',
      'dDay': 'D-31',
      'tag': 'Rookie',
      'muted': true,
    },
    {
      'title': 'Pop-Up Store Crew',
      'employer': 'Happy Gumpy',
      'dDay': 'D-31',
      'tag': 'Rookie',
      'muted': true,
    },
    {
      'title': 'Pop-Up Store Crew',
      'employer': 'Happy Gumpy',
      'dDay': 'D-31',
      'tag': 'Rookie',
      'muted': true,
    },
    {
      'title': 'Pop-Up Store Crew',
      'employer': 'Happy Gumpy',
      'dDay': 'D-31',
      'tag': 'Rookie',
      'muted': true,
    },
  ];

  /// Saved 탭 (구직자) - 북마크한 공고 더미.
  static const List<Map<String, dynamic>> _seekerSavedDummy = [
    {
      'title': 'Record Shop Employee',
      'employer': 'People needs Rabbit!',
      'dDay': 'D-8',
      'tag': 'Rookie',
    },
    {
      'title': 'Festival Support Staff',
      'employer': 'Boost Juice',
      'dDay': 'D-31',
      'tag': 'Rookie',
    },
    {
      'title': 'Hostel Staff',
      'employer': 'Ustaing',
      'dDay': 'D-10',
      'tag': 'Rookie',
    },
    {
      'title': 'Dog Walker',
      'employer': 'Pet Lovers',
      'dDay': 'D-5',
      'tag': 'Rookie',
    },
  ];

  void setVolunteerFilter(int value) => volunteerFilter.value = value;

  Future<void> goToEmployerWritePage() async {
    final result = await Get.to(() => const EmployerNoteWritePage());
    if (result == true) await fetchAllData();
  }

  Future<void> goToWritePage(Map<String, dynamic> item) async {
    final isRecruitmentTab = selectedTab.value == 0;
    if (!(isRecruitmentTab && item['hasContent'] != true)) return;

    final result = isEmployer
        ? await Get.to(() => const EmployerNoteWritePage())
        : await Get.to(() => const SeekerNoteWritePage());

    // 글 작성 성공 시 (result == true) 데이터 새로고침
    if (result == true) {
      await fetchAllData();
    }
  }

  void goToDetailPage(Map<String, dynamic> item) {
    // 1. 구인자(Employer)인 경우
    if (isEmployer) {
      if (item['employerStatus'] == 'draft') {
        goToEmployerWritePage();
        return;
      }
      Get.to(() => const JobDetailPage());
      return;
    }

    // 2. 구직자(Seeker)인 경우
    // 현재 선택된 탭이 '모집 중(Recruitment)' 탭(index 0)인지 확인
    if (selectedTab.value == 0) {
      // 모집 중인 공고를 누르면 작성 페이지로 이동
      Get.to(() => const SeekerNoteWritePage())?.then((result) {
        if (result == true) fetchAllData(); // 작성 후 돌아오면 새로고침
      });
    } else {
      // 완료(Completion) / Saved 탭에서 내용이 있는 경우 상세를 인라인으로 표시.
      if (item['hasContent'] != true) return;
      openViewingNote(item);
    }
  }
}
