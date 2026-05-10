import 'dart:math';

class GeoUtils {
  static const double _earthRadius = 6371000;

  static double distanceMeters(
      double lat1, double lon1, double lat2, double lon2) {
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    return _earthRadius * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double bearingDegrees(
      double lat1, double lon1, double lat2, double lon2) {
    final dLon = _toRad(lon2 - lon1);
    final y = sin(dLon) * cos(_toRad(lat2));
    final x = cos(_toRad(lat1)) * sin(_toRad(lat2)) -
        sin(_toRad(lat1)) * cos(_toRad(lat2)) * cos(dLon);
    return (_toDeg(atan2(y, x)) + 360) % 360;
  }

  static String formatDistance(double meters) {
    if (meters < 1000) return '${meters.toStringAsFixed(0)} m';
    return '${(meters / 1000).toStringAsFixed(2)} km';
  }

  static String formatSpeed(double mps) {
    return '${(mps * 3.6).toStringAsFixed(1)} km/h';
  }

  static String formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  static double _toRad(double deg) => deg * pi / 180;
  static double _toDeg(double rad) => rad * 180 / pi;
}
