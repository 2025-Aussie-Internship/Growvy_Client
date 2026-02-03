import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../styles/colors.dart';

/// 지도 화면 Region 버튼 탭 시 오른쪽에서 슬라이드되는 지역 필터 패널.
class RegionFilterPanel extends StatefulWidget {
  const RegionFilterPanel({
    super.key,
    required this.onClose,
    this.onComplete,
  });

  final VoidCallback onClose;
  final void Function(List<String> selected)? onComplete;

  @override
  State<RegionFilterPanel> createState() => _RegionFilterPanelState();
}

class _RegionNode {
  final String name;
  final List<_RegionNode>? children;
  _RegionNode(this.name, [this.children]);
}

class _RegionFilterPanelState extends State<RegionFilterPanel> {
  final TextEditingController _searchController = TextEditingController();

  static const List<String> _filterChips = [
    'NSW',
    'VIC',
    'QLD',
    'WA',
    'SA',
    'TAS',
    'ACT',
    'NT',
  ];

  int _selectedChipIndex = 0;
  /// 도시 하나만 선택 (표시용 이름, 예: Sydney_CBD, Newcastle)
  String? _selectedRegion;
  String _searchQuery = '';

  static List<_RegionNode> get _regionTree => [
        _RegionNode('NSW', [
          _RegionNode('Sydney', [
            _RegionNode('CBD'),
            _RegionNode('Inner City'),
            _RegionNode('North'),
            _RegionNode('West'),
            _RegionNode('South'),
            _RegionNode('East'),
          ]),
          _RegionNode('Newcastle'),
          _RegionNode('Wollongong'),
          _RegionNode('Central Coast'),
        ]),
        _RegionNode('VIC', [
          _RegionNode('Melbourne', [
            _RegionNode('CBD'),
            _RegionNode('Inner'),
            _RegionNode('North'),
            _RegionNode('East'),
            _RegionNode('West'),
            _RegionNode('South-East'),
          ]),
          _RegionNode('Geelong'),
          _RegionNode('Ballarat'),
          _RegionNode('Bendigo'),
        ]),
        _RegionNode('QLD', [
          _RegionNode('Brisbane', [
            _RegionNode('CBD'),
            _RegionNode('North'),
            _RegionNode('South'),
            _RegionNode('East'),
            _RegionNode('West'),
          ]),
          _RegionNode('Gold Coast'),
          _RegionNode('Sunshine Coast'),
          _RegionNode('Cairns'),
          _RegionNode('Townsville'),
        ]),
        _RegionNode('WA', [
          _RegionNode('Perth', [
            _RegionNode('CBD'),
            _RegionNode('North'),
            _RegionNode('South'),
            _RegionNode('East'),
            _RegionNode('West'),
          ]),
          _RegionNode('Mandurah'),
        ]),
        _RegionNode('SA', [
          _RegionNode('Adelaide', [
            _RegionNode('CBD'),
            _RegionNode('North'),
            _RegionNode('South'),
            _RegionNode('East'),
            _RegionNode('West'),
          ]),
        ]),
        _RegionNode('TAS', [
          _RegionNode('Hobart'),
          _RegionNode('Launceston'),
        ]),
        _RegionNode('ACT', [
          _RegionNode('Canberra'),
        ]),
        _RegionNode('NT', [
          _RegionNode('Darwin'),
          _RegionNode('Alice Springs'),
        ]),
      ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesQuery(String name) {
    if (_searchQuery.trim().isEmpty) return true;
    return name.toLowerCase().contains(_searchQuery.toLowerCase());
  }

  /// State 아래 도시/하위지역만 평면 리스트로 (표시명: Sydney_CBD, Newcastle 등). State 행은 없음.
  List<String> _buildFlatRegionDisplayNames(_RegionNode stateRoot) {
    final out = <String>[];
    final cities = stateRoot.children ?? [];
    for (final city in cities) {
      final hasSub = city.children != null && city.children!.isNotEmpty;
      if (hasSub) {
        for (final sub in city.children!) {
          final displayName = '${city.name}_${sub.name}';
          if (_matchesQuery(city.name) || _matchesQuery(sub.name)) {
            out.add(displayName);
          }
        }
      } else {
        if (_matchesQuery(city.name)) out.add(city.name);
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final stateRoot = _regionTree[_selectedChipIndex];
    final flatItems = _buildFlatRegionDisplayNames(stateRoot);

    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.horizontal(left: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 10,
            offset: Offset(-4, 0),
          ),
        ],
      ),
      child: SafeArea(
        left: false,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 헤더: Region w600 16 가운데, X Icons.close
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Center(
                        child: Text(
                          'Region',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: widget.onClose,
                          child: const Icon(
                            Icons.close,
                            size: 24,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 1,
                  color: const Color(0xFFF5F5F5),
                ),
                const SizedBox(height: 16),
                Center(
                  child: SizedBox(
                    width: 250,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: const Color(0xFFF5F5F5)),
                      ),
                      child: Row(
                        children: [
                          if (_searchQuery.trim().isEmpty) ...[
                            const SizedBox(width: 14),
                            SvgPicture.asset(
                              'assets/icon/search_icon.svg',
                              width: 20,
                              height: 20,
                            ),
                            const SizedBox(width: 10),
                          ],
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                hintText: 'Sydney',
                                hintStyle: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF8C8C8C),
                                  fontWeight: FontWeight.w400,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: const TextStyle(fontSize: 14),
                              onChanged: (value) =>
                                  setState(() => _searchQuery = value),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: GestureDetector(
                              onTap: () {},
                              child: SvgPicture.asset(
                                'assets/icon/mike_icon.svg',
                                width: 32,
                                height: 32,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // State 칩 가운데 정렬, 탭 시 리스트만 전환 (선택 아님)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(_filterChips.length, (index) {
                        final isSelected = _selectedChipIndex == index;
                        final stateCode = _filterChips[index];
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedChipIndex = index);
                          },
                          child: SizedBox(
                            width: 62,
                            height: 30,
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.mainColor
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.mainColor
                                      : const Color(0xFFD9D9D9),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                stateCode,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.mainColor,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // NSW 아래 도시/하위만 리스트 (State 행 없음), 도시 하나만 선택, 체크박스 14·체크 아이콘 없음
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: flatItems.length,
                    itemBuilder: (context, index) {
                      final displayName = flatItems[index];
                      final isSelected = _selectedRegion == displayName;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() {
                                _selectedRegion =
                                    isSelected ? null : displayName;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  // 검정 박스 14, 체크 표시 없음 (선택 시 채움만)
                                  Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.black
                                          : Colors.white,
                                      border: Border.all(
                                          color: Colors.black, width: 1),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    displayName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: Color(0xFFF5F5F5),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
            // 오른쪽 아래 선택 도시 칩: FF7252, h40 r47, 도시명에 따라 너비 변동, 양옆 패딩 16
            if (_selectedRegion != null)
              Positioned(
                right: 16,
                bottom: 16,
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF7252),
                    borderRadius: BorderRadius.circular(47),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/icon/marker_icon.svg',
                        width: 24,
                        height: 24,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _selectedRegion!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
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
