import 'package:flutter/material.dart';

import '../pages/MainPage/job_detail_page.dart';
import '../styles/colors.dart';
import 'job_search_bar.dart';
import 'region_modal.dart';
import 'search_result_card.dart';

/// 메인/맵의 검색 바를 누르면 그 위에 띄우는 오버레이 화면.
/// 상단 로고 헤더와 하단 네비게이션은 그대로 두고, 본문 영역만 교체된다.
class SearchOverlay extends StatefulWidget {
  const SearchOverlay({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  State<SearchOverlay> createState() => SearchOverlayState();
}

class SearchOverlayState extends State<SearchOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final TextEditingController _searchController;
  bool _autoSave = true;
  bool _recentExpanded = false;
  bool _closing = false;

  /// 검색을 제출했을 때 결과 화면으로 전환되는 상태값.
  bool _showResults = false;
  String _selectedLocation = 'Sydney';

  /// 접힌 상태에서 보여줄 태그 갯수 (두 줄 이내 기준)
  static const int _collapsedTagCount = 5;

  /// 임시 검색 결과 데이터 — 추후 API 연동.
  final List<Map<String, dynamic>> _results = const [
    {
      'title': 'Restaurant staff',
      'company': 'Aussie Bite',
      'tags': ['NEW', 'D-32', 'Veteran'],
    },
    {
      'title': 'Farm work',
      'company': "Will's fram",
      'tags': ['NEW', 'D-22', 'Veteran'],
    },
    {
      'title': 'Café job',
      'company': 'This is for you Jane',
      'tags': ['NEW', 'D-11', 'Rookie'],
    },
    {
      'title': 'Record Shop Employee',
      'company': 'People needs Rabbit!',
      'tags': ['HOT', 'D-8', 'Rookie'],
    },
    {
      'title': 'Restaurant Staff',
      'company': 'Hopkins Night',
      'tags': ['NEW', 'D-16', 'Veteran'],
    },
    {
      'title': 'Babysitter',
      'company': 'Dustin Byers',
      'tags': ['NEW', 'D-13', 'Rookie'],
    },
  ];

  final List<String> _recentSearches = [
    'Farm work',
    'Farm',
    'Cafe',
    'Cafe staff',
    'Hotel staff',
    'Hotel',
    'Warehouse',
  ];

  final List<Map<String, dynamic>> _popularSearches = const [
    {'title': 'Barista', 'trending': true},
    {'title': 'Restaurant Staff', 'trending': false},
    {'title': 'Farm Work', 'trending': false},
    {'title': 'Hotel Staff', 'trending': false},
    {'title': 'Event Staff', 'trending': false},
    {'title': 'Deckhand', 'trending': true},
    {'title': 'Au Pair', 'trending': false},
    {'title': 'Warehouse Assistant', 'trending': false},
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
      reverseDuration: const Duration(milliseconds: 300),
    )..forward();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// 외부(메인 페이지의 탭 전환 등)에서 호출하여 부드럽게 닫기.
  Future<void> close() async {
    if (_closing) return;
    _closing = true;
    if (!_controller.isAnimating || _controller.status == AnimationStatus.forward) {
      await _controller.reverse();
    }
    if (mounted) widget.onClose();
  }

  void _submitSearch(String query) {
    final q = query.trim();
    if (q.isEmpty) return;
    setState(() {
      // 최근 검색어 맨 앞에 추가 (중복 제거)
      _recentSearches.remove(q);
      _recentSearches.insert(0, q);
      _showResults = true;
    });
  }

  Future<void> _openRegionModal() async {
    final selected = await RegionModal.show(
      context,
      initialRegions: {_selectedLocation},
    );
    if (selected != null && mounted) {
      setState(() => _selectedLocation = selected);
    }
  }

  void _goToJobDetail() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const JobDetailPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topSlide = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
      reverseCurve: Curves.easeInCubic,
    );
    final bottomSlide = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.15, 1.0, curve: Curves.easeOutCubic),
      reverseCurve: Curves.easeInCubic,
    );
    final fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) close();
      },
      child: FadeTransition(
        opacity: fade,
        child: Material(
          color: AppColors.subColor,
          child: Column(
            children: [
              ClipRect(
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, -1),
                    end: Offset.zero,
                  ).animate(topSlide),
                  child: Container(
                    width: double.infinity,
                    color: AppColors.subColor,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: JobSearchBar.field(
                        controller: _searchController,
                        autofocus: true,
                        onChanged: (_) => setState(() {}),
                        onSubmitted: _submitSearch,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ClipRect(
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.18),
                      end: Offset.zero,
                    ).animate(bottomSlide),
                    child: FadeTransition(
                      opacity: fade,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: Container(
                          color: Colors.white,
                          width: double.infinity,
                          child: _showResults
                              ? _buildResults()
                              : _buildContent(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final hasMore = _recentSearches.length > _collapsedTagCount;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildRecentHeader(),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildRecentTags(),
          ),
          if (hasMore) ...[
            const SizedBox(height: 12),
            Center(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _recentExpanded = !_recentExpanded),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 4,
                  ),
                  child: Icon(
                    _recentExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 22,
                    color: const Color(0xFF9E9E9E),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Center(
            child: GestureDetector(
              onTap: () => setState(() => _recentSearches.clear()),
              child: const Text(
                'delete all',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFFBDBDBD),
                  fontWeight: FontWeight.w400,
                  decoration: TextDecoration.underline,
                  decorationColor: Color(0xFFBDBDBD),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Popular searches',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: _buildPopularGrid(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildRecentHeader() {
    return Row(
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
                color: Color(0xFF747474),
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => setState(() => _autoSave = !_autoSave),
              child: Container(
                width: 32,
                height: 16,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: _autoSave
                      ? AppColors.mainColor
                      : const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Align(
                  alignment: Alignment(_autoSave ? 1.0 : -1.0, 0),
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentTags() {
    final visibleTags = _recentExpanded
        ? _recentSearches
        : _recentSearches.take(_collapsedTagCount).toList();

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: visibleTags.map(_buildTag).toList(),
    );
  }

  Widget _buildResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Result of ${_results.length}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFFBDBDBD),
                  fontWeight: FontWeight.w400,
                ),
              ),
              _buildLocationButton(),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemCount: _results.length,
            itemBuilder: (context, index) {
              final item = _results[index];
              return SearchResultCard(
                title: item['title'] as String,
                company: item['company'] as String,
                tags: List<String>.from(item['tags'] as List),
                onTap: _goToJobDetail,
                onApply: _goToJobDetail,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLocationButton() {
    return GestureDetector(
      onTap: _openRegionModal,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 95,
        height: 27,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFBDBDBD),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Location',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String term) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFD9D9D9).withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            term,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFFA3A3A3),
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => setState(() => _recentSearches.remove(term)),
            child: const Icon(
              Icons.close,
              size: 16,
              color: Color(0xFFA3A3A3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularGrid() {
    final half = (_popularSearches.length / 2).ceil();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildPopularColumn(0, half)),
        const SizedBox(width: 16),
        Expanded(child: _buildPopularColumn(half, _popularSearches.length)),
      ],
    );
  }

  Widget _buildPopularColumn(int start, int end) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(end - start, (i) {
        final index = start + i;
        final item = _popularSearches[index];
        final title = item['title'] as String;
        final trending = item['trending'] as bool;
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: InkWell(
            onTap: () {
              _searchController.text = title;
              _submitSearch(title);
            },
            child: Row(
              children: [
                SizedBox(
                  width: 18,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.subColor1,
                    ),
                  ),
                ),
                if (trending)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.arrow_upward,
                      size: 16,
                      color: AppColors.pointColor,
                    ),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
