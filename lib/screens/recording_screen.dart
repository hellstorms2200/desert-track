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

class _RecordingScreenState extends State<RecordingScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionSub;
  final List<LatLng> _points = [];
  Position? _currentPosition;
  double _totalDistance = 0;
  Duration _elapsed = Duration.zero;
  Timer? _timer;
  bool _followUser = true;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulseAnimation = Tween(begin: 0.8, end: 1.2).animate(_pulseController);

    _startTracking();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  void _startTracking() {
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 3,
      ),
    ).listen((pos) {
      final point = LatLng(pos.latitude, pos.longitude);
      if (_currentPosition != null) {
        _totalDistance += GeoUtils.distanceMeters(
          _currentPosition!.latitude, _currentPosition!.longitude,
          pos.latitude, pos.longitude,
        );
      }
      setState(() {
        _currentPosition = pos;
        _points.add(point);
      });
      if (_followUser) {
        _mapController.move(point, _mapController.camera.zoom);
      }
      context.read<TripProvider>().addTrackPoint(pos, _totalDistance);
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pos = _currentPosition;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recording'),
        actions: [
          IconButton(
            icon: Icon(_followUser ? Icons.gps_fixed : Icons.gps_not_fixed),
            onPressed: () => setState(() => _followUser = !_followUser),
          ),
          IconButton(
            icon: const Icon(Icons.stop, color: Colors.red),
            onPressed: () async {
              await context.read<TripProvider>().stopTrip();
              if (mounted) Navigator.pop(context);
            },
          ),
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
                initialZoom: 16,
                onMapEvent: (event) {
                  if (event is MapEventMove) {
                    setState(() => _followUser = false);
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                  userAgentPackageName: 'com.deserttrack.app',
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
                      point: _points.first,
                      child: const Icon(Icons.flag,
                          color: Colors.green, size: 28),
                    ),
                    Marker(
                      point: _points.last,
                      child: ScaleTransition(
                        scale: _pulseAnimation,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.5),
                                blurRadius: 10,
                                spreadRadius: 4,
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ]),
              ],
            ),
          ),

          // Stats bar
          Container(
            color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _stat(Icons.straighten, 'Distance',
                    GeoUtils.formatDistance(_totalDistance)),
                _stat(Icons.speed, 'Speed',
                    pos != null ? GeoUtils.formatSpeed(pos.speed) : '0 km/h'),
                _stat(Icons.timer, 'Time',
                    GeoUtils.formatDuration(_elapsed)),
                _stat(Icons.terrain, 'Alt',
                    pos != null ? '${pos.altitude.toStringAsFixed(0)} m' : '-- m'),
              ],
            ),
          ),

          // Compass + bearing
          if (pos != null && pos.heading >= 0)
            Container(
              color: isDark ? const Color(0xFF111111) : const Color(0xFFF5F5F5),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform.rotate(
                    angle: pos.heading * 3.14159 / 180,
                    child: const Icon(Icons.navigation,
                        color: Colors.orange, size: 28),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _bearingLabel(pos.heading),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${pos.heading.toStringAsFixed(0)}°',
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange.shade700),
                  ),
                ],
              ),
            ),
        ],
      ),

      floatingActionButton: _followUser
          ? null
          : FloatingActionButton.small(
              onPressed: () {
                if (_points.isNotEmpty) {
                  _mapController.move(_points.last, 16);
                  setState(() => _followUser = true);
                }
              },
              child: const Icon(Icons.my_location),
            ),
    );
  }

  String _bearingLabel(double heading) {
    const labels = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW', 'N'];
    return labels[(heading / 45).round() % 8];
  }

  Widget _stat(IconData icon, String label, String value) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: Colors.orange),
      const SizedBox(height: 2),
      Text(value,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.bold)),
      Text(label,
          style: const TextStyle(fontSize: 10, color: Colors.grey)),
    ],
  );
}
