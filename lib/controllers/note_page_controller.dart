import 'package:get/get.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/env.dart';
import '../utils/image_url.dart';
import '../controllers/auth_controller.dart';
import '../pages/MainPage/job_detail_page.dart';
import '../pages/NotePage/employer_note_write_page.dart';
import '../pages/NotePage/seeker_note_write_page.dart';
import '../services/user_service.dart';
import '../services/token_storage.dart';
import '../../services/token_storage.dart';

class NotePageController extends GetxController {
  final selectedTab = 0.obs;

  /// 구인자 Note 상단 탭: 0 Hiring, 1 Ongoing, 2 Done
  final employerTabIndex = 0.obs;

  /// 구직자 Note 상단 탭: 0 Applied, 1 Ongoing, 2 Done, 3 Saved
  final seekerTabIndex = 0.obs;
  final volunteerFilter = 1.obs; // 0: Draft, 1: Most recent
  final isLoading = false.obs;

  bool isEmployer = false;
  final RxBool isEmployerObs = false.obs;

  Worker? _employerTypeWorker;

  // --- 관찰 가능한 리스트 (RxList) : 유저님 기존 변수명 100% 복구 ---
  // 💡 구인자용 (Employer)
  final RxList<Map<String, dynamic>> employerHiringList =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> employerOngoingList =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> employerDoneList =
      <Map<String, dynamic>>[].obs;

  // 💡 구직자용 (Job Seeker)
  final RxList<Map<String, dynamic>> recruitmentHistory =
      <Map<String, dynamic>>[].obs; // Applied
  final RxList<Map<String, dynamic>> seekerOngoingList =
      <Map<String, dynamic>>[].obs; // Ongoing
  final RxList<Map<String, dynamic>> completionHistoryWorks =
      <Map<String, dynamic>>[].obs; // Done (Wage)
  final RxList<Map<String, dynamic>> completionHistoryVolunteer =
      <Map<String, dynamic>>[].obs; // Done (Volunteer)

  /// 구직자가 직접 작성한 노트(후기) 목록
  final RxList<Map<String, dynamic>> seekerWrittenNotes =
      <Map<String, dynamic>>[].obs;

  /// 구직자 Done 탭과 write_button 모달이 함께 참조하는 "후기 작성 가능 목록"
  late final RxList<Map<String, dynamic>> seekerDoneJobs =
      <Map<String, dynamic>>[
        for (final e in _seekerDoneDummy) Map<String, dynamic>.from(e),
      ].obs;

  // --- 로컬 사본 데이터 (더미 대응용) ---
  late final RxList<Map<String, dynamic>> localEmployerHiring =
      <Map<String, dynamic>>[
        for (final e in _employerHiringDummy) Map<String, dynamic>.from(e),
      ].obs;
  late final RxList<Map<String, dynamic>> localEmployerOngoing =
      <Map<String, dynamic>>[
        for (final e in _employerOngoingDummy) Map<String, dynamic>.from(e),
      ].obs;
  late final RxList<Map<String, dynamic>> localSeekerApplied =
      <Map<String, dynamic>>[
        for (final e in _seekerAppliedDummy) Map<String, dynamic>.from(e),
      ].obs;
  late final RxList<Map<String, dynamic>> localEmployerDone =
      <Map<String, dynamic>>[
        for (final e in _employerDoneDummy) Map<String, dynamic>.from(e),
      ].obs;

  final Rxn<Map<String, dynamic>> viewingNote = Rxn<Map<String, dynamic>>();

  void openViewingNote(Map<String, dynamic> note) => viewingNote.value = note;
  void closeViewingNote() => viewingNote.value = null;
  void addSeekerWrittenNote(Map<String, dynamic> note) =>
      seekerWrittenNotes.insert(0, note);

  void deleteSeekerWrittenNote(Map<String, dynamic> note) {
    final removed = seekerWrittenNotes.remove(note);
    if (!removed) {
      seekerWrittenNotes.removeWhere(
        (n) => identical(n, note) || n['title'] == note['title'],
      );
    }
  }

