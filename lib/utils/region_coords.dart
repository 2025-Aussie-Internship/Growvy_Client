import 'package:latlong2/latlong.dart';

/// 호주 주요 도시(및 sub-region) 의 위/경도 매핑.
///
/// [RegionFilterPanel] 에서 만들어지는 displayName 규칙:
/// - 단일 도시: 'Newcastle', 'Geelong', 'Hobart', 'Canberra' …
/// - 도시 + sub: 'Sydney_CBD', 'Melbourne_North', 'Brisbane_East' …
///
/// 정확한 sub-region 좌표가 없는 경우엔 도시 좌표에 offset 을 줘서
/// "비슷한 동네 위치" 를 만든다. 어느 displayName 이 들어와도 null 이
/// 반환되지 않도록 [resolve] 가 안전한 fallback 을 보장한다.
class RegionCoords {
  RegionCoords._();

  /// 주요 호주 도시 좌표 (위도, 경도). 위키피디아 도시 중심점 기준 근사값.
  static const Map<String, LatLng> _cities = <String, LatLng>{
    // NSW
    'Sydney': LatLng(-33.8688, 151.2093),
    'Newcastle': LatLng(-32.9283, 151.7817),
    'Wollongong': LatLng(-34.4278, 150.8931),
    'Central Coast': LatLng(-33.4269, 151.3424),

    // VIC
    'Melbourne': LatLng(-37.8136, 144.9631),
    'Geelong': LatLng(-38.1499, 144.3617),
    'Ballarat': LatLng(-37.5622, 143.8503),
    'Bendigo': LatLng(-36.7570, 144.2794),

    // QLD
    'Brisbane': LatLng(-27.4705, 153.0260),
    'Gold Coast': LatLng(-28.0167, 153.4000),
    'Sunshine Coast': LatLng(-26.6500, 153.0667),
    'Cairns': LatLng(-16.9203, 145.7710),
    'Townsville': LatLng(-19.2589, 146.8169),

    // WA
    'Perth': LatLng(-31.9523, 115.8613),
    'Mandurah': LatLng(-32.5298, 115.7426),

    // SA
    'Adelaide': LatLng(-34.9285, 138.6007),

    // TAS
    'Hobart': LatLng(-42.8821, 147.3272),
    'Launceston': LatLng(-41.4332, 147.1441),

    // ACT
    'Canberra': LatLng(-35.2809, 149.1300),

    // NT
    'Darwin': LatLng(-12.4634, 130.8456),
    'Alice Springs': LatLng(-23.6980, 133.8807),
  };

  /// City + sub-region 별 미세 오프셋. displayName 이 'Sydney_CBD' 같이
  /// 들어왔을 때 도시 좌표에 더해질 (latΔ, lngΔ).
  /// 정확한 좌표 대신 약간씩 다른 위치를 줘서 지도 카메라가 동일 좌표로
  /// 반복 이동하지 않게 한다.
  static const Map<String, _LatLngOffset> _subRegionOffsets = <String, _LatLngOffset>{
    'CBD': _LatLngOffset(0.000, 0.000),
    'Inner': _LatLngOffset(-0.010, 0.010),
    'Inner City': _LatLngOffset(-0.010, 0.010),
    'North': _LatLngOffset(0.060, 0.000),
    'South': _LatLngOffset(-0.060, 0.000),
    'East': _LatLngOffset(0.000, 0.060),
    'West': _LatLngOffset(0.000, -0.060),
    'South-East': _LatLngOffset(-0.050, 0.050),
  };

  /// displayName ('Sydney_CBD', 'Newcastle' 등) → LatLng 변환.
  /// 매핑이 없으면 호주 중앙(시드니) 으로 fallback.
  static LatLng resolve(String displayName) {
    if (displayName.isEmpty) return _cities['Sydney']!;
    final parts = displayName.split('_');
    final cityName = parts.first;
    final city = _cities[cityName];
    if (city == null) {
      // 단일 도시 매핑이 없으면 시드니로 fallback.
      return _cities['Sydney']!;
    }
    if (parts.length == 1) return city;
    final subName = parts.sublist(1).join('_');
    final offset = _subRegionOffsets[subName];
    if (offset == null) return city;
    return LatLng(city.latitude + offset.dLat, city.longitude + offset.dLng);
  }

  /// 도시(LatLng) 근처에 흩어진 더미 일자리 좌표를 생성한다.
  /// MapPage 의 마커 표시용. [count] 만큼 도시 좌표 주변에 균등하게.
  static List<LatLng> dummyJobOffsetsAround(LatLng center, {int count = 7}) {
    const offsets = <_LatLngOffset>[
      _LatLngOffset(0.008, 0.005),
      _LatLngOffset(-0.007, -0.006),
      _LatLngOffset(0.010, -0.008),
      _LatLngOffset(-0.009, 0.007),
      _LatLngOffset(0.006, 0.012),
      _LatLngOffset(-0.012, 0.004),
      _LatLngOffset(0.005, -0.011),
      _LatLngOffset(0.014, 0.000),
      _LatLngOffset(0.000, 0.014),
      _LatLngOffset(-0.014, 0.000),
    ];
    return [
      for (var i = 0; i < count; i++)
        LatLng(
          center.latitude + offsets[i % offsets.length].dLat,
          center.longitude + offsets[i % offsets.length].dLng,
        ),
    ];
  }
}

class _LatLngOffset {
  final double dLat;
  final double dLng;
  const _LatLngOffset(this.dLat, this.dLng);
}
