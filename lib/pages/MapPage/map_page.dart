import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../../styles/colors.dart';
import '../../utils/region_coords.dart';
import '../../widgets/job_search_bar.dart';
import '../../widgets/map_job_info_sheet.dart';
import '../../widgets/region_filter_panel.dart';
import '../MainPage/job_detail_page.dart';
import '../SearchPage/search_page.dart';


class MapPage extends StatefulWidget {
  const MapPage({
    super.key,
    this.onRegionPanelChanged,
    this.onSearchTap,
  });

  final void Function(bool open)? onRegionPanelChanged;
  final VoidCallback? onSearchTap;

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  bool _isLoadingLocation = true;
  int? _selectedJobId;
  bool _showRegionPanel = false;
  bool _isBookmarked = false;
  late AnimationController _regionSlideController;
  late Animation<Offset> _regionSlideAnimation;

  /// Region 패널에서 사용자가 마지막으로 고른 도시. null 이면 현재 위치 기준.
  LatLng? _pickedRegionCenter;
  String? _pickedRegionLabel;

  /// 카메라 이동 보간용. _mapController.move 는 즉시 이동만 지원하므로
  /// AnimationController 로 프레임마다 보간해서 이동시킨다.
  AnimationController? _cameraAnim;

  static const _defaultCenter = LatLng(37.5665, 126.9780);

  static const List<Map<String, dynamic>> _jobsTemplate = [
    {'id': 1, 'title': 'Warehouse Job', 'company': 'Company', 'payment': '\$24.95 per hour', 'time': '4~8 hours per day', 'qualifications': 'Age 18+ 2025'},
    {'id': 2, 'title': 'Event Staff', 'company': 'Event Co', 'payment': '\$22.00 per hour', 'time': '6~10 hours per day', 'qualifications': 'Age 18+ 2025'},
    {'id': 3, 'title': 'Retail Assistant', 'company': 'Retail Inc', 'payment': '\$23.50 per hour', 'time': '4~6 hours per day', 'qualifications': 'Age 18+ 2025'},
    {'id': 4, 'title': 'Cafe Staff', 'company': 'Cafe Co', 'payment': '\$21.00 per hour', 'time': '4~6 hours per day', 'qualifications': 'Age 18+ 2025'},
    {'id': 5, 'title': 'Delivery Helper', 'company': 'Logistics', 'payment': '\$25.00 per hour', 'time': '6~8 hours per day', 'qualifications': 'Age 18+ 2025'},
    {'id': 6, 'title': 'Store Associate', 'company': 'Retail', 'payment': '\$22.50 per hour', 'time': '5~7 hours per day', 'qualifications': 'Age 18+ 2025'},
    {'id': 7, 'title': 'Kitchen Helper', 'company': 'Food Co', 'payment': '\$23.00 per hour', 'time': '4~8 hours per day', 'qualifications': 'Age 18+ 2025'},
  ];

