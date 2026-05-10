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
      appBar: AppBar(title: const Text('My Trips')),
      body: provider.trips.isEmpty
          ? const Center(child: Text('No trips yet.'))
          : ListView.builder(
              itemCount: provider.trips.length,
              itemBuilder: (context, index) {
                final trip = provider.trips[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: const Icon(Icons.route, color: Colors.orange),
                    title: Text(trip.name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      '${GeoUtils.formatDistance(trip.totalDistance)} • '
                      '${trip.startTime.toLocal().toString().substring(0, 16)}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => provider.deleteTrip(trip.id!),
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MapViewScreen(trip: trip),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
