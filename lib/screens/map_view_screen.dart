import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/trip.dart';
import '../models/track_point.dart';
import '../services/database_service.dart';
import '../services/export_service.dart';
import '../utils/geo_utils.dart';

class MapViewScreen extends StatefulWidget {
  final Trip trip;
  const MapViewScreen({super.key, required this.trip});
  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  List<TrackPoint> _points = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final points =
        await DatabaseService.instance.getTrackPoints(widget.trip.id!);
    setState(() {
      _points = points;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final latLngs =
        _points.map((p) => LatLng(p.latitude, p.longitude)).toList();
    final center = latLngs.isNotEmpty
        ? latLngs[latLngs.length ~/ 2]
        : const LatLng(24.0, 45.0);
    final duration = widget.trip.endTime != null
        ? GeoUtils.formatDuration(
            widget.trip.endTime!.difference(widget.trip.startTime))
        : '--';

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(widget.trip.name,
            style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          GestureDetector(
            onTap: () => _showExportMenu(context),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFD4870A),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                children: [
                  Text('EXPORT',
                      style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 1)),
                  SizedBox(width: 4),
                  Icon(Icons.open_in_new, color: Colors.black, size: 14),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFD4870A)))
          : Column(
              children: [
                Expanded(
                  child: FlutterMap(
                    options: MapOptions(
                        initialCenter: center, initialZoom: 13),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                        userAgentPackageName: 'com.deserttrack.app',
                      ),
                      if (latLngs.isNotEmpty) ...[
                        PolylineLayer(polylines: [
                          Polyline(
                            points: latLngs,
                            color: const Color(0xFFD4870A),
                            strokeWidth: 4,
                          )
                        ]),
                        MarkerLayer(markers: [
                          Marker(
                            point: latLngs.first,
                            child: const Icon(Icons.flag,
                                color: Color(0xFF4CAF50), size: 32),
                          ),
                          Marker(
                            point: latLngs.last,
                            child: const Icon(Icons.flag,
                                color: Color(0xFFCF6679), size: 32),
                          ),
                        ]),
                      ],
                    ],
                  ),
                ),
                Container(
                  color: const Color(0xFF1A1A1A),
                  padding: const EdgeInsets.symmetric(
                      vertical: 16, horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _stat('DISTANCE',
                          GeoUtils.formatDistance(widget.trip.totalDistance)),
                      _divider(),
                      _stat('DURATION', duration),
                      _divider(),
                      _stat('POINTS', '${_points.length} pts'),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _stat(String label, String value) => Column(
    children: [
      Text(label,
          style: const TextStyle(
              color: Colors.grey, fontSize: 10, letterSpacing: 2)),
      const SizedBox(height: 4),
      Text(value,
          style: const TextStyle(
              color: Color(0xFFD4870A),
              fontSize: 18,
              fontWeight: FontWeight.w900)),
    ],
  );

  Widget _divider() => Container(
      width: 1, height: 40, color: const Color(0xFF333333));

  void _showExportMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.map, color: Color(0xFFD4870A)),
            title: const Text('Export GPX',
                style: TextStyle(color: Colors.white,
                    fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.pop(context);
              ExportService.exportGPX(widget.trip, _points);
            },
          ),
          ListTile(
            leading: const Icon(Icons.layers, color: Color(0xFFD4870A)),
            title: const Text('Export KML',
                style: TextStyle(color: Colors.white,
                    fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.pop(context);
              ExportService.exportKML(widget.trip, _points);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
