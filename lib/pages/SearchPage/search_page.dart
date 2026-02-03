import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../styles/colors.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _autoSave = true;
  bool _recentExpanded = true;

  final List<String> _recentSearches = [
    'Farm work',
    'Farm',
    'Cafe',
    'Cafe staff',
    'Hotel staff',
    'Hotel',
    'Warehouse',
  ];

  // 이미지: 1,2,5,6,8 주황 / 3,4,7 검정. 1,6 트렌딩(위 화살표)
  final List<Map<String, dynamic>> _popularSearches = [
    {'title': 'Barista', 'trending': true, 'orange': true},
    {'title': 'Restaurant Staff', 'trending': false, 'orange': true},
    {'title': 'Farm Work', 'trending': false, 'orange': false},
    {'title': 'Hotel Staff', 'trending': false, 'orange': false},
    {'title': 'Event Staff', 'trending': false, 'orange': true},
    {'title': 'Deckhand', 'trending': true, 'orange': true},
    {'title': 'Au Pair', 'trending': false, 'orange': false},
    {'title': 'Warehouse Assi...', 'trending': false, 'orange': true},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0.5,
          centerTitle: true,
          title: SvgPicture.asset(
              'assets/icon/logo_orange.svg', height: 36),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // 검색창 (main_page와 동일)
            const SizedBox(height: 12),
            Center(
              child: SizedBox(
                width: 290,
                height: 48,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFEEEEEE)),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 14),
                      SvgPicture.asset(
                        'assets/icon/search_icon.svg',
                        width: 18,
                        height: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'search for jobs',
                            hintStyle: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF9E9E9E),
                              fontWeight: FontWeight.w400,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: const TextStyle(fontSize: 14),
                          onChanged: (value) => setState(() {}),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: SvgPicture.asset(
                          'assets/icon/mike_icon.svg',
                          width: 32,
                          height: 32,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // 하얀 영역: Recent searches / Popular searches
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    // Recent searches 헤더: 제목 + auto save 토글
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent searches',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'auto save',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _autoSave = !_autoSave),
                              child: Container(
                                width: 44,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: _autoSave
                                      ? AppColors.mainColor
                                      : const Color(0xFFE0E0E0),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment(
                                    _autoSave ? 1.0 : -1.0, 0),
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 2),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // 최근 검색 칩: 연한 회색 배경, 연한 회색 글자, 검정 X
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _recentSearches.map((term) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F0F0),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: const Color(0xFFE0E0E0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                term,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF757575),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () {
                                  setState(() =>
                                      _recentSearches.remove(term));
                                },
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _recentExpanded = !_recentExpanded),
                        child: const Icon(
                          Icons.keyboard_arrow_down,
                          size: 24,
                          color: Color(0xFF9E9E9E),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _recentSearches.clear());
                        },
                        child: const Text(
                          'delete all',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF9E9E9E),
                            fontWeight: FontWeight.w400,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Popular searches
                    const Text(
                      'Popular searches',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...List.generate(_popularSearches.length, (index) {
                      final item = _popularSearches[index];
                      final title = item['title'] as String;
                      final trending = item['trending'] as bool;
                      final orange = item['orange'] as bool;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: InkWell(
                          onTap: () {
                            _searchController.text = title;
                            setState(() {});
                          },
                          child: Row(
                            children: [
                              SizedBox(
                                width: 24,
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: orange
                                        ? AppColors.mainColor
                                        : Colors.black,
                                  ),
                                ),
                              ),
                              if (trending)
                                const Icon(
                                  Icons.arrow_upward,
                                  size: 18,
                                  color: AppColors.mainColor,
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
