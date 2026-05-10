import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:provider/provider.dart';

import 'providers/trip_provider.dart';
import 'screens/home_screen.dart';
import 'services/database_service.dart';
import 'services/location_service.dart';
import 'services/tile_cache_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Required by flutter_foreground_task
  FlutterForegroundTask.initCommunicationPort();

  // Lock to portrait (optional, remove if landscape needed)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Initialize services
  await DatabaseService.instance.initialize();
  await TileCacheService.initialize();

  // Setup foreground task config
  LocationService.instance.initForegroundTask();

  runApp(
    ChangeNotifierProvider(
      create: (_) => TripProvider()..loadTrips(),
      child: const DesertTrackApp(),
    ),
  );
}

class DesertTrackApp extends StatelessWidget {
  const DesertTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Desert Track',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,

      // ── Light theme (day) ──────────────────────────────────────────────
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD4870A),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFD4870A),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 64),
            textStyle: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFD4870A),
          foregroundColor: Colors.white,
          extendedPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),

      // ── Dark theme (night) ─────────────────────────────────────────────
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD4870A),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1A1A),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 64),
            textStyle: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFD4870A),
          foregroundColor: Colors.white,
        ),
      ),

      home: const HomeScreen(),
    );
  }
}
