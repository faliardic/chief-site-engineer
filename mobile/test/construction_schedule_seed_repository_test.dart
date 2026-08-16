import 'dart:convert';
import 'dart:io';

import 'package:chief_site_engineer/application/construction_corpus_repository.dart';
import 'package:chief_site_engineer/application/construction_schedule_seed_repository.dart';
import 'package:chief_site_engineer/domain/construction_corpus_models.dart';
import 'package:chief_site_engineer/domain/construction_schedule_models.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ConstructionCorpus corpus;
  late String canonicalEncoded;
  late String canonicalDecoded;
  late Map<String, Object?> canonicalRoot;

  setUpAll(() async {
    corpus = await BundledConstructionCorpusRepository().load();
    canonicalEncoded = (await rootBundle.loadString(
      BundledConstructionScheduleSeedCatalogRepository.defaultAssetPath,
    )).trim();
    canonicalDecoded = utf8.decode(gzip.decode(base64Decode(canonicalEncoded)));
    canonicalRoot = _asMap(jsonDecode(canonicalDecoded));
  });

  test(
    'bundled bytes, decoded bytes, metadata and physical counts are exact',
    () async {
      expect(
        sha256.convert(utf8.encode(canonicalEncoded)).toString(),
        'b80ebe90f57fa71bafcaee5102acfe3dda29368f53cd5a164b248b6530b9587e',
      );
      expect(
        sha256.convert(utf8.encode(canonicalDecoded)).toString(),
        '6504b81825b56dd85caeee042b1980cbeb4e8ced0d0c81084369b1486be111b4',
      );

      final catalog = await BundledConstructionScheduleSeedCatalogRepository()
          .load(corpus);
      expect(catalog.seeds, hasLength(316));
      expect(
        catalog.seeds.where(
          (seed) =>
              seed.durationCalendarType ==
              ConstructionActivityDurationCalendarType.workingDay,
        ),
        hasLength(313),
      );
      expect(
        catalog.seeds.where(
          (seed) =>
              seed.durationCalendarType ==
              ConstructionActivityDurationCalendarType.calendarDay,
        ),
        hasLength(3),
      );
      expect(catalog.seeds.where((seed) => seed.isMilestone), hasLength(4));
      expect(
        _counts(catalog.seeds.map((seed) => seed.durationConfidence.jsonValue)),
        const {'A_AUTHORITATIVE': 1, 'D_AI_SEED': 295, 'E_UNKNOWN': 20},
      );
      expect(
        _counts(catalog.seeds.map((seed) => seed.durationStatus.jsonValue)),
        const {'SOURCE_BACKED': 1, 'AI_SEED_ESTIMATE': 295, 'UNKNOWN': 20},
      );
      expect(catalog.seedsByActivityId.keys.toSet(), {
        for (final activity in corpus.activities) activity.activityId,
      });
    },
  );

  test('raw duration is preserved and scheduling duration uses ceil', () {
    final seed = ConstructionScheduleSeed(
      activityId: 'ACT-1',
      durationDays: 1.2,
      durationCalendarType: ConstructionActivityDurationCalendarType.workingDay,
      durationStatus: ConstructionScheduleDurationStatus.aiSeedEstimate,
      durationConfidence: ConstructionScheduleDurationConfidence.aiSeed,
    );
    expect(seed.durationDays, 1.2);
    expect(seed.roundedSchedulingDays, 2);
    expect(seed.isMilestone, isFalse);
  });

  for (final duration in <double>[-1, double.nan, double.infinity]) {
    test('invalid duration $duration fails closed', () {
      expect(
        () => ConstructionScheduleSeed(
          activityId: 'ACT-1',
          durationDays: duration,
          durationCalendarType:
              ConstructionActivityDurationCalendarType.workingDay,
          durationStatus: ConstructionScheduleDurationStatus.aiSeedEstimate,
          durationConfidence: ConstructionScheduleDurationConfidence.aiSeed,
        ),
        _throwsCorpusFailure('invalid_schedule_seed_duration'),
      );
    });
  }

  test('duplicate activity ID fails closed', () async {
    final root = _cloneRoot(canonicalRoot);
    final records = _records(root);
    records.add(_asMap(records.first));
    await expectLater(_load(root), throwsA(isA<ConstructionCorpusFailure>()));
  });

  test('missing activity ID fails closed', () async {
    final root = _cloneRoot(canonicalRoot);
    _records(root).removeLast();
    await expectLater(_load(root), throwsA(isA<ConstructionCorpusFailure>()));
  });

  test('extra activity ID fails closed', () async {
    final root = _cloneRoot(canonicalRoot);
    final records = _records(root);
    final extra = _asMap(records.first);
    extra['activity_id'] = 'UNKNOWN-ACTIVITY';
    records.add(extra);
    await expectLater(_load(root), throwsA(isA<ConstructionCorpusFailure>()));
  });

  test('unknown replacement activity ID fails closed', () async {
    final root = _cloneRoot(canonicalRoot);
    _asMap(_records(root).first)['activity_id'] = 'UNKNOWN-ACTIVITY';
    await expectLater(
      _load(root),
      throwsA(_corpusFailure('unknown_schedule_seed_activity')),
    );
  });

  test('invalid calendar type fails closed', () async {
    final root = _cloneRoot(canonicalRoot);
    _asMap(_records(root).first)['duration_calendar_type'] = 'FISCAL_DAY';
    await expectLater(
      _load(root),
      throwsA(_corpusFailure('invalid_duration_calendar_type')),
    );
  });

  test('negative JSON duration fails closed without clamping', () async {
    final root = _cloneRoot(canonicalRoot);
    _asMap(_records(root).first)['duration_days'] = -0.1;
    await expectLater(
      _load(root),
      throwsA(_corpusFailure('invalid_schedule_seed_duration')),
    );
  });

  test('activity duration metadata mismatch fails closed', () async {
    final root = _cloneRoot(canonicalRoot);
    final nonMilestone = _asMap(_records(root)[1]);
    nonMilestone['duration_days'] = 4.0;
    await expectLater(
      _load(root),
      throwsA(_corpusFailure('schedule_seed_activity_metadata_mismatch')),
    );
  });

  test('unknown duration status and confidence fail closed', () async {
    final statusRoot = _cloneRoot(canonicalRoot);
    _asMap(_records(statusRoot).first)['duration_status'] = 'APPROVED';
    await expectLater(
      _load(statusRoot),
      throwsA(_corpusFailure('invalid_schedule_duration_status')),
    );

    final confidenceRoot = _cloneRoot(canonicalRoot);
    _asMap(_records(confidenceRoot).first)['duration_confidence'] =
        'B_REVIEWED';
    await expectLater(
      _load(confidenceRoot),
      throwsA(_corpusFailure('invalid_schedule_duration_confidence')),
    );
  });

  test('forbidden raw, price or resource fields cannot enter a row', () async {
    for (final field in <String>[
      'raw_analysis_text',
      'unit_price',
      'material_coefficient',
      'labor_coefficient',
      'machine_coefficient',
      'schedule_instance',
      'actual_duration',
    ]) {
      final root = _cloneRoot(canonicalRoot);
      _asMap(_records(root).first)[field] = 'forbidden';
      await expectLater(
        _load(root),
        throwsA(_corpusFailure('invalid_schedule_seed')),
        reason: field,
      );
    }
  });
}

Future<ConstructionScheduleSeedCatalog> _load(Map<String, Object?> root) async {
  final encoded = base64Encode(gzip.encode(utf8.encode(jsonEncode(root))));
  final corpus = await BundledConstructionCorpusRepository().load();
  return BundledConstructionScheduleSeedCatalogRepository(
    loader: (_) async => encoded,
  ).load(corpus);
}

Map<String, Object?> _cloneRoot(Map<String, Object?> root) =>
    _asMap(jsonDecode(jsonEncode(root)));

List<Object?> _records(Map<String, Object?> root) =>
    root['records']! as List<Object?>;

Map<String, Object?> _asMap(Object? value) => value! as Map<String, Object?>;

Map<String, int> _counts(Iterable<String> values) {
  final counts = <String, int>{};
  for (final value in values) {
    counts[value] = (counts[value] ?? 0) + 1;
  }
  return counts;
}

Matcher _throwsCorpusFailure(String code) => throwsA(_corpusFailure(code));

Matcher _corpusFailure(String code) => isA<ConstructionCorpusFailure>().having(
  (failure) => failure.code,
  'code',
  code,
);
