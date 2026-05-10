import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/trip_provider.dart';
import '../services/location_service.dart';
import 'recording_screen.dart';
import 'trips_list_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TripProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Desert Track 🏜️')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.terrain, size: 100, color: Colors.orange),
              const SizedBox(height: 32),
              if (!provider.isTracking) ...[
                FilledButton.icon(
                  onPressed: () => _startTrip(context, provider),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start New Trip'),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const TripsListScreen())),
                  icon: const Icon(Icons.history),
                  label: const Text('My Trips'),
                ),
              ] else ...[
                FilledButton.icon(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const RecordingScreen())),
                  icon: const Icon(Icons.gps_fixed),
                  label: Text('Recording: ${provider.activeTrip?.name}'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startTrip(BuildContext context, TripProvider provider) async {
    final hasPermission =
        await LocationService.instance.requestPermission();
    if (!hasPermission) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission required')),
        );
      }
      return;
    }
    if (!context.mounted) return;
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Trip Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'e.g. Desert Run 1'),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await provider.startTrip(controller.text);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  Navigator.push(context, MaterialPageRoute(
                      builder: (_) => const RecordingScreen()));
                }
              }
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }
}
