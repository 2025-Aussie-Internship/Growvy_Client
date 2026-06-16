import 'package:get/get.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/env.dart';
import '../controllers/auth_controller.dart';
import '../pages/MainPage/job_detail_page.dart';
import '../pages/NotePage/employer_note_write_page.dart';
import '../pages/NotePage/seeker_note_write_page.dart';
// 🚨 경로를 프로젝트에 맞게 수정해주세요!
import '../services/user_service.dart';

class NotePageController extends GetxController {
  final selectedTab = 0.obs;

  final employerTabIndex = 0.obs;
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

  // 💡 구인자용 (Employer) - 3개의 탭에 맞게 명확하게 분리
  final RxList<Map<String, dynamic>> employerHiringList =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> employerOngoingList =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> employerDoneList =
      <Map<String, dynamic>>[].obs;

  final RxList<Map<String, dynamic>> seekerWrittenNotes =
      <Map<String, dynamic>>[].obs;

  late final RxList<Map<String, dynamic>> seekerDoneJobs =
      <Map<String, dynamic>>[
        for (final e in _seekerDoneDummy) Map<String, dynamic>.from(e),
      ].obs;

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

  void openViewingNote(Map<String, dynamic> note) {
    viewingNote.value = note;
  }

  void closeViewingNote() {
    viewingNote.value = null;
  }

  void addSeekerWrittenNote(Map<String, dynamic> note) {
    seekerWrittenNotes.insert(0, note);
  }

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

