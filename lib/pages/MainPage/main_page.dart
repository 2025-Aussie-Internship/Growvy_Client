import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../controllers/note_page_controller.dart';
import '../../i18n/app_translations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart' hide Trans;
import '../../styles/colors.dart';
import '../../config/env.dart';
import '../../controllers/auth_controller.dart';
import '../../services/token_storage.dart';
import '../../widgets/nearby_job_card.dart';
import '../../widgets/popular_job_card.dart';
import '../../widgets/calendar_modal.dart';
import '../../widgets/notification_modal.dart';
import '../../bindings/main_binding.dart';
import '../../widgets/job_search_bar.dart';
import '../../widgets/auto_translate_text.dart';
import '../SearchPage/search_page.dart';
import '../ChatPage/chat_page.dart';
import '../MainPage/job_detail_page.dart';
import '../MyPage/my_page.dart';
import '../MapPage/map_page.dart';
import '../NotePage/start_hiring_page.dart';
import '../NotePage/note_tab_page.dart';
import '../../widgets/main_logo_header.dart';
import '../../widgets/search_overlay.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<MainPage> createState() => _MainPageState();
}

class _FabEndFloatLocation extends FloatingActionButtonLocation {
  final double right;
  final double bottomGap;

  _FabEndFloatLocation({this.right = 0, this.bottomGap = 16});

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final double x =
        scaffoldGeometry.scaffoldSize.width -
        scaffoldGeometry.floatingActionButtonSize.width -
        right;
    final double y =
        scaffoldGeometry.contentBottom -
        scaffoldGeometry.floatingActionButtonSize.height -
        bottomGap;
    return Offset(x, y);
  }
}

