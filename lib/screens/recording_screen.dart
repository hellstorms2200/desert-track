import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/trip_provider.dart';
import '../services/tile_cache_service.dart';
import '../utils/geo_utils.dart';

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});
  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
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
    _timer = Timer.periodic(const Duration(seconds: 1),
        (_) => setState(() => _elapsed += const Duration(seconds: 1)));
  }

  void _onPosition(Position pos) {
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
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pos = _currentPosition;
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        title: const Text('RECORDING',
            style: TextStyle(letterSpacing: 3, fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            icon: Icon(
                _followUser ? Icons.gps_fixed : Icons.gps_not_fixed,
                color: const Color(0xFFD4870A)),
            onPressed: () => setState(() => _followUser = !_followUser),
          ),
          IconButton(
            icon: const Icon(Icons.stop, color: Color(0xFFCF6679)),
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
                onMapEvent: (e) {
                  if (e is MapEventMove && e.source != MapEventSource.mapController) {
                    setState(() => _followUser = false);
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: kSatelliteUrl,
                  userAgentPackageName: 'com.deserttrack.app',
                ),
                if (_points.isNotEmpty)
                  PolylineLayer(polylines: [
                    Polyline(
                        points: _points,
                        color: const Color(0xFFD4870A),
                        strokeWidth: 4)
                  ]),
                if (_points.isNotEmpty)
                  MarkerLayer(markers: [
                    Marker(
                      point: _points.first,
                      child: const Icon(Icons.flag,
                          color: Color(0xFF4CAF50), size: 28),
                    ),
                    Marker(
                      point: _points.last,
                      child: ScaleTransition(
                        scale: _pulseAnimation,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4870A),
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFD4870A)
                                    .withOpacity(0.5),
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
          Container(
            color: const Color(0xFF1A1A1A),
            padding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _stat(Icons.straighten, 'DISTANCE',
                    GeoUtils.formatDistance(_totalDistance)),
                _stat(Icons.speed, 'SPEED',
                    pos != null
                        ? GeoUtils.formatSpeed(pos.speed)
                        : '0 km/h'),
                _stat(Icons.timer, 'TIME',
                    GeoUtils.formatDuration(_elapsed)),
                _stat(Icons.terrain, 'ALT',
                    pos != null
                        ? '${pos.altitude.toStringAsFixed(0)} m'
                        : '-- m'),
              ],
            ),
          ),
          if (pos != null && pos.heading >= 0)
            Container(
              color: const Color(0xFF111111),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform.rotate(
                    angle: pos.heading * 3.14159 / 180,
                    child: const Icon(Icons.navigation,
                        color: Color(0xFFD4870A), size: 24),
                  ),
                  const SizedBox(width: 8),
                  Text(_bearingLabel(pos.heading),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(width: 4),
                  Text('${pos.heading.toStringAsFixed(0)}°',
                      style: const TextStyle(
                          color: Color(0xFFD4870A), fontSize: 14)),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: !_followUser
          ? FloatingActionButton.small(
              backgroundColor: const Color(0xFFD4870A),
              onPressed: () {
                if (_points.isNotEmpty) {
                  _mapController.move(_points.last, 16);
                  setState(() => _followUser = true);
                }
              },
              child: const Icon(Icons.my_location, color: Colors.black),
            )
          : null,
    );
  }

  String _bearingLabel(double h) {
    const l = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    return l[(h / 45).round() % 8];
  }

  Widget _stat(IconData icon, String label, String value) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFFD4870A)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900)),
          Text(label,
              style: const TextStyle(color: Colors.grey, fontSize: 9)),
        ],
      );
}