  /// 모든 탭의 데이터 새로고침
  Future<void> fetchAllData() async {
    isLoading.value = true;
    if (isEmployer) {
      // 💡 구인자의 3가지 상태(Hiring, Ongoing, Done)를 각각 호출합니다.
      await fetchEmployerHiring();
      await fetchEmployerOngoing();
      await fetchEmployerDone();
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

  // 🌟 구인자 API 1: Hiring (모집 중) 연동
  Future<void> fetchEmployerHiring() async {
    final data = await _fetchFromApi("${Env.apiBaseUrl}employer/posts/hiring");
    if (data != null) employerHiringList.assignAll(_mapHiringData(data));
  }

  // 🌟 구인자 API 2: Ongoing (진행 중) 연동
  Future<void> fetchEmployerOngoing() async {
    final data = await _fetchFromApi("${Env.apiBaseUrl}employer/posts/ongoing");
    if (data != null) employerOngoingList.assignAll(_mapOngoingData(data));
  }

  // 🌟 구인자 API 3: Done (완료) 연동
  Future<void> fetchEmployerDone() async {
    final data = await _fetchFromApi("${Env.apiBaseUrl}employer/posts/done");
    if (data != null) employerDoneList.assignAll(_mapDoneData(data));
  }

  // --- 공통 API 호출 로직 ---
  Future<List<dynamic>?> _fetchFromApi(String url) async {
    final storage = const FlutterSecureStorage();
    // 💡 안전한 토큰 조회를 위해 스네이크/카멜 케이스 모두 대응
    final String? accessToken =
        await storage.read(key: 'access_token') ??
        await storage.read(key: 'accessToken');
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

  // --- 💡 프론트 더미 매핑 로직 1: Hiring ---
  List<Map<String, dynamic>> _mapHiringData(List<dynamic> data) {
    return data.map((raw) {
      final item = raw as Map<String, dynamic>;
      final count = item['count'] ?? 1;
      final hourlyRates = item['hourlyRates'] ?? 0.0;
      final payTextValue = (hourlyRates % 1 == 0)
          ? hourlyRates.toInt()
          : hourlyRates;

      String formatDate(String? dateStr) {
        if (dateStr == null) return '';
        try {
          final d = DateTime.parse(dateStr);
          const months = [
            'Jan',
            'Feb',
            'Mar',
            'Apr',
            'May',
            'Jun',
            'Jul',
            'Aug',
            'Sep',
            'Oct',
            'Nov',
            'Dec',
          ];
          return '${months[d.month - 1]} ${d.day.toString().padLeft(2, '0')}, ${d.year}';
        } catch (e) {
          return dateStr.toString();
        }
      }

      final startDate = formatDate(item['startDate']);
      final endDate = formatDate(item['endDate']);
      final scheduleDate = (startDate.isNotEmpty && endDate.isNotEmpty)
          ? '$startDate - $endDate'
          : '';
      final List<String> safePhotos =
          (item['imageUrls'] as List?)?.map((e) => e.toString()).toList() ?? [];

      return <String, dynamic>{
        'id': item['id'],
        'title': item['title'] ?? '',
        'employer': item['companyName'] ?? '',
        'location': item['jobAddress'] ?? '',
        'description': item['description'] ?? '',
        'applicantsTotal': count,
        'applicantsCurrent': item['applicantsCurrent'] ?? 0,
        'openingsText': '$count opening${count > 1 ? 's' : ''}.',
        'payText': '\$$payTextValue / hour',
        'scheduleDate': scheduleDate,
        'dDay': item['dDay'] ?? item['dday'] ?? 'D-?',
        'tag': item['employmentTag'] ?? 'Rookie',
        'employerStatus': item['employerStatus'] ?? 'hiring',
        'photos': safePhotos,
        'hourlyWage': hourlyRates,
        'isDraft': false,
        'hasContent':
            item['description'] != null &&
            item['description'].toString().isNotEmpty,
      };
    }).toList();
  }

  // --- 💡 프론트 더미 매핑 로직 2: Ongoing ---
  List<Map<String, dynamic>> _mapOngoingData(List<dynamic> data) {
    return data.map((raw) {
      final item = raw as Map<String, dynamic>;
      return <String, dynamic>{
        'id': item['id'],
        'title': item['title'] ?? '',
        'employer': item['companyName'] ?? '',
        'applicantsTotal': item['count'] ?? 1,
        'applicantsCurrent': item['applicantsCurrent'] ?? 0,
        'dDay': item['dDay'] ?? item['dday'] ?? 'D-?',
        'tag': item['employmentTag'] ?? 'Rookie',
        'employerStatus': item['employerStatus'] ?? 'ongoing',
      };
    }).toList();
  }

  // --- 💡 프론트 더미 매핑 로직 3: Done ---
  List<Map<String, dynamic>> _mapDoneData(List<dynamic> data) {
    return data.map((raw) {
      final item = raw as Map<String, dynamic>;
      return <String, dynamic>{
        'id': item['id'],
        'title': item['title'] ?? '',
        'employer': item['companyName'] ?? '',
        'dDay': item['dDay'] ?? item['dday'] ?? 'D-?',
        'tag': item['employmentTag'] ?? 'Rookie',
        'employerStatus': item['employerStatus'] ?? 'done',
        'reviewedAll': item['reviewedAll'] ?? false,
      };
    }).toList();
  }

  // --- 구직자 API 데이터를 위한 기존 매핑 (변경 없음) ---
  List<Map<String, dynamic>> _mapApiData(
    List<dynamic> data, {
    bool isDone = false,
  }) {
    return data.map((raw) {
      final item = raw is Map<String, dynamic>
          ? raw
          : Map<String, dynamic>.from(raw as Map);
      final wage = item['hourlyWage'] ?? 0;
      final isDraft = _isDraftItem(item);
      final List<String> safePhotos =
          (item['imageUrls'] as List?)?.map((e) => e.toString()).toList() ?? [];

      return <String, dynamic>{
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
        'photos': safePhotos,
        'hourlyWage': wage,
        'isDraft': isDraft,
      };
    }).toList();
  }

  bool _isDraftItem(Map<String, dynamic> item) {
    if (item['isDraft'] == true) return true;
    final status = (item['status'] ?? item['postStatus'] ?? '')
        .toString()
        .toLowerCase();
    return status == 'draft';
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

  // --- UI 구조 통일화를 위한 Getter (안전하게 기존 UI 유지) ---
  List<Map<String, dynamic>> get currentRecruitmentHistory {
    return isEmployer ? employerHiringList : recruitmentHistory;
  }

  List<Map<String, dynamic>> get currentCompletionWorks {
    return isEmployer ? employerDoneList : completionHistoryWorks;
  }

  List<Map<String, dynamic>> get filteredVolunteerList {
    // 💡 새로운 구인자 UI 구조에선 자원봉사 필터가 없으므로 구직자일 때만 반환
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

  /// 💡 구인자 전용: 내 모든 공고 (새로운 3개의 리스트 병합)
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

  void removeSeekerApplied(Map<String, dynamic> item) {
    bool sameItem(Map<String, dynamic> e) {
      if (item['id'] != null && e['id'] != null) return e['id'] == item['id'];
      return e['title'] == item['title'] && e['employer'] == item['employer'];
    }

    recruitmentHistory.removeWhere(sameItem);
    localSeekerApplied.removeWhere(sameItem);
  }

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

  List<Map<String, dynamic>> get seekerWritableJobs => seekerDoneJobs;

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

    if (result == true) {
      await fetchAllData();
    }
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
}
