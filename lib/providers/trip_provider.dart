import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/trip.dart';
import '../models/track_point.dart';
import '../services/database_service.dart';
import '../services/location_service.dart';

class TripProvider extends ChangeNotifier {
  List<Trip> _trips = [];
  Trip? _activeTrip;
  bool _isTracking = false;
  double _currentDistance = 0;
  Position? _lastPosition;

  List<Trip> get trips => _trips;
  Trip? get activeTrip => _activeTrip;
  bool get isTracking => _isTracking;

  Future<void> loadTrips() async {
    _trips = await DatabaseService.instance.getAllTrips();
    notifyListeners();
  }

  Future<bool> startRecording(String name) async {
    final trip = Trip(name: name, startTime: DateTime.now());
    final id = await DatabaseService.instance.insertTrip(trip);
    _activeTrip = trip.copyWith(id: id);
    _currentDistance = 0;
    _lastPosition = null;
    _isTracking = true;
    final started = await LocationService.instance.startTracking(_onPosition);
    notifyListeners();
    return started;
  }

  Future<void> startTrip(String name) async => startRecording(name);

  void _onPosition(Position pos) {
    if (_lastPosition != null) {
      _currentDistance += _distance(
        _lastPosition!.latitude, _lastPosition!.longitude,
        pos.latitude, pos.longitude,
      );
    }
    _lastPosition = pos;
    addTrackPoint(pos, _currentDistance);
    notifyListeners();
  }

  double _distance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  Future<void> addTrackPoint(Position pos, double totalDistance) async {
    if (_activeTrip == null) return;
    await DatabaseService.instance.insertTrackPoint(TrackPoint(
      tripId: _activeTrip!.id!,
      latitude: pos.latitude,
      longitude: pos.longitude,
      altitude: pos.altitude,
      speed: pos.speed,
      timestamp: DateTime.now(),
    ));
  }

  Future<void> stopTrip() async {
    if (_activeTrip == null) return;
    await LocationService.instance.stopTracking();
    final finished = _activeTrip!.copyWith(
      endTime: DateTime.now(),
      totalDistanceMeters: _currentDistance,
    );
    await DatabaseService.instance.updateTrip(finished);
    _activeTrip = null;
    _isTracking = false;
    await loadTrips();
  }

  Future<void> deleteTrip(int id) async {
    await DatabaseService.instance.deleteTrip(id);
    await loadTrips();
  }

  Future<void> renameTrip(int id, String newName) async {
    await DatabaseService.instance.renameTrip(id, newName);
    await loadTrips();
  }

  Future<Trip?> getTripWithDetails(int id) async {
    return DatabaseService.instance.getTripById(id);
  }
}
