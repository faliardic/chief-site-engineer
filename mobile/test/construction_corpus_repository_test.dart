import 'dart:convert';
import 'dart:io';

import 'package:chief_site_engineer/application/construction_corpus_repository.dart';
import 'package:chief_site_engineer/domain/construction_corpus_models.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/construction_profile_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<int> canonicalAssetBytes;
  late Map<String, dynamic> canonicalRoot;

  setUpAll(() async {
    canonicalAssetBytes = await File(
      BundledConstructionCorpusRepository.defaultAssetPath,
    ).readAsBytes();
    canonicalRoot = _decodeAsset(canonicalAssetBytes);
  });

  test('canonical bundled asset and runtime JSON hashes are exact', () {
    expect(
      sha256.convert(canonicalAssetBytes).toString(),
      'a9b225d6403168f7d3fd35494eceb4907d1ea705492700bc865add95021f42ca',
    );

    final runtimeJson = gzip.decode(
      base64Decode(utf8.decode(canonicalAssetBytes).trim()),
    );
    expect(
      sha256.convert(runtimeJson).toString(),
      '5636d6286b09c09182cd7b96af2276fba2eedf8cd0b0607c8bab0060a9f57688',
    );
  });

  test('bundled activity catalog loads the exact read-only contract', () async {
    final corpus = await BundledConstructionCorpusRepository().load();

    expect(
      corpus.metadata.corpusVersion,
      BundledConstructionCorpusRepository.expectedCorpusVersion,
    );
    expect(
      corpus.metadata.sourcePublicationStatus,
      BundledConstructionCorpusRepository.expectedPublicationStatus,
    );
    expect(
      corpus.metadata.sourceProductionStatus,
      BundledConstructionCorpusRepository.expectedProductionStatus,
    );
    expect(
      corpus.metadata.runtimeScope,
      BundledConstructionCorpusRepository.expectedRuntimeScope,
    );
    expect(corpus.wbsPackages, hasLength(34));
    expect(corpus.activities, hasLength(316));
    expect(corpus.profileFields, hasLength(29));

    final metadata = canonicalRoot['metadata'] as Map<String, dynamic>;
    expect(
      metadata['source_zip_sha256'],
      'de2bf1a542a331ea79fadddb81e315120e46c2e3b8204ea239e30fb4aaa616cd',
    );
  });

  test('bundled activity rows omit prices, raw analyses, and coefficients', () {
    expect(
      canonicalRoot.keys,
      unorderedEquals([
        'metadata',
        'profile_fields',
        'wbs_packages',
        'activities',
      ]),
    );

    final activities = canonicalRoot['activities'] as List<dynamic>;
    for (final value in activities) {
      final activity = value as Map<String, dynamic>;
      expect(
        activity.keys,
        unorderedEquals([
          'activity_id',
          'wbs_code',
          'package_id',
          'activity_name_tr',
          'aliases_tr',
          'applicability',
          'repeat_dimension',
          'natural_unit',
          'duration_status',
          'duration_confidence',
          'test_seed_duration_days',
          'sequence_confidence',
          'sequence_index',
        ]),
      );
    }

    const forbiddenKeyFragments = [
      'price',
      'fiyat',
      'raw_text',
      'analysis_description',
      'full_analysis',
      'resource_coefficient',
      'material_coefficient',
      'labor_coefficient',
      'machine_coefficient',
      'yfk_analysis',
    ];
    for (final key in _collectKeys(canonicalRoot)) {
      final normalized = key.toLowerCase();
      expect(
        forbiddenKeyFragments.any(normalized.contains),
        isFalse,
        reason: 'Forbidden runtime key: $key',
      );
    }
  });

  test('wrong corpus version fails closed', () async {
    final root = _copyCanonicalRoot(canonicalRoot);
    _metadata(root)['corpus_version'] = '0.4';

    await expectLater(
      _repositoryForRoot(root).load(),
      _throwsCorpusFailure('unsupported_corpus_version'),
    );
  });

  test('wrong publication status fails closed', () async {
    final root = _copyCanonicalRoot(canonicalRoot);
    _metadata(root)['source_publication_status'] = 'PUBLIC';

    await expectLater(
      _repositoryForRoot(root).load(),
      _throwsCorpusFailure('unexpected_publication_status'),
    );
  });

  test('wrong production status fails closed', () async {
    final root = _copyCanonicalRoot(canonicalRoot);
    _metadata(root)['source_production_status'] = 'PRODUCTION';

    await expectLater(
      _repositoryForRoot(root).load(),
      _throwsCorpusFailure('unexpected_production_status'),
    );
  });

  test('wrong runtime scope fails closed', () async {
    final root = _copyCanonicalRoot(canonicalRoot);
    _metadata(root)['runtime_scope'] = 'FULL_CORPUS';

    await expectLater(
      _repositoryForRoot(root).load(),
      _throwsCorpusFailure('unsupported_runtime_scope'),
    );
  });

  test('non-canonical declared counts fail closed', () async {
    final root = _copyCanonicalRoot(canonicalRoot);
    (_metadata(root)['counts'] as Map<String, dynamic>)['activities'] = 315;

    await expectLater(
      _repositoryForRoot(root).load(),
      _throwsCorpusFailure('unexpected_corpus_counts'),
    );
  });

  test('metadata and physical count mismatch fails closed', () async {
    final root = _copyCanonicalRoot(canonicalRoot);
    (root['activities'] as List<dynamic>).removeLast();

    await expectLater(
      _repositoryForRoot(root).load(),
      _throwsCorpusFailure('corpus_count_mismatch'),
    );
  });

  test('non-canonical profile field count fails closed', () async {
    final root = _copyCanonicalRoot(canonicalRoot);
    (root['profile_fields'] as List<dynamic>).removeLast();

    await expectLater(
      _repositoryForRoot(root).load(),
      _throwsCorpusFailure('unexpected_profile_field_count'),
    );
  });

  test('duplicate activities are rejected', () async {
    final root = _copyCanonicalRoot(canonicalRoot);
    final activities = root['activities'] as List<dynamic>;
    activities[activities.length - 1] = Map<String, dynamic>.from(
      activities.first as Map,
    );

    await expectLater(
      _repositoryForRoot(root).load(),
      _throwsCorpusFailure('duplicate_activity'),
    );
  });

  test('duplicate WBS or package identifiers are rejected', () async {
    for (final duplicateKey in ['wbs_code', 'package_id']) {
      final root = _copyCanonicalRoot(canonicalRoot);
      final packages = root['wbs_packages'] as List<dynamic>;
      final first = packages.first as Map<String, dynamic>;
      final last = packages.last as Map<String, dynamic>;
      last[duplicateKey] = first[duplicateKey];

      await expectLater(
        _repositoryForRoot(root).load(),
        _throwsCorpusFailure('duplicate_wbs'),
        reason: duplicateKey,
      );
    }
  });

  test('unknown WBS/package references are rejected', () async {
    final root = _copyCanonicalRoot(canonicalRoot);
    final activity =
        (root['activities'] as List<dynamic>).first as Map<String, dynamic>;
    activity['wbs_code'] = '99';

    await expectLater(
      _repositoryForRoot(root).load(),
      _throwsCorpusFailure('dangling_activity_package'),
    );
  });

  test(
    'individually valid WBS and package in an invalid pair are rejected',
    () async {
      final root = _copyCanonicalRoot(canonicalRoot);
      final packages = root['wbs_packages'] as List<dynamic>;
      final activity =
          (root['activities'] as List<dynamic>).first as Map<String, dynamic>;
      final foreignPackage =
          packages.firstWhere(
                (value) =>
                    (value as Map<String, dynamic>)['wbs_code'] !=
                    activity['wbs_code'],
              )
              as Map<String, dynamic>;
      activity['package_id'] = foreignPackage['package_id'];

      await expectLater(
        _repositoryForRoot(root).load(),
        _throwsCorpusFailure('dangling_activity_package'),
      );
    },
  );

  test('nested unknown profile field makes corpus load fail', () async {
    final root = _copyCanonicalRoot(canonicalRoot);
    _firstActivity(root)['applicability'] = {
      'op': 'any',
      'rules': [
        {'field': 'unknown_project_field', 'op': 'eq', 'value': true},
      ],
    };

    await expectLater(
      _repositoryForRoot(root).load(),
      _throwsCorpusFailure('unknown_applicability_field'),
    );
  });

  test('nested unsupported applicability op makes corpus load fail', () async {
    final root = _copyCanonicalRoot(canonicalRoot);
    _firstActivity(root)['applicability'] = {
      'op': 'any',
      'rules': [
        {'op': 'script'},
      ],
    };

    await expectLater(
      _repositoryForRoot(root).load(),
      _throwsCorpusFailure('unsupported_applicability'),
    );
  });

  test(
    'nested malformed applicability operands make corpus load fail',
    () async {
      final invalidRules = <Map<String, dynamic>>[
        {
          'op': 'any',
          'rules': [
            {'field': 'foundation_type', 'op': 'eq'},
          ],
        },
        {'op': 'any', 'rules': <Object?>[]},
        {'op': 'not'},
      ];

      for (final invalidRule in invalidRules) {
        final root = _copyCanonicalRoot(canonicalRoot);
        _firstActivity(root)['applicability'] = invalidRule;
        await expectLater(
          _repositoryForRoot(root).load(),
          _throwsCorpusFailure('invalid_applicability'),
          reason: jsonEncode(invalidRule),
        );
      }
    },
  );

  test('missing field fails closed for eq, neq, and in', () {
    final rules = [
      ConstructionApplicabilityRule.fromJson({
        'field': 'foundation_type',
        'op': 'eq',
        'value': 'RADYE',
      }),
      ConstructionApplicabilityRule.fromJson({
        'field': 'foundation_type',
        'op': 'neq',
        'value': 'NONE',
      }),
      ConstructionApplicabilityRule.fromJson({
        'field': 'foundation_type',
        'op': 'in',
        'values': ['RADYE', 'TEKIL'],
      }),
    ];

    for (final rule in rules) {
      expect(rule.matches(const <String, Object?>{}), isFalse);
    }
  });

  test('all and not preserve recursive missing-field fail-closed behavior', () {
    final rule = ConstructionApplicabilityRule.fromJson({
      'op': 'all',
      'rules': [
        {'field': 'has_basement', 'op': 'eq', 'value': true},
        {
          'op': 'not',
          'rule': {'field': 'foundation_type', 'op': 'eq', 'value': 'TEKIL'},
        },
      ],
    });

    expect(
      rule.matches({'has_basement': true, 'foundation_type': 'RADYE'}),
      isTrue,
    );
    expect(rule.matches({'has_basement': true}), isFalse);
  });

  test('RADYE profile includes RADYE branch without TEKIL leakage', () async {
    final corpus = await BundledConstructionCorpusRepository().load();
    final activities = corpus.filterActivities(
      validConstructionProjectProfile(),
    );

    expect(
      activities.any((activity) => activity.activityId.contains('-RADYE-')),
      isTrue,
    );
    expect(
      activities.where((activity) => activity.activityId.contains('-TEKIL-')),
      isEmpty,
    );
  });

  test(
    'identical profile input produces an identical ordered ID sequence',
    () async {
      final corpus = await BundledConstructionCorpusRepository().load();

      final first = corpus
          .filterActivities(validConstructionProjectProfile())
          .map((activity) => activity.activityId)
          .toList();
      final second = corpus
          .filterActivities(validConstructionProjectProfile())
          .map((activity) => activity.activityId)
          .toList();

      expect(first, orderedEquals(second));
    },
  );

  test('DOLGU search is Turkish-normalized and deterministic', () async {
    final corpus = await BundledConstructionCorpusRepository().load();

    final upper = corpus
        .searchActivities('DOLGU')
        .map((activity) => activity.activityId)
        .toList();
    final lower = corpus
        .searchActivities('dolgu')
        .map((activity) => activity.activityId)
        .toList();

    expect(upper, isNotEmpty);
    expect(upper, orderedEquals(lower));
    expect(upper.every((id) => id.contains('DOLGU')), isTrue);
  });
}

