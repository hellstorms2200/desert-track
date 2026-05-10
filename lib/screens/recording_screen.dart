import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/trip_provider.dart';
import '../utils/geo_utils.dart';

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});
  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionSub;
  final List<LatLng> _points = [];
  Position? _lastPosition;
  double _totalDistance = 0;
  Duration _elapsed = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTracking();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  void _startTracking() {
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
      ),
    ).listen((pos) {
      final point = LatLng(pos.latitude, pos.longitude);
      if (_lastPosition != null) {
        _totalDistance += GeoUtils.distanceMeters(
          _lastPosition!.latitude, _lastPosition!.longitude,
          pos.latitude, pos.longitude,
        );
      }
      _lastPosition = pos;
      setState(() => _points.add(point));
      _mapController.move(point, _mapController.camera.zoom);
      context.read<TripProvider>().addTrackPoint(pos, _totalDistance);
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pos = _lastPosition;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recording'),
        actions: [
          IconButton(
            icon: const Icon(Icons.stop),
            onPressed: () async {
              await context.read<TripProvider>().stopTrip();
              if (mounted) Navigator.pop(context);
            },
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _points.isNotEmpty
                    ? _points.last
                    : const LatLng(24.0, 45.0),
                initialZoom: 15,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                ),
                if (_points.isNotEmpty)
                  PolylineLayer(polylines: [
                    Polyline(
                      points: _points,
                      color: Colors.orange,
                      strokeWidth: 4,
                    )
                  ]),
                if (_points.isNotEmpty)
                  MarkerLayer(markers: [
                    Marker(
                      point: _points.last,
                      child: const Icon(Icons.my_location,
                          color: Colors.orange, size: 32),
                    )
                  ]),
              ],
            ),
          ),
          Container(
            color: Theme.of(context).colorScheme.surface,
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _stat('Distance',
                    GeoUtils.formatDistance(_totalDistance)),
                _stat('Speed',
                    pos != null ? GeoUtils.formatSpeed(pos.speed) : '0 km/h'),
                _stat('Time', GeoUtils.formatDuration(_elapsed)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) => Column(
    children: [
      Text(value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(fontSize: 12)),
    ],
  );
}
