import 'package:get/get.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/env.dart';
import '../controllers/auth_controller.dart';
import '../pages/MainPage/job_detail_page.dart';
import '../pages/NotePage/employer_note_write_page.dart';
import '../pages/NotePage/seeker_note_write_page.dart';
// 🚨 경로를 프로젝트에 맞게 수정해주세요! (보통 controllers 폴더와 services 폴더가 나란히 있습니다)
import '../services/user_service.dart';

class NotePageController extends GetxController {
  final selectedTab = 0.obs;

  /// 구인자 Note 상단 탭: 0 Hiring(모집중), 1 Ongoing(인원 확정·진행중), 2 Done(완료)
  ///
  /// - Hiring: 모집 마감일 전. 정원이 다 차도 마감일까지 여기에 머무르며
  ///   `_buildApplicantBadge` 가 색만 바뀐다. 카드 탭 시 `JobApplicationListModal` 노출.
  /// - Ongoing: 정원이 확정되고 실제 일이 진행 중. 카드 탭은 무반응.
  /// - Done: 모든 일정이 끝남. 각 카드 우측에 Write Review 버튼이 떠
  ///   사람 선택 모달 → 별점 작성 페이지로 연결.
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

  /// 구인자 Hiring/Ongoing/Done 더미를 시드로 한 mutable RxList.
  /// 백엔드 데이터가 비어있는 동안 UI 가 실제처럼 동작하도록 — 삭제/수정이
  /// 이 RxList 에 반영되어 즉시 카드 목록에서 사라지거나 갱신된다.
  late final RxList<Map<String, dynamic>> localEmployerHiring =
      <Map<String, dynamic>>[
        for (final e in _employerHiringDummy) Map<String, dynamic>.from(e),
      ].obs;
  late final RxList<Map<String, dynamic>> localEmployerOngoing =
      <Map<String, dynamic>>[
        for (final e in _employerOngoingDummy) Map<String, dynamic>.from(e),
      ].obs;
  /// Applied 탭 (구직자) 의 mutable 사본. Cancel application 등으로 즉시
  /// 카드가 사라지도록 employer 쪽과 동일한 패턴으로 RxList 로 들고 있다.
  late final RxList<Map<String, dynamic>> localSeekerApplied =
      <Map<String, dynamic>>[
        for (final e in _seekerAppliedDummy) Map<String, dynamic>.from(e),
      ].obs;

  late final RxList<Map<String, dynamic>> localEmployerDone =
      <Map<String, dynamic>>[
        for (final e in _employerDoneDummy) Map<String, dynamic>.from(e),
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
    _initEmployerState();
  }

  @override
  void onClose() {
    _employerTypeWorker?.dispose();
    super.onClose();
  }

