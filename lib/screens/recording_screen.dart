import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/trip.dart';
import '../providers/trip_provider.dart';
import '../services/tile_cache_service.dart';
import '../utils/geo_utils.dart';
import 'map_view_screen.dart';

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  final MapController _mapCtrl = MapController();
  bool _followUser = true;
  bool _showStats = true;

  @override
  void dispose() {
    _mapCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return WillPopScope(
      onWillPop: () async => _confirmStop(context),
      child: Scaffold(
        body: Consumer<TripProvider>(
          builder: (_, provider, __) {
            final points = provider.livePoints
                .map((p) => LatLng(p.latitude, p.longitude))
                .toList();

            // Auto-follow user position
            if (_followUser &&
                provider.currentLat != 0 &&
                provider.currentLon != 0) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                try {
                  _mapCtrl.move(
                    LatLng(provider.currentLat, provider.currentLon),
                    _mapCtrl.camera.zoom,
                  );
                } catch (_) {}
              });
            }

            return Stack(
              children: [
                // ── MAP ─────────────────────────────────────────────────────
                FlutterMap(
                  mapController: _mapCtrl,
                  options: MapOptions(
                    initialCenter: provider.currentLat != 0
                        ? LatLng(
                            provider.currentLat, provider.currentLon)
                        : const LatLng(24.0, 45.0),
                    initialZoom: 15,
                    onMapEvent: (event) {
                      if (event is MapEventMove &&
                          event.source ==
                              MapEventSource.dragStart) {
                        setState(() => _followUser = false);
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: kSatelliteUrl,
                      tileProvider:
                          const CachedSatelliteTileProvider(),
                      maxZoom: 19,
                      userAgentPackageName: 'com.deserttrack.app',
                    ),
                    // Track polyline
                    if (points.length > 1)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: points,
                            color: Colors.orangeAccent,
                            strokeWidth: 4,
                          ),
                        ],
                      ),
                    // Current position marker
                    if (provider.currentLat != 0)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(
                                provider.currentLat,
                                provider.currentLon),
                            width: 48,
                            height: 48,
                            child: Transform.rotate(
                              angle: provider.currentBearing *
                                  3.14159 /
                                  180,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: cs.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white,
                                      width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black
                                          .withOpacity(0.4),
                                      blurRadius: 6,
                                    )
                                  ],
                                ),
                                child: const Icon(
                                    Icons.navigation,
                                    color: Colors.white,
                                    size: 24),
                              ),
                            ),
                          ),
                        ],
                      ),
                    // Follow track (if active)
                    if (provider.isFollowing)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: provider.followTrip!.trackPoints
                                .map((p) =>
                                    LatLng(p.latitude, p.longitude))
                                .toList(),
                            color: Colors.cyanAccent.withOpacity(0.7),
                            strokeWidth: 3,
                            isDotted: true,
                          ),
                        ],
                      ),
                  ],
                ),

                // ── TOP BAR ──────────────────────────────────────────────────
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          _glassCard(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.fiber_manual_record,
                                    color: Colors.red, size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  provider.currentTrip?.name ?? '',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          // Add waypoint
                          _mapIconBtn(
                            icon: Icons.flag,
                            onTap: () => _addWaypoint(context, provider),
                          ),
                          const SizedBox(width: 8),
                          // Toggle stats
                          _mapIconBtn(
                            icon: Icons.bar_chart,
                            onTap: () =>
                                setState(() => _showStats = !_showStats),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── OFF-TRACK WARNING ─────────────────────────────────────────
                if (provider.isFollowing && provider.isOffTrack)
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
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber,
                              color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            '⚠️ انحراف: ${GeoUtils.formatDistance(provider.deviationMeters)}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),

                // ── STATS PANEL ───────────────────────────────────────────────
                if (_showStats)
                  Positioned(
                    bottom: 120,
                    left: 12,
                    right: 12,
                    child: _StatsPanel(provider: provider),
                  ),

                // ── BOTTOM BUTTONS ────────────────────────────────────────────
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          // Re-center
                          FloatingActionButton(
                            heroTag: 'recenter',
                            mini: true,
                            onPressed: () {
                              setState(() => _followUser = true);
                              if (provider.currentLat != 0) {
                                _mapCtrl.move(
                                  LatLng(provider.currentLat,
                                      provider.currentLon),
                                  15,
                                );
                              }
                            },
                            child: Icon(_followUser
                                ? Icons.my_location
                                : Icons.location_searching),
                          ),
                          const SizedBox(width: 12),
                          // Zoom in/out
                          FloatingActionButton(
                            heroTag: 'zoomin',
                            mini: true,
                            onPressed: () => _mapCtrl.move(
                                _mapCtrl.camera.center,
                                _mapCtrl.camera.zoom + 1),
                            child: const Icon(Icons.add),
                          ),
                          const SizedBox(width: 8),
                          FloatingActionButton(
                            heroTag: 'zoomout',
                            mini: true,
                            onPressed: () => _mapCtrl.move(
                                _mapCtrl.camera.center,
                                _mapCtrl.camera.zoom - 1),
                            child: const Icon(Icons.remove),
                          ),
                          const Spacer(),
                          // STOP button
                          ElevatedButton.icon(
                            onPressed: () => _stopRecording(context),
                            icon: const Icon(Icons.stop_circle,
                                color: Colors.white),
                            label: const Text('إيقاف وحفظ',
                                style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade700,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(16)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _glassCard({required Widget child}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: child,
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

  void _addWaypoint(BuildContext ctx, TripProvider provider) {
    final ctrl = TextEditingController(
        text: 'نقطة ${provider.livePoints.length + 1}');
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('إضافة نقطة مرجعية'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
              labelText: 'اسم النقطة',
              border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              provider.addWaypoint(ctrl.text.trim());
              Navigator.pop(ctx);
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('✅ تمت إضافة النقطة')),
              );
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _stopRecording(BuildContext ctx) async {
    final confirm = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('إيقاف الرحلة؟'),
        content: const Text('سيتم حفظ الرحلة محلياً على جهازك.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('متابعة التسجيل')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700),
            child: const Text('إيقاف وحفظ'),
          ),
        ],
      ),
    );
    if (confirm != true || !ctx.mounted) return;

    final provider = ctx.read<TripProvider>();
    final saved = await provider.stopRecording();
    if (!ctx.mounted) return;

    Navigator.pushReplacement(
      ctx,
      MaterialPageRoute(
        builder: (_) => saved != null
            ? MapViewScreen(tripId: saved.id!)
            : const Scaffold(
                body: Center(child: Text('تم الحفظ'))),
      ),
    );
  }

  Future<bool> _confirmStop(BuildContext ctx) async {
    final confirm = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('الخروج من التسجيل؟'),
        content: const Text('الرحلة لا تزال قيد التسجيل.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('البقاء')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('خروج دون حفظ',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    return confirm ?? false;
  }
}

// ── Stats Panel ───────────────────────────────────────────────────────────────

class _StatsPanel extends StatelessWidget {
  final TripProvider provider;
  const _StatsPanel({required this.provider});

  @override
  Widget build(BuildContext context) {
    final duration = provider.currentTrip != null
        ? DateTime.now()
            .difference(provider.currentTrip!.startTime)
        : Duration.zero;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.75),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _stat(Icons.speed,
              GeoUtils.formatSpeed(provider.currentSpeedKmh), 'السرعة'),
          _stat(
              Icons.route,
              GeoUtils.formatDistance(
                  provider.totalDistanceMeters),
              'المسافة'),
          _stat(Icons.timer,
              GeoUtils.formatDuration(duration), 'المدة'),
          _stat(
              Icons.location_on,
              '${provider.livePoints.length}',
              'نقاط GPS'),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String value, String label) => Column(
        children: [
          Icon(icon, color: Colors.orangeAccent, size: 20),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      );
}
