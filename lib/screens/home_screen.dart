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
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFD4870A), width: 2),
                  color: const Color(0xFF1A1A1A),
                ),
                child: const Icon(Icons.explore, size: 72, color: Color(0xFFD4870A)),
              ),
              const SizedBox(height: 16),
              const Text('DESERT TRACK',
                  style: TextStyle(
                      color: Color(0xFFD4870A),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4)),
              const SizedBox(height: 8),
              const Text('OFF-ROAD GPS NAVIGATOR',
                  style: TextStyle(color: Colors.grey, fontSize: 11, letterSpacing: 3)),
              const Spacer(),
              SizedBox(
                width: double.infinity, height: 64,
                child: ElevatedButton(
                  onPressed: () => _startTrip(context, provider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4870A),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('START TRIP',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 3)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity, height: 56,
                child: OutlinedButton(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const TripsListScreen())),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFD4870A),
                    side: const BorderSide(color: Color(0xFFD4870A), width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('MY TRIPS',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 3)),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startTrip(BuildContext context, TripProvider provider) async {
    final hasPermission = await LocationService.instance.requestPermission();
    if (!hasPermission) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission required')));
      }
      return;
    }
    if (!context.mounted) return;
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('TRIP NAME',
            style: TextStyle(color: Color(0xFFD4870A), fontWeight: FontWeight.w900, letterSpacing: 2)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'e.g. Rub al Khali North',
            hintStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD4870A))),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD4870A), width: 2)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await provider.startRecording(controller.text);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const RecordingScreen()));
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4870A),
              foregroundColor: Colors.black,
            ),
            child: const Text('START', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}
