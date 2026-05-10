import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/trip_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TripProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Desert Track')),
      body: provider.trips.isEmpty
          ? const Center(child: Text('No trips yet. Start tracking!'))
          : ListView.builder(
              itemCount: provider.trips.length,
              itemBuilder: (context, index) {
                final trip = provider.trips[index];
                return ListTile(
                  title: Text(trip.name),
                  subtitle: Text(trip.startTime.toLocal().toString()),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => provider.deleteTrip(trip.id!),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showStartDialog(context, provider),
        icon: const Icon(Icons.play_arrow),
        label: const Text('Start Trip'),
      ),
    );
  }

  void _showStartDialog(BuildContext context, TripProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Trip'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Trip name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                provider.startTrip(controller.text);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }
}
