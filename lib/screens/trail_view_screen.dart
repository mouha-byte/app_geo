import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';

import '../models/trail.dart';
import '../services/storage_service.dart';
import '../utils/formatters.dart';

class TrailViewScreen extends StatelessWidget {
  final Trail trail;
  const TrailViewScreen({super.key, required this.trail});

  Future<void> _share(BuildContext context) async {
    final storage = StorageService();
    try {
      final file = await storage.exportToGpxTempFile(trail);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/gpx+xml')],
        subject: trail.name,
        text: 'Trajet GPX : ${trail.name}',
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur partage GPX : $e')),
      );
    }
  }

  LatLngBounds? _bounds(List<LatLng> pts) {
    if (pts.isEmpty) return null;
    double minLat = pts.first.latitude, maxLat = pts.first.latitude;
    double minLon = pts.first.longitude, maxLon = pts.first.longitude;
    for (final p in pts) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLon) minLon = p.longitude;
      if (p.longitude > maxLon) maxLon = p.longitude;
    }
    return LatLngBounds(LatLng(minLat, minLon), LatLng(maxLat, maxLon));
  }

  @override
  Widget build(BuildContext context) {
    final pts = trail.points
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();
    final bounds = _bounds(pts);
    final center = pts.isNotEmpty ? pts.first : const LatLng(48.8566, 2.3522);

    return Scaffold(
      appBar: AppBar(
        title: Text(trail.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Partager en GPX',
            icon: const Icon(Icons.ios_share),
            onPressed: () => _share(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: 14,
                initialCameraFit: bounds == null
                    ? null
                    : CameraFit.bounds(
                        bounds: bounds,
                        padding: const EdgeInsets.all(40),
                      ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app_geo',
                  maxZoom: 19,
                ),
                if (pts.length >= 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: pts,
                        strokeWidth: 5,
                        color: Colors.deepPurple,
                      ),
                    ],
                  ),
                if (pts.isNotEmpty)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: pts.first,
                        width: 28,
                        height: 28,
                        child: _Pin(color: Colors.green),
                      ),
                      Marker(
                        point: pts.last,
                        width: 28,
                        height: 28,
                        child: _Pin(color: Colors.red),
                      ),
                    ],
                  ),
                const RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution('OpenStreetMap contributors'),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatDateTime(trail.startedAt),
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _Stat(
                      label: 'Distance',
                      value: formatDistance(trail.distanceMeters),
                    ),
                    _Stat(
                      label: 'Durée',
                      value: formatDuration(trail.duration),
                    ),
                    _Stat(
                      label: 'V. moy.',
                      value: formatSpeed(trail.averageSpeed),
                    ),
                    _Stat(
                      label: 'V. max',
                      value: formatSpeed(trail.maxSpeed),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pin extends StatelessWidget {
  final Color color;
  const _Pin({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
