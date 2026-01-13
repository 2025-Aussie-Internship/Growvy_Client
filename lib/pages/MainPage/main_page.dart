import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../styles/colors.dart';
import '../../widgets/custom_bottom_nav_bar.dart';
import '../../widgets/nearby_job_card.dart';
import '../../widgets/popular_job_card.dart';
import '../../widgets/calendar_modal.dart';
import '../../widgets/notification_modal.dart';
import '../SearchPage/search_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    HomePageContent(),
    const Center(child: Text('Map Page')),
    const Center(child: Text('Chat Page')),
    const Center(child: Text('Note Page')),
    const Center(child: Text('Profile Page')),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      extendBody: true,
      // 로고 AppBar 추가 - 모든 페이지에서 고정
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: SvgPicture.asset(
            'assets/icon/logo_orange.svg',
            height: 36,
          ),
        ),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

class HomePageContent extends StatefulWidget {
  const HomePageContent({super.key});

  @override
  State<HomePageContent> createState() => _HomePageContentState();
}

class _HomePageContentState extends State<HomePageContent> {
  String _sortFilter = 'Newest'; // 'Nearest' or 'Newest'
  bool _isCalendarOpen = false;
  bool _isNotificationOpen = false;
  
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

  final List<Map<String, dynamic>> popularJobs = const [
    {
      "title": "Babysitter",
      "company": "Jake's mom",
      "dDay": "D-8",
      "distance": "2.6 km",
    },
    {
      "title": "Hostel Staff",
      "company": "Ustaing",
      "dDay": "D-10",
      "distance": "2.6 km",
    },
    {
      "title": "Record Shop",
      "company": "The Gomori",
      "dDay": "D-21",
      "distance": "3.4 km",
    },
    {
      "title": "Packing",
      "company": "Ropine",
      "dDay": "D-9",
      "distance": "3.4 km",
    },
    {
      "title": "Dog Walker",
      "company": "Pet Lovers",
      "dDay": "D-5",
      "distance": "1.1 km",
    },
    {
      "title": "Barista",
      "company": "Starbucks",
      "dDay": "D-2",
      "distance": "0.8 km",
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

            // 검색창: 너비 290 고정 & 중앙 정렬
            Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SearchPage()),
                  );
                },
                child: Container(
                  width: 290,
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        'assets/icon/search_icon.svg',
                        width: 24,
                        height: 24,
                        colorFilter: const ColorFilter.mode(
                            Colors.grey, BlendMode.srcIn),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'search for jobs',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      SvgPicture.asset(
                        'assets/icon/mike_icon.svg',
                        width: 32,
                        height: 32,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
            
            // Today's Tasks 영역
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 왼쪽: 캘린더/알림 버튼 그룹
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
                        // Calendar Button
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
                                color: _isCalendarOpen ? AppColors.mainColor : Colors.white,
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
                                        _isCalendarOpen ? Colors.white : Colors.black,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Calendar",
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: _isCalendarOpen ? Colors.white : Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        // Divider
                        const Divider(height: 1, thickness: 1, indent: 8, endIndent: 8),

                        // Notification Button
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
                                color: _isNotificationOpen ? AppColors.mainColor : Colors.white,
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
                                        _isNotificationOpen ? Colors.white : Colors.black,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Notification",
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w500,
                                        color: _isNotificationOpen ? Colors.white : Colors.black,
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
                      children: const [
                        Center(
                          child: Text(
                            "Today's Tasks",
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                        ),
                        Divider(height: 20, thickness: 1),
                        Text(
                          "Part-time café job in Sydney",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontWeight: FontWeight.w500, fontSize: 15),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "12:00 PM ~ 2:00 PM",
                          style:
                              TextStyle(color: Colors.grey, fontSize: 12),
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
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
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
                        const Text(
                          "Job postings nearby",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600),
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
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _sortFilter == 'Nearest'
                                      ? AppColors.subColor.withValues(alpha: 0.2)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  "Nearest",
                                  style: TextStyle(
                                      color: _sortFilter == 'Nearest'
                                          ? AppColors.mainColor
                                          : Colors.grey[600],
                                      fontSize: 12,
                                      fontWeight: _sortFilter == 'Nearest'
                                          ? FontWeight.w600
                                          : FontWeight.normal),
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
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _sortFilter == 'Newest'
                                      ? AppColors.subColor.withValues(alpha: 0.2)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  "Newest",
                                  style: TextStyle(
                                      color: _sortFilter == 'Newest'
                                          ? AppColors.mainColor
                                          : Colors.grey[600],
                                      fontSize: 12,
                                      fontWeight: _sortFilter == 'Newest'
                                          ? FontWeight.w600
                                          : FontWeight.normal),
                                ),
                              ),
                            ),
                          ],
                        )
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
                        // 필터에 따라 정렬
                        List<Map<String, dynamic>> sortedJobs = List.from(nearbyJobs);
                        if (_sortFilter == 'Nearest') {
                          sortedJobs.sort((a, b) {
                            double distA = double.parse(a['distance'].replaceAll(' km', ''));
                            double distB = double.parse(b['distance'].replaceAll(' km', ''));
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
                                distance: sortedJobs[columnIndex * 2]['distance'],
                                tags: List<String>.from(sortedJobs[columnIndex * 2]['tags']),
                                onTap: () {},
                              ),
                              if (columnIndex * 2 + 1 < sortedJobs.length) ...[
                                const SizedBox(height: 12),
                                NearbyJobCard(
                                  title: sortedJobs[columnIndex * 2 + 1]['title'],
                                  company: sortedJobs[columnIndex * 2 + 1]['company'],
                                  distance: sortedJobs[columnIndex * 2 + 1]['distance'],
                                  tags: List<String>.from(sortedJobs[columnIndex * 2 + 1]['tags']),
                                  onTap: () {},
                                ),
                              ]
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Popular Header
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "Popular Jobs",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                                company: popularJobs[columnIndex * 2]['company'],
                                dDay: popularJobs[columnIndex * 2]['dDay'],
                                distance: popularJobs[columnIndex * 2]['distance'],
                                onTap: () {},
                              ),
                              if (columnIndex * 2 + 1 < popularJobs.length) ...[
                                const SizedBox(height: 12),
                                PopularJobCard(
                                  title: popularJobs[columnIndex * 2 + 1]['title'],
                                  company: popularJobs[columnIndex * 2 + 1]['company'],
                                  dDay: popularJobs[columnIndex * 2 + 1]['dDay'],
                                  distance: popularJobs[columnIndex * 2 + 1]['distance'],
                                  onTap: () {},
                                ),
                              ]
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Banner
                  Container(
                    width: double.infinity,
                    height: 150,
                    color: Colors.lightBlueAccent,
                    alignment: Alignment.center,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 20,
                          top: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                "Holiday Season",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FontStyle.italic),
                              ),
                              Text(
                                "Jobs",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FontStyle.italic),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          right: 20,
                          bottom: 20,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white),
                            ),
                            child: const Text(
                              "See More",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        )
                      ],
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