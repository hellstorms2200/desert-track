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

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.trip.name),
        actions: [
          PopupMenuButton(
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'gpx', child: Text('Export GPX')),
              const PopupMenuItem(value: 'kml', child: Text('Export KML')),
            ],
            onSelected: (value) {
              if (value == 'gpx') {
                ExportService.exportGPX(widget.trip, _points);
              } else {
                ExportService.exportKML(widget.trip, _points);
              }
            },
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
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
                      ),
                      if (latLngs.isNotEmpty)
                        PolylineLayer(polylines: [
                          Polyline(
                            points: latLngs,
                            color: Colors.orange,
                            strokeWidth: 4,
                          )
                        ]),
                      if (latLngs.isNotEmpty)
                        MarkerLayer(markers: [
                          Marker(
                            point: latLngs.first,
                            child: const Icon(Icons.flag,
                                color: Colors.green, size: 32),
                          ),
                          Marker(
                            point: latLngs.last,
                            child: const Icon(Icons.flag,
                                color: Colors.red, size: 32),
                          ),
                        ]),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _stat('Distance',
                          GeoUtils.formatDistance(widget.trip.totalDistance)),
                      _stat('Points', '${_points.length}'),
                      _stat('Duration', widget.trip.endTime != null
                          ? GeoUtils.formatDuration(widget.trip.endTime!
                              .difference(widget.trip.startTime))
                          : '--'),
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
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(fontSize: 12)),
    ],
  );
}
