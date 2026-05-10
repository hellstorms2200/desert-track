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
        channelDescription: 'Tracking your desert route',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        autoRunOnBoot: false,
        allowWakeLock: true,
      ),
    );
  }

  Future<bool> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  Future<bool> startTracking(Function(Position) onPosition) async {
    final hasPermission = await requestPermission();
    if (!hasPermission) return false;
    _subscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
      ),
    ).listen((pos) => onPosition(pos));
    _isTracking = true;
    return true;
  }

  Future<void> stopTracking() async {
    await _subscription?.cancel();
    _subscription = null;
    _isTracking = false;
  }
}