BundledConstructionCorpusRepository _repositoryForRoot(
  Map<String, dynamic> root,
) => BundledConstructionCorpusRepository(
  loader: (_) async => base64Encode(gzip.encode(utf8.encode(jsonEncode(root)))),
);

Map<String, dynamic> _decodeAsset(List<int> assetBytes) {
  final runtimeJson = gzip.decode(base64Decode(utf8.decode(assetBytes).trim()));
  return jsonDecode(utf8.decode(runtimeJson)) as Map<String, dynamic>;
}

Map<String, dynamic> _copyCanonicalRoot(Map<String, dynamic> root) =>
    jsonDecode(jsonEncode(root)) as Map<String, dynamic>;

Map<String, dynamic> _metadata(Map<String, dynamic> root) =>
    root['metadata'] as Map<String, dynamic>;

Map<String, dynamic> _firstActivity(Map<String, dynamic> root) =>
    (root['activities'] as List<dynamic>).first as Map<String, dynamic>;

Matcher _throwsCorpusFailure(String code) => throwsA(
  isA<ConstructionCorpusFailure>().having(
    (failure) => failure.code,
    'code',
    code,
  ),
);

Set<String> _collectKeys(Object? value) {
  final result = <String>{};

  void visit(Object? item) {
    if (item is Map) {
      for (final entry in item.entries) {
        if (entry.key is String) {
          result.add(entry.key as String);
        }
        visit(entry.value);
      }
    } else if (item is List) {
      for (final child in item) {
        visit(child);
      }
    }
  }

  visit(value);
  return result;
}
