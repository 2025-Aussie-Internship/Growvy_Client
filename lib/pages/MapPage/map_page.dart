import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' hide Path;

import '../../styles/colors.dart';
import '../../widgets/map_job_info_sheet.dart';
import '../../widgets/region_filter_panel.dart';
import '../MainPage/job_detail_page.dart';


class MapPage extends StatefulWidget {
  const MapPage({super.key, this.onRegionPanelChanged});

  final void Function(bool open)? onRegionPanelChanged;

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  bool _isLoadingLocation = true;
  int? _selectedJobId;
  bool _showRegionPanel = false;
  bool _isBookmarked = false;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  late AnimationController _regionSlideController;
  late Animation<Offset> _regionSlideAnimation;

  static const _defaultCenter = LatLng(37.5665, 126.9780);

  final List<Map<String, dynamic>> _jobsTemplate = [
    {'id': 1, 'latOffset': 0.008, 'lngOffset': 0.005, 'title': 'Warehouse Job', 'company': 'Company', 'payment': '\$24.95 per hour', 'time': '4~8 hours per day', 'qualifications': 'Age 18+ 2025'},
    {'id': 2, 'latOffset': -0.007, 'lngOffset': -0.006, 'title': 'Event Staff', 'company': 'Event Co', 'payment': '\$22.00 per hour', 'time': '6~10 hours per day', 'qualifications': 'Age 18+ 2025'},
    {'id': 3, 'latOffset': 0.010, 'lngOffset': -0.008, 'title': 'Retail Assistant', 'company': 'Retail Inc', 'payment': '\$23.50 per hour', 'time': '4~6 hours per day', 'qualifications': 'Age 18+ 2025'},
    {'id': 4, 'latOffset': -0.009, 'lngOffset': 0.007, 'title': 'Cafe Staff', 'company': 'Cafe Co', 'payment': '\$21.00 per hour', 'time': '4~6 hours per day', 'qualifications': 'Age 18+ 2025'},
    {'id': 5, 'latOffset': 0.006, 'lngOffset': 0.012, 'title': 'Delivery Helper', 'company': 'Logistics', 'payment': '\$25.00 per hour', 'time': '6~8 hours per day', 'qualifications': 'Age 18+ 2025'},
    {'id': 6, 'latOffset': -0.012, 'lngOffset': 0.004, 'title': 'Store Associate', 'company': 'Retail', 'payment': '\$22.50 per hour', 'time': '5~7 hours per day', 'qualifications': 'Age 18+ 2025'},
    {'id': 7, 'latOffset': 0.005, 'lngOffset': -0.011, 'title': 'Kitchen Helper', 'company': 'Food Co', 'payment': '\$23.00 per hour', 'time': '4~8 hours per day', 'qualifications': 'Age 18+ 2025'},
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
    _searchController.dispose();
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

  Future<void> _searchAndMoveToPlace(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    if (!mounted) return;
    setState(() => _isSearching = true);
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(q)}&format=json&limit=1',
      );
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'GrowvyClient/1.0'},
      ).timeout(const Duration(seconds: 10));
      if (!mounted) return;
      if (response.statusCode != 200) {
        setState(() => _isSearching = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('장소를 찾을 수 없습니다.')),
          );
        }
        return;
      }
      final list = jsonDecode(response.body) as List;
      if (list.isEmpty) {
        setState(() => _isSearching = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('장소를 찾을 수 없습니다.')),
          );
        }
        return;
      }
      final first = list.first as Map<String, dynamic>;
      final lat = double.tryParse(first['lat']?.toString() ?? '') ?? 0.0;
      final lon = double.tryParse(first['lon']?.toString() ?? '') ?? 0.0;
      final latLng = LatLng(lat, lon);
      _mapController.move(latLng, 15.0);
      if (mounted) setState(() => _isSearching = false);
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('검색 중 오류가 발생했습니다.')),
        );
      }
    }
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

  List<Map<String, dynamic>> get _jobs {
    final base = _currentLocation ?? _defaultCenter;
    return _jobsTemplate.map((j) {
      final lat = base.latitude + (j['latOffset'] as num).toDouble();
      final lng = base.longitude + (j['lngOffset'] as num).toDouble();
      return {...j, 'lat': lat, 'lng': lng};
    }).toList();
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
                padding: const EdgeInsets.fromLTRB(20, 12, 16, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Center(child: _buildSearchBar()),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _buildRegionButton(),
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

  Widget _buildSearchBar() {
    return SizedBox(
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
          GestureDetector(
            onTap: () => _searchAndMoveToPlace(_searchController.text),
            child: _isSearching
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.mainColor,
                    ),
                  )
                : SvgPicture.asset(
                    'assets/icon/search_icon.svg',
                    width: 18,
                    height: 18,
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'search for jobs',
                hintStyle: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF9E9E9E),
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(fontSize: 14),
              textInputAction: TextInputAction.search,
              onSubmitted: _searchAndMoveToPlace,
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
