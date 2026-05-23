import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../styles/colors.dart';
import 'job_search_bar.dart';

/// 검색 결과 화면의 'Location' 버튼에서 호출되는 우측 슬라이드 모달.
/// 상단: Region 타이틀 + X 버튼
/// search bar (search for region) + 주(state) 칩 행
/// 지역(region) 체크리스트 + 하단 floating 'Sydney' 버튼.
class RegionModal extends StatefulWidget {
  const RegionModal({
    super.key,
    this.initialState = 'NSW',
    this.initialRegions = const {'Sydney'},
  });

  final String initialState;
  final Set<String> initialRegions;

  /// 우측에서 슬라이드되어 들어오는 다이얼로그를 띄운다.
  /// 반환값: 선택된 region 이름 (취소 시 null).
  static Future<String?> show(
    BuildContext context, {
    String initialState = 'NSW',
    Set<String> initialRegions = const {'Sydney'},
  }) {
    return showGeneralDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      barrierDismissible: true,
      barrierLabel: 'Region',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, _, _) {
        return Align(
          alignment: Alignment.centerRight,
          child: RegionModal(
            initialState: initialState,
            initialRegions: initialRegions,
          ),
        );
      },
      transitionBuilder: (context, anim, _, child) => _slideIn(anim, child),
    );
  }

  static Widget _slideIn(Animation<double> anim, Widget child) {
    final curved = CurvedAnimation(
      parent: anim,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(curved),
      child: child,
    );
  }

  @override
  State<RegionModal> createState() => _RegionModalState();
}

class _RegionModalState extends State<RegionModal> {
  static const List<String> _states = [
    'NSW',
    'VIC',
    'QLD',
    'WA',
    'SA',
    'TAS',
    'ACT',
    'NT',
  ];

  static const Map<String, List<String>> _regionsByState = {
    'NSW': [
      'Sydney',
      'Sydney_CBD',
      'Sydney_Inner City',
      'Sydney_N',
      'Sydney_W',
      'Sydney_S',
      'Sydney_E',
      'Newcastle',
      'Wollongong',
      'Central Coast',
    ],
    'VIC': ['Melbourne', 'Geelong', 'Ballarat', 'Bendigo'],
    'QLD': ['Brisbane', 'Gold Coast', 'Sunshine Coast', 'Cairns', 'Townsville'],
    'WA': ['Perth', 'Fremantle', 'Bunbury'],
    'SA': ['Adelaide', 'Mount Gambier'],
    'TAS': ['Hobart', 'Launceston'],
    'ACT': ['Canberra'],
    'NT': ['Darwin', 'Alice Springs'],
  };

  late String _selectedState;
  late Set<String> _selectedRegions;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedState = widget.initialState;
    _selectedRegions = {...widget.initialRegions};
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _visibleRegions {
    final all = _regionsByState[_selectedState] ?? const <String>[];
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all.where((r) => r.toLowerCase().contains(q)).toList();
  }

  void _toggleRegion(String region) {
    setState(() {
      if (_selectedRegions.contains(region)) {
        _selectedRegions.remove(region);
      } else {
        _selectedRegions.add(region);
      }
    });
  }

  void _close([String? result]) {
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width * 0.83; // 좌측에 underlying 화면이 살짝 보이도록

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        left: false,
        child: Container(
          width: width,
          height: size.height,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildSearchBar(),
                  const SizedBox(height: 20),
                  _buildStateChips(),
                  const SizedBox(height: 24),
                  Expanded(child: _buildRegionList()),
                ],
              ),
              if (_selectedRegions.isNotEmpty)
                Positioned(
                  right: 20,
                  bottom: 24,
                  child: _buildSelectedPill(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Text(
            'Region',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => _close(),
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.close, size: 22, color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Center(
      child: JobSearchBar.field(
        controller: _searchController,
        hintText: 'search for region',
        width: MediaQuery.sizeOf(context).width * 0.66,
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildStateChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _states.map(_buildStateChip).toList(),
      ),
    );
  }

  Widget _buildStateChip(String state) {
    final selected = state == _selectedState;
    return GestureDetector(
      onTap: () => setState(() => _selectedState = state),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 64,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.mainColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.mainColor,
            width: 1,
          ),
        ),
        child: Text(
          state,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.mainColor,
          ),
        ),
      ),
    );
  }

  Widget _buildRegionList() {
    final regions = _visibleRegions;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
      itemCount: regions.length,
      separatorBuilder: (_, _) => const Divider(
        height: 1,
        thickness: 1,
        color: Color(0xFFEEEEEE),
      ),
      itemBuilder: (context, index) {
        final region = regions[index];
        final checked = _selectedRegions.contains(region);
        return InkWell(
          onTap: () => _toggleRegion(region),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                _buildCheckbox(checked),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    region,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCheckbox(bool checked) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: checked ? const Color(0xFF202020) : Colors.white,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
          color: checked ? const Color(0xFF202020) : const Color(0xFFBDBDBD),
          width: 1.4,
        ),
      ),
      child: checked
          ? const Icon(Icons.check, size: 14, color: Colors.white)
          : null,
    );
  }

  Widget _buildSelectedPill() {
    final label = _selectedRegions.length == 1
        ? _selectedRegions.first
        : '${_selectedRegions.length} selected';
    return GestureDetector(
      onTap: () => _close(label),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: AppColors.mainColor,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.mainColor.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/icon/location_icon.svg',
              width: 18,
              height: 18,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
