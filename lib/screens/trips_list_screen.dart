import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/trip.dart';
import '../providers/trip_provider.dart';
import '../services/export_service.dart';
import '../utils/geo_utils.dart';
import 'map_view_screen.dart';

class TripsListScreen extends StatelessWidget {
  const TripsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('رحلاتي'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<TripProvider>().loadTrips(),
          ),
        ],
      ),
      body: Consumer<TripProvider>(
        builder: (_, provider, __) {
          if (provider.trips.isEmpty) {
            return const _EmptyState();
          }
          return RefreshIndicator(
            onRefresh: provider.loadTrips,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: provider.trips.length,
              itemBuilder: (ctx, i) =>
                  _TripCard(trip: provider.trips[i]),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _TripCard extends StatelessWidget {
  final Trip trip;
  const _TripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dateStr = DateFormat('dd/MM/yyyy – HH:mm').format(trip.startTime);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => MapViewScreen(tripId: trip.id!)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Trip name + status ─────────────────────────────────────────
              Row(
                children: [
                  Icon(
                    trip.isCompleted ? Icons.check_circle : Icons.pending,
                    color: trip.isCompleted ? Colors.green : Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      trip.name,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Options menu
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (v) =>
                        _handleMenu(context, v, trip),
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                          value: 'view',
                          child: ListTile(
                              leading: Icon(Icons.map),
                              title: Text('عرض على الخريطة'))),
                      const PopupMenuItem(
                          value: 'rename',
                          child: ListTile(
                              leading: Icon(Icons.edit),
                              title: Text('إعادة تسمية'))),
                      const PopupMenuItem(
                          value: 'gpx',
                          child: ListTile(
                              leading: Icon(Icons.download),
                              title: Text('تصدير GPX'))),
                      const PopupMenuItem(
                          value: 'kml',
                          child: ListTile(
                              leading: Icon(Icons.download),
                              title: Text('تصدير KML'))),
                      const PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                              leading: Icon(Icons.delete,
                                  color: Colors.red),
                              title: Text('حذف',
                                  style: TextStyle(
                                      color: Colors.red)))),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // ── Date ────────────────────────────────────────────────────────
              Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 14, color: cs.outline),
                  const SizedBox(width: 4),
                  Text(dateStr,
                      style: TextStyle(
                          fontSize: 12, color: cs.outline)),
                ],
              ),

              const SizedBox(height: 10),

              // ── Stats chips ─────────────────────────────────────────────────
              Row(
                children: [
                  _chip(Icons.route,
                      '${trip.totalDistanceKm.toStringAsFixed(1)} كم',
                      cs),
                  const SizedBox(width: 8),
                  _chip(Icons.timer,
                      GeoUtils.formatDuration(trip.duration), cs),
                  const SizedBox(width: 8),
                  _chip(
                      Icons.speed,
                      '${trip.avgSpeedKmh.toStringAsFixed(0)} كم/س',
                      cs),
                ],
              ),

              // ── Follow button ───────────────────────────────────────────────
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                MapViewScreen(tripId: trip.id!)),
                      ),
                      icon: const Icon(Icons.map_outlined, size: 18),
                      label: const Text('عرض الخريطة'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MapViewScreen(
                              tripId: trip.id!),
                        ),
                      ),
                      icon: const Icon(Icons.directions, size: 18),
                      label: const Text('اتباع المسار'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, ColorScheme cs) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: cs.secondaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: cs.onSecondaryContainer),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: cs.onSecondaryContainer,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );

  Future<void> _handleMenu(
      BuildContext ctx, String action, Trip trip) async {
    final provider = ctx.read<TripProvider>();

    switch (action) {
      case 'view':
        Navigator.push(ctx,
            MaterialPageRoute(
                builder: (_) => MapViewScreen(tripId: trip.id!)));
        break;

      case 'rename':
        final ctrl = TextEditingController(text: trip.name);
        await showDialog(
          context: ctx,
          builder: (_) => AlertDialog(
            title: const Text('إعادة تسمية'),
            content: TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                  border: OutlineInputBorder()),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('إلغاء')),
              FilledButton(
                onPressed: () {
                  final n = ctrl.text.trim();
                  if (n.isNotEmpty) {
                    provider.renameTrip(trip.id!, n);
                  }
                  Navigator.pop(ctx);
                },
                child: const Text('حفظ'),
              ),
            ],
          ),
        );
        break;

      case 'gpx':
      case 'kml':
        try {
          final full =
              await provider.getTripWithDetails(trip.id!);
          if (full == null) return;
          late String path;
          if (action == 'gpx') {
            path = await ExportService.exportGpx(full);
          } else {
            path = await ExportService.exportKml(full);
          }
          await Share.shareXFiles(
            [XFile(path)],
            text: 'مسار: ${trip.name}',
          );
        } catch (e) {
          if (ctx.mounted) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(content: Text('خطأ: $e')),
            );
          }
        }
        break;

      case 'delete':
        final ok = await showDialog<bool>(
          context: ctx,
          builder: (_) => AlertDialog(
            title: const Text('حذف الرحلة'),
            content: Text('هل تريد حذف "${trip.name}" نهائياً؟'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('إلغاء')),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                    backgroundColor: Colors.red),
                child: const Text('حذف'),
              ),
            ],
          ),
        );
        if (ok == true) await provider.deleteTrip(trip.id!);
        break;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.explore_off, size: 80, color: cs.outline),
          const SizedBox(height: 16),
          Text('لا توجد رحلات محفوظة',
              style: TextStyle(fontSize: 18, color: cs.outline)),
          const SizedBox(height: 8),
          Text('ابدأ رحلة جديدة من الشاشة الرئيسية',
              style: TextStyle(color: cs.outline)),
        ],
      ),
    );
  }
}
