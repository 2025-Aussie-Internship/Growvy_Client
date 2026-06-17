import '../i18n/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

import '../controllers/recent_searches_controller.dart';
import '../pages/MainPage/job_detail_page.dart';
import '../services/search_repository.dart';
import '../styles/colors.dart';
import 'auto_translate_text.dart';
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
  late final FocusNode _searchFocus;
  bool _autoSave = true;
  bool _recentExpanded = false;
  bool _closing = false;

  /// 검색을 제출했을 때 결과 화면으로 전환되는 상태값.
  bool _showResults = false;
  bool _isLoading = false;
  List<Map<String, dynamic>> _results = [];

  /// 접힌 상태에서 보여줄 태그 갯수 (두 줄 이내 기준)
  static const int _collapsedTagCount = 5;

  /// SearchPage 와 같은 인스턴스를 공유해, 메인으로 나갔다가 다시 검색을 열어도
  /// 사용자가 입력했던 키워드 ("ㅇㅇ" 등) 가 그대로 칩으로 남아 있다.
  RecentSearchesController get _recents => RecentSearchesController.to;

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
    _searchFocus = FocusNode();
    // 사용자가 검색 키를 누르지 않고 다른 영역을 터치해 검색창 포커스가
    // 빠질 때도 마지막 입력값을 recent 에 자동 저장해 둔다.
    _searchFocus.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    _searchFocus.removeListener(_handleFocusChange);
    _searchFocus.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_searchFocus.hasFocus) return;
    _saveTerm(_searchController.text);
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

  Future<void> _submitSearch(String query) async {
    final q = _saveTerm(query);
    if (q == null) return;
    setState(() {
      _showResults = true;
      _isLoading = true;
    });
    final results = await SearchRepository.search(q);
    if (!mounted) return;
    setState(() {
      _results = results;
      _isLoading = false;
    });
  }

  /// 입력값을 recent 목록 맨 위에 추가한다. 컨트롤러가 중복 제거 + 최대
  /// 길이 cap + 디스크 저장까지 모두 처리. autoSave OFF 면 저장은 생략.
  String? _saveTerm(String raw) {
    final q = raw.trim();
    if (q.isEmpty) return null;
    if (_autoSave) _recents.add(q);
    return q;
  }

  Future<void> _openRegionModal() async {
    await RegionModal.show(context);
  }

  /// 결과 카드 탭/Apply 버튼 → 해당 job 의 정보를 그대로 [JobDetailPage] 에 전달.
  /// (이전에는 항상 default 더미 'Sadie\'s HotPot' 만 나오던 문제 수정)
  void _openResultDetail(Map<String, dynamic> item) {
    final tagsRaw = item['tags'];
    final tags = tagsRaw is List
        ? tagsRaw.map((e) => e.toString()).toList()
        : <String>[];
    final rawPhotos = item['photoUrls'];
    final photoUrls = rawPhotos is List
        ? rawPhotos.map((e) => e.toString()).toList()
        : null;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => JobDetailPage(
          postId: item['id'],
          title: item['title'] as String?,
          companyName: item['company'] as String?,
          tags: tags,
          description: item['description'] as String?,
          payText: item['payText'] as String?,
          photoUrls: photoUrls,
        ),
      ),
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
                        focusNode: _searchFocus,
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
    return SingleChildScrollView(
      child: Obx(() {
        final hasMore = _recents.recents.length > _collapsedTagCount;
        return Column(
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
              onTap: _recents.clearAll,
              child: const AutoTranslateText(
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
            child: AutoTranslateText(
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
      );
      }),
    );
  }

  Widget _buildRecentHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const AutoTranslateText(
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
            const AutoTranslateText(
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
    final all = _recents.recents;
    final visibleTags = _recentExpanded
        ? all.toList()
        : all.take(_collapsedTagCount).toList();

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: visibleTags.map(_buildTag).toList(),
    );
  }

  Future<void> _refreshSearch() async {
    final q = _searchController.text.trim();
    if (q.isEmpty) return;
    final results = await SearchRepository.search(q);
    if (!mounted) return;
    setState(() => _results = results);
  }

  Widget _buildResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_results.isEmpty) {
      return RefreshIndicator(
        color: AppColors.mainColor,
        onRefresh: _refreshSearch,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.35,
              child: const Center(
                child: AutoTranslateText(
                  'No results found',
                  style: TextStyle(fontSize: 14, color: Color(0xFFBDBDBD)),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${'search.result_of'.tr()} ${_results.length}',
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
          child: RefreshIndicator(
            color: AppColors.mainColor,
            onRefresh: _refreshSearch,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: _results.length,
            itemBuilder: (context, index) {
              final item = _results[index];
              return SearchResultCard(
                title: item['title'] as String,
                company: item['company'] as String,
                tags: List<String>.from(item['tags'] as List),
                onTap: () => _openResultDetail(item),
                onApply: () => _openResultDetail(item),
              );
            },
            ),
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
        child: Text(
          'search.location'.tr(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String term) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        // 칩 본체를 탭하면 검색창에 그 키워드를 채우고 검색을 트리거한다.
        // (X 아이콘은 별도 GestureDetector + HitTestBehavior.opaque 로
        // 이 InkWell 이 같이 호출되지 않도록 한다.)
        onTap: () {
          _searchController.text = term;
          _searchController.selection =
              TextSelection.collapsed(offset: term.length);
          _submitSearch(term);
        },
        child: Container(
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
              // 사용자가 친 키워드는 자동 번역하지 않고 원문 그대로 표시.
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
                behavior: HitTestBehavior.opaque,
                onTap: () => _recents.remove(term),
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: Color(0xFFA3A3A3),
                ),
              ),
            ],
          ),
        ),
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
                  child: AutoTranslateText(
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
                      color: AppColors.subColor1,
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
