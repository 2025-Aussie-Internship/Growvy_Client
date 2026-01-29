import 'package:flutter/material.dart';
import '../../services/user_service.dart';
import 'employer_note_write_page.dart';

class EmployerNotePage extends StatefulWidget {
  const EmployerNotePage({super.key});

  @override
  State<EmployerNotePage> createState() => _EmployerNotePageState();
}

class _EmployerNotePageState extends State<EmployerNotePage> {
  int _selectedTab = 0; 
  int _volunteerFilter = 1; // 0: Draft, 1: most recent
  bool _isEmployer = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkUserType();
  }

  Future<void> _checkUserType() async {
    final isEmployer = await UserService.isEmployer();
    if (!isEmployer) {
      // Employer가 아니면 이전 페이지로 돌아가기
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Employer 회원만 접근할 수 있습니다.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      setState(() {
        _isEmployer = true;
        _isLoading = false;
      });
    }
  }

  final List<Map<String, dynamic>> _recruitmentHistory = [
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
      'photos': [
        'https://images.unsplash.com/photo-1542208998-f6dbbb27a72f?w=100',
        'https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?w=100',
      ],
    },
  ];

  final List<Map<String, dynamic>> _completionHistoryWorks = [
    {
      'title': 'Weekend Market Assistant',
      'employer': 'Freshyyy',
      'dDay': 'Completed',
      'tag': 'Veteran',
      'hasContent': true,
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
      'photos': [
        'https://images.unsplash.com/photo-1542208998-f6dbbb27a72f?w=100',
      ],
    },
  ];

  final List<Map<String, dynamic>> _completionHistoryVolunteer = [
    {
      'title': 'Youth Program Support Assistant',
      'employer': 'You and Us',
      'dDay': 'Completed',
      'tag': 'Rookie',
      'hasContent': true,
      'isDraft': false,
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
      'photos': [
        'https://images.unsplash.com/photo-1542208998-f6dbbb27a72f?w=100',
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_isEmployer) {
      return const Scaffold(
        body: Center(
          child: Text('접근 권한이 없습니다.'),
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 16),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTab = 0;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10.5),
                      decoration: BoxDecoration(
                        color: _selectedTab == 0
                            ? Colors.white
                            : const Color(0xFFF5F5F5),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        boxShadow: _selectedTab == 0
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  offset: const Offset(0, -3),
                                  blurRadius: 4,
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        'Recruitment history',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _selectedTab == 0
                              ? const Color(0xFF931515)
                              : const Color(0xFF747474),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTab = 1;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedTab == 1
                            ? Colors.white
                            : const Color(0xFFF5F5F5),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        boxShadow: _selectedTab == 1
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  offset: const Offset(0, -3),
                                  blurRadius: 4,
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        'Completion history',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _selectedTab == 1
                              ? const Color(0xFF931515)
                              : const Color(0xFF747474),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 헤더와 리스트
          Expanded(
            child: _selectedTab == 0
                ? _buildRecruitmentHistory()
                : _buildCompletionHistory(),
          ),
        ],
      ),
    );
  }


  Widget _buildRecruitmentHistory() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My History',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              Text(
                'most recent',
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFF931515),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _recruitmentHistory.length,
            itemBuilder: (context, index) {
              return _buildHistoryCard(_recruitmentHistory[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionHistory() {
    final filteredVolunteerList = _volunteerFilter == 0
        ? _completionHistoryVolunteer.where((item) => item['isDraft'] == true).toList()
        : _completionHistoryVolunteer.where((item) => item['isDraft'] == false).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Works 섹션
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Works',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                Text(
                  'most recent',
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF931515),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _completionHistoryWorks.length,
            itemBuilder: (context, index) {
              return _buildHistoryCard(_completionHistoryWorks[index]);
            },
          ),
          
          const SizedBox(height: 24),
          
          // Volunteer 섹션
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Volunteer',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _volunteerFilter = 0;
                        });
                      },
                      child: Text(
                        'Draft',
                        style: TextStyle(
                          fontSize: 14,
                          color: _volunteerFilter == 0
                              ? const Color(0xFF931515)
                              : const Color(0xFF931515),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Container(
                        width: 1,
                        height: 14,
                        color: const Color(0xFF931515),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _volunteerFilter = 1;
                        });
                      },
                      child: Text(
                        'most recent',
                        style: TextStyle(
                          fontSize: 14,
                          color: _volunteerFilter == 1
                              ? const Color(0xFF931515)
                              : const Color(0xFF931515),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filteredVolunteerList.length,
            itemBuilder: (context, index) {
              return _buildHistoryCard(filteredVolunteerList[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> item) {
    final bool isRecruitmentTab = _selectedTab == 0;
    final bool shouldNavigateToWrite = isRecruitmentTab && !item['hasContent'];

    return GestureDetector(
      onTap: shouldNavigateToWrite
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EmployerNoteWritePage(),
                ),
              );
            }
          : null,
      child: Container(
        width: 358,
        height: 111,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF5F5F5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item['employer'],
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFF747474),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildTag(item['dDay']),
                      const SizedBox(width: 10),
                      _buildTag(item['tag']),
                    ],
                  ),
                ],
              ),
            ),
            // 사진 썸네일
            if (item['photos'] != null && (item['photos'] as List).isNotEmpty)
              _buildPhotoThumbnails(item['photos'] as List<String>),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE9D8),
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF931515),
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 14/12,
        ),
      ),
    );
  }

  Widget _buildPhotoThumbnails(List<String> photos) {
    final displayPhotos = photos.take(3).toList();
    final double photoSize = 30;
    final double overlap = 8;

    return SizedBox(
      width: photoSize + (displayPhotos.length - 1) * (photoSize - overlap),
      height: photoSize,
      child: Stack(
        children: List.generate(displayPhotos.length, (index) {
          return Positioned(
            left: index * (photoSize - overlap),
            child: Container(
              width: photoSize,
              height: photoSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  displayPhotos[index],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, size: 20),
                    );
                  },
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
