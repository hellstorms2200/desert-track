import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/trip.dart';
import '../models/track_point.dart';
import '../services/database_service.dart';

class TripProvider extends ChangeNotifier {
  List<Trip> _trips = [];
  Trip? _activeTrip;
  bool _isTracking = false;
  double _currentDistance = 0;

  List<Trip> get trips => _trips;
  Trip? get activeTrip => _activeTrip;
  bool get isTracking => _isTracking;

  Future<void> loadTrips() async {
    _trips = await DatabaseService.instance.getTrips();
    notifyListeners();
  }

  Future<void> startTrip(String name) async {
    final trip = Trip(name: name, startTime: DateTime.now());
    final id = await DatabaseService.instance.insertTrip(trip);
    _activeTrip = Trip(id: id, name: name, startTime: trip.startTime);
    _isTracking = true;
    _currentDistance = 0;
    notifyListeners();
  }

  Future<void> addTrackPoint(Position pos, double totalDistance) async {
    if (_activeTrip == null) return;
    _currentDistance = totalDistance;
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
    final finished = Trip(
      id: _activeTrip!.id,
      name: _activeTrip!.name,
      startTime: _activeTrip!.startTime,
      endTime: DateTime.now(),
      totalDistance: _currentDistance,
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
}
