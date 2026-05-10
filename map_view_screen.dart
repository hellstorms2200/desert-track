import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/trip.dart';
import '../providers/trip_provider.dart';
import '../services/export_service.dart';
import '../services/tile_cache_service.dart';
import '../utils/geo_utils.dart';

class MapViewScreen extends StatefulWidget {
  final int tripId;
  const MapViewScreen({super.key, required this.tripId});

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  final MapController _map = MapController();
  Trip? _trip;
  bool _loading = true;

  // Live location for follow-mode
  StreamSubscription<Position>? _posSub;
  double _liveLatitude = 0;
  double _liveLongitude = 0;
  double _liveDeviation = 0;
  bool _followMode = false;
  bool _showWaypoints = true;

  @override
  void initState() {
    super.initState();
    _loadTrip();
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _map.dispose();
    super.dispose();
  }

  Future<void> _loadTrip() async {
    final provider = context.read<TripProvider>();
    final trip = await provider.getTripWithDetails(widget.tripId);
    setState(() {
      _trip = trip;
      _loading = false;
    });
    if (trip != null && trip.trackPoints.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fitBounds();
      });
    }
  }

  void _fitBounds() {
    if (_trip == null || _trip!.trackPoints.isEmpty) return;
    final pts = _trip!.trackPoints
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();
    final bounds = LatLngBounds.fromPoints(pts);
    _map.fitCamera(CameraFit.bounds(
      bounds: bounds,
      padding: const EdgeInsets.all(40),
    ));
  }

  void _startFollowMode() async {
    final ok = await Geolocator.isLocationServiceEnabled();
    if (!ok || !mounted) return;
    setState(() => _followMode = true);
    _posSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high, distanceFilter: 5),
    ).listen((pos) {
      setState(() {
        _liveLatitude = pos.latitude;
        _liveLongitude = pos.longitude;
      });
      _map.move(LatLng(pos.latitude, pos.longitude),
          _map.camera.zoom);
      _updateDeviation(pos.latitude, pos.longitude);
    });
  }

  void _stopFollowMode() {
    _posSub?.cancel();
    _posSub = null;
    setState(() {
      _followMode = false;
      _liveDeviation = 0;
      _liveLatitude = 0;
      _liveLongitude = 0;
    });
  }

  void _updateDeviation(double lat, double lon) {
    if (_trip == null || _trip!.trackPoints.isEmpty) return;
    final track = _trip!.trackPoints
        .map((p) => (lat: p.latitude, lon: p.longitude))
        .toList();
    final nearest =
        GeoUtils.nearestPointIndex(lat, lon, track);
    if (nearest >= 0 && nearest < _trip!.trackPoints.length - 1) {
      final dev = GeoUtils.crossTrackDistance(
        lat, lon,
        _trip!.trackPoints[nearest].latitude,
        _trip!.trackPoints[nearest].longitude,
        _trip!.trackPoints[nearest + 1].latitude,
        _trip!.trackPoints[nearest + 1].longitude,
      );
      setState(() => _liveDeviation = dev);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_trip == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('خطأ')),
        body: const Center(child: Text('تعذر تحميل الرحلة')),
      );
    }

    final trackPoints = _trip!.trackPoints
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();

    return Scaffold(
      body: Stack(
        children: [
          // ── MAP ───────────────────────────────────────────────────────────
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: trackPoints.isNotEmpty
                  ? trackPoints[trackPoints.length ~/ 2]
                  : const LatLng(24.0, 45.0),
              initialZoom: 13,
            ),
            children: [
              TileLayer(
                urlTemplate: kSatelliteUrl,
                tileProvider: const CachedSatelliteTileProvider(),
                maxZoom: 19,
                userAgentPackageName: 'com.deserttrack.app',
              ),
              // Track
              if (trackPoints.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: trackPoints,
                      color: Colors.orangeAccent,
                      strokeWidth: 4,
                    ),
                  ],
                ),
              // Start / End markers
              if (trackPoints.isNotEmpty)
                MarkerLayer(
                  markers: [
                    _buildMarker(trackPoints.first,
                        Colors.green, Icons.flag),
                    _buildMarker(trackPoints.last,
                        Colors.red, Icons.flag_outlined),
                  ],
                ),
              // Waypoints
              if (_showWaypoints && _trip!.waypoints.isNotEmpty)
                MarkerLayer(
                  markers: _trip!.waypoints
                      .map((wp) => Marker(
                            point:
                                LatLng(wp.latitude, wp.longitude),
                            width: 80,
                            height: 60,
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: cs.primary,
                                    borderRadius:
                                        BorderRadius.circular(8),
                                  ),
                                  child: Text(wp.name,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10)),
                                ),
                                Icon(Icons.location_pin,
                                    color: cs.primary, size: 28),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              // Live position
              if (_followMode && _liveLatitude != 0)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(_liveLatitude, _liveLongitude),
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white, width: 3),
                        ),
                        child: const Icon(Icons.person,
                            color: Colors.white, size: 22),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // ── TOP BAR ────────────────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    _mapIconBtn(
                        icon: Icons.arrow_back,
                        onTap: () => Navigator.pop(context)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _trip!.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _mapIconBtn(
                        icon: Icons.share_outlined,
                        onTap: () => _showExportSheet(context)),
                    const SizedBox(width: 8),
                    _mapIconBtn(
                      icon: _showWaypoints
                          ? Icons.flag
                          : Icons.flag_outlined,
                      onTap: () => setState(
                          () => _showWaypoints = !_showWaypoints),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── OFF TRACK WARNING ──────────────────────────────────────────────
          if (_followMode && _liveDeviation > 100)
            Positioned(
              top: 100,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '⚠️ انحرفت عن المسار – ${GeoUtils.formatDistance(_liveDeviation)}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          // ── STATS STRIP ────────────────────────────────────────────────────
          Positioned(
            bottom: 90,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statChip(Icons.route,
                      _trip!.totalDistanceKm.toStringAsFixed(1) +
                          ' كم',
                      'المسافة'),
                  _statChip(Icons.timer,
                      GeoUtils.formatDuration(_trip!.duration),
                      'المدة'),
                  _statChip(
                      Icons.speed,
                      _trip!.avgSpeedKmh.toStringAsFixed(0) + ' كم/س',
                      'متوسط السرعة'),
                  _statChip(
                      Icons.location_on,
                      '${_trip!.trackPoints.length}',
                      'نقطة GPS'),
                ],
              ),
            ),
          ),

          // ── BOTTOM BUTTONS ──────────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Row(
                  children: [
                    FloatingActionButton(
                      heroTag: 'fit',
                      mini: true,
                      onPressed: _fitBounds,
                      child: const Icon(Icons.fit_screen),
                    ),
                    const SizedBox(width: 8),
                    FloatingActionButton(
                      heroTag: 'zoom+',
                      mini: true,
                      onPressed: () => _map.move(
                          _map.camera.center,
                          _map.camera.zoom + 1),
                      child: const Icon(Icons.add),
                    ),
                    const SizedBox(width: 8),
                    FloatingActionButton(
                      heroTag: 'zoom-',
                      mini: true,
                      onPressed: () => _map.move(
                          _map.camera.center,
                          _map.camera.zoom - 1),
                      child: const Icon(Icons.remove),
                    ),
                    const Spacer(),
                    // Follow / Stop follow
                    ElevatedButton.icon(
                      onPressed: _followMode
                          ? _stopFollowMode
                          : _startFollowMode,
                      icon: Icon(
                        _followMode
                            ? Icons.stop
                            : Icons.directions,
                        color: Colors.white,
                      ),
                      label: Text(
                        _followMode ? 'إيقاف التتبع' : 'اتباع المسار',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _followMode
                            ? Colors.grey.shade700
                            : Colors.blue.shade700,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Marker _buildMarker(LatLng point, Color color, IconData icon) =>
      Marker(
        point: point,
        width: 36,
        height: 36,
        child: Icon(icon, color: color, size: 36),
      );

  Widget _mapIconBtn(
          {required IconData icon, required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      );

  Widget _statChip(IconData icon, String value, String label) =>
      Column(
        children: [
          Icon(icon, color: Colors.orangeAccent, size: 18),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
          Text(label,
              style: const TextStyle(
                  color: Colors.white54, fontSize: 10)),
        ],
      );

  void _showExportSheet(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      builder: (_) => _ExportSheet(
        trip: _trip!,
        onExport: (fmt) => _export(ctx, fmt),
      ),
    );
  }

  Future<void> _export(BuildContext ctx, String format) async {
    Navigator.pop(ctx);
    try {
      late String path;
      if (format == 'gpx') {
        path = await ExportService.exportGpx(_trip!);
      } else {
        path = await ExportService.exportKml(_trip!);
      }
      await Share.shareXFiles(
        [XFile(path)],
        text: 'مسار رحلة: ${_trip!.name}',
      );
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    }
  }
}

class _ExportSheet extends StatelessWidget {
  final Trip trip;
  final void Function(String fmt) onExport;
  const _ExportSheet({required this.trip, required this.onExport});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('تصدير: ${trip.name}',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.map_outlined, color: Colors.blue),
            title: const Text('تصدير كـ GPX'),
            subtitle: const Text('متوافق مع Google Earth, OsmAnd, …'),
            onTap: () => onExport('gpx'),
          ),
          ListTile(
            leading: const Icon(Icons.public, color: Colors.green),
            title: const Text('تصدير كـ KML'),
            subtitle:
                const Text('متوافق مع Google Maps, Google Earth'),
            onTap: () => onExport('kml'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
