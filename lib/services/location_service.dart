import 'dart:async';
import 'package:geolocator/geolocator.dart';

typedef PositionCallback = void Function(Map<String, dynamic> posData);

class LocationService {
  static final LocationService instance = LocationService._();
  LocationService._();

  StreamSubscription<Position>? _subscription;
  PositionCallback? _onPosition;

  void initForegroundTask() {}

  Future<bool> checkAndRequestPermissions() async {
    bool enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return false;
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) return false;
    return true;
  }

  Future<bool> startTracking(PositionCallback onPosition) async {
    final ok = await checkAndRequestPermissions();
    if (!ok) return false;
    _onPosition = onPosition;
    _subscription = Geolocator.getPositionStream(
      locationSettings: const AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3,
        intervalDuration: Duration(seconds: 3),
        foregroundNotificationConfig: ForegroundNotificationConfig(
          notificationChannelName: 'Desert Track GPS',
          notificationTitle: 'Desert Track',
          notificationText: 'جارٍ تسجيل المسار...',
          enableLaunchButton: true,
        ),
      ),
    ).listen((pos) {
      _onPosition?.call({
        'lat': pos.latitude,
        'lon': pos.longitude,
        'alt': pos.altitude,
        'speed': pos.speed,
        'bearing': pos.heading,
        'ts': pos.timestamp.toIso8601String(),
      });
    });
    return true;
  }

  Future<void> stopTracking() async {
    await _subscription?.cancel();
    _subscription = null;
    _onPosition = null;
  }

  Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (_) { return null; }
  }

  Stream<Position> positionStream() =>
    Geolocator.getPositionStream(
      locationSettings: const AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    );

  bool get isTracking => _subscription != null;
}
