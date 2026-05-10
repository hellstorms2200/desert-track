import 'dart:async';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static final LocationService instance = LocationService._();
  LocationService._();
  StreamSubscription<Position>? _subscription;
  bool _isTracking = false;
  bool get isTracking => _isTracking;

  void initForegroundTask() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'desert_track_location',
        channelName: 'Desert Track GPS',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        autoRunOnBoot: false,
        allowWakeLock: true,
      ),
    );
  }

  Future<bool> requestPermission() async {
    LocationPermission p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) {
      p = await Geolocator.requestPermission();
    }
    return p == LocationPermission.whileInUse || p == LocationPermission.always;
  }

  Future<bool> startTracking(void Function(Position) onPosition) async {
    if (!await requestPermission()) return false;
    _subscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
      ),
    ).listen(onPosition);
    _isTracking = true;
    return true;
  }

  Future<void> stopTracking() async {
    await _subscription?.cancel();
    _subscription = null;
    _isTracking = false;
  }
}
