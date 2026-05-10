import 'package:flutter/foundation.dart';
import '../models/trip.dart';
import '../services/database_service.dart';

class TripProvider extends ChangeNotifier {
  List<Trip> _trips = [];
  Trip? _activeTrip;
  bool _isTracking = false;

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
    _activeTrip = Trip(
      id: id,
      name: name,
      startTime: trip.startTime,
    );
    _isTracking = true;
    notifyListeners();
  }

  Future<void> stopTrip() async {
    if (_activeTrip == null) return;
    final finished = Trip(
      id: _activeTrip!.id,
      name: _activeTrip!.name,
      startTime: _activeTrip!.startTime,
      endTime: DateTime.now(),
      totalDistance: _activeTrip!.totalDistance,
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
