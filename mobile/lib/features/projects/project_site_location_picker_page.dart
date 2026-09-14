import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Outcome of a one-shot current-device-position read.
///
/// This never represents a stream, background fix or history — only the
/// single foreground read triggered by the explicit "Konumumu bul" action.
sealed class CurrentLocationOutcome {
  const CurrentLocationOutcome();
}

class CurrentLocationSuccess extends CurrentLocationOutcome {
  const CurrentLocationSuccess(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}

enum CurrentLocationFailureReason {
  permissionDenied,
  permissionDeniedForever,
  serviceDisabled,
  timeout,
  unknown,
}

class CurrentLocationFailure extends CurrentLocationOutcome {
  const CurrentLocationFailure(this.reason);

  final CurrentLocationFailureReason reason;
}

typedef CurrentLocationReader = Future<CurrentLocationOutcome> Function();

/// Default production current-location reader: a single foreground,
/// while-in-use-permission, one-shot position read. No stream, background
/// tracking, geofencing or periodic work is started.
Future<CurrentLocationOutcome> _defaultReadCurrentLocation() async {
  try {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const CurrentLocationFailure(
        CurrentLocationFailureReason.serviceDisabled,
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      return const CurrentLocationFailure(
        CurrentLocationFailureReason.permissionDenied,
      );
    }
    if (permission == LocationPermission.deniedForever) {
      return const CurrentLocationFailure(
        CurrentLocationFailureReason.permissionDeniedForever,
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );
    return CurrentLocationSuccess(position.latitude, position.longitude);
  } on TimeoutException {
    return const CurrentLocationFailure(CurrentLocationFailureReason.timeout);
  } catch (_) {
    return const CurrentLocationFailure(CurrentLocationFailureReason.unknown);
  }
}

/// Dedicated full-screen `Şantiye konumu` map picker.
///
/// Pans/zooms are free; a tap places a single pending marker. Nothing is
/// persisted here — this page only returns the chosen `(latitude,
/// longitude)` pair to its caller via [Navigator.pop]. Explicit Cancel/Back
/// returns `null` and makes no change. The explicit `Konumumu bul` action
/// performs a single foreground, while-in-use-permission current-position
/// read and only re-centers the map / places the pending marker; it never
/// persists anything by itself and never overwrites the initial saved point
/// unless the owner then taps the existing `Kaydet` action.
class ProjectSiteLocationPickerPage extends StatefulWidget {
  const ProjectSiteLocationPickerPage({
    this.initialLatitude,
    this.initialLongitude,
    this.tileProvider,
    CurrentLocationReader? locationReader,
    super.key,
  }) : _locationReader = locationReader ?? _defaultReadCurrentLocation;

  final double? initialLatitude;
  final double? initialLongitude;

  /// Injectable for widget tests so they never depend on live OSM network
  /// access.
  final TileProvider? tileProvider;

  /// Injectable for widget tests so they never depend on real GPS/permission
  /// hardware; defaults to the real foreground one-shot Geolocator read.
  final CurrentLocationReader _locationReader;

  static const LatLng _turkeyDefaultCenter = LatLng(39.0, 35.0);
  static const double _existingPointZoom = 15;
  static const double _defaultZoom = 5.5;
  static const double _currentLocationZoom = 17;

  @override
  State<ProjectSiteLocationPickerPage> createState() =>
      _ProjectSiteLocationPickerPageState();
}

class _ProjectSiteLocationPickerPageState
    extends State<ProjectSiteLocationPickerPage> {
  final MapController _mapController = MapController();
  LatLng? _pending;
  String? _tileError;
  String? _locationError;
  bool _locating = false;

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
      _locationError = null;
    });
  }

  Future<void> _useCurrentLocation() async {
    if (_locating) return;
    setState(() {
      _locating = true;
      _locationError = null;
    });
    final outcome = await widget._locationReader();
    if (!mounted) return;
    switch (outcome) {
      case CurrentLocationSuccess(:final latitude, :final longitude):
        final point = LatLng(latitude, longitude);
        setState(() {
          _pending = point;
          _locating = false;
          _locationError = null;
        });
        _mapController.move(
          point,
          ProjectSiteLocationPickerPage._currentLocationZoom,
        );
      case CurrentLocationFailure(:final reason):
        setState(() {
          _locating = false;
          _locationError = _messageForFailure(reason);
        });
    }
  }

  String _messageForFailure(CurrentLocationFailureReason reason) {
    switch (reason) {
      case CurrentLocationFailureReason.permissionDenied:
        return 'Konum izni verilmedi. Haritadan seçmeye devam edebilirsiniz.';
      case CurrentLocationFailureReason.permissionDeniedForever:
        return 'Konum izni kalıcı olarak reddedildi. Ayarlardan izin verebilir '
            'veya haritadan seçmeye devam edebilirsiniz.';
      case CurrentLocationFailureReason.serviceDisabled:
        return 'Konum servisleri kapalı. Haritadan seçmeye devam edebilirsiniz.';
      case CurrentLocationFailureReason.timeout:
        return 'Mevcut konum alınamadı. Haritadan seçmeye devam edebilirsiniz.';
      case CurrentLocationFailureReason.unknown:
        return 'Mevcut konum alınamadı. Haritadan seçmeye devam edebilirsiniz.';
    }
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
            mapController: _mapController,
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
          Positioned(
            right: 12,
            bottom: _tileError != null || _locationError != null ? 76 : 12,
            child: FloatingActionButton.extended(
              key: const Key('site-location-picker-locate'),
              onPressed: _locating ? null : _useCurrentLocation,
              icon: _locating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
              label: const Text('Konumumu bul'),
            ),
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
          if (_locationError != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Material(
                key: const Key('site-location-picker-location-error'),
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_locationError!),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
