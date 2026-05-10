import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/trip_provider.dart';
import '../services/location_service.dart';
import 'recording_screen.dart';
import 'trips_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = false;

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
              // If already tracking show resume button
              if (provider.isTracking) ...[
                SizedBox(
                  width: double.infinity, height: 64,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const RecordingScreen())),
                    icon: const Icon(Icons.gps_fixed),
                    label: Text('RESUME: ${provider.activeTrip?.name ?? ""}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              SizedBox(
                width: double.infinity, height: 64,
                child: ElevatedButton(
                  onPressed: _loading ? null : () => _startTrip(context, provider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4870A),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text('START TRIP',
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
    setState(() => _loading = true);

    try {
      final hasPermission = await LocationService.instance.requestPermission();
      if (!hasPermission) {
        if (mounted) {
          _showError(context,
              'Location permission denied.\nGo to Settings → Apps → Desert Track → Permissions → Allow Location');
        }
        return;
      }

      if (!mounted) return;

      final controller = TextEditingController();
      final name = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text('TRIP NAME',
              style: TextStyle(
                  color: Color(0xFFD4870A),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2)),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'e.g. Rub al Khali North',
              hintStyle: TextStyle(color: Colors.grey),
              enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFD4870A))),
              focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFD4870A), width: 2)),
            ),
            onSubmitted: (v) => Navigator.pop(ctx, v),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('CANCEL', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4870A),
                foregroundColor: Colors.black,
              ),
              child: const Text('START',
                  style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      );

      if (name == null || name.trim().isEmpty) return;
      if (!mounted) return;

      final started = await provider.startRecording(name.trim());

      if (!started) {
        if (mounted) _showError(context, 'Failed to start GPS. Check location settings.');
        return;
      }

      if (mounted) {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const RecordingScreen()));
      }
    } catch (e) {
      if (mounted) _showError(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Row(children: [
          Icon(Icons.warning, color: Color(0xFFCF6679)),
          SizedBox(width: 8),
          Text('ERROR', style: TextStyle(color: Color(0xFFCF6679), fontWeight: FontWeight.w900)),
        ]),
        content: Text(message, style: const TextStyle(color: Colors.white)),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4870A),
              foregroundColor: Colors.black,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
