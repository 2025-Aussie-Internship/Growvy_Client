import 'package:flutter/material.dart';
import '../../styles/colors.dart';
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
                                    setState(
                                        () => _recentSearches.remove(term));
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
            ),
          ),
        ],
      ),
    );
  }
}
