import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import '../../controllers/recent_searches_controller.dart';
import '../../pages/MainPage/job_detail_page.dart';
import '../../services/search_repository.dart';
import '../../styles/colors.dart';
import '../../widgets/auto_translate_text.dart';
import '../../widgets/job_search_bar.dart';
import '../../widgets/safe_back_app_bar.dart';
import '../../widgets/search_result_card.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  static const Duration _routeDuration = Duration(milliseconds: 420);

  static Route<void> route() {
    return PageRouteBuilder<void>(
      settings: const RouteSettings(name: 'SearchPage'),
      transitionDuration: _routeDuration,
      reverseTransitionDuration: const Duration(milliseconds: 340),
      opaque: true,
      pageBuilder: (context, animation, secondaryAnimation) =>
          const SearchPage(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          child,
    );
  }

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push<void>(route());
  }

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  bool _autoSave = true;
  bool _recentExpanded = true;
  bool _isSearching = false;
  bool _showResults = false;
  List<Map<String, dynamic>> _results = [];

  /// 페이지 외부에 살아있는 single source-of-truth.
  /// 메인으로 나갔다가 다시 들어와도 동일한 칩 목록이 보인다.
  RecentSearchesController get _recents => RecentSearchesController.to;

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
  void initState() {
    super.initState();
    // 검색창에서 포커스를 잃을 때 (예: 사용자가 검색키를 누르지 않고
    // 다른 영역을 터치) 도 마지막 입력값을 recent 에 자동 저장한다.
    _searchFocus.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _searchFocus.removeListener(_handleFocusChange);
    _searchFocus.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_searchFocus.hasFocus) return;
    _saveCurrentTerm(_searchController.text);
  }

  /// 검색창에서 enter / 검색 키를 눌렀을 때 또는 칩을 탭했을 때.
  /// 1) recent 목록에 저장 (중복 제거 + 최상단 정렬 + 20개 캡)
  /// 2) 검색 중임을 알리는 짧은 spinner 피드백 (실제 결과 페이지는 추후)
  Future<void> _onSearchSubmitted(String raw) async {
    final term = _saveCurrentTerm(raw);
    if (term == null) return;
    setState(() {
      _isSearching = true;
      _showResults = true;
    });
    final results = await SearchRepository.search(term);
    if (!mounted) return;
    setState(() {
      _results = results;
      _isSearching = false;
    });
  }

  /// 현재 입력을 recent 목록에 저장한다. 저장이 일어났다면 그 term 을, 아니면 null.
  String? _saveCurrentTerm(String raw) {
    final term = raw.trim();
    if (term.isEmpty) return null;
    if (_autoSave) _recents.add(term);
    return term;
  }

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

  Future<void> _refreshSearch() async {
    final q = _searchController.text.trim();
    if (q.isEmpty) return;
    final results = await SearchRepository.search(q);
    if (!mounted) return;
    setState(() => _results = results);
  }

  Widget _buildResults() {
    if (_isSearching) {
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
    return RefreshIndicator(
      color: AppColors.mainColor,
      onRefresh: _refreshSearch,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context);
    final Animation<double> primary =
        route?.animation ?? const AlwaysStoppedAnimation<double>(1.0);

    final searchBarSlide = CurvedAnimation(
      parent: primary,
      curve: const Interval(0.0, 0.58, curve: Curves.easeOutCubic),
    );
    final bottomSlide = CurvedAnimation(
      parent: primary,
      curve: const Interval(0.18, 1.0, curve: Curves.easeOutCubic),
    );
    final bottomFade = CurvedAnimation(
      parent: primary,
      curve: const Interval(0.28, 1.0, curve: Curves.easeOut),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const SafeBackAppBar(showDivider: false),
      body: Column(
        children: [
          ClipRect(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.4),
                  end: Offset.zero,
                ).animate(searchBarSlide),
                child: FadeTransition(
                  opacity: Tween<double>(begin: 0, end: 1).animate(
                    CurvedAnimation(
                      parent: primary,
                      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
                    ),
                  ),
                  child: Center(
                    child: JobSearchBar.field(
                      controller: _searchController,
                      focusNode: _searchFocus,
                      autofocus: true,
                      isSearching: _isSearching,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: _onSearchSubmitted,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: _showResults
                ? _buildResults()
                : FadeTransition(
              opacity: Tween<double>(begin: 0, end: 1).animate(bottomFade),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.14),
                  end: Offset.zero,
                ).animate(bottomSlide),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      Row(
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
                      Obx(() => Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _recents.recents.map((term) {
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              // 칩 본체 탭: 검색창에 키워드 채우고 검색 트리거.
                              // _onSearchSubmitted 가 중복 제거 + 최상단 재배치까지 처리한다.
                              onTap: () {
                                _searchController.text = term;
                                _searchController.selection =
                                    TextSelection.collapsed(
                                        offset: term.length);
                                _onSearchSubmitted(term);
                              },
                              child: Container(
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
                                    // 사용자가 친 키워드 ("farm", "cafe" 등)
                                    // 가 한국어 등으로 자동 번역되지 않고
                                    // 원본 그대로 표시되도록 일반 Text 사용.
                                    Text(
                                      term,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF757575),
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    // 닫기(X) 는 별도 GestureDetector 로 두고
                                    // 상위 InkWell 의 검색 트리거가 같이 호출되지
                                    // 않도록 GestureDetector 기본 동작에 맡긴다.
                                    GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () => _recents.remove(term),
                                      child: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      )),
                      const SizedBox(height: 8),
                      Center(
                        child: GestureDetector(
                          onTap: () => setState(
                              () => _recentExpanded = !_recentExpanded),
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
                          onTap: _recents.clearAll,
                          child: const AutoTranslateText(
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
                      const AutoTranslateText(
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
                              // 인기 검색어를 누르면 검색을 수행한 것과 동일하게
                              // 최근 검색어 상단에도 자동으로 쌓이도록 한다.
                              _onSearchSubmitted(title);
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
                                  child: AutoTranslateText(
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
            ),
          ),
        ],
      ),
    );
  }
}
