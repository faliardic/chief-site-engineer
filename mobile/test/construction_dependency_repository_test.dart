import 'dart:convert';
import 'dart:io';

import 'package:chief_site_engineer/application/construction_corpus_repository.dart';
import 'package:chief_site_engineer/application/construction_dependency_repository.dart';
import 'package:chief_site_engineer/domain/construction_corpus_models.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/construction_profile_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<int> canonicalAssetBytes;
  late Map<String, dynamic> canonicalRoot;
  late ConstructionCorpus activityCorpus;

  setUpAll(() async {
    canonicalAssetBytes = await File(
      BundledConstructionDependencyCatalogRepository.defaultAssetPath,
    ).readAsBytes();
    canonicalRoot = _decodeAsset(canonicalAssetBytes);
    activityCorpus = await BundledConstructionCorpusRepository().load();
  });

  group('typed project profile', () {
    test('canonical profile parses into typed values', () {
      final profile = validConstructionProjectProfile();

      expect(profile.projectId, 'PRJ-001');
      expect(profile.projectType, ConstructionProjectType.residential);
      expect(profile.foundationType, ConstructionFoundationType.raft);
      expect(
        profile.structuralSystem,
        ConstructionStructuralSystem.shearWallFrame,
      );
      expect(profile.blocks.single.blockId, 'A');
      expect(profile.calendar.startDate, DateTime.utc(2026, 8, 15));
      expect(profile.calendar.workdayHours, 8);
    });

    test('every canonical enum value in every family is accepted', () {
      final enumValues = <String, List<String>>{
        'project_type': [
          'KONUT',
          'OFIS',
          'TICARI',
          'OKUL',
          'YURT',
          'HASTANE_GENEL',
          'KAMU',
          'OTEL',
          'KARMA',
        ],
        'foundation_type': ['RADYE', 'TEKIL', 'SUREKLI', 'KAZIKLI_RADYE'],
        'structural_system': [
          'PERDE_CERCEVE',
          'CERCEVE',
          'PERDE_AGIRLIKLI',
          'TUNEL_KALIP',
          'KARMA',
        ],
        'formwork_system': ['KONVANSIYONEL', 'TUNEL', 'TIRMANIR', 'KARMA'],
        'wall_type': ['GAZBETON', 'TUGLA', 'ALCIPAN', 'KARMA'],
        'facade_type': [
          'MANTOLAMA',
          'GIYDIRME',
          'TAS',
          'SERAMIK',
          'KARMA',
          'DIGER',
          'NONE',
        ],
        'roof_type': ['TERAS', 'EGIMLI', 'KARMA'],
        'heating_system': [
          'MERKEZI',
          'BAGIMSIZ',
          'ISI_POMPASI',
          'YOK',
          'DIGER',
        ],
        'cooling_system': ['VRF', 'CHILLER', 'SPLIT', 'YOK', 'DIGER'],
      };

      for (final entry in enumValues.entries) {
        for (final value in entry.value) {
          expect(
            () =>
                validConstructionProjectProfile(overrides: {entry.key: value}),
            returnsNormally,
            reason: '${entry.key}=$value',
          );
        }
      }
    });

    test('unknown and missing project properties fail closed', () {
      final unknown = validConstructionProjectProfileJson()
        ..['unexpected'] = true;
      final missing = validConstructionProjectProfileJson()..remove('calendar');

      _expectProfileFailure(unknown, 'unknown_project_profile_property');
      _expectProfileFailure(missing, 'missing_project_profile_property');
    });

    test('invalid enum fails closed', () {
      _expectProfileFailure(
        validConstructionProjectProfileJson(
          overrides: const {'foundation_type': 'UNKNOWN'},
        ),
        'invalid_project_profile_enum',
      );
    });

    test('malformed project and block IDs fail closed', () {
      _expectProfileFailure(
        validConstructionProjectProfileJson(
          overrides: const {'project_id': 'bad id'},
        ),
        'invalid_project_id',
      );

      final invalidBlock = validConstructionProjectProfileJson();
      _firstProfileBlock(invalidBlock)['block_id'] = 'lowercase';
      _expectProfileFailure(invalidBlock, 'invalid_block_id');
    });

    test('empty project name fails closed', () {
      _expectProfileFailure(
        validConstructionProjectProfileJson(
          overrides: const {'project_name': '   '},
        ),
        'invalid_project_name',
      );
    });

    test('invalid block count and physical mismatch fail closed', () {
      _expectProfileFailure(
        validConstructionProjectProfileJson(
          overrides: const {'block_count': 0},
        ),
        'invalid_block_count',
      );
      _expectProfileFailure(
        validConstructionProjectProfileJson(
          overrides: const {'block_count': 2},
        ),
        'block_count_mismatch',
      );
    });

    test('duplicate block ID fails closed', () {
      final profile = validConstructionProjectProfileJson();
      final first = Map<String, Object?>.from(_firstProfileBlock(profile));
      profile['blocks'] = <Object?>[first, Map<String, Object?>.from(first)];
      profile['block_count'] = 2;

      _expectProfileFailure(profile, 'duplicate_block_id');
    });

    test('floor and basement ranges fail closed', () {
      final invalidFloor = validConstructionProjectProfileJson();
      _firstProfileBlock(invalidFloor)['floor_count'] = 0;
      _expectProfileFailure(invalidFloor, 'invalid_floor_count');

      final invalidBasement = validConstructionProjectProfileJson();
      _firstProfileBlock(invalidBasement)['basement_count'] = 21;
      _expectProfileFailure(invalidBasement, 'invalid_basement_count');
    });

    test('hasBasement must agree with block topology', () {
      _expectProfileFailure(
        validConstructionProjectProfileJson(
          overrides: const {'has_basement': false},
        ),
        'inconsistent_basement_profile',
      );
    });

    test('facade elevations reject duplicates and malformed tokens', () {
      _expectProfileFailure(
        validConstructionProjectProfileJson(
          overrides: const {
            'facade_elevations': <Object?>['NORTH', 'NORTH'],
          },
        ),
        'duplicate_facade_elevation',
      );
      _expectProfileFailure(
        validConstructionProjectProfileJson(
          overrides: const {
            'facade_elevations': <Object?>['north face'],
          },
        ),
        'invalid_facade_elevation',
      );
    });

    test('zones, lot, and test batch counts reject invalid values', () {
      final invalidCounts = <String>[
        'zones_per_block',
        'lot_count',
        'test_batch_count',
      ];
      final expectedCodes = <String>[
        'invalid_zones_per_block',
        'invalid_lot_count',
        'invalid_test_batch_count',
      ];
      for (var index = 0; index < invalidCounts.length; index += 1) {
        _expectProfileFailure(
          validConstructionProjectProfileJson(
            overrides: {invalidCounts[index]: 0},
          ),
          expectedCodes[index],
        );
      }
    });

    test('malformed start date fails closed', () {
      final profile = validConstructionProjectProfileJson();
      _profileCalendar(profile)['start_date'] = '2026-02-30';

      _expectProfileFailure(profile, 'invalid_project_date');
    });

    test('duplicate and out-of-range weekdays fail closed', () {
      final duplicate = validConstructionProjectProfileJson();
      _profileCalendar(duplicate)['working_weekdays'] = <Object?>[0, 0];
      _expectProfileFailure(duplicate, 'duplicate_working_weekday');

      final outOfRange = validConstructionProjectProfileJson();
      _profileCalendar(outOfRange)['working_weekdays'] = <Object?>[7];
      _expectProfileFailure(outOfRange, 'invalid_working_weekday');
    });

    test('duplicate and malformed holidays fail closed', () {
      final duplicate = validConstructionProjectProfileJson();
      _profileCalendar(duplicate)['holidays'] = <Object?>[
        '2026-08-30',
        '2026-08-30',
      ];
      _expectProfileFailure(duplicate, 'duplicate_project_holiday');

      final malformed = validConstructionProjectProfileJson();
      _profileCalendar(malformed)['holidays'] = <Object?>['2026-13-01'];
      _expectProfileFailure(malformed, 'invalid_project_date');
    });

    test('workday hours outside the canonical range fail closed', () {
      for (final value in <num>[0, 24.1, double.nan]) {
        final profile = validConstructionProjectProfileJson();
        _profileCalendar(profile)['workday_hours'] = value;
        _expectProfileFailure(profile, 'invalid_workday_hours');
      }
    });

    test('applicability map has exactly the canonical 29 fields', () {
      final map = validConstructionProjectProfile().toApplicabilityMap();

      expect(map, hasLength(29));
      expect(
        map.keys,
        orderedEquals(ConstructionProjectProfile.applicabilityFieldNames),
      );
      expect(map['foundation_type'], 'RADYE');
      expect(map['has_basement'], isTrue);
      expect(map.keys, isNot(contains('project_id')));
      expect(() => map['extra'] = true, throwsUnsupportedError);
    });
  });

  group('dependency catalog', () {
    test('canonical asset and decoded JSON hashes are exact', () {
      expect(
        sha256.convert(canonicalAssetBytes).toString(),
        '07f58de9912fe76303d18b48863b45aeaaac0f0f203aa14ebe8f8b1a8db12c86',
      );
      final runtimeJson = gzip.decode(
        base64Decode(utf8.decode(canonicalAssetBytes).trim()),
      );
      expect(
        sha256.convert(runtimeJson).toString(),
        '145f52622b3badf72e9f43107157a67f154056077aeb35d8f531661999ab68a1',
      );
    });

    test('bundled catalog loads the exact read-only contract', () async {
      final catalog = await BundledConstructionDependencyCatalogRepository()
          .load(activityCorpus);

      expect(catalog.dependencies, hasLength(362));
      expect(catalog.profileFields, hasLength(29));
      expect(catalog.metadata.activeActivityCount, 316);
      expect(catalog.metadata.dependencyCount, 362);
      expect(
        catalog.metadata.runtimeScope,
        BundledConstructionDependencyCatalogRepository.expectedRuntimeScope,
      );
      expect(
        catalog.dependencies
            .map((item) => item.relationshipType.jsonValue)
            .toSet(),
        {'FS', 'SS'},
      );
      expect(
        catalog.dependencies.map((item) => item.scopeRule.jsonValue).toSet(),
        ConstructionDependencyScopeRule.values
            .map((item) => item.jsonValue)
            .toSet(),
      );
    });

    test('dependency runtime omits schedule instances and resource data', () {
      const forbiddenKeyFragments = <String>[
        'price',
        'fiyat',
        'raw_text',
        'resource_coefficient',
        'schedule_date',
        'critical_path',
        'instance_id',
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

    test('non-canonical metadata fails closed', () async {
      final mutations = <String, Object?>{
        'corpus_version': '0.4',
        'source_publication_status': 'PUBLIC',
        'source_production_status': 'PRODUCTION',
        'runtime_scope': 'FULL_SCHEDULE',
      };
      for (final entry in mutations.entries) {
        final root = _copyCanonicalRoot(canonicalRoot);
        _metadata(root)[entry.key] = entry.value;
        await expectLater(
          _repositoryForRoot(root).load(activityCorpus),
          _throwsCorpusFailure('unexpected_dependency_metadata'),
          reason: entry.key,
        );
      }
    });

    test('declared and physical dependency counts fail closed', () async {
      final declared = _copyCanonicalRoot(canonicalRoot);
      (_metadata(declared)['counts'] as Map<String, dynamic>)['dependencies'] =
          361;
      await expectLater(
        _repositoryForRoot(declared).load(activityCorpus),
        _throwsCorpusFailure('unexpected_dependency_counts'),
      );

      final physical = _copyCanonicalRoot(canonicalRoot);
      (physical['dependencies'] as List<dynamic>).removeLast();
      await expectLater(
        _repositoryForRoot(physical).load(activityCorpus),
        _throwsCorpusFailure('dependency_count_mismatch'),
      );
    });

    test('profile field count and identity fail closed', () async {
      final count = _copyCanonicalRoot(canonicalRoot);
      (count['profile_fields'] as List<dynamic>).removeLast();
      await expectLater(
        _repositoryForRoot(count).load(activityCorpus),
        _throwsCorpusFailure('dependency_count_mismatch'),
      );

      final identity = _copyCanonicalRoot(canonicalRoot);
      final fields = identity['profile_fields'] as List<dynamic>;
      final first = fields.removeAt(0);
      fields.add(first);
      await expectLater(
        _repositoryForRoot(identity).load(activityCorpus),
        _throwsCorpusFailure('unexpected_dependency_profile_fields'),
      );
    });

    test('invalid activity authority fails closed', () async {
      final invalidAuthority = ConstructionCorpus(
        metadata: activityCorpus.metadata,
        profileFields: activityCorpus.profileFields,
        wbsPackages: activityCorpus.wbsPackages,
        activities: activityCorpus.activities.take(315),
      );

      await expectLater(
        _repositoryForRoot(canonicalRoot).load(invalidAuthority),
        _throwsCorpusFailure('invalid_dependency_activity_authority'),
      );
    });

    test('duplicate dependency ID fails closed', () async {
      final root = _copyCanonicalRoot(canonicalRoot);
      final dependencies = root['dependencies'] as List<dynamic>;
      final first = dependencies.first as Map<String, dynamic>;
      (dependencies.last as Map<String, dynamic>)['dependency_id'] =
          first['dependency_id'];

      await expectLater(
        _repositoryForRoot(root).load(activityCorpus),
        _throwsCorpusFailure('duplicate_dependency'),
      );
    });

    test('self-loop fails closed', () async {
      final root = _copyCanonicalRoot(canonicalRoot);
      final dependency = _firstDependency(root);
      dependency['successor_activity_id'] =
          dependency['predecessor_activity_id'];

      await expectLater(
        _repositoryForRoot(root).load(activityCorpus),
        _throwsCorpusFailure('dependency_self_loop'),
      );
    });

    test('unknown predecessor and successor fail closed', () async {
      final mutations = <String, String>{
        'predecessor_activity_id': 'UNKNOWN-PREDECESSOR',
        'successor_activity_id': 'UNKNOWN-SUCCESSOR',
      };
      final expectedCodes = <String, String>{
        'predecessor_activity_id': 'unknown_dependency_predecessor',
        'successor_activity_id': 'unknown_dependency_successor',
      };
      for (final entry in mutations.entries) {
        final root = _copyCanonicalRoot(canonicalRoot);
        _firstDependency(root)[entry.key] = entry.value;
        await expectLater(
          _repositoryForRoot(root).load(activityCorpus),
          _throwsCorpusFailure(expectedCodes[entry.key]!),
          reason: entry.key,
        );
      }
    });

    test('unknown relationship and lag unit fail closed', () async {
      final mutations = <String, String>{
        'relationship_type': 'FF',
        'lag_unit': 'CALENDAR_DAY',
      };
      final expectedCodes = <String, String>{
        'relationship_type': 'invalid_dependency_relationship_type',
        'lag_unit': 'invalid_dependency_lag_unit',
      };
      for (final entry in mutations.entries) {
        final root = _copyCanonicalRoot(canonicalRoot);
        _firstDependency(root)[entry.key] = entry.value;
        await expectLater(
          _repositoryForRoot(root).load(activityCorpus),
          _throwsCorpusFailure(expectedCodes[entry.key]!),
          reason: entry.key,
        );
      }
    });

    test('negative lag and invalid floor offset fail closed', () async {
      final lag = _copyCanonicalRoot(canonicalRoot);
      _firstDependency(lag)['lag_value'] = -1;
      await expectLater(
        _repositoryForRoot(lag).load(activityCorpus),
        _throwsCorpusFailure('invalid_dependency_lag'),
      );

      final floor = _copyCanonicalRoot(canonicalRoot);
      _firstDependency(floor)['floor_offset'] = 2;
      await expectLater(
        _repositoryForRoot(floor).load(activityCorpus),
        _throwsCorpusFailure('invalid_dependency_floor_offset'),
      );
    });

    test('unknown scope, confidence, and review status fail closed', () async {
      final mutations = <String, String>{
        'scope_rule': 'SOMEWHERE',
        'confidence': 'A_APPROVED',
        'review_status': 'APPROVED',
      };
      final expectedCodes = <String, String>{
        'scope_rule': 'invalid_dependency_scope_rule',
        'confidence': 'invalid_dependency_confidence',
        'review_status': 'invalid_dependency_review_status',
      };
      for (final entry in mutations.entries) {
        final root = _copyCanonicalRoot(canonicalRoot);
        _firstDependency(root)[entry.key] = entry.value;
        await expectLater(
          _repositoryForRoot(root).load(activityCorpus),
          _throwsCorpusFailure(expectedCodes[entry.key]!),
          reason: entry.key,
        );
      }
    });

    test('nested unknown condition field fails closed', () async {
      final root = _copyCanonicalRoot(canonicalRoot);
      _firstDependency(root)['condition'] = <String, Object?>{
        'op': 'all',
        'rules': <Object?>[
          <String, Object?>{
            'op': 'eq',
            'field': 'unknown_profile_field',
            'value': true,
          },
        ],
      };

      await expectLater(
        _repositoryForRoot(root).load(activityCorpus),
        _throwsCorpusFailure('unknown_applicability_field'),
      );
    });

    test('nested unknown condition op fails closed', () async {
      final root = _copyCanonicalRoot(canonicalRoot);
      _firstDependency(root)['condition'] = <String, Object?>{
        'op': 'not',
        'rule': <String, Object?>{'op': 'script'},
      };

      await expectLater(
        _repositoryForRoot(root).load(activityCorpus),
        _throwsCorpusFailure('unsupported_applicability'),
      );
    });

    test('unknown recursive condition property fails closed', () async {
      final root = _copyCanonicalRoot(canonicalRoot);
      _firstDependency(root)['condition'] = <String, Object?>{
        'op': 'always',
        'unexpected': true,
      };

      await expectLater(
        _repositoryForRoot(root).load(activityCorpus),
        _throwsCorpusFailure('invalid_applicability'),
      );
    });

    test('unselected endpoint leakage is zero', () async {
      final catalog = await BundledConstructionDependencyCatalogRepository()
          .load(activityCorpus);
      final dependency = catalog.dependencies.first;

      final filtered = catalog.dependenciesForSelectedActivities({
        dependency.predecessorActivityId,
      }, validConstructionProjectProfile());

      expect(filtered, isEmpty);
    });

    test('condition mismatch leakage is zero', () async {
      final root = _copyCanonicalRoot(canonicalRoot);
      final dependency = _firstDependency(root);
      dependency['condition'] = <String, Object?>{
        'op': 'eq',
        'field': 'foundation_type',
        'value': 'TEKIL',
      };
      final dependencyId = dependency['dependency_id'] as String;
      final catalog = await _repositoryForRoot(root).load(activityCorpus);

      final filtered = catalog.dependenciesForSelectedActivities({
        dependency['predecessor_activity_id'] as String,
        dependency['successor_activity_id'] as String,
      }, validConstructionProjectProfile());

      expect(
        filtered.where((item) => item.dependencyId == dependencyId),
        isEmpty,
      );
    });

    test(
      'identical filtering is complete and deterministically ordered',
      () async {
        final catalog = await BundledConstructionDependencyCatalogRepository()
            .load(activityCorpus);
        final selectedIds = activityCorpus.activities
            .map((activity) => activity.activityId)
            .toSet();

        final first = catalog
            .dependenciesForSelectedActivities(
              selectedIds,
              validConstructionProjectProfile(),
            )
            .map((dependency) => dependency.dependencyId)
            .toList();
        final second = catalog
            .dependenciesForSelectedActivities(
              selectedIds,
              validConstructionProjectProfile(),
            )
            .map((dependency) => dependency.dependencyId)
            .toList();
        final sorted = List<String>.from(first)..sort();

        expect(first, hasLength(362));
        expect(first, orderedEquals(second));
        expect(first, orderedEquals(sorted));
      },
    );
  });
}

BundledConstructionDependencyCatalogRepository _repositoryForRoot(
  Map<String, dynamic> root,
) => BundledConstructionDependencyCatalogRepository(
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

Map<String, dynamic> _firstDependency(Map<String, dynamic> root) =>
    (root['dependencies'] as List<dynamic>).first as Map<String, dynamic>;

Map<String, Object?> _firstProfileBlock(Map<String, Object?> profile) =>
    (profile['blocks'] as List<Object?>).first as Map<String, Object?>;

Map<String, Object?> _profileCalendar(Map<String, Object?> profile) =>
    profile['calendar'] as Map<String, Object?>;

void _expectProfileFailure(Map<String, Object?> profile, String code) {
  expect(
    () => ConstructionProjectProfile.fromJson(profile),
    _throwsCorpusFailure(code),
  );
}

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
