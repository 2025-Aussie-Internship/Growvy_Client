import 'package:flutter/material.dart';
import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart' hide Trans;
import '../../styles/colors.dart';
import '../../controllers/auth_controller.dart';
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
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

/// FAB을 화면 오른쪽 끝에 붙이기 (우측 여백 0, nav바와 16px 간격)
class _FabEndFloatLocation extends FloatingActionButtonLocation {
  final double right;
  final double bottomGap;

  _FabEndFloatLocation({this.right = 0, this.bottomGap = 16});

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final double x = scaffoldGeometry.scaffoldSize.width -
        scaffoldGeometry.floatingActionButtonSize.width -
        right;
    final double y = scaffoldGeometry.contentBottom -
        scaffoldGeometry.floatingActionButtonSize.height -
        bottomGap;
    return Offset(x, y);
  }
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  bool _regionPanelOpen = false;
  bool _isSearchActive = false;
  final GlobalKey<SearchOverlayState> _searchOverlayKey =
      GlobalKey<SearchOverlayState>();
  final GlobalKey<MyPageState> _myPageKey = GlobalKey<MyPageState>();
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    MainBinding().dependencies();
    _pages = [
      HomePageContent(onSearchTap: _openSearch),
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

  /// 홈 탭이거나 검색 오버레이가 떠 있을 때 로고 표시
  bool get _showLogoHeader =>
      (_selectedIndex == 0 || _isSearchActive) && !_regionPanelOpen;

  void _onItemTapped(int index) {
    if (_isSearchActive) {
      // 오버레이의 reverse 애니메이션이 끝나면 onClose가 _isSearchActive를 풀어준다.
      _searchOverlayKey.currentState?.close();
    }
    // Profile 탭을 다시 누르면 리뷰 화면을 닫고 기본 프로필로 되돌아간다.
    if (index == 4 && _selectedIndex == 4) {
      _myPageKey.currentState?.closeReviews();
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
        child: Container(
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
                IndexedStack(
                  index: _selectedIndex,
                  children: _pages,
                ),
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
        // Obx 가 관찰할 대상 — 분기 이전에 반드시 한 번은 .value 를 읽어야
        // "no observable in Obx" 에러가 발생하지 않는다.
        final isEmployer = AuthController.to.isEmployer.value;
        // Note 탭(3)에서만 표시. 구인자/구직자별 액션 분기.
        if (_selectedIndex != 3) return const SizedBox.shrink();
        if (isEmployer) {
          // 구인자: Note 탭에서도 write 버튼 하나만 노출한다.
          // 지원자 수락 흐름은 Hiring 탭의 카드 탭으로 이동했다.
          return GestureDetector(
            onTap: () => Get.to(() => const StartHiringPage()),
            child: SvgPicture.asset(
              'assets/icon/write_button.svg',
              width: 66,
              height: 66,
            ),
          );
        }
        // 구직자: 별도 floating write 버튼을 두지 않는다.
        // Done 탭에서 카드 자체를 탭하면 노트 작성 페이지로 이동하고,
        // Saved 탭에서 카드를 탭하면 작성된 노트 상세를 본다.
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

class HomePageContent extends StatefulWidget {
  const HomePageContent({super.key, this.onSearchTap});

  final VoidCallback? onSearchTap;

  @override
  State<HomePageContent> createState() => _HomePageContentState();
}

class _HomePageContentState extends State<HomePageContent> {
  String _sortFilter = 'Newest';
  bool _isCalendarOpen = false;
  bool _isNotificationOpen = false;

  // Banner State
  late PageController _bannerController;
  late Timer _bannerTimer;
  int _bannerCurrentPage = 1000;

  final List<String> _bannerImages = [
    'assets/image/banner1.png',
    'assets/image/banner2.png',
    'assets/image/banner3.png',
  ];

  @override
  void initState() {
    super.initState();
    _bannerController = PageController(initialPage: _bannerCurrentPage);
    _startBannerTimer();
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

  /// nearby / popular 카드, 배너 어디에서 눌러도 동일한 매핑으로
  /// 카드의 값을 [JobDetailPage] 로 prefill 한다.
  /// - title, company 는 그대로.
  /// - popular 의 `dDay` 와 nearby 의 `tags` 는 모두 합쳐서 상단 칩으로 노출.
  /// - `distance` 는 위치 라벨이 따로 없으니 칩 맨 앞에 붙여 표시한다.
  void _openJobDetailFromCard(Map<String, dynamic> job) {
    final List<String> tags = <String>[];
    final distance = job['distance'];
    if (distance is String && distance.isNotEmpty) {
      tags.add(distance);
    }
    final dDay = job['dDay'];
    if (dDay is String && dDay.isNotEmpty) {
      tags.add(dDay);
    }
    final rawTags = job['tags'];
    if (rawTags is List) {
      tags.addAll(rawTags.map((e) => e.toString()));
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JobDetailPage(
          title: job['title'] as String?,
          companyName: job['company'] as String?,
          tags: tags.isEmpty ? null : tags,
        ),
      ),
    );
  }

  final List<Map<String, dynamic>> nearbyJobs = const [
    {
      "title": "Restaurant Staff",
      "company": "Aussie Bite",
      "distance": "2.4 km",
      "tags": ["HOT", "D-34", "A"],
    },
    {
      "title": "Farm work",
      "company": "COMPANY",
      "distance": "0.6 km",
      "tags": ["NEW", "D-32", "B"],
    },
    {
      "title": "Café Job",
      "company": "Bunny's",
      "distance": "1.2 km",
      "tags": ["HOT", "D-15", "C"],
    },
    {
      "title": "Kitchen Hand",
      "company": "Sydney Kitchen",
      "distance": "3.1 km",
      "tags": ["Urgent", "Exp"],
    },
    {
      "title": "Delivery Driver",
      "company": "Uber Eats",
      "distance": "0.5 km",
      "tags": ["Flexible", "Bike"],
    },
    {
      "title": "Warehouse",
      "company": "Amazon",
      "distance": "5.2 km",
      "tags": ["Night", "High Pay"],
    },
  ];

  // popular 카드도 nearby 와 동일하게 title/company/distance/tags + dDay 키를 갖도록 통일.
  final List<Map<String, dynamic>> popularJobs = const [
    {
      "title": "Babysitter",
      "company": "Jake's mom",
      "dDay": "D-8",
      "distance": "2.6 km",
      "tags": ["HOT"],
    },
    {
      "title": "Hostel Staff",
      "company": "Ustaing",
      "dDay": "D-10",
      "distance": "2.6 km",
      "tags": ["NEW"],
    },
    {
      "title": "Record Shop",
      "company": "The Gomori",
      "dDay": "D-21",
      "distance": "3.4 km",
      "tags": ["A"],
    },
    {
      "title": "Packing",
      "company": "Ropine",
      "dDay": "D-9",
      "distance": "3.4 km",
      "tags": ["B"],
    },
    {
      "title": "Dog Walker",
      "company": "Pet Lovers",
      "dDay": "D-5",
      "distance": "1.1 km",
      "tags": ["Flexible"],
    },
    {
      "title": "Barista",
      "company": "Starbucks",
      "dDay": "D-2",
      "distance": "0.8 km",
      "tags": ["HOT"],
    },
  ];

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

            // Today's Tasks 영역
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 캘린더/알림 버튼
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
                              setState(() {
                                _isCalendarOpen = true;
                              });
                              showDialog(
                                context: context,
                                builder: (context) => const CalendarModal(),
                              ).then((_) {
                                setState(() {
                                  _isCalendarOpen = false;
                                });
                              });
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
                              setState(() {
                                _isNotificationOpen = true;
                              });
                              showDialog(
                                context: context,
                                builder: (context) => const NotificationModal(),
                              ).then((_) {
                                setState(() {
                                  _isNotificationOpen = false;
                                });
                              });
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
                        // DB 에서 영문으로 내려오는 더미 데이터.
                        // AutoTranslateText 가 현재 locale 에 맞춰 자동 번역해 준다.
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nearby Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'main.job_postings_nearby'.tr(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _sortFilter = 'Nearest';
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _sortFilter == 'Nearest'
                                      ? AppColors.subColor.withValues(
                                          alpha: 0.2,
                                        )
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'main.nearest'.tr(),
                                  style: TextStyle(
                                    color: _sortFilter == 'Nearest'
                                        ? AppColors.mainColor
                                        : Colors.grey[600],
                                    fontSize: 12,
                                    fontWeight: _sortFilter == 'Nearest'
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _sortFilter = 'Newest';
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _sortFilter == 'Newest'
                                      ? AppColors.subColor.withValues(
                                          alpha: 0.2,
                                        )
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'main.newest'.tr(),
                                  style: TextStyle(
                                    color: _sortFilter == 'Newest'
                                        ? AppColors.mainColor
                                        : Colors.grey[600],
                                    fontSize: 12,
                                    fontWeight: _sortFilter == 'Newest'
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Nearby Grid
                  SizedBox(
                    height: 420,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: (nearbyJobs.length / 2).ceil(),
                      itemBuilder: (context, columnIndex) {
                        List<Map<String, dynamic>> sortedJobs = List.from(
                          nearbyJobs,
                        );
                        if (_sortFilter == 'Nearest') {
                          sortedJobs.sort((a, b) {
                            double distA = double.parse(
                              a['distance'].replaceAll(' km', ''),
                            );
                            double distB = double.parse(
                              b['distance'].replaceAll(' km', ''),
                            );
                            return distA.compareTo(distB);
                          });
                        }

                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Column(
                            children: [
                              NearbyJobCard(
                                title: sortedJobs[columnIndex * 2]['title'],
                                company: sortedJobs[columnIndex * 2]['company'],
                                tags: List<String>.from(
                                  sortedJobs[columnIndex * 2]['tags'],
                                ),
                                onTap: () => _openJobDetailFromCard(
                                  sortedJobs[columnIndex * 2],
                                ),
                              ),
                              if (columnIndex * 2 + 1 < sortedJobs.length) ...[
                                const SizedBox(height: 12),
                                NearbyJobCard(
                                  title:
                                      sortedJobs[columnIndex * 2 + 1]['title'],
                                  company:
                                      sortedJobs[columnIndex * 2 +
                                          1]['company'],
                                  tags: List<String>.from(
                                    sortedJobs[columnIndex * 2 + 1]['tags'],
                                  ),
                                  onTap: () => _openJobDetailFromCard(
                                    sortedJobs[columnIndex * 2 + 1],
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
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: (popularJobs.length / 2).ceil(),
                      itemBuilder: (context, columnIndex) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Column(
                            children: [
                              PopularJobCard(
                                title: popularJobs[columnIndex * 2]['title'],
                                company:
                                    popularJobs[columnIndex * 2]['company'],
                                dDay: popularJobs[columnIndex * 2]['dDay'],
                                onTap: () => _openJobDetailFromCard(
                                  popularJobs[columnIndex * 2],
                                ),
                              ),
                              if (columnIndex * 2 + 1 < popularJobs.length) ...[
                                const SizedBox(height: 12),
                                PopularJobCard(
                                  title:
                                      popularJobs[columnIndex * 2 + 1]['title'],
                                  company:
                                      popularJobs[columnIndex * 2 +
                                          1]['company'],
                                  dDay:
                                      popularJobs[columnIndex * 2 + 1]['dDay'],
                                  onTap: () => _openJobDetailFromCard(
                                    popularJobs[columnIndex * 2 + 1],
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
                        // 배너는 popular 의 첫 항목을 대표 공고로 매핑해 둔다.
                        // (배너에 실제 공고 ID 가 연동되면 그때 매핑만 바꿔주면 됨.)
                        final bannerJob = popularJobs.isNotEmpty
                            ? popularJobs[index % popularJobs.length]
                            : <String, dynamic>{};
                        return GestureDetector(
                          onTap: () => _openJobDetailFromCard(bannerJob),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage(
                                  _bannerImages[index % _bannerImages.length],
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
                                      borderRadius: BorderRadius.circular(20),
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