class _MainPageState extends State<MainPage> {
  late int _selectedIndex = widget.initialTab.clamp(0, 4);
  bool _regionPanelOpen = false;
  bool _isSearchActive = false;
  final GlobalKey<SearchOverlayState> _searchOverlayKey =
      GlobalKey<SearchOverlayState>();
  final GlobalKey<MyPageState> _myPageKey = GlobalKey<MyPageState>();
  final GlobalKey<_HomePageContentState> _homeKey =
      GlobalKey<_HomePageContentState>();
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    MainBinding().dependencies();
    _pages = [
      HomePageContent(key: _homeKey, onSearchTap: _openSearch),
      MapPage(
        onRegionPanelChanged: _onRegionPanelChanged,
        onSearchTap: _openSearch,
      ),
      const ChatListPage(),
      const NoteTabPage(),
      MyPage(key: _myPageKey),
    ];
  }

  void _onRegionPanelChanged(bool open) {
    setState(() => _regionPanelOpen = open);
  }

  void _openSearch() {
    if (_isSearchActive) return;
    setState(() => _isSearchActive = true);
  }

  void _closeSearch() {
    if (!_isSearchActive) return;
    setState(() => _isSearchActive = false);
  }

  bool get _showLogoHeader =>
      (_selectedIndex == 0 || _isSearchActive) && !_regionPanelOpen;

  void _onItemTapped(int index) {
    if (_isSearchActive) {
      _searchOverlayKey.currentState?.close();
    }
    if (index == 4 && _selectedIndex == 4) {
      _myPageKey.currentState?.closeReviews();
    }
    // 홈 탭(0)으로 돌아올 때 jobseeker면 새로고침
    if (index == 0 && _selectedIndex != 0) {
      if (!AuthController.to.isEmployer.value) {
        _homeKey.currentState?.refreshJobs();
      }
    }
    if (_selectedIndex != index) {
      setState(() => _selectedIndex = index);
    }
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF202020).withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(4, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 65,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildNavItem(0, 'home'),
              _buildNavItem(1, 'map'),
              _buildNavItem(2, 'chat'),
              _buildNavItem(3, 'note'),
              _buildNavItem(4, 'profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String iconName) {
    final bool isSelected = _selectedIndex == index;
    final String svgPath = isSelected
        ? 'assets/icon/${iconName}_filled.svg'
        : 'assets/icon/${iconName}_not.svg';

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.center,
        child: SvgPicture.asset(svgPath, width: 31, height: 44),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: Column(
        children: [
          MainLogoHeader(visible: _showLogoHeader),
          Expanded(
            child: Stack(
              children: [
                IndexedStack(index: _selectedIndex, children: _pages),
                if (_isSearchActive)
                  Positioned.fill(
                    child: SearchOverlay(
                      key: _searchOverlayKey,
                      onClose: _closeSearch,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _regionPanelOpen ? null : _buildBottomBar(),
      floatingActionButton: Obx(() {
        final isEmployer = AuthController.to.isEmployer.value;
        if (_selectedIndex != 3) return const SizedBox.shrink();
        if (isEmployer) {
          return GestureDetector(
            onTap: () async {
              // 1. 공고 등록 페이지로 이동하고 결과를 기다립니다.
              final result = await Get.to(() => const StartHiringPage());

              // 2. 만약 result가 true(공고 등록 완료)라면?
              if (result == true) {
                // NotePageController가 메모리에 있는지 확인 후, 데이데이터를 새로고침합니다.
                if (Get.isRegistered<NotePageController>()) {
                  Get.find<NotePageController>().fetchAllData();
                }
              }
            },
            child: SvgPicture.asset(
              'assets/icon/write_button.svg',
              width: 66,
              height: 66,
            ),
          );
        }
        return const SizedBox.shrink();
      }),
      floatingActionButtonLocation: _FabEndFloatLocation(
        right: 20,
        bottomGap: 20,
      ),
      floatingActionButtonAnimator: FloatingActionButtonAnimator.noAnimation,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HomePageContent
// ─────────────────────────────────────────────────────────────────────────────

class HomePageContent extends StatefulWidget {
  const HomePageContent({super.key, this.onSearchTap});

  final VoidCallback? onSearchTap;

  @override
  State<HomePageContent> createState() => _HomePageContentState();
}

class _HomePageContentState extends State<HomePageContent> {
  bool _isCalendarOpen = false;
  bool _isNotificationOpen = false;

  // ── Banner ────────────────────────────────────────────────
  late PageController _bannerController;
  late Timer _bannerTimer;
  int _bannerCurrentPage = 1000;

  final List<String> _bannerImages = [
    'assets/image/banner1.png',
    'assets/image/banner2.png',
    'assets/image/banner3.png',
  ];

  // ── Job lists ─────────────────────────────────────────────
  bool _isLoading = false;

  /// employer 또는 API 실패 시 폴백 더미 데이터
  static const List<Map<String, dynamic>> _dummyCustomized = [
    {
      "title": "Restaurant Staff",
      "company": "Aussie Bite",
      "tags": ["Part-time", "D-34"],
    },
    {
      "title": "Farm work",
      "company": "COMPANY",
      "tags": ["Contract", "D-32"],
    },
    {
      "title": "Café Job",
      "company": "Bunny's",
      "tags": ["Temporary", "D-15"],
    },
    {
      "title": "Kitchen Hand",
      "company": "Sydney Kitchen",
      "tags": ["Full-time", "D-20"],
    },
    {
      "title": "Delivery Driver",
      "company": "Uber Eats",
      "tags": ["Part-time", "D-10"],
    },
    {
      "title": "Warehouse",
      "company": "Amazon",
      "tags": ["Casual'", "D-7"],
    },
  ];

  static const List<Map<String, dynamic>> _dummyPopular = [
    {
      "title": "Babysitter",
      "company": "Jake's mom",
      "dDay": "D-8",
      "tags": ["Casual"],
    },
    {
      "title": "Hostel Staff",
      "company": "Ustaing",
      "dDay": "D-10",
      "tags": ["Part-time"],
    },
    {
      "title": "Record Shop",
      "company": "The Gomori",
      "dDay": "D-21",
      "tags": ["Contract"],
    },
    {
      "title": "Packing",
      "company": "Ropine",
      "dDay": "D-9",
      "tags": ["Full-time"],
    },
    {
      "title": "Dog Walker",
      "company": "Pet Lovers",
      "dDay": "D-5",
      "tags": ["Flexible"],
    },
    {
      "title": "Barista",
      "company": "Starbucks",
      "dDay": "D-2",
      "tags": ["Temporary"],
    },
  ];

  List<Map<String, dynamic>> _customizedJobs = List.from(_dummyCustomized);
  List<Map<String, dynamic>> _popularJobs = List.from(_dummyPopular);

  // ── API 설정 ──────────────────────────────────────────────
  static String get _baseUrl => "${Env.apiBaseUrl}posts/jobseeker";

  bool _jobsFetched = false; // ← 상태 변수 추가

  @override
  void initState() {
    super.initState();
    _bannerController = PageController(initialPage: _bannerCurrentPage);
    _startBannerTimer();

    ever(AuthController.to.isLoading, (bool loading) {
      if (!loading && !_jobsFetched && !AuthController.to.isEmployer.value) {
        _jobsFetched = true;
        _fetchJobs();
      }
    });

    if (!AuthController.to.isLoading.value &&
        !_jobsFetched &&
        !AuthController.to.isEmployer.value) {
      _jobsFetched = true;
      _fetchJobs();
    }
  }

  @override
  void dispose() {
    _bannerTimer.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  void _startBannerTimer() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _bannerCurrentPage++;
      _bannerController.animateToPage(
        _bannerCurrentPage,
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeInOut,
      );
    });
  }

  void refreshJobs() {
    _fetchJobs();
  }

  // ── Fetch ─────────────────────────────────────────────────

  Future<void> _fetchJobs() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final results = await Future.wait([_fetchRecommended(), _fetchPopular()]);
      debugPrint('✅ recommended: ${results[0].length}개');
      debugPrint('✅ popular: ${results[1].length}개');
      if (mounted) {
        setState(() {
          if (results[0].isNotEmpty) _customizedJobs = results[0];
          if (results[1].isNotEmpty) _popularJobs = results[1];
        });
      }
    } catch (e, st) {
      debugPrint('❌ _fetchJobs 에러: $e');
      debugPrint(st.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchRecommended() async {
    final resp = await http
        .get(Uri.parse('$_baseUrl/recommended'), headers: await _authHeaders())
        .timeout(const Duration(seconds: 10));
    debugPrint('📡 recommended status: ${resp.statusCode}');
    debugPrint('📡 recommended body: ${resp.body}'); // ← 응답 원문 확인
    if (resp.statusCode != 200) return [];
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    final List<dynamic> content =
        (body['data'] as Map<String, dynamic>?)?['content'] ??
        body['content'] ??
        [];
    return content.map<Map<String, dynamic>>(_mapPost).toList();
  }

  Future<List<Map<String, dynamic>>> _fetchPopular() async {
    final resp = await http
        .get(Uri.parse('$_baseUrl/popular'), headers: await _authHeaders())
        .timeout(const Duration(seconds: 10));
    if (resp.statusCode != 200) return [];
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    final List<dynamic> content =
        (body['data'] as Map<String, dynamic>?)?['content'] ??
        body['content'] ??
        [];
    return content.map<Map<String, dynamic>>(_mapPost).toList();
  }

  /// TokenStorage에서 액세스 토큰을 읽어 Authorization 헤더에 추가
  Future<Map<String, String>> _authHeaders() async {
    final token = await TokenStorage.readAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// HiringJobPostResponse JSON → 카드에서 쓰는 Map으로 변환
  Map<String, dynamic> _mapPost(dynamic p) {
    final dDay = (p['dday'] as String?) ?? ''; // 'dDay' → 'dday'
    final empTag = (p['employmentTag'] as String?) ?? '';

    final List<String> tags = [
      if (dDay.isNotEmpty) dDay,
      if (empTag.isNotEmpty) empTag,
    ];

    return {
      'id': p['id'],
      'title': (p['title'] as String?) ?? '',
      'company': (p['companyName'] as String?) ?? '',
      'dDay': dDay,
      'tags': tags,
    };
  }

  // ── Detail navigation ─────────────────────────────────────

  void _openJobDetailFromCard(Map<String, dynamic> job) {
    final List<String> tags = <String>[];
    final dDay = job['dDay'];
    if (dDay is String && dDay.isNotEmpty) tags.add(dDay);
    final rawTags = job['tags'];
    if (rawTags is List) tags.addAll(rawTags.map((e) => e.toString()));

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JobDetailPage(
          postId: job['id'],
          title: job['title'] as String?,
          companyName: job['company'] as String?,
          tags: tags.isEmpty ? null : tags,
        ),
      ),
    ).then((_) {
      // 지원 후 돌아왔을 때 메인 + Note Applied 동시 새로고침
      _fetchJobs();
      if (Get.isRegistered<NotePageController>()) {
        Get.find<NotePageController>().fetchSeekerApplied();
      }
    });
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        color: AppColors.subColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),

            Center(
              child: JobSearchBar.tappable(
                onTap: widget.onSearchTap ?? () => SearchPage.open(context),
              ),
            ),

            const SizedBox(height: 24),

            // Today's Tasks
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 60,
                    height: 124,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() => _isCalendarOpen = true);
                              showDialog(
                                context: context,
                                builder: (_) => const CalendarModal(),
                              ).then(
                                (_) => setState(() => _isCalendarOpen = false),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: _isCalendarOpen
                                    ? AppColors.mainColor
                                    : Colors.white,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  topRight: Radius.circular(8),
                                ),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SvgPicture.asset(
                                      'assets/icon/calendar_icon.svg',
                                      width: 24,
                                      height: 24,
                                      colorFilter: ColorFilter.mode(
                                        _isCalendarOpen
                                            ? Colors.white
                                            : Colors.black,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'main.calendar'.tr(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: _isCalendarOpen
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const Divider(
                          height: 1,
                          thickness: 1,
                          indent: 8,
                          endIndent: 8,
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() => _isNotificationOpen = true);
                              showDialog(
                                context: context,
                                builder: (_) => const NotificationModal(),
                              ).then(
                                (_) =>
                                    setState(() => _isNotificationOpen = false),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: _isNotificationOpen
                                    ? AppColors.mainColor
                                    : Colors.white,
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(8),
                                  bottomRight: Radius.circular(8),
                                ),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SvgPicture.asset(
                                      'assets/icon/bell_icon.svg',
                                      width: 24,
                                      height: 24,
                                      colorFilter: ColorFilter.mode(
                                        _isNotificationOpen
                                            ? Colors.white
                                            : Colors.black,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'main.notification'.tr(),
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w500,
                                        color: _isNotificationOpen
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                      overflow: TextOverflow.fade,
                                      maxLines: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 275,
                    height: 124,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Center(
                          child: Text(
                            'main.todays_task'.tr(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const Divider(height: 20, thickness: 1),
                        const AutoTranslateText(
                          'Part-time café job in Sydney',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "12:00 PM ~ 2:00 PM",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 하단 흰색 배경 영역
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 30, bottom: 100),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: _isLoading
                  // ── 로딩 중 ──────────────────────────────────────
                  ? const SizedBox(
                      height: 300,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  // ── 데이터 표시 ───────────────────────────────────
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Customized Header
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            'main.customized_job_postings'.tr(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Customized Grid
                        SizedBox(
                          height: 420,
                          child: _customizedJobs.isEmpty
                              ? const Center(child: Text('No jobs found'))
                              : ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  itemCount: (_customizedJobs.length / 2)
                                      .ceil(),
                                  itemBuilder: (context, colIdx) {
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 12),
                                      child: Column(
                                        children: [
                                          NearbyJobCard(
                                            title:
                                                _customizedJobs[colIdx *
                                                    2]['title'],
                                            company:
                                                _customizedJobs[colIdx *
                                                    2]['company'],
                                            tags: List<String>.from(
                                              _customizedJobs[colIdx *
                                                  2]['tags'],
                                            ),
                                            onTap: () => _openJobDetailFromCard(
                                              _customizedJobs[colIdx * 2],
                                            ),
                                          ),
                                          if (colIdx * 2 + 1 <
                                              _customizedJobs.length) ...[
                                            const SizedBox(height: 12),
                                            NearbyJobCard(
                                              title:
                                                  _customizedJobs[colIdx * 2 +
                                                      1]['title'],
                                              company:
                                                  _customizedJobs[colIdx * 2 +
                                                      1]['company'],
                                              tags: List<String>.from(
                                                _customizedJobs[colIdx * 2 +
                                                    1]['tags'],
                                              ),
                                              onTap: () =>
                                                  _openJobDetailFromCard(
                                                    _customizedJobs[colIdx * 2 +
                                                        1],
                                                  ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),

                        const SizedBox(height: 30),

                        // Popular Header
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            'main.popular_jobs'.tr(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Popular Grid
                        SizedBox(
                          height: 254,
                          child: _popularJobs.isEmpty
                              ? const Center(child: Text('No jobs found'))
                              : ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  itemCount: (_popularJobs.length / 2).ceil(),
                                  itemBuilder: (context, colIdx) {
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 12),
                                      child: Column(
                                        children: [
                                          PopularJobCard(
                                            title:
                                                _popularJobs[colIdx *
                                                    2]['title'],
                                            company:
                                                _popularJobs[colIdx *
                                                    2]['company'],
                                            dDay:
                                                _popularJobs[colIdx *
                                                    2]['dDay'],
                                            tags: List<String>.from(
                                              _popularJobs[colIdx * 2]['tags'],
                                            ),

                                            onTap: () => _openJobDetailFromCard(
                                              _popularJobs[colIdx * 2],
                                            ),
                                          ),
                                          if (colIdx * 2 + 1 <
                                              _popularJobs.length) ...[
                                            const SizedBox(height: 12),
                                            PopularJobCard(
                                              title:
                                                  _popularJobs[colIdx * 2 +
                                                      1]['title'],
                                              company:
                                                  _popularJobs[colIdx * 2 +
                                                      1]['company'],
                                              dDay:
                                                  _popularJobs[colIdx * 2 +
                                                      1]['dDay'],
                                              tags:
                                                  _popularJobs[colIdx * 2 +
                                                      1]['tags'],
                                              onTap: () =>
                                                  _openJobDetailFromCard(
                                                    _popularJobs[colIdx * 2 +
                                                        1],
                                                  ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),

                        const SizedBox(height: 30),

                        // Banner
                        SizedBox(
                          height: 212,
                          child: PageView.builder(
                            controller: _bannerController,
                            itemBuilder: (context, index) {
                              final bannerJob = _popularJobs.isNotEmpty
                                  ? _popularJobs[index % _popularJobs.length]
                                  : <String, dynamic>{};
                              return GestureDetector(
                                onTap: () => _openJobDetailFromCard(bannerJob),
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      image: AssetImage(
                                        _bannerImages[index %
                                            _bannerImages.length],
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  child: Stack(
                                    children: [
                                      Positioned(
                                        right: 20,
                                        bottom: 20,
                                        child: Container(
                                          width: 111,
                                          height: 33,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            'main.see_more'.tr(),
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: Color(0xFF3B3B3B),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