  /// 🌟 기기 저장소에서 유저 타입을 가져와 UI 및 API 호출을 준비합니다.
  Future<void> _initEmployerState() async {
    // 1. 기기 저장소(UserService)에서 고용주 여부를 먼저 가져옵니다.
    final isEmp = await UserService.isEmployer();
    isEmployer = isEmp;
    isEmployerObs.value = isEmp; // 이 순간 UI가 Employer 화면으로 변경됩니다!

    // 2. AuthController 동기화 및 리스너 등록
    if (Get.isRegistered<AuthController>()) {
      AuthController.to.isEmployer.value = isEmp;

      _employerTypeWorker?.dispose();
      _employerTypeWorker = ever(AuthController.to.isEmployer, (_) {
        _syncEmployerFlag();
        fetchAllData();
      });
    }

    // 3. 역할이 확정된 후 알맞은 API를 호출합니다.
    await fetchAllData();
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
    final data = await _fetchFromApi("${Env.apiBaseUrl}/api/jobseeker/posts");
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
    final data = await _fetchFromApi("${Env.apiBaseUrl}/api/employer/posts");
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
            item['description'] != null &&
            item['description'].toString().isNotEmpty,
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
    final value =
        item['acceptedCount'] ??
        item['applicantCount'] ??
        item['currentApplicants'] ??
        item['filledCount'];
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _applicantsTotal(Map<String, dynamic> item) {
    final value =
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
    // 새 3탭 구조 (hiring / ongoing / done) 에서는
    // draft 는 별도 탭이 사라졌으므로 hiring 으로 흡수하여 표시한다.
    if (isDone ||
        status == 'closed' ||
        status == 'completed' ||
        status == 'done') {
      return 'done';
    }
    if (status == 'ongoing' || status == 'in_progress' || status == 'filled') {
      return 'ongoing';
    }
    if (isDraft || status == 'draft') return 'hiring';
    if (status == 'hiring' || status == 'open' || status == 'active') {
      return 'hiring';
    }
    // 정원 다 차도 마감일 전이면 여전히 hiring 으로 두고
    // UI 의 배지 색만 바뀌게 한다.
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

  static const _employerStatusByTab = ['hiring', 'ongoing', 'done'];

  /// 현재 구인자 탭에 해당하는 공고 목록.
  /// API 데이터가 비어 있을 때(디자인/개발용)는 더미를 반환한다.
  ///
  /// Done 탭(2) 은 `reviewedAll == true` 인 카드(=모든 참여자에게 리뷰 작성 완료) 를
  /// 리스트 맨 아래로 정렬해, 사용자가 아직 작성해야 할 카드를 위쪽에서 바로 보게 한다.
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
      // Done 탭: 리뷰 미완료(false) 가 먼저, 완료(true) 는 뒤로.
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

  /// 구인자 공고를 더미/실데이터 양쪽에서 모두 안전하게 제거한다.
  /// 매칭 우선순위: id → (title + employer).
  void removeEmployerJob(Map<String, dynamic> item) {
    bool sameItem(Map<String, dynamic> e) {
      if (item['id'] != null && e['id'] != null) return e['id'] == item['id'];
      return e['title'] == item['title'] && e['employer'] == item['employer'];
    }

    employerRecruitmentHistory.removeWhere(sameItem);
    employerCompletionHistory.removeWhere(sameItem);
    employerCompletionVolunteer.removeWhere(sameItem);
    localEmployerHiring.removeWhere(sameItem);
    localEmployerOngoing.removeWhere(sameItem);
    localEmployerDone.removeWhere(sameItem);
  }

  /// 구인자 공고 카드를 새 값으로 갱신한다. (수정 페이지 저장 후 호출)
  /// 매칭은 [removeEmployerJob] 과 동일 규칙.
  void updateEmployerJob(
    Map<String, dynamic> oldItem,
    Map<String, dynamic> newItem,
  ) {
    bool sameItem(Map<String, dynamic> e) {
      if (oldItem['id'] != null && e['id'] != null) {
        return e['id'] == oldItem['id'];
      }
      return e['title'] == oldItem['title'] &&
          e['employer'] == oldItem['employer'];
    }

    void replaceIn(RxList<Map<String, dynamic>> list) {
      final idx = list.indexWhere(sameItem);
      if (idx >= 0) list[idx] = newItem;
    }

    replaceIn(employerRecruitmentHistory);
    replaceIn(employerCompletionHistory);
    replaceIn(employerCompletionVolunteer);
    replaceIn(localEmployerHiring);
    replaceIn(localEmployerOngoing);
    replaceIn(localEmployerDone);
  }

  /// 새로 publish 된 구인 공고를 Hiring 탭 최상단에 끼워 넣는다.
  /// (StartHiringPage 의 publish 흐름 — 백엔드 응답을 기다리지 않고
  ///  먼저 로컬 RxList 에 반영해 사용자가 곧장 카드 형태로 볼 수 있게 한다.)
  ///
  /// 같은 카드를 두 번 등록하지 않도록 `id` 또는 `title + employer` 기준으로
  /// 이미 존재하면 무시한다. (백엔드가 응답하며 같은 id 의 카드를 다시
  /// 보낼 수도 있어 안전망을 둠.)
  void addEmployerHiring(Map<String, dynamic> item) {
    bool isSame(Map<String, dynamic> e) {
      if (item['id'] != null && e['id'] != null) return e['id'] == item['id'];
      return e['title'] == item['title'] && e['employer'] == item['employer'];
    }

    if (employerRecruitmentHistory.any(isSame)) return;
    if (localEmployerHiring.any(isSame)) return;
    localEmployerHiring.insert(0, item);
    // 현재 표시 탭이 Hiring 이 아니어도 다음에 Hiring 탭을 열 때 보이도록 한다.
  }

  /// 구직자 Applied 탭에서 카드를 제거한다 (Cancel application 시 사용).
  /// API 데이터(recruitmentHistory) / 로컬 더미 양쪽에서 모두 제거.
  void removeSeekerApplied(Map<String, dynamic> item) {
    bool sameItem(Map<String, dynamic> e) {
      if (item['id'] != null && e['id'] != null) return e['id'] == item['id'];
      return e['title'] == item['title'] && e['employer'] == item['employer'];
    }

    recruitmentHistory.removeWhere(sameItem);
    localSeekerApplied.removeWhere(sameItem);
  }

  /// Hiring 탭 (구인자) - 모집 마감 전 공고.
  /// 선착순이 아니라 누구든 지원 가능한 구조라
  /// 가분수(예: 8/3, 5/4) 도 자연스럽게 나올 수 있다.
  /// 정원이 다 찼거나 넘긴 카드는 `NotePage._buildApplicantBadge` 에서
  /// 색만 주황으로 강조해 사용자가 바로 알아볼 수 있게 한다.
  static const List<Map<String, dynamic>> _employerHiringDummy = [
    {
      'title': 'Pop-Up Store Crew',
      'employer': 'UGG (AU)',
      'dDay': 'D-31',
      'tag': 'Rookie',
      'applicantsCurrent': 8,
      'applicantsTotal': 3,
      'employerStatus': 'hiring',
      'scheduleDate': 'Jan 29, 2026 - Feb 21, 2026',
      'location': '120 Pitt St, Sydney NSW 2000',
      'payText': '\$28 / hour',
      'openingsText': '3 openings.',
      'description':
          'UGG Pop-Up Store is hiring outgoing crew members to assist '
          'customers during our 4-week pop-up campaign. Shifts are '
          'flexible (weekdays + weekends) and full training is provided.',
    },
    {
      'title': 'Brand Ambassador',
      'employer': 'UGG (AU)',
      'dDay': 'D-31',
      'tag': 'Rookie',
      'applicantsCurrent': 5,
      'applicantsTotal': 4,
      'employerStatus': 'hiring',
      'scheduleDate': 'Feb 03, 2026 - Mar 14, 2026',
      'location': 'Westfield Bondi Junction, NSW 2022',
      'payText': '\$32 / hour + bonus',
      'openingsText': '4 openings.',
      'description':
          'Represent UGG at flagship stores across Sydney. Looking for '
          'enthusiastic ambassadors for weekend shifts.',
    },
    {
      'title': 'Cashier',
      'employer': 'Blue Wattle Coffee',
      'dDay': 'D-31',
      'tag': 'Rookie',
      'applicantsCurrent': 1,
      'applicantsTotal': 1,
      'employerStatus': 'hiring',
      'scheduleDate': 'Feb 10, 2026 - May 10, 2026',
      'location': '12 Oxford St, Paddington NSW 2021',
      'payText': '\$26 / hour',
      'openingsText': '1 opening.',
      'description':
          'Friendly cafe in Paddington looking for a cashier for the morning '
          'rush (6am - 11am). Coffee knowledge is a plus.',
    },
    {
      'title': 'Barista',
      'employer': 'Blue Wattle Coffee',
      'dDay': 'D-31',
      'tag': 'Rookie',
      'applicantsCurrent': 2,
      'applicantsTotal': 2,
      'employerStatus': 'hiring',
      'scheduleDate': 'Feb 10, 2026 - May 10, 2026',
      'location': '12 Oxford St, Paddington NSW 2021',
      'payText': '\$30 / hour',
      'openingsText': '2 openings.',
      'description':
          'Experienced barista (6+ months) wanted for our specialty coffee '
          'bar. Latte art and pour-over experience preferred.',
    },
    {
      'title': 'Office Assistant',
      'employer': "Browing'",
      'dDay': 'D-31',
      'tag': 'Rookie',
      'applicantsCurrent': 1,
      'applicantsTotal': 3,
      'employerStatus': 'hiring',
      'scheduleDate': 'Feb 15, 2026 - Aug 15, 2026',
      'location': '88 Phillip St, Sydney NSW 2000',
      'payText': '\$27 / hour',
      'openingsText': '3 openings.',
      'description':
          'Support our 12-person team with light admin tasks: filing, '
          'reception cover, and meeting prep. 3 days a week.',
    },
    {
      'title': 'Food Delivery Rider',
      'employer': 'Hungry Panda',
      'dDay': 'D-15',
      'tag': 'Rookie',
      'applicantsCurrent': 1,
      'applicantsTotal': 3,
      'employerStatus': 'hiring',
      'scheduleDate': 'Feb 20, 2026 - Aug 20, 2026',
      'location': 'Sydney CBD & Inner West',
      'payText': '\$29 / hour + tips',
      'openingsText': '3 openings.',
      'description':
          'Deliver Asian cuisine across Sydney with our e-bike fleet. Bikes '
          'and uniforms supplied.',
    },
    {
      'title': 'Event Helper',
      'employer': 'Boost Juice',
      'dDay': 'D-7',
      'tag': 'Rookie',
      'applicantsCurrent': 0,
      'applicantsTotal': 4,
      'employerStatus': 'hiring',
      'scheduleDate': 'Feb 28, 2026 - Mar 02, 2026',
      'location': 'Royal Botanic Garden Sydney',
      'payText': '\$31 / hour',
      'openingsText': '4 openings.',
      'description':
          'Weekend pop-up at the Botanic Gardens. Help set up the booth, '
          'serve samples, and pack down.',
    },
  ];

  /// Ongoing 탭 (구인자) - 인원이 확정되어 실제로 일이 진행 중인 공고.
  /// 카드 탭은 무반응이며, trailing 에는 정원 배지(항상 다 찬 상태) 만 보인다.
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
    {
      'title': 'Temporary Sales Assistant',
      'employer': 'Happy Gumpy',
      'dDay': 'D-5',
      'tag': 'Rookie',
      'applicantsCurrent': 4,
      'applicantsTotal': 4,
      'employerStatus': 'ongoing',
    },
    {
      'title': 'Pop-Up Store Crew',
      'employer': 'Red Bull Australia',
      'dDay': 'D-2',
      'tag': 'Rookie',
      'applicantsCurrent': 7,
      'applicantsTotal': 7,
      'employerStatus': 'ongoing',
    },
  ];

  /// Done 탭 (구인자) - 종료된 공고 더미.
  /// 각 카드에는 Write Review 주황색 버튼이 trailing 으로 노출되고,
  /// 누르면 사람 선택 모달 → ReviewDetailPage 흐름으로 연결된다.
  ///
  /// `reviewedAll == true` 이면 참여한 모든 사람에 대해 이미 리뷰를 작성한
  /// 상태로 간주해 버튼을 회색·비활성으로 표시하고,
  /// `employerJobsForCurrentTab` 에서 리스트 맨 아래로 정렬된다.
  static const List<Map<String, dynamic>> _employerDoneDummy = [
    {
      'title': 'Pop-Up Store Crew',
      'employer': 'Happy Gumpy',
      'dDay': 'D-31',
      'tag': 'Rookie',
      'employerStatus': 'done',
      'reviewedAll': false,
    },
    {
      'title': 'Festival Support Staff',
      'employer': 'Boost Juice',
      'dDay': 'D-31',
      'tag': 'Rookie',
      'employerStatus': 'done',
      'reviewedAll': false,
    },
    {
      'title': 'Cashier',
      'employer': 'Blue Wattle Coffee',
      'dDay': 'D-31',
      'tag': 'Rookie',
      'employerStatus': 'done',
      'reviewedAll': false,
    },
    {
      'title': 'Pop-Up Store Crew',
      'employer': 'Sephora Australia',
      'dDay': 'D-31',
      'tag': 'Rookie',
      'employerStatus': 'done',
      'reviewedAll': true,
    },
    {
      'title': 'Brand Ambassador',
      'employer': 'UGG (AU)',
      'dDay': 'D-31',
      'tag': 'Rookie',
      'employerStatus': 'done',
      'reviewedAll': true,
    },
  ];

  /// trailing 영역에 정원 배지(1/1, 2/5 …)를 노출할지 여부.
  /// Hiring(0) / Ongoing(1) 만 true, Done(2) 은 Write Review 버튼이 대신 노출된다.
  bool get showEmployerApplicantBadge {
    final tab = employerTabIndex.value;
    return tab == 0 || tab == 1;
  }

  /// Done 탭(2) 일 때만 카드 trailing 에 Write Review 버튼이 보인다.
  bool get showEmployerWriteReviewButton => employerTabIndex.value == 2;

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
            : localSeekerApplied;
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

  /// Done 탭 (구직자) - 완료한 일 더미.
  /// 카드 자체를 탭하면 SeekerNoteWritePage 로 prefill 진입하므로
  /// 시안과 같이 다양한 회사명을 노출해 디자인 보강.
  static const List<Map<String, dynamic>> _seekerDoneDummy = [
    {
      'title': 'Pop-Up Store Crew',
      'employer': 'Sephora Australia',
      'dDay': 'D-31',
      'tag': 'Rookie',
      'muted': true,
    },
    {
      'title': 'Festival Support Staff',
      'employer': 'UNIQLO Australia',
      'dDay': 'D-31',
      'tag': 'Rookie',
      'muted': true,
    },
    {
      'title': 'Event Helper',
      'employer': "Grill'd",
      'dDay': 'D-31',
      'tag': 'Rookie',
      'muted': true,
    },
    {
      'title': 'Casual Bar Support Staff',
      'employer': 'Pepper & Vine',
      'dDay': 'D-31',
      'tag': 'Rookie',
      'muted': true,
    },
    {
      'title': 'Temporary Sales Assistant',
      'employer': 'Oak & Ivy',
      'dDay': 'D-31',
      'tag': 'Rookie',
      'muted': true,
    },
  ];

  /// Saved 탭 (구직자) - 사용자가 저장한 자기 노트 더미.
  /// detail / edit 페이지가 정상 동작하도록 hasContent, body, skills,
  /// tag(=Overall Experience 라벨), photos 까지 함께 채워둔다.
  static const List<Map<String, dynamic>> _seekerSavedDummy = [
    {
      'title': 'Record Shop Employee',
      'employer': "People Needs Rabbit!",
      'dDay': 'Saved',
      'tag': 'Great',
      'hasContent': true,
      'body':
          'Loved every shift here. The crew was super welcoming and I '
          'genuinely learned how to recommend vinyl to first-time buyers. '
          'Closing duties are quick once you get the rhythm.',
      'skills': ['Communication', 'Customer Interaction', 'Initiative'],
      'photos': [
        'https://images.unsplash.com/photo-1511735111819-9a3f7709049c?w=800',
        'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=800',
      ],
    },
    {
      'title': 'Festival Support Staff',
      'employer': 'Boost Juice',
      'dDay': 'Saved',
      'tag': 'Good',
      'hasContent': true,
      'body':
          'High-energy weekend at the festival. Long shifts but the team '
          'made it fly by. Got better at handling cash and managing queues.',
      'skills': ['Teamwork', 'Time Management', 'Adaptability'],
      'photos': [
        'https://images.unsplash.com/photo-1533174072545-7a4b6ad7a6c3?w=800',
      ],
    },
    {
      'title': 'Hostel Staff',
      'employer': 'Ustaing',
      'dDay': 'Saved',
      'tag': 'Okay',
      'hasContent': true,
      'body':
          'Front-desk shifts were quiet on weekdays, busy on weekends. '
          'Good entry-level role if you want to practise English with '
          'international guests.',
      'skills': ['Communication', 'Problem Solving'],
      'photos': <String>[],
    },
    {
      'title': 'Dog Walker',
      'employer': 'Pet Lovers',
      'dDay': 'Saved',
      'tag': 'Great',
      'hasContent': true,
      'body':
          'Met three adorable regulars and learned how to read each dog\'s '
          'energy. Outdoor work in the morning is honestly the best.',
      'skills': ['Independence', 'Adaptability'],
      'photos': [
        'https://images.unsplash.com/photo-1583337130417-3346a1be7dee?w=800',
      ],
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
    // 1. 구인자(Employer)인 경우 - 카드별 상세 진입.
    //    새 3탭 구조에서는 view(NotePage)가 탭별로 직접 분기하므로
    //    여기로 들어오는 경우는 외부(예: 다른 페이지)에서 명시적으로 호출한 때다.
    if (isEmployer) {
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
