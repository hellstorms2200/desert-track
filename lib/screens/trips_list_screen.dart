import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/trip_provider.dart';
import '../utils/geo_utils.dart';
import 'map_view_screen.dart';

class TripsListScreen extends StatelessWidget {
  const TripsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TripProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        foregroundColor: Colors.white,
        title: const Text('MY TRIPS',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 3, fontSize: 18)),
        elevation: 0,
      ),
      body: provider.trips.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.route, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('NO TRIPS YET',
                      style: TextStyle(color: Colors.grey, letterSpacing: 3, fontWeight: FontWeight.bold)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: provider.trips.length,
              itemBuilder: (context, index) {
                final trip = provider.trips[index];
                final duration = trip.endTime != null
                    ? GeoUtils.formatDuration(trip.endTime!.difference(trip.startTime))
                    : '--';
                final d = trip.startTime.toLocal();
                final dateStr = '${d.day} ${_month(d.month)} ${d.year}';
                return Dismissible(
                  key: Key(trip.id.toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    color: const Color(0xFFCF6679),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => provider.deleteTrip(trip.id!),
                  child: GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => MapViewScreen(trip: trip))),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(8),
                        border: const Border(left: BorderSide(color: Color(0xFFD4870A), width: 4)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(trip.name,
                                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                                const Icon(Icons.arrow_forward_ios, color: Color(0xFFD4870A), size: 16),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(children: [
                              _tripStat('DISTANCE', GeoUtils.formatDistance(trip.totalDistanceMeters)),
                              const SizedBox(width: 24),
                              _tripStat('DURATION', duration),
                              const SizedBox(width: 24),
                              _tripStat('DATE', dateStr),
                            ]),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _tripStat(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 9, letterSpacing: 1.5)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(color: Color(0xFFD4870A), fontSize: 14, fontWeight: FontWeight.w800)),
        ],
      );

  String _month(int m) =>
      ['', 'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'][m];
}
