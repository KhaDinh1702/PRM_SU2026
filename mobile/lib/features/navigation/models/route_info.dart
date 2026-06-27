import 'package:latlong2/latlong.dart';

class RouteInfo {
  final int distanceMeters;
  final Duration duration;
  final List<LatLng> points;

  const RouteInfo({
    required this.distanceMeters,
    required this.duration,
    required this.points,
  });

  factory RouteInfo.fromJson(Map<String, dynamic> json) {
    return RouteInfo(
      distanceMeters:
          int.tryParse(json['distanceMeters']?.toString() ?? '') ?? 0,
      duration: _parseDuration(json['duration']?.toString()),
      points: decodePolyline(json['polyline']?.toString() ?? ''),
    );
  }

  String get distanceLabel {
    if (distanceMeters >= 1000) {
      return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
    }
    return '$distanceMeters m';
  }

  String get durationLabel {
    final minutes = duration.inMinutes;
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remain = minutes % 60;
    return '${hours}h ${remain}m';
  }

  static Duration _parseDuration(String? raw) {
    if (raw == null || raw.isEmpty) return Duration.zero;
    final seconds = int.tryParse(raw.replaceAll('s', '')) ?? 0;
    return Duration(seconds: seconds);
  }

  static List<LatLng> decodePolyline(String encoded) {
    final points = <LatLng>[];
    var index = 0;
    var lat = 0;
    var lng = 0;

    while (index < encoded.length) {
      var shift = 0;
      var result = 0;
      int byte;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20 && index < encoded.length);
      lat += (result & 1) != 0 ? ~(result >> 1) : result >> 1;

      shift = 0;
      result = 0;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20 && index < encoded.length);
      lng += (result & 1) != 0 ? ~(result >> 1) : result >> 1;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }
}
