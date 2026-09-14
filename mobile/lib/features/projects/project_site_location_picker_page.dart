import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Dedicated full-screen `Şantiye konumu` map picker.
///
/// Pans/zooms are free; a tap places a single pending marker. Nothing is
/// persisted here — this page only returns the chosen `(latitude,
/// longitude)` pair to its caller via [Navigator.pop]. Explicit Cancel/Back
/// returns `null` and makes no change. No current-device GPS/location read
/// is used; the initial view is either the project's existing saved point
/// or a neutral Turkey-wide default.
class ProjectSiteLocationPickerPage extends StatefulWidget {
  const ProjectSiteLocationPickerPage({
    this.initialLatitude,
    this.initialLongitude,
    this.tileProvider,
    super.key,
  });

  final double? initialLatitude;
  final double? initialLongitude;

  /// Injectable for widget tests so they never depend on live OSM network
  /// access.
  final TileProvider? tileProvider;

  static const LatLng _turkeyDefaultCenter = LatLng(39.0, 35.0);
  static const double _existingPointZoom = 15;
  static const double _defaultZoom = 5.5;

  @override
  State<ProjectSiteLocationPickerPage> createState() =>
      _ProjectSiteLocationPickerPageState();
}

class _ProjectSiteLocationPickerPageState
    extends State<ProjectSiteLocationPickerPage> {
  LatLng? _pending;
  String? _tileError;

  bool get _hasExistingPoint =>
      widget.initialLatitude != null && widget.initialLongitude != null;

  @override
  void initState() {
    super.initState();
    if (_hasExistingPoint) {
      _pending = LatLng(widget.initialLatitude!, widget.initialLongitude!);
    }
  }

  void _handleTap(TapPosition _, LatLng point) {
    setState(() {
      _pending = point;
      _tileError = null;
    });
  }

  void _save() {
    final point = _pending;
    if (point == null ||
        !point.latitude.isFinite ||
        !point.longitude.isFinite) {
      return;
    }
    Navigator.of(context).pop((point.latitude, point.longitude));
  }

  @override
  Widget build(BuildContext context) {
    final initialCenter = _hasExistingPoint
        ? LatLng(widget.initialLatitude!, widget.initialLongitude!)
        : ProjectSiteLocationPickerPage._turkeyDefaultCenter;
    final initialZoom = _hasExistingPoint
        ? ProjectSiteLocationPickerPage._existingPointZoom
        : ProjectSiteLocationPickerPage._defaultZoom;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Şantiye konumunu seç'),
        actions: [
          TextButton(
            key: const Key('site-location-picker-save'),
            onPressed: _pending == null ? null : _save,
            child: const Text('Kaydet'),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: initialZoom,
              onTap: _handleTap,
            ),
            children: [
              TileLayer(
                key: const Key('site-location-picker-tiles'),
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.faliardic.sefim',
                tileProvider: widget.tileProvider,
                errorTileCallback: (tile, error, stackTrace) {
                  if (!mounted) return;
                  setState(() => _tileError = 'Harita şu an yüklenemiyor.');
                },
              ),
              if (_pending != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _pending!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('© OpenStreetMap contributors'),
                ],
              ),
            ],
          ),
          if (_tileError != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Material(
                key: const Key('site-location-picker-tile-error'),
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_tileError!),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
