import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/trip_provider.dart';
import '../services/tile_cache_service.dart';
import 'recording_screen.dart';
import 'trips_list_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.explore,
                        size: 40, color: cs.onPrimaryContainer),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Desert Track',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      Text('الملاحة البرية الحرة',
                          style: TextStyle(color: cs.outline)),
                    ],
                  ),
                  const Spacer(),
                  // Settings / cache info
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () => _showSettings(context),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // ── Main action: Start Trip ───────────────────────────────────
              _BigButton(
                icon: Icons.play_circle_fill_rounded,
                label: 'بدء رحلة جديدة',
                subtitle: 'تسجيل المسار بـ GPS',
                color: cs.primary,
                onTap: () => _startNewTrip(context),
              ),

              const SizedBox(height: 16),

              // ── Trips list ────────────────────────────────────────────────
              _BigButton(
                icon: Icons.list_alt_rounded,
                label: 'رحلاتي',
                subtitle: 'عرض وإدارة الرحلات المحفوظة',
                color: cs.secondary,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const TripsListScreen())),
              ),

              const Spacer(),

              // ── Status card ───────────────────────────────────────────────
              Consumer<TripProvider>(
                builder: (_, provider, __) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            provider.trips.isEmpty
                                ? Icons.satellite_alt
                                : Icons.check_circle,
                            color: provider.trips.isEmpty
                                ? cs.outline
                                : Colors.green,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  provider.trips.isEmpty
                                      ? 'لا توجد رحلات بعد'
                                      : '${provider.trips.length} رحلة محفوظة',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'خرائط أقمار صناعية مجانية – ESRI',
                                  style: TextStyle(
                                      fontSize: 12, color: cs.outline),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _startNewTrip(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _NewTripDialog(onStart: (name) async {
        Navigator.pop(ctx);
        final provider = context.read<TripProvider>();
        final started = await provider.startRecording(name);
        if (!started && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  '⚠️ تعذّر تشغيل GPS. تحقق من أذونات الموقع.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        if (context.mounted) {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const RecordingScreen()));
        }
      }),
    );
  }

  void _showSettings(BuildContext context) async {
    final size = await TileCacheService.cacheSizeFormatted();
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (_) => _SettingsSheet(cacheSize: size),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _BigButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _BigButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Row(
            children: [
              Icon(icon, size: 48, color: Colors.white),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── New Trip Dialog ───────────────────────────────────────────────────────────

class _NewTripDialog extends StatefulWidget {
  final void Function(String name) onStart;
  const _NewTripDialog({required this.onStart});

  @override
  State<_NewTripDialog> createState() => _NewTripDialogState();
}

class _NewTripDialogState extends State<_NewTripDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _ctrl = TextEditingController(
      text: 'رحلة ${now.day}-${now.month}-${now.year}',
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('رحلة جديدة'),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'اسم الرحلة',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.drive_eta),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء')),
        FilledButton(
          onPressed: () {
            final name = _ctrl.text.trim();
            if (name.isNotEmpty) widget.onStart(name);
          },
          child: const Text('ابدأ التسجيل'),
        ),
      ],
    );
  }
}

// ── Settings Sheet ────────────────────────────────────────────────────────────

class _SettingsSheet extends StatelessWidget {
  final String cacheSize;
  const _SettingsSheet({required this.cacheSize});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('الإعدادات',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.map_outlined),
            title: const Text('حجم كاش الخرائط'),
            subtitle: Text(cacheSize),
            trailing: TextButton(
              onPressed: () async {
                await TileCacheService.clearCache();
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('مسح'),
            ),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.satellite_alt),
            title: Text('مصدر الخرائط'),
            subtitle: Text('ESRI World Imagery – مجاني بالكامل'),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('الإصدار'),
            subtitle: Text('Desert Track v1.0'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