  void consumeSeekerDoneJob(Map<String, dynamic> item) {
    final removed = seekerDoneJobs.remove(item);
    if (removed) return;
    seekerDoneJobs.removeWhere((e) {
      if (item['id'] != null && e['id'] != null) return e['id'] == item['id'];
      return e['title'] == item['title'] && e['employer'] == item['employer'];
    });
  }

  @override
  void onInit() {
    super.onInit();
    _initEmployerState();
  }

  @override
  void onClose() {
    _employerTypeWorker?.dispose();
    super.onClose();
  }

  Future<void> _initEmployerState() async {
    final isEmp = await UserService.isEmployer();
    isEmployer = isEmp;
    isEmployerObs.value = isEmp;

    if (Get.isRegistered<AuthController>()) {
      AuthController.to.isEmployer.value = isEmp;
      _employerTypeWorker?.dispose();
      _employerTypeWorker = ever(AuthController.to.isEmployer, (_) {
        _syncEmployerFlag();
        fetchAllData();
      });
    }
    await fetchAllData();
  }

  void _syncEmployerFlag() {
    if (Get.isRegistered<AuthController>()) {
      isEmployer = AuthController.to.isEmployer.value;
      isEmployerObs.value = isEmployer;
    }
  }

  /// 모든 탭의 데이터 새로고침 (구인자 3개 / 구직자 3개 API 연결)
  Future<void> fetchAllData() async {
    isLoading.value = true;
    if (isEmployer) {
      await fetchEmployerHiring();
      await fetchEmployerOngoing();
      await fetchEmployerDone();
    } else {
      await fetchSeekerApplied();
      await fetchSeekerOngoing();
      await fetchSeekerDone();
    }
    isLoading.value = false;
  }

  // =========================================================
  // 🌟 [구인자 API 연결] - 건드리지 않고 그대로 살림!
  // =========================================================
  Future<void> fetchEmployerHiring() async {
    final data = await _fetchFromApi("${Env.apiBaseUrl}employer/posts/hiring");
    if (data != null)
      employerHiringList.assignAll(_mapApiData(data, forEmployer: true));
  }

  Future<void> fetchEmployerOngoing() async {
    final data = await _fetchFromApi("${Env.apiBaseUrl}employer/posts/ongoing");
    if (data != null)
      employerOngoingList.assignAll(_mapApiData(data, forEmployer: true));
  }

  Future<void> fetchEmployerDone() async {
    final data = await _fetchFromApi("${Env.apiBaseUrl}employer/posts/done");
    if (data != null)
      employerDoneList.assignAll(
        _mapApiData(data, isDone: true, forEmployer: true),
      );
  }

  // =========================================================
  // 🌟 [구직자 API 연결] - Saved 제외 3개 연결 완료!
  // =========================================================
  Future<void> fetchSeekerApplied() async {
    final data = await _fetchFromApi(
      "${Env.apiBaseUrl}jobseeker/posts/applied",
    );
    if (data != null) recruitmentHistory.assignAll(_mapApiData(data));
  }

  Future<void> fetchSeekerOngoing() async {
    final data = await _fetchFromApi(
      "${Env.apiBaseUrl}jobseeker/posts/ongoing",
    );
    if (data != null) seekerOngoingList.assignAll(_mapApiData(data));
  }

  Future<void> fetchSeekerDone() async {
    final data = await _fetchFromApi("${Env.apiBaseUrl}jobseeker/posts/done");
    if (data != null) {
      final allDone = _mapApiData(data, isDone: true);
      seekerDoneJobs.assignAll(allDone);
      completionHistoryWorks.assignAll(
        allDone.where((e) => e['hourlyWage'] > 0).toList(),
      );
      completionHistoryVolunteer.assignAll(
        allDone.where((e) => e['hourlyWage'] == 0).toList(),
      );
    }
  }