  @override
  void initState() {
    super.initState();
    _regionSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _regionSlideAnimation = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _regionSlideController,
      curve: Curves.easeOut,
    ));
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _regionSlideController.dispose();
    _cameraAnim?.dispose();
    super.dispose();
  }

  void _openRegionPanel() {
    setState(() => _showRegionPanel = true);
    _regionSlideController.forward();
    widget.onRegionPanelChanged?.call(true);
  }

  void _closeRegionPanel() {
    _regionSlideController.reverse().then((_) {
      if (mounted) setState(() => _showRegionPanel = false);
      widget.onRegionPanelChanged?.call(false);
    });
  }

  /// RegionFilterPanel 에서 도시 선택이 일어났을 때 호출.
  /// - 패널은 닫고
  /// - 해당 지역 좌표로 카메라를 부드럽게 이동시키며
  /// - 더미 마커도 그 지역 기준으로 재배치한다.
  void _onRegionPicked(String displayName) {
    final target = RegionCoords.resolve(displayName);
    setState(() {
      _pickedRegionCenter = target;
      _pickedRegionLabel = displayName.replaceAll('_', ' / ');
      _selectedJobId = null;
    });
    _closeRegionPanel();
    _animateMapTo(target, targetZoom: 12.0);
  }

  /// 현재 카메라 위치에서 [target] 좌표/줌으로 보간하며 부드럽게 이동시킨다.
  /// flutter_map 의 MapController.move 는 즉시 이동만 지원하므로
  /// 별도 AnimationController 로 매 프레임 보간한 좌표를 move 한다.
  void _animateMapTo(
    LatLng target, {
    double targetZoom = 13.0,
    Duration duration = const Duration(milliseconds: 700),
  }) {
    _cameraAnim?.dispose();
    final startCenter = _mapController.camera.center;
    final startZoom = _mapController.camera.zoom;
    final controller = AnimationController(vsync: this, duration: duration);
    _cameraAnim = controller;
    final curve = CurvedAnimation(parent: controller, curve: Curves.easeInOut);
    controller.addListener(() {
      final t = curve.value;
      final lat =
          startCenter.latitude + (target.latitude - startCenter.latitude) * t;
      final lng =
          startCenter.longitude + (target.longitude - startCenter.longitude) * t;
      final zoom = startZoom + (targetZoom - startZoom) * t;
      _mapController.move(LatLng(lat, lng), zoom);
    });
    controller.forward();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setDefaultLocation();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _setDefaultLocation();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _setDefaultLocation();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );
      final location = LatLng(position.latitude, position.longitude);
      if (mounted) {
        setState(() {
          _currentLocation = location;
          _isLoadingLocation = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _mapController.move(location, 15.0);
        });
      }
    } catch (e) {
      _setDefaultLocation();
    }
  }

  void _setDefaultLocation() {
    if (mounted) {
      setState(() {
        _currentLocation = _defaultCenter;
        _isLoadingLocation = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(_defaultCenter, 15.0);
      });
    }
  }

  /// 마커들의 기준 좌표. Region 패널에서 도시를 골랐으면 그 도시 중심,
  /// 아니면 사용자의 현재 위치 (없으면 디폴트).
  LatLng get _markerOrigin =>
      _pickedRegionCenter ?? _currentLocation ?? _defaultCenter;

  List<Map<String, dynamic>> get _jobs {
    final base = _markerOrigin;
    // 도시 중심 주변에 흩어진 더미 좌표 7개. 도시를 바꾸면 자동으로
    // 그 도시 기준으로 마커가 다시 흩어진다.
    final coords = RegionCoords.dummyJobOffsetsAround(
      base,
      count: _jobsTemplate.length,
    );
    return [
      for (var i = 0; i < _jobsTemplate.length; i++)
        {
          ..._jobsTemplate[i],
          'lat': coords[i].latitude,
          'lng': coords[i].longitude,
        }
    ];
  }

  Map<String, dynamic>? get _selectedJob {
    if (_selectedJobId == null) return null;
    try {
      return _jobs.firstWhere((j) => j['id'] == _selectedJobId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          _buildMap(),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  JobSearchBar.topSpacing,
                  20,
                  0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Center(
                      child: JobSearchBar.tappable(
                        onTap: widget.onSearchTap ??
                            () => SearchPage.open(context),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_pickedRegionLabel != null)
                          _buildPickedRegionChip()
                        else
                          const SizedBox.shrink(),
                        _buildRegionButton(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_selectedJob != null) _buildJobBottomSheet(),
          if (_showRegionPanel) _buildRegionOverlay(),
        ],
      ),
    );
  }

  Widget _buildMap() {
    if (_isLoadingLocation) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.mainColor),
      );
    }

    final center = _currentLocation ?? _defaultCenter;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 15.0,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.growvy.client',
          maxZoom: 19,
        ),
        if (_currentLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: _currentLocation!,
                width: 56,
                height: 56,
                alignment: Alignment.bottomCenter,
                child: _buildMyLocationMarker(),
              ),
            ],
          ),
        MarkerLayer(
          markers: _jobs.map((job) {
            final isSelected = _selectedJobId == job['id'];
            final point = LatLng(
              (job['lat'] as num).toDouble(),
              (job['lng'] as num).toDouble(),
            );
            return Marker(
              point: point,
              width: 32,
              height: 32,
              alignment: Alignment.center,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (_selectedJobId == job['id']) {
                      _selectedJobId = null;
                    } else {
                      _selectedJobId = job['id'] as int;
                    }
                  });
                  _mapController.move(point, 15.0);
                },
                child: SvgPicture.asset(
                  isSelected
                      ? 'assets/icon/location_icon.svg'
                      : 'assets/icon/marker_icon.svg',
                  width: 32,
                  height: 32,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMyLocationMarker() {
    const double size = 56;
    const double circleRadius = 8;
    const double whiteRadius = 3;
    const Color ringColor = Color(0xFFD9534F);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // 보고 있는 방향 블러 (위쪽 팬 형태)
          Positioned(
            top: 0,
            left: size * 0.2,
            right: size * 0.2,
            bottom: size * 0.35,
            child: IgnorePointer(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: CustomPaint(
                  painter: _DirectionFanPainter(),
                  size: Size(size * 0.6, size * 0.65),
                ),
              ),
            ),
          ),
          // 빨간 링 + 가운데 흰 원
          Positioned(
            bottom: 0,
            child: Container(
              width: circleRadius * 2,
              height: circleRadius * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ringColor,
                border: Border.all(color: ringColor, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: ringColor.withValues(alpha: 0.3),
                    blurRadius: 4,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: whiteRadius * 2,
                  height: whiteRadius * 2,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegionButton() {
    return GestureDetector(
      onTap: _openRegionPanel,
      child: SvgPicture.asset(
        'assets/icon/Region_button.svg',
        width: 67,
        height: 67,
      ),
    );
  }

  /// 선택된 지역 칩. 탭하면 마지막 선택을 해제하고 카메라가
  /// 사용자 현재 위치(또는 기본값) 로 되돌아간다.
  Widget _buildPickedRegionChip() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _pickedRegionCenter = null;
          _pickedRegionLabel = null;
          _selectedJobId = null;
        });
        final fallback = _currentLocation ?? _defaultCenter;
        _animateMapTo(fallback, targetZoom: 13.0);
      },
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.mainColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.place, color: Colors.white, size: 16),
            const SizedBox(width: 4),
            Text(
              _pickedRegionLabel ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.close, color: Colors.white, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildJobBottomSheet() {
    final job = _selectedJob!;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: MapJobInfoSheet(
        title: job['title'] as String,
        company: job['company'] as String,
        payment: job['payment'] as String,
        time: job['time'] as String,
        qualifications: job['qualifications'] as String,
        isBookmarked: _isBookmarked,
        onBookmarkTap: () => setState(() => _isBookmarked = !_isBookmarked),
        onClose: () => setState(() => _selectedJobId = null),
        onAddTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const JobDetailPage(),
            ),
          );
        },
      ),
      ),
    );
  }

  Widget _buildRegionOverlay() {
    return Positioned(
      top: 0,
      bottom: 0,
      left: 0,
      right: 0,
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _closeRegionPanel,
              child: Container(color: Colors.black26),
            ),
          ),
          SlideTransition(
            position: _regionSlideAnimation,
            child: RegionFilterPanel(
              onClose: _closeRegionPanel,
              onComplete: (selected) {},
              onRegionPicked: _onRegionPicked,
            ),
          ),
        ],
      ),
    );
  }
}

class _DirectionFanPainter extends CustomPainter {
  static const Color _fanColor = Color(0xFFD9534F);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _fanColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width * 0.5, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
