import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Background task entry point (runs in separate isolate)
// ─────────────────────────────────────────────────────────────────────────────

@pragma('vm:entry-point')
void startLocationCallback() {
  FlutterForegroundTask.setTaskHandler(_LocationTaskHandler());
}

class _LocationTaskHandler extends TaskHandler {
  StreamSubscription<Position>? _sub;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    const settings = AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 3,
      intervalDuration: Duration(seconds: 3),
      forceLocationManager: false,
    );

    _sub = Geolocator.getPositionStream(locationSettings: settings)
        .listen((pos) {
      FlutterForegroundTask.sendDataToMain({
        'lat': pos.latitude,
        'lon': pos.longitude,
        'alt': pos.altitude,
        'speed': pos.speed,
        'bearing': pos.heading,
        'ts': pos.timestamp.toIso8601String(),
      });
    });
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    // Notification text updated every interval
    await FlutterForegroundTask.updateService(
      notificationTitle: 'Desert Track 🛰️',
      notificationText: 'جارٍ تسجيل المسار...',
    );
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    await _sub?.cancel();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LocationService – used from the UI/provider
// ─────────────────────────────────────────────────────────────────────────────

typedef PositionCallback = void Function(Map<String, dynamic> posData);

class LocationService {
  static final LocationService instance = LocationService._();
  LocationService._();

  PositionCallback? _onPositionReceived;

  // ── Setup ──────────────────────────────────────────────────────────────────

  void initForegroundTask() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'desert_track_location',
        channelName: 'Desert Track GPS',
        channelDescription: 'تسجيل موقع GPS أثناء الرحلة',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        iconData: const NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
        ),
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(3000),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWifiLock: true,
      ),
    );
  }

  // ── Permissions ─────────────────────────────────────────────────────────────

  Future<bool> checkAndRequestPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) return false;

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  // ── Start / Stop ───────────────────────────────────────────────────────────

  Future<bool> startTracking(PositionCallback onPosition) async {
    _onPositionReceived = onPosition;

    final hasPermission = await checkAndRequestPermissions();
    if (!hasPermission) return false;

    FlutterForegroundTask.addTaskDataCallback(_handleTaskData);

    final result = await FlutterForegroundTask.startService(
      serviceId: 256,
      notificationTitle: 'Desert Track 🛰️',
      notificationText: 'جارٍ تسجيل المسار...',
      callback: startLocationCallback,
    );

    return result == ServiceRequestResult.success;
  }

  Future<void> stopTracking() async {
    FlutterForegroundTask.removeTaskDataCallback(_handleTaskData);
    await FlutterForegroundTask.stopService();
    _onPositionReceived = null;
  }

  void _handleTaskData(Object data) {
    if (data is Map<String, dynamic>) {
      _onPositionReceived?.call(data);
    }
  }

  // ── One-shot current position ──────────────────────────────────────────────

  Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  // ── Single stream (for viewing, not recording) ─────────────────────────────

  Stream<Position> positionStream() => Geolocator.getPositionStream(
        locationSettings: const AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      );

  bool get isTracking => FlutterForegroundTask.isRunningService;
}
