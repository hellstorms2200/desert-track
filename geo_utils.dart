import 'dart:math';

class GeoUtils {
  static const double _earthRadius = 6371000.0; // meters

  /// Haversine formula – distance between two lat/lng points in meters
  static double distanceMeters(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) *
            cos(_toRad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return _earthRadius * c;
  }

  /// Bearing in degrees from point 1 → point 2
  static double bearing(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    final dLon = _toRad(lon2 - lon1);
    final y = sin(dLon) * cos(_toRad(lat2));
    final x = cos(_toRad(lat1)) * sin(_toRad(lat2)) -
        sin(_toRad(lat1)) * cos(_toRad(lat2)) * cos(dLon);
    return (_toDeg(atan2(y, x)) + 360) % 360;
  }

  /// Format distance for display
  static String formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()} م';
    final km = meters / 1000.0;
    return '${km.toStringAsFixed(1)} كم';
  }

  /// Format speed km/h for display
  static String formatSpeed(double kmh) {
    return '${kmh.round()} كم/س';
  }

  /// Format duration as HH:MM:SS
  static String formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:'
          '${m.toString().padLeft(2, '0')}:'
          '${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  /// Find the nearest point index on a track to a given position
  static int nearestPointIndex(
    double lat, double lon,
    List<({double lat, double lon})> track,
  ) {
    if (track.isEmpty) return -1;
    int nearest = 0;
    double minDist = double.infinity;
    for (int i = 0; i < track.length; i++) {
      final d = distanceMeters(lat, lon, track[i].lat, track[i].lon);
      if (d < minDist) {
        minDist = d;
        nearest = i;
      }
    }
    return nearest;
  }

  /// Cross-track deviation (meters) from current position to track segment
  static double crossTrackDistance(
    double lat, double lon,
    double trackLat, double trackLon,
    double nextLat, double nextLon,
  ) {
    final d13 = distanceMeters(lat, lon, trackLat, trackLon) / _earthRadius;
    final theta13 = _toRad(bearing(lat, lon, trackLat, trackLon));
    final theta12 = _toRad(bearing(trackLat, trackLon, nextLat, nextLon));
    return (_earthRadius * asin(sin(d13) * sin(theta13 - theta12))).abs();
  }

  static double _toRad(double deg) => deg * pi / 180.0;
  static double _toDeg(double rad) => rad * 180.0 / pi;
}
