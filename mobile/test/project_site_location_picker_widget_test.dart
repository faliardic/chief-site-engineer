import 'package:chief_site_engineer/features/projects/project_site_location_picker_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget testApp({double? lat, double? lng}) => MaterialApp(
    home: ProjectSiteLocationPickerPage(
      initialLatitude: lat,
      initialLongitude: lng,
      tileProvider: _FakeOfflineTileProvider(),
    ),
  );

  testWidgets('Save is disabled until a point is selected', (tester) async {
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    final save = tester.widget<TextButton>(
      find.byKey(const Key('site-location-picker-save')),
    );
    expect(save.onPressed, isNull);
  });

  testWidgets(
    'existing saved point pre-selects the marker, enables Save immediately, '
    'and Save returns that exact (latitude, longitude)',
    (tester) async {
      Object? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await Navigator.of(context).push<Object?>(
                  MaterialPageRoute(
                    builder: (_) => ProjectSiteLocationPickerPage(
                      initialLatitude: 41.015137,
                      initialLongitude: 28.97953,
                      tileProvider: _FakeOfflineTileProvider(),
                    ),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<TextButton>(
              find.byKey(const Key('site-location-picker-save')),
            )
            .onPressed,
        isNotNull,
      );

      await tester.tap(find.byKey(const Key('site-location-picker-save')));
      await tester.pumpAndSettle();

      expect(find.byType(ProjectSiteLocationPickerPage), findsNothing);
      expect(result, (41.015137, 28.97953));
    },
  );

  testWidgets(
    'Cancel/Back returns null and performs no save even with a pending point',
    (tester) async {
      late Object? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await Navigator.of(context).push<Object?>(
                  MaterialPageRoute(
                    builder: (_) => ProjectSiteLocationPickerPage(
                      // Pending point already present (as if the owner had
                      // previously saved one) — Back must still discard it.
                      initialLatitude: 41.015137,
                      initialLongitude: 28.97953,
                      tileProvider: _FakeOfflineTileProvider(),
                    ),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(result, isNull);
    },
  );

  testWidgets('tile load failure shows bounded human-readable feedback', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProjectSiteLocationPickerPage(
          tileProvider: _FailingTileProvider(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('site-location-picker-tile-error')),
      findsOneWidget,
    );
    expect(find.text('Harita şu an yüklenemiyor.'), findsOneWidget);
  });
}

/// Serves a tiny in-memory 1x1 PNG for every tile request so the picker
/// renders deterministically without any live OpenStreetMap network access.
class _FakeOfflineTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(_transparentPngBytes);
}

/// Always fails tile loading to exercise the picker's error path without any
/// live network access.
class _FailingTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      const _AlwaysFailingImageProvider();
}

class _AlwaysFailingImageProvider
    extends ImageProvider<_AlwaysFailingImageProvider> {
  const _AlwaysFailingImageProvider();

  @override
  Future<_AlwaysFailingImageProvider> obtainKey(
    ImageConfiguration configuration,
  ) => SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    _AlwaysFailingImageProvider key,
    ImageDecoderCallback decode,
  ) => OneFrameImageStreamCompleter(
    Future<ImageInfo>.error(StateError('offline tile fixture failure')),
  );
}

final Uint8List _transparentPngBytes = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR chunk
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, // IDAT chunk
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, // IEND chunk
  0x42, 0x60, 0x82,
]);
