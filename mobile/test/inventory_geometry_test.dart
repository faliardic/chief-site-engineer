import 'package:chief_site_engineer/domain/inventory_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Inventory geometry canonical codec', () {
    test('empty DRAFT has exact canonical bytes and independent digest', () {
      final geometry = InventoryGeometry.emptyDraft();

      expect(
        geometry.canonicalJson,
        '{"canvas_height":3072,"canvas_width":4096,'
        '"geometry_version":1,"polylines":[]}',
      );
      expect(
        geometry.sha256,
        'bd23cac9d6ab5b9c8aafff69496a31ed588cffd2761edf7a27208432c81a121a',
      );
      expect(geometry.pointCount, 0);
      expect(geometry.segmentCount, 0);
      expect(
        geometry.validateFinalizable,
        _geometryFailure('geometry_not_finalizable'),
      );
    });

    test(
      'decode accepts semantic key order and emits fixed canonical order',
      () {
        const reordered = '''
        {
          "polylines": [
            {"points": [[0, 0], [64, 64]], "closed": false}
          ],
          "geometry_version": 1,
          "canvas_width": 4096,
          "canvas_height": 3072
        }
      ''';
        final decoded = InventoryGeometry.decode(reordered);
        const canonical =
            '{"canvas_height":3072,"canvas_width":4096,'
            '"geometry_version":1,"polylines":['
            '{"closed":false,"points":[[0,0],[64,64]]}]}';

        expect(decoded.canonicalJson, canonical);
        expect(
          InventoryGeometry.decode(
            reordered,
            expectedSha256: decoded.sha256,
          ).canonicalJson,
          canonical,
        );
        expect(InventoryGeometry.decode(canonical).sha256, decoded.sha256);
      },
    );

    test('decoded and constructed collections are immutable', () {
      final source = <InventorySketchPoint>[
        InventorySketchPoint(x: 0, y: 0),
        InventorySketchPoint(x: 64, y: 64),
      ];
      final polyline = InventoryPolyline(closed: false, points: source);
      final geometry = InventoryGeometry(polylines: [polyline]);
      source.add(InventorySketchPoint(x: 128, y: 128));

      expect(polyline.points, hasLength(2));
      expect(
        () => polyline.points.add(InventorySketchPoint(x: 128, y: 128)),
        throwsUnsupportedError,
      );
      expect(() => geometry.polylines.add(polyline), throwsUnsupportedError);
    });
  });

  group('Inventory coordinate and polyline rules', () {
    test('exact half ties snap down and inclusive edges remain valid', () {
      expect(
        InventoryGeometryContract.snapSketchCoordinate(
          32,
          maximum: InventoryGeometryContract.canvasWidth,
        ),
        0,
      );
      expect(
        InventoryGeometryContract.snapSketchCoordinate(
          96,
          maximum: InventoryGeometryContract.canvasWidth,
        ),
        64,
      );
      expect(
        InventoryGeometryContract.snapSketchCoordinate(
          4095,
          maximum: InventoryGeometryContract.canvasWidth,
        ),
        4096,
      );
      expect(
        InventoryGeometryContract.snapPlacementCoordinate(
          2,
          maximum: InventoryGeometryContract.canvasWidth,
        ),
        0,
      );
      expect(
        InventoryGeometryContract.snapPlacementCoordinate(
          6,
          maximum: InventoryGeometryContract.canvasWidth,
        ),
        4,
      );
      expect(
        InventoryGeometryContract.snapPlacementCoordinate(
          4096,
          maximum: InventoryGeometryContract.canvasWidth,
        ),
        4096,
      );
      InventoryGeometryContract.validatePlacementCoordinate(
        3072,
        maximum: InventoryGeometryContract.canvasHeight,
      );
      expect(
        () => InventoryGeometryContract.snapPlacementCoordinate(
          -1,
          maximum: InventoryGeometryContract.canvasWidth,
        ),
        _geometryFailure('coordinate_out_of_bounds'),
      );
      expect(
        () => InventoryGeometryContract.validatePlacementCoordinate(
          3,
          maximum: InventoryGeometryContract.canvasWidth,
        ),
        _geometryFailure('coordinate_not_quantized'),
      );
    });

    test('open and closed segment counts and finalization are exact', () {
      final open = InventoryPolyline(closed: false, points: _boundedPoints(2));
      final closed = InventoryPolyline(closed: true, points: _boundedPoints(3));
      final geometry = InventoryGeometry(polylines: [open, closed]);

      expect(open.segmentCount, 1);
      expect(closed.segmentCount, 3);
      expect(geometry.segmentCount, 4);
      geometry.validateFinalizable();
    });

    test('one incomplete open polyline is DRAFT-only', () {
      final geometry = InventoryGeometry(
        polylines: [
          InventoryPolyline(closed: false, points: _boundedPoints(1)),
        ],
      );

      expect(geometry.segmentCount, 0);
      expect(
        geometry.validateFinalizable,
        _geometryFailure('geometry_not_finalizable'),
      );
      expect(
        () => InventoryGeometry(
          polylines: [
            InventoryPolyline(closed: false, points: _boundedPoints(1)),
            InventoryPolyline(closed: false, points: _boundedPoints(2)),
          ],
        ),
        _geometryFailure('incomplete_draft_invalid'),
      );
    });
  });

  group('Inventory geometry exact limits', () {
    test('64 polylines pass and 65 fail', () {
      final line = InventoryPolyline(closed: false, points: _boundedPoints(2));

      expect(
        InventoryGeometry(polylines: List.filled(64, line)).polylines,
        hasLength(64),
      );
      expect(
        () => InventoryGeometry(polylines: List.filled(65, line)),
        _geometryFailure('polyline_limit_exceeded'),
      );
    });

    test('1024 points per polyline pass and 1025 fail', () {
      final maximum = InventoryPolyline(
        closed: false,
        points: _boundedPoints(1024),
      );

      expect(maximum.points, hasLength(1024));
      expect(
        () => InventoryPolyline(closed: false, points: _boundedPoints(1025)),
        _geometryFailure('polyline_point_limit_exceeded'),
      );
    });

    test('4096 total points pass and one-over fails', () {
      final maximum = InventoryGeometry(
        polylines: List.generate(
          4,
          (_) => InventoryPolyline(closed: false, points: _boundedPoints(1024)),
        ),
      );
      final oneOver = <InventoryPolyline>[
        for (var index = 0; index < 3; index += 1)
          InventoryPolyline(closed: false, points: _boundedPoints(1024)),
        InventoryPolyline(closed: false, points: _boundedPoints(1023)),
        InventoryPolyline(closed: false, points: _boundedPoints(2)),
      ];

      expect(maximum.pointCount, 4096);
      expect(
        () => InventoryGeometry(polylines: oneOver),
        _geometryFailure('total_point_limit_exceeded'),
      );
    });

    test('4096 closed segments are accepted at the exact bound', () {
      final geometry = InventoryGeometry(
        polylines: List.generate(
          4,
          (_) => InventoryPolyline(closed: true, points: _boundedPoints(1024)),
        ),
      );

      expect(geometry.pointCount, 4096);
      expect(geometry.segmentCount, 4096);
      geometry.validateFinalizable();
    });
  });

  group('Inventory geometry fail-closed decode', () {
    test('polyline duplicates and repeated closing point are rejected', () {
      final point = InventorySketchPoint(x: 0, y: 0);
      expect(
        () => InventoryPolyline(closed: false, points: [point, point]),
        _geometryFailure('zero_length_segment'),
      );
      expect(
        () => InventoryPolyline(
          closed: true,
          points: [
            point,
            InventorySketchPoint(x: 64, y: 0),
            InventorySketchPoint(x: 64, y: 64),
            point,
          ],
        ),
        _geometryFailure('repeated_closing_point'),
      );
      expect(
        () => InventoryPolyline(closed: true, points: _boundedPoints(2)),
        _geometryFailure('closed_polyline_too_short'),
      );
    });

    for (final invalid in <String, String>{
      'malformed': '{',
      'unknown key':
          '{"canvas_height":3072,"canvas_width":4096,'
          '"geometry_version":1,"polylines":[],"extra":true}',
      'missing key':
          '{"canvas_height":3072,"canvas_width":4096,"polylines":[]}',
      'unknown version':
          '{"canvas_height":3072,"canvas_width":4096,'
          '"geometry_version":2,"polylines":[]}',
      'wrong canvas':
          '{"canvas_height":3072,"canvas_width":4095,'
          '"geometry_version":1,"polylines":[]}',
      'float coordinate':
          '{"canvas_height":3072,"canvas_width":4096,'
          '"geometry_version":1,"polylines":['
          '{"closed":false,"points":[[0.0,0],[64,64]]}]}',
      'out of range':
          '{"canvas_height":3072,"canvas_width":4096,'
          '"geometry_version":1,"polylines":['
          '{"closed":false,"points":[[0,0],[4160,64]]}]}',
      'unsnapped':
          '{"canvas_height":3072,"canvas_width":4096,'
          '"geometry_version":1,"polylines":['
          '{"closed":false,"points":[[0,0],[63,64]]}]}',
      'duplicate':
          '{"canvas_height":3072,"canvas_width":4096,'
          '"geometry_version":1,"polylines":['
          '{"closed":false,"points":[[0,0],[0,0]]}]}',
      'repeated close':
          '{"canvas_height":3072,"canvas_width":4096,'
          '"geometry_version":1,"polylines":['
          '{"closed":true,"points":[[0,0],[64,0],[64,64],[0,0]]}]}',
    }.entries) {
      test('${invalid.key} input fails with safe diagnostic', () {
        expect(
          () => InventoryGeometry.decode(invalid.value),
          throwsA(
            isA<InventoryGeometryFailure>().having(
              (failure) => failure.code,
              'code',
              InventoryGeometryFailure.safeCode,
            ),
          ),
        );
      });
    }

    test('checksum mismatch and malformed checksum fail closed', () {
      final geometry = InventoryGeometry(
        polylines: [
          InventoryPolyline(closed: false, points: _boundedPoints(2)),
        ],
      );

      expect(
        () => InventoryGeometry.decode(
          geometry.canonicalJson,
          expectedSha256: '0' * 64,
        ),
        _geometryFailure('checksum_mismatch'),
      );
      expect(
        () => InventoryGeometry.decode(
          geometry.canonicalJson,
          expectedSha256: 'ABC',
        ),
        _geometryFailure('checksum_invalid'),
      );
    });
  });
}

List<InventorySketchPoint> _boundedPoints(int count) => List.generate(
  count,
  (index) => InventorySketchPoint(
    x: (index % 65) * InventoryGeometryContract.sketchGridStep,
    y: ((index ~/ 65) % 49) * InventoryGeometryContract.sketchGridStep,
  ),
);

Matcher _geometryFailure(String reason) => throwsA(
  isA<InventoryGeometryFailure>()
      .having(
        (failure) => failure.code,
        'code',
        InventoryGeometryFailure.safeCode,
      )
      .having((failure) => failure.reason, 'reason', reason),
);
