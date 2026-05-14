import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/gpx_service.dart';
import 'history_screen.dart';
import 'record_screen.dart';
import 'trail_view_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _importGpx(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );
    if (result == null || result.files.single.path == null) return;

    final path = result.files.single.path!;
    if (!path.toLowerCase().endsWith('.gpx')) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un fichier .gpx')),
      );
      return;
    }

    try {
      final trail = await GpxService().parseGpxFile(File(path));
      if (!context.mounted) return;
      if (trail.points.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucun point trouvé dans ce GPX')),
        );
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => TrailViewScreen(trail: trail)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la lecture du GPX: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GeoTracker'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            const Icon(Icons.map_outlined, size: 96, color: Colors.deepPurple),
            const SizedBox(height: 24),
            Text(
              'Enregistrez vos trajets GPS\net exportez-les en GPX',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 32),
            _MenuButton(
              icon: Icons.fiber_manual_record,
              color: Colors.red,
              label: 'Nouveau trajet',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RecordScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _MenuButton(
              icon: Icons.history,
              color: Colors.indigo,
              label: 'Mes trajets',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _MenuButton(
              icon: Icons.file_open,
              color: Colors.teal,
              label: 'Importer un GPX',
              onTap: () => _importGpx(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _MenuButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          child: Row(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
