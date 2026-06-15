import 'package:flutter/material.dart';
import '../../styles/colors.dart';
import '../../widgets/auto_translate_text.dart';
import '../../widgets/job_search_bar.dart';
import '../../widgets/safe_back_app_bar.dart';

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

  /// 검색창에서 enter / 검색 키를 눌렀을 때.
  /// - autoSave 가 켜져 있고 빈 문자열이 아니면 _recentSearches 상단에 삽입.
  /// - 같은 단어가 이미 있으면 그것을 위로 끌어올리고 중복은 피한다.
  /// - 최대 20개까지만 유지해서 무한히 늘어나는 것을 방지.
  void _onSearchSubmitted(String raw) {
    final term = raw.trim();
    if (term.isEmpty) return;
    if (_autoSave) {
      setState(() {
        _recentSearches.removeWhere(
          (existing) => existing.toLowerCase() == term.toLowerCase(),
        );
        _recentSearches.insert(0, term);
        if (_recentSearches.length > 20) {
          _recentSearches.removeRange(20, _recentSearches.length);
        }
      });
    }
    // TODO: 실제 검색 결과 페이지로 이동. 현재는 데모 데이터만 보여주므로
    // 검색어 저장만 처리하고 검색창에 입력값은 유지한다.
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
                      autofocus: true,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: _onSearchSubmitted,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: FadeTransition(
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
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _recentSearches.map((term) {
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
                                    AutoTranslateText(
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
                              ),
                            ),
                          );
                        }).toList(),
                      ),
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
                          onTap: () {
                            setState(() => _recentSearches.clear());
                          },
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
