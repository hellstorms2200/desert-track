import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/track_point.dart';
import '../models/trip.dart';
import '../services/database_service.dart';
import '../services/location_service.dart';
import '../utils/geo_utils.dart';

enum RecordingState { idle, recording, paused }

class TripProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  final LocationService _loc = LocationService.instance;

  // ── Recording state ────────────────────────────────────────────────────────
  RecordingState _state = RecordingState.idle;
  RecordingState get state => _state;
  bool get isRecording => _state == RecordingState.recording;

  Trip? _currentTrip;
  Trip? get currentTrip => _currentTrip;

  final List<TrackPoint> _livePoints = [];
  List<TrackPoint> get livePoints => List.unmodifiable(_livePoints);

  double _currentLat = 0;
  double _currentLon = 0;
  double _currentSpeed = 0;
  double _currentBearing = 0;
  double get currentLat => _currentLat;
  double get currentLon => _currentLon;
  double get currentSpeedKmh => _currentSpeed * 3.6;
  double get currentBearing => _currentBearing;

  double _totalDistance = 0;
  double get totalDistanceMeters => _totalDistance;

  // ── Follow-track state ─────────────────────────────────────────────────────
  Trip? _followTrip;
  Trip? get followTrip => _followTrip;
  bool get isFollowing => _followTrip != null;

  int _followIndex = 0;
  double _deviationMeters = 0;
  double get deviationMeters => _deviationMeters;
  bool get isOffTrack => _deviationMeters > 100;

  // ── Trips list ─────────────────────────────────────────────────────────────
  List<Trip> _trips = [];
  List<Trip> get trips => List.unmodifiable(_trips);

  // ── Pending batch insert ───────────────────────────────────────────────────
  final List<TrackPoint> _pendingPoints = [];
  Timer? _batchTimer;

  // ── Init ───────────────────────────────────────────────────────────────────

  Future<void> loadTrips() async {
    _trips = await _db.getAllTrips();
    notifyListeners();
  }

  // ── Recording ──────────────────────────────────────────────────────────────

  Future<bool> startRecording(String tripName) async {
    if (_state == RecordingState.recording) return false;

    final startTime = DateTime.now();
    final tripId = await _db.insertTrip(Trip(
      name: tripName,
      startTime: startTime,
    ));

    _currentTrip = Trip(
      id: tripId,
      name: tripName,
      startTime: startTime,
    );
    _livePoints.clear();
    _totalDistance = 0;
    _state = RecordingState.recording;
    notifyListeners();

    final started = await _loc.startTracking(_onPositionData);
    if (!started) {
      _state = RecordingState.idle;
      notifyListeners();
      return false;
    }

    _batchTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _flushPoints();
    });

    return true;
  }

  Future<Trip?> stopRecording() async {
    if (_state == RecordingState.idle) return null;

    await _loc.stopTracking();
    _batchTimer?.cancel();
    await _flushPoints();

    final endTime = DateTime.now();
    final saved = _currentTrip!.copyWith(
      endTime: endTime,
      totalDistanceMeters: _totalDistance,
      trackPoints: List.from(_livePoints),
    );

    await _db.updateTrip(saved);
    _state = RecordingState.idle;
    _currentTrip = null;
    _livePoints.clear();
    _totalDistance = 0;

    await loadTrips();
    return saved;
  }

  void _onPositionData(Map<String, dynamic> data) {
    final lat = (data['lat'] as num).toDouble();
    final lon = (data['lon'] as num).toDouble();
    final speed = (data['speed'] as num?)?.toDouble() ?? 0.0;
    final bearing = (data['bearing'] as num?)?.toDouble() ?? 0.0;
    final alt = (data['alt'] as num?)?.toDouble() ?? 0.0;
    final ts = DateTime.tryParse(data['ts'] as String? ?? '') ?? DateTime.now();

    _currentLat = lat;
    _currentLon = lon;
    _currentSpeed = speed;
    _currentBearing = bearing;

    if (_livePoints.isNotEmpty) {
      final last = _livePoints.last;
      final dist = GeoUtils.distanceMeters(
          last.latitude, last.longitude, lat, lon);
      if (dist < 2) return; // Filter micro-jitter
      _totalDistance += dist;
    }

    final point = TrackPoint(
      tripId: _currentTrip!.id!,
      latitude: lat,
      longitude: lon,
      altitude: alt,
      speed: speed,
      bearing: bearing,
      timestamp: ts,
    );
    _livePoints.add(point);
    _pendingPoints.add(point);

    // Follow track deviation check
    if (isFollowing) _checkDeviation(lat, lon);

    notifyListeners();
  }

  Future<void> _flushPoints() async {
    if (_pendingPoints.isEmpty) return;
    final toSave = List<TrackPoint>.from(_pendingPoints);
    _pendingPoints.clear();
    await _db.insertTrackPoints(toSave);
  }

  // ── Waypoints ──────────────────────────────────────────────────────────────

  Future<void> addWaypoint(String name) async {
    if (_currentTrip?.id == null) return;
    final wp = Waypoint(
      tripId: _currentTrip!.id!,
      latitude: _currentLat,
      longitude: _currentLon,
      name: name,
      timestamp: DateTime.now(),
    );
    await _db.insertWaypoint(wp);
    notifyListeners();
  }

  // ── Follow Track ───────────────────────────────────────────────────────────

  Future<void> startFollowing(Trip trip) async {
    _followTrip = await _db.getTripById(trip.id!);
    _followIndex = 0;
    _deviationMeters = 0;
    notifyListeners();
  }

  void stopFollowing() {
    _followTrip = null;
    _deviationMeters = 0;
    notifyListeners();
  }

  void _checkDeviation(double lat, double lon) {
    final pts = _followTrip!.trackPoints;
    if (pts.isEmpty) return;
    final track = pts
        .map((p) => (lat: p.latitude, lon: p.longitude))
        .toList();
    final nearest = GeoUtils.nearestPointIndex(lat, lon, track);
    _followIndex = nearest;
    if (nearest < pts.length - 1) {
      _deviationMeters = GeoUtils.crossTrackDistance(
        lat, lon,
        pts[nearest].latitude, pts[nearest].longitude,
        pts[nearest + 1].latitude, pts[nearest + 1].longitude,
      );
    } else {
      _deviationMeters = GeoUtils.distanceMeters(
          lat, lon, pts[nearest].latitude, pts[nearest].longitude);
    }
  }

  // ── Trip management ────────────────────────────────────────────────────────

  Future<Trip?> getTripWithDetails(int id) => _db.getTripById(id);

  Future<void> deleteTrip(int id) async {
    await _db.deleteTrip(id);
    _trips.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  Future<void> renameTrip(int id, String name) async {
    await _db.renameTrip(id, name);
    final idx = _trips.indexWhere((t) => t.id == id);
    if (idx != -1) {
      _trips[idx] = _trips[idx].copyWith(name: name);
      notifyListeners();
    }
  }
}