  // --- 공통 API 호출 로직 ---
  // --- 공통 API 호출 로직 ---
  Future<List<dynamic>?> _fetchFromApi(String url) async {
    // 💡 불필요한 스토리지 중복 생성을 제거하고 기존 TokenStorage 시스템으로 통일!
    final String? accessToken = await TokenStorage.readAccessToken();

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
      } else {
        print("API Error ($url): Status Code ${response.statusCode}");
      }
    } catch (e) {
      print("API Exception ($url): $e");
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

      // 💡 매핑 1: 백엔드의 hourlyRates(구인자) 또는 hourlyWage(구직자) 모두 대응
      final wage = item['hourlyRates'] ?? item['hourlyWage'] ?? 0;

      final applicantsCurrent = _applicantsCurrent(item);
      final applicantsTotal = _applicantsTotal(item);
      final isDraft = _isDraftItem(item);

      final List<String> safePhotos =
          (item['imageUrls'] as List?)
              ?.map((e) => resolveImageUrl(e.toString()))
              .toList() ??
          [];

      // 💡 매핑 2: 백엔드의 employmentTag(구인자 단일 String) 또는 tags(구직자 List) 모두 대응
      String tagValue = 'Rookie';
      if (item['employmentTag'] != null) {
        tagValue = item['employmentTag'];
      } else if (item['tags'] != null && (item['tags'] as List).isNotEmpty) {
        tagValue = item['tags'][0];
      } else if (wage == 0) {
        tagValue = 'Volunteer';
      }

      final map = <String, dynamic>{
        'id': item['id'],
        'title': item['title'] ?? '',
        'employer': item['companyName'] ?? '',
        // 💡 매핑 3: 백엔드에서 미리 계산해 넘겨준 dDay 문자열 우선 사용 (없으면 기존 방식)
        // 'dDay': isDone
        //     ? 'Completed'
        //     : (item['dDay'] ?? _calculateDDay(item['recruitmentDeadline'])),
        'dDay': item['dDay'] ?? item['dday'],
        'tag': tagValue,
        'responsibility': item['responsibility']?.toString() ?? '',
        'description': item['description']?.toString() ?? '',
        'hasContent':
            (item['responsibility'] != null &&
                item['responsibility'].toString().isNotEmpty) ||
            (item['description'] != null &&
                item['description'].toString().isNotEmpty),
        'body': item['description'] ?? '',
        'photos': safePhotos,
        'hourlyWage': wage,
        'isDraft': isDraft,
      };

      if (forEmployer) {
        map.addAll({
          'applicantsCurrent': applicantsCurrent,
          'applicantsTotal': applicantsTotal,
          // 💡 매핑 4: 백엔드가 넘겨준 employerStatus 최우선 적용
          'employerStatus':
              item['employerStatus'] ??
              _resolveEmployerStatus(
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
    // 💡 매핑 5: 백엔드의 'applicantsCurrent' 키 추가
    final value =
        item['applicantsCurrent'] ??
        item['acceptedCount'] ??
        item['applicantCount'] ??
        item['currentApplicants'] ??
        item['filledCount'];
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _applicantsTotal(Map<String, dynamic> item) {
    // 💡 매핑 6: 백엔드의 'count' 키 추가
    final value =
        item['count'] ??
        item['headcount'] ??
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
    if (isDone ||
        status == 'closed' ||
        status == 'completed' ||
        status == 'done')
      return 'done';
    if (status == 'ongoing' || status == 'in_progress' || status == 'filled')
      return 'ongoing';
    if (isDraft || status == 'draft') return 'hiring';
    if (status == 'hiring' || status == 'open' || status == 'active')
      return 'hiring';
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

  // --- 기존 UI 로직 (에러 나던 부분 정상화 완료) ---
  List<Map<String, dynamic>> get currentRecruitmentHistory {
    return isEmployer ? employerHiringList : recruitmentHistory;
  }

  List<Map<String, dynamic>> get currentCompletionWorks {
    return isEmployer ? employerDoneList : completionHistoryWorks;
  }

  List<Map<String, dynamic>> get filteredVolunteerList {
    if (isEmployer) return [];
    if (volunteerFilter.value == 0) {
      return completionHistoryVolunteer
          .where((item) => item['isDraft'] == true)
          .toList();
    } else {
      return completionHistoryVolunteer
          .where((item) => item['isDraft'] == false)
          .toList();
    }
  }

  List<Map<String, dynamic>> get employerJobOpenings => [
    ...employerHiringList,
    ...employerOngoingList,
    ...employerDoneList,
  ];

  static const _employerStatusByTab = ['hiring', 'ongoing', 'done'];

  List<Map<String, dynamic>> get employerJobsForCurrentTab {
    final tab = employerTabIndex.value.clamp(0, 2);
    final status = _employerStatusByTab[tab];
    final filtered = employerJobOpenings
        .where((job) => job['employerStatus'] == status)
        .toList();
    final base = filtered.isNotEmpty
        ? filtered
        : switch (tab) {
            0 => localEmployerHiring,
            1 => localEmployerOngoing,
            2 => localEmployerDone,
            _ => const <Map<String, dynamic>>[],
          };
    if (tab == 2) {
      final sorted = [...base];
      sorted.sort((a, b) {
        final aDone = a['reviewedAll'] == true ? 1 : 0;
        final bDone = b['reviewedAll'] == true ? 1 : 0;
        return aDone.compareTo(bDone);
      });
      return sorted;
    }
    return base;
  }

  void removeEmployerJob(Map<String, dynamic> item) {
    bool sameItem(Map<String, dynamic> e) {
      if (item['id'] != null && e['id'] != null) return e['id'] == item['id'];
      return e['title'] == item['title'] && e['employer'] == item['employer'];
    }

    employerHiringList.removeWhere(sameItem);
    employerOngoingList.removeWhere(sameItem);
    employerDoneList.removeWhere(sameItem);
    localEmployerHiring.removeWhere(sameItem);
    localEmployerOngoing.removeWhere(sameItem);
    localEmployerDone.removeWhere(sameItem);
  }

  void updateEmployerJob(
    Map<String, dynamic> oldItem,
    Map<String, dynamic> newItem,
  ) {
    bool sameItem(Map<String, dynamic> e) {
      if (oldItem['id'] != null && e['id'] != null)
        return e['id'] == oldItem['id'];
      return e['title'] == oldItem['title'] &&
          e['employer'] == oldItem['employer'];
    }

    void replaceIn(RxList<Map<String, dynamic>> list) {
      final idx = list.indexWhere(sameItem);
      if (idx >= 0) list[idx] = newItem;
    }

    replaceIn(employerHiringList);
    replaceIn(employerOngoingList);
    replaceIn(employerDoneList);
    replaceIn(localEmployerHiring);
    replaceIn(localEmployerOngoing);
    replaceIn(localEmployerDone);
  }

  void addEmployerHiring(Map<String, dynamic> item) {
    bool isSame(Map<String, dynamic> e) {
      if (item['id'] != null && e['id'] != null) return e['id'] == item['id'];
      return e['title'] == item['title'] && e['employer'] == item['employer'];
    }

    if (employerHiringList.any(isSame)) return;
    if (localEmployerHiring.any(isSame)) return;
    localEmployerHiring.insert(0, item);
  }

  // --- 💡 [클래스 내부로 복구] 에러가 났던 곳 ---
  void removeSeekerApplied(Map<String, dynamic> item) {
    bool sameItem(Map<String, dynamic> e) {
      if (item['id'] != null && e['id'] != null) return e['id'] == item['id'];
      return e['title'] == item['title'] && e['employer'] == item['employer'];
    }

    recruitmentHistory.removeWhere(sameItem);
    localSeekerApplied.removeWhere(sameItem);
  }

  bool get showEmployerApplicantBadge {
    final tab = employerTabIndex.value;
    return tab == 0 || tab == 1;
  }

  bool get showEmployerWriteReviewButton => employerTabIndex.value == 2;

  void setSelectedTab(int index) => selectedTab.value = index;
  void setEmployerTab(int index) => employerTabIndex.value = index;
  void setSeekerTab(int index) {
    seekerTabIndex.value = index;
    selectedTab.value = index == 0 ? 0 : 1;
  }

  /// 구직자 탭 노출 리스트
  List<Map<String, dynamic>> get seekerJobsForCurrentTab {
    final tab = seekerTabIndex.value.clamp(0, 3);
    switch (tab) {
      case 0:
        return recruitmentHistory.isNotEmpty
            ? recruitmentHistory
            : localSeekerApplied;
      case 1:
        return seekerOngoingList.isNotEmpty
            ? seekerOngoingList
            : _seekerOngoingDummy;
      case 2:
        return seekerDoneJobs;
      case 3: // Saved (아직 API 연동 안 했으므로 더미/로컬만)
        return [...seekerWrittenNotes, ..._seekerSavedDummy];
    }
    return const [];
  }

  List<Map<String, dynamic>> get seekerWritableJobs => seekerDoneJobs;

  // --- 더미 데이터 리스트들 ---
  static const List<Map<String, dynamic>> _employerHiringDummy = [
    {
      'title': 'Pop-Up Store Crew',
      'employer': 'UGG (AU)',
      'dDay': 'D-31',
      'tag': 'Rookie',
      'applicantsCurrent': 8,
      'applicantsTotal': 3,
      'employerStatus': 'hiring',
    },
  ];

  static const List<Map<String, dynamic>> _employerOngoingDummy = [
    {
      'title': 'Festival Support Staff',
      'employer': 'Boost Juice',
      'dDay': 'D-3',
      'tag': 'Rookie',
      'applicantsCurrent': 5,
      'applicantsTotal': 5,
      'employerStatus': 'ongoing',
    },
  ];

  static const List<Map<String, dynamic>> _employerDoneDummy = [
    {
      'title': 'Pop-Up Store Crew',
      'employer': 'Happy Gumpy',
      'dDay': 'D-31',
      'tag': 'Rookie',
      'employerStatus': 'done',
      'reviewedAll': false,
    },
  ];

  static const List<Map<String, dynamic>> _seekerAppliedDummy = [
    {
      'title': 'Food Delivery Rider',
      'employer': 'Hungry Panda',
      'dDay': 'D-31',
      'tag': 'Rookie',
    },
  ];

  static const List<Map<String, dynamic>> _seekerOngoingDummy = [
    {
      'title': 'Cashier',
      'employer': 'Blue Wattle Coffee',
      'dDay': 'D-12',
      'tag': 'Rookie',
    },
  ];

  static const List<Map<String, dynamic>> _seekerDoneDummy = [
    {
      'title': 'Pop-Up Store Crew',
      'employer': 'Sephora Australia',
      'dDay': 'D-31',
      'tag': 'Rookie',
      'muted': true,
    },
  ];

  static const List<Map<String, dynamic>> _seekerSavedDummy = [
    {
      'title': 'Record Shop Employee',
      'employer': "People Needs Rabbit!",
      'dDay': 'Saved',
      'tag': 'Great',
      'hasContent': true,
      'body': 'Loved every shift here. The crew was super welcoming...',
      'skills': ['Communication', 'Customer Interaction'],
      'photos': <String>[],
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

    if (result == true) await fetchAllData();
  }

  void goToDetailPage(Map<String, dynamic> item) {
    if (isEmployer) {
      Get.to(() => const JobDetailPage());
      return;
    }

    if (selectedTab.value == 0) {
      Get.to(() => const SeekerNoteWritePage())?.then((result) {
        if (result == true) fetchAllData();
      });
    } else {
      if (item['hasContent'] != true) return;
      openViewingNote(item);
    }
  }
} // 💡 클래스가 정상적으로 맨 끝에서 닫힙니다.
