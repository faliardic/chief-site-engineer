import 'dart:convert';

import 'package:chief_site_engineer/application/construction_corpus_repository.dart';
import 'package:chief_site_engineer/application/construction_dependency_repository.dart';
import 'package:chief_site_engineer/application/construction_project_graph_builder.dart';
import 'package:chief_site_engineer/domain/construction_corpus_models.dart';
import 'package:chief_site_engineer/domain/construction_project_graph_models.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/construction_profile_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ConstructionCorpus corpus;
  late ConstructionDependencyCatalog dependencies;
  late Map<String, ConstructionProjectActivityGraph> referenceGraphs;

  setUpAll(() async {
    corpus = await BundledConstructionCorpusRepository().load();
    dependencies = await BundledConstructionDependencyCatalogRepository().load(
      corpus,
    );
    final builder = ConstructionProjectActivityGraphBuilder();
    referenceGraphs = {
      for (final profile in [
        referenceConstructionProfile01(),
        referenceConstructionProfile02(),
        referenceConstructionProfile03(),
      ])
        profile.projectId: builder.buildFromCatalogs(
          profile: profile,
          corpus: corpus,
          dependencyCatalog: dependencies,
        ),
    };
  });

  group('repeat dimension and instance context', () {
    test('all 9 exact repeat dimension values are typed', () {
      expect(
        ConstructionActivityRepeatDimension.values.map(
          (value) => value.jsonValue,
        ),
        orderedEquals(const [
          'PROJECT',
          'BLOCK',
          'BASEMENT',
          'FLOOR',
          'ZONE',
          'FACADE_ELEVATION',
          'ROOF',
          'LOT',
          'SYSTEM',
        ]),
      );
      for (final value in ConstructionActivityRepeatDimension.values) {
        expect(
          ConstructionActivityRepeatDimension.fromJson(value.jsonValue),
          value,
        );
      }
    });

    test('unknown repeat dimension fails closed', () {
      expect(
        () => ConstructionActivityRepeatDimension.fromJson('ROOM'),
        _throwsCorpusFailure('invalid_activity_repeat_dimension'),
      );
    });

    test('all context and instance ID forms are exact and deterministic', () {
      final activities = <ConstructionActivity>[
        for (final dimension in ConstructionActivityRepeatDimension.values)
          _activity('ACT-${dimension.jsonValue}', dimension),
      ];
      final graph = _buildCustomGraph(
        profile: _mixedProfile(),
        activities: activities,
      );
      final ids = graph.activityInstances
          .map((instance) => instance.instanceId)
          .toSet();

      expect(ids, contains('ACT-PROJECT@PROJECT'));
      expect(ids, contains('ACT-BLOCK@B-A'));
      expect(ids, contains('ACT-BASEMENT@B-A/BS-01'));
      expect(ids, contains('ACT-FLOOR@B-A/F-01'));
      expect(ids, contains('ACT-ZONE@B-A/Z-01'));
      expect(ids, contains('ACT-FACADE_ELEVATION@B-A/FA-N'));
      expect(ids, contains('ACT-ROOF@B-A/R-MAIN'));
      expect(ids, contains('ACT-LOT@LOT-01'));
      expect(ids, contains('ACT-SYSTEM@SYS-SYSTEM'));
      expect(
        graph.activityInstances.map((instance) => instance.instanceId),
        orderedEquals(
          [...graph.activityInstances.map((instance) => instance.instanceId)]
            ..sort(),
        ),
      );
      expect(
        graph.activityInstances
            .singleWhere((item) => item.instanceId == 'ACT-PROJECT@PROJECT')
            .context
            .toJson(),
        isEmpty,
      );
    });

    test(
      'numeric suffixes have minimum two digits and do not truncate 100',
      () {
        final profile = validConstructionProjectProfile(
          overrides: {
            'blocks': <Object?>[
              <String, Object?>{
                'block_id': 'A',
                'floor_count': 100,
                'basement_count': 0,
              },
            ],
            'zones_per_block': 100,
            'lot_count': 100,
            'has_basement': false,
          },
        );
        final graph = _buildCustomGraph(
          profile: profile,
          activities: [
            _activity('ACT-FLOOR', ConstructionActivityRepeatDimension.floor),
            _activity('ACT-ZONE', ConstructionActivityRepeatDimension.zone),
            _activity('ACT-LOT', ConstructionActivityRepeatDimension.lot),
          ],
        );
        final ids = graph.activityInstances
            .map((instance) => instance.instanceId)
            .toSet();
        expect(ids, containsAll(['ACT-FLOOR@B-A/F-100', 'ACT-ZONE@B-A/Z-100']));
        expect(ids, contains('ACT-LOT@LOT-100'));
      },
    );

    test('no-basement block creates zero basement instances', () {
      final graph = _buildCustomGraph(
        profile: _noBasementProfile(),
        activities: [
          _activity(
            'ACT-BASEMENT',
            ConstructionActivityRepeatDimension.basement,
          ),
        ],
      );
      expect(graph.activityInstances, isEmpty);
    });

    test('duplicate generated instance ID fails closed', () {
      expect(
        () => _buildCustomGraph(
          profile: _noBasementProfile(),
          activities: [
            _activity('ACT-DUP', ConstructionActivityRepeatDimension.project),
            _activity('ACT-DUP', ConstructionActivityRepeatDimension.project),
          ],
        ),
        _throwsCorpusFailure('duplicate_activity_instance'),
      );
    });
  });

  group('20 canonical scope rules', () {
    final allReferenceEdges = <ConstructionResolvedDependencyEdge>[];

    setUpAll(() {
      for (final graph in referenceGraphs.values) {
        allReferenceEdges.addAll(graph.dependencyEdges);
      }
    });

    for (final rule in ConstructionDependencyScopeRule.values) {
      test('${rule.jsonValue} resolves at least one canonical pair', () {
        if (rule ==
            ConstructionDependencyScopeRule.blockToFirstFloorIfNoBasement) {
          final graph = _twoActivityGraph(
            profile: _noBasementProfile(),
            predecessorDimension: ConstructionActivityRepeatDimension.block,
            successorDimension: ConstructionActivityRepeatDimension.floor,
            scopeRule: rule,
          );
          expect(graph.dependencyEdges, hasLength(1));
          return;
        }
        expect(allReferenceEdges.any((edge) => edge.scopeRule == rule), isTrue);
      });
    }
  });

  group('scope boundaries and graph integrity', () {
    test('SAME_FLOOR has no wrong block or floor leakage', () {
      final graph = _twoActivityGraph(
        profile: _mixedProfile(),
        predecessorDimension: ConstructionActivityRepeatDimension.floor,
        successorDimension: ConstructionActivityRepeatDimension.floor,
        scopeRule: ConstructionDependencyScopeRule.sameFloor,
      );
      expect(graph.dependencyEdges, hasLength(6));
      for (final edge in graph.dependencyEdges) {
        final predecessor = _instance(graph, edge.predecessorInstanceId);
        final successor = _instance(graph, edge.successorInstanceId);
        expect(predecessor.context.blockId, successor.context.blockId);
        expect(predecessor.context.floorIndex, successor.context.floorIndex);
      }
    });

    test('NEXT_FLOOR pairs the next floor and emits no top-floor overflow', () {
      final graph = _twoActivityGraph(
        profile: _mixedProfile(),
        predecessorDimension: ConstructionActivityRepeatDimension.floor,
        successorDimension: ConstructionActivityRepeatDimension.floor,
        scopeRule: ConstructionDependencyScopeRule.nextFloor,
        floorOffset: 1,
      );
      expect(graph.dependencyEdges, hasLength(4));
      for (final edge in graph.dependencyEdges) {
        final predecessor = _instance(graph, edge.predecessorInstanceId);
        final successor = _instance(graph, edge.successorInstanceId);
        expect(predecessor.context.blockId, successor.context.blockId);
        expect(
          successor.context.floorIndex,
          predecessor.context.floorIndex! + 1,
        );
      }
    });

    test('NEXT_BASEMENT pairs the next basement and emits no overflow', () {
      final graph = _twoActivityGraph(
        profile: _mixedProfile(),
        predecessorDimension: ConstructionActivityRepeatDimension.basement,
        successorDimension: ConstructionActivityRepeatDimension.basement,
        scopeRule: ConstructionDependencyScopeRule.nextBasement,
      );
      expect(graph.dependencyEdges, hasLength(1));
      expect(
        graph.dependencyEdges.single.predecessorInstanceId,
        endsWith('/BS-01'),
      );
      expect(
        graph.dependencyEdges.single.successorInstanceId,
        endsWith('/BS-02'),
      );
    });

    test('no-basement bridge resolves only on the no-basement block', () {
      final graph = _twoActivityGraph(
        profile: _mixedProfile(),
        predecessorDimension: ConstructionActivityRepeatDimension.block,
        successorDimension: ConstructionActivityRepeatDimension.floor,
        scopeRule:
            ConstructionDependencyScopeRule.blockToFirstFloorIfNoBasement,
      );
      expect(graph.dependencyEdges, hasLength(1));
      expect(
        graph.dependencyEdges.single.predecessorInstanceId,
        endsWith('@B-B'),
      );
      expect(
        graph.dependencyEdges.single.successorInstanceId,
        endsWith('@B-B/F-01'),
      );
    });

    test('last-basement bridge resolves exact last basement to floor 1', () {
      final graph = _twoActivityGraph(
        profile: _mixedProfile(),
        predecessorDimension: ConstructionActivityRepeatDimension.basement,
        successorDimension: ConstructionActivityRepeatDimension.floor,
        scopeRule: ConstructionDependencyScopeRule.lastBasementToFirstFloor,
      );
      expect(graph.dependencyEdges, hasLength(1));
      expect(
        graph.dependencyEdges.single.predecessorInstanceId,
        endsWith('/BS-02'),
      );
      expect(
        graph.dependencyEdges.single.successorInstanceId,
        endsWith('/F-01'),
      );
    });

    test('top-floor-to-roof resolves each block top floor exactly', () {
      final graph = _twoActivityGraph(
        profile: _mixedProfile(),
        predecessorDimension: ConstructionActivityRepeatDimension.floor,
        successorDimension: ConstructionActivityRepeatDimension.roof,
        scopeRule: ConstructionDependencyScopeRule.topFloorToRoof,
      );
      expect(graph.dependencyEdges, hasLength(2));
      expect(
        graph.dependencyEdges.map((edge) => edge.predecessorInstanceId),
        containsAll([endsWith('@B-A/F-04'), endsWith('@B-B/F-02')]),
      );
    });

    for (final topFloor in [1, 2, 3, 4]) {
      test('floor-threshold-to-facade is exact for $topFloor floor(s)', () {
        final graph = _twoActivityGraph(
          profile: _singleBlockProfile(floorCount: topFloor, basementCount: 0),
          predecessorDimension: ConstructionActivityRepeatDimension.floor,
          successorDimension:
              ConstructionActivityRepeatDimension.facadeElevation,
          scopeRule: ConstructionDependencyScopeRule.floorThresholdToFacade,
        );
        expect(graph.dependencyEdges, hasLength(2));
        final threshold = topFloor < 3 ? topFloor : 3;
        expect(
          graph.dependencyEdges.every(
            (edge) => edge.predecessorInstanceId.endsWith(
              '/F-${threshold.toString().padLeft(2, '0')}',
            ),
          ),
          isTrue,
        );
      });
    }

    test('invalid NEXT_FLOOR floor offset fails closed', () {
      expect(
        () => _twoActivityGraph(
          profile: _mixedProfile(),
          predecessorDimension: ConstructionActivityRepeatDimension.floor,
          successorDimension: ConstructionActivityRepeatDimension.floor,
          scopeRule: ConstructionDependencyScopeRule.nextFloor,
          floorOffset: 0,
        ),
        _throwsCorpusFailure('invalid_scope_floor_offset'),
      );
    });

    test('non-NEXT_FLOOR offset fails closed', () {
      expect(
        () => _twoActivityGraph(
          profile: _mixedProfile(),
          predecessorDimension: ConstructionActivityRepeatDimension.floor,
          successorDimension: ConstructionActivityRepeatDimension.floor,
          scopeRule: ConstructionDependencyScopeRule.sameFloor,
          floorOffset: 1,
        ),
        _throwsCorpusFailure('invalid_scope_floor_offset'),
      );
    });

    test('missing selected template endpoint emits no repair edge', () {
      final graph = _buildCustomGraph(
        profile: _noBasementProfile(),
        activities: [
          _activity('ACT-PRED', ConstructionActivityRepeatDimension.project),
        ],
        dependencies: [
          _dependency(
            predecessorId: 'ACT-PRED',
            successorId: 'ACT-MISSING',
            scopeRule: ConstructionDependencyScopeRule.automatic,
          ),
        ],
      );
      expect(graph.dependencyEdges, isEmpty);
      expect(graph.isolatedInstanceIds, ['ACT-PRED@PROJECT']);
    });

    test('resolved self edge fails closed', () {
      expect(
        () => _buildCustomGraph(
          profile: _noBasementProfile(),
          activities: [
            _activity('ACT-SELF', ConstructionActivityRepeatDimension.project),
          ],
          dependencies: [
            _dependency(
              predecessorId: 'ACT-SELF',
              successorId: 'ACT-SELF',
              scopeRule: ConstructionDependencyScopeRule.automatic,
            ),
          ],
        ),
        _throwsCorpusFailure('resolved_dependency_self_loop'),
      );
    });

    test('duplicate deterministic edge key fails closed', () {
      expect(
        () => _buildCustomGraph(
          profile: _noBasementProfile(),
          activities: [
            _activity('ACT-PRED', ConstructionActivityRepeatDimension.project),
            _activity('ACT-SUCC', ConstructionActivityRepeatDimension.project),
          ],
          dependencies: [
            _dependency(
              predecessorId: 'ACT-PRED',
              successorId: 'ACT-SUCC',
              scopeRule: ConstructionDependencyScopeRule.automatic,
            ),
            _dependency(
              predecessorId: 'ACT-PRED',
              successorId: 'ACT-SUCC',
              scopeRule: ConstructionDependencyScopeRule.automatic,
            ),
          ],
        ),
        _throwsCorpusFailure('duplicate_resolved_dependency'),
      );
    });

    test('resolved graph cycle fails closed', () {
      expect(
        () => _buildCustomGraph(
          profile: _noBasementProfile(),
          activities: [
            _activity('ACT-A', ConstructionActivityRepeatDimension.project),
            _activity('ACT-B', ConstructionActivityRepeatDimension.project),
          ],
          dependencies: [
            _dependency(
              dependencyId: 'DEP-A-B',
              predecessorId: 'ACT-A',
              successorId: 'ACT-B',
              scopeRule: ConstructionDependencyScopeRule.automatic,
            ),
            _dependency(
              dependencyId: 'DEP-B-A',
              predecessorId: 'ACT-B',
              successorId: 'ACT-A',
              scopeRule: ConstructionDependencyScopeRule.automatic,
            ),
          ],
        ),
        _throwsCorpusFailure('resolved_graph_cycle'),
      );
    });
  });

  group('canonical full graph regression', () {
    final expected = <String, _ReferenceExpectation>{
      'CSE-P01': const _ReferenceExpectation(
        activityCount: 1687,
        activitySha:
            'f194731552003f16221f658acb7fd45ab761a05fbbb09926bd4d9670b644dd5a',
        dependencyCount: 1702,
        dependencySha:
            '0f9db030bd2098e1a25d649dddf7b5181ced75e51b0f7e3df55a930d473320c5',
        isolatedCount: 15,
        isolatedSha:
            '509a879fd5745019040a82344a8346c0a2c51835b4fb6af1aa880f97a6ee7048',
      ),
      'CSE-P02': const _ReferenceExpectation(
        activityCount: 599,
        activitySha:
            '5282aa8c3c0b8e3d186cae838689e3776f93bc6c572198306670b0bdaef85100',
        dependencyCount: 644,
        dependencySha:
            '921b54e397da434fd23e490313b10d2b3a46c6bb4cafbb6ad7df7a6d26d11f05',
        isolatedCount: 5,
        isolatedSha:
            '3b60bea4b7eb73751af98e72f2e785d8ae10dc49e8f748c95d791be57b34411d',
      ),
      'CSE-P03': const _ReferenceExpectation(
        activityCount: 3537,
        activitySha:
            '401bc7ed1d232aca982c014275e46c235d509022a0276920aa619383265453ea',
        dependencyCount: 3605,
        dependencySha:
            '74b7a8f768a0d7086511a2a346db1ba9db1441977605885e54d756474eec2681',
        isolatedCount: 39,
        isolatedSha:
            '545902672d0f17c90ccd3cde3efa4c95c56c86a8572ee6ee058268bc51cac73b',
      ),
    };

    for (final profileId in ['CSE-P01', 'CSE-P02', 'CSE-P03']) {
      test('$profileId counts and canonical fingerprints are exact', () {
        final graph = referenceGraphs[profileId]!;
        final reference = expected[profileId]!;
        expect(graph.activityInstances, hasLength(reference.activityCount));
        expect(
          _sha256Canonical(_activityProjection(graph)),
          reference.activitySha,
        );
        expect(graph.dependencyEdges, hasLength(reference.dependencyCount));
        expect(
          _sha256Canonical(_dependencyProjection(graph)),
          reference.dependencySha,
        );
        expect(graph.isolatedInstanceIds, hasLength(reference.isolatedCount));
        expect(
          _sha256Canonical(graph.isolatedInstanceIds),
          reference.isolatedSha,
        );
        expect(
          graph.dependencyEdges.where(
            (edge) =>
                edge.templateDependencyId == 'DERIVED-CONNECTIVITY' ||
                edge.templateDependencyId == 'D_AI_SEED',
          ),
          isEmpty,
        );
      });
    }

    test('repeated build is byte/order equivalent', () {
      final builder = ConstructionProjectActivityGraphBuilder();
      final profile = referenceConstructionProfile01();
      final rebuilt = builder.buildFromCatalogs(
        profile: profile,
        corpus: corpus,
        dependencyCatalog: dependencies,
      );
      final original = referenceGraphs['CSE-P01']!;
      expect(_activityProjection(rebuilt), _activityProjection(original));
      expect(_dependencyProjection(rebuilt), _dependencyProjection(original));
      expect(rebuilt.isolatedInstanceIds, original.isolatedInstanceIds);
    });

    test('equivalent reordered blocks and facades produce the same graph', () {
      final reordered = validConstructionProjectProfile(
        overrides: {
          'project_id': 'CSE-P03',
          'project_name': 'reordered',
          'blocks': <Object?>[
            <String, Object?>{
              'block_id': 'B',
              'floor_count': 12,
              'basement_count': 3,
            },
            <String, Object?>{
              'block_id': 'A',
              'floor_count': 18,
              'basement_count': 3,
            },
          ],
          'block_count': 2,
          'zones_per_block': 8,
          'facade_elevations': <Object?>['W', 'S', 'E', 'N'],
          'lot_count': 4,
          'test_batch_count': 4,
          'foundation_type': 'KAZIKLI_RADYE',
          'wall_type': 'KARMA',
          'facade_type': 'GIYDIRME',
          'roof_type': 'KARMA',
          'cooling_system': 'VRF',
          'has_dewatering': true,
          'ground_improvement_required': true,
          'has_piles': true,
          'foundation_thermal_insulation_required': true,
          'has_steel_auxiliary': true,
          'has_precast_auxiliary': true,
          'has_generator': true,
          'has_ups': true,
          'has_transformer': true,
          'has_bms': true,
        },
      );
      final graph = ConstructionProjectActivityGraphBuilder().buildFromCatalogs(
        profile: reordered,
        corpus: corpus,
        dependencyCatalog: dependencies,
      );
      final original = referenceGraphs['CSE-P03']!;
      expect(_activityProjection(graph), _activityProjection(original));
      expect(_dependencyProjection(graph), _dependencyProjection(original));
      expect(graph.isolatedInstanceIds, original.isolatedInstanceIds);
    });
  });
}

ConstructionProjectActivityGraph _twoActivityGraph({
  required ConstructionProjectProfile profile,
  required ConstructionActivityRepeatDimension predecessorDimension,
  required ConstructionActivityRepeatDimension successorDimension,
  required ConstructionDependencyScopeRule scopeRule,
  int floorOffset = 0,
}) => _buildCustomGraph(
  profile: profile,
  activities: [
    _activity('ACT-PRED', predecessorDimension),
    _activity('ACT-SUCC', successorDimension),
  ],
  dependencies: [
    _dependency(
      predecessorId: 'ACT-PRED',
      successorId: 'ACT-SUCC',
      scopeRule: scopeRule,
      floorOffset: floorOffset,
    ),
  ],
);

ConstructionProjectActivityGraph _buildCustomGraph({
  required ConstructionProjectProfile profile,
  required List<ConstructionActivity> activities,
  List<ConstructionDependency> dependencies = const [],
}) {
  final corpus = ConstructionCorpus(
    metadata: const ConstructionCorpusMetadata(
      name: 'test',
      corpusVersion: 'test',
      sourcePublicationStatus: 'test',
      sourceProductionStatus: 'test',
      warning: 'test',
      runtimeScope: 'test',
      wbsCount: 1,
      activityCount: 0,
    ),
    profileFields: ConstructionProjectProfile.applicabilityFieldNames,
    wbsPackages: const [
      ConstructionWbsPackage(
        wbsCode: '01',
        packageId: 'PKG',
        packageNameTr: 'Test',
        packageNameEn: 'Test',
        frequencyClass: 'TEST',
      ),
    ],
    activities: activities,
  );
  final catalog = ConstructionDependencyCatalog(
    metadata: const ConstructionDependencyCatalogMetadata(
      name: 'test',
      corpusVersion: 'test',
      sourcePublicationStatus: 'test',
      sourceProductionStatus: 'test',
      sourceZipSha256: 'test',
      warning: 'test',
      runtimeScope: 'test',
      activeActivityCount: 0,
      dependencyCount: 0,
      profileFieldCount: 29,
    ),
    profileFields: ConstructionProjectProfile.applicabilityFieldNames,
    dependencies: dependencies,
  );
  return ConstructionProjectActivityGraphBuilder().buildFromCatalogs(
    profile: profile,
    corpus: corpus,
    dependencyCatalog: catalog,
  );
}

ConstructionActivity _activity(
  String activityId,
  ConstructionActivityRepeatDimension dimension,
) => ConstructionActivity(
  activityId: activityId,
  wbsCode: '01',
  packageId: 'PKG',
  activityNameTr: activityId,
  aliasesTr: const [],
  applicability: const ConstructionAlwaysRule(),
  repeatDimension: dimension,
  naturalUnit: 'ADET',
  durationStatus: 'TEST_SEED_ONLY',
  durationConfidence: 'C_TEST_SEED',
  testSeedDurationDays: 1,
  sequenceConfidence: 'C_TEST_SEED',
  sequenceIndex: 1,
);

ConstructionDependency _dependency({
  String dependencyId = 'DEP-TEST',
  required String predecessorId,
  required String successorId,
  required ConstructionDependencyScopeRule scopeRule,
  int floorOffset = 0,
}) => ConstructionDependency(
  dependencyId: dependencyId,
  predecessorActivityId: predecessorId,
  successorActivityId: successorId,
  relationshipType: ConstructionDependencyRelationshipType.finishToStart,
  lagValue: 0,
  lagUnit: ConstructionDependencyLagUnit.workingDay,
  floorOffset: floorOffset,
  scopeRule: scopeRule,
  condition: const ConstructionAlwaysRule(),
  isMandatory: true,
  confidence: ConstructionDependencyConfidence.supportedInference,
  reviewStatus: ConstructionDependencyReviewStatus.reviewRequired,
);

ConstructionProjectProfile _mixedProfile() => validConstructionProjectProfile(
  overrides: {
    'blocks': <Object?>[
      <String, Object?>{'block_id': 'A', 'floor_count': 4, 'basement_count': 2},
      <String, Object?>{'block_id': 'B', 'floor_count': 2, 'basement_count': 0},
    ],
    'block_count': 2,
    'facade_elevations': <Object?>['N', 'S'],
  },
);

ConstructionProjectProfile _noBasementProfile() =>
    _singleBlockProfile(floorCount: 2, basementCount: 0);

ConstructionProjectProfile _singleBlockProfile({
  required int floorCount,
  required int basementCount,
}) => validConstructionProjectProfile(
  overrides: {
    'blocks': <Object?>[
      <String, Object?>{
        'block_id': 'A',
        'floor_count': floorCount,
        'basement_count': basementCount,
      },
    ],
    'facade_elevations': <Object?>['N', 'S'],
    'has_basement': basementCount > 0,
  },
);

ConstructionProjectActivityInstance _instance(
  ConstructionProjectActivityGraph graph,
  String instanceId,
) => graph.activityInstances.singleWhere(
  (instance) => instance.instanceId == instanceId,
);

List<Map<String, Object?>> _activityProjection(
  ConstructionProjectActivityGraph graph,
) => [
  for (final instance in graph.activityInstances)
    <String, Object?>{
      'instance_id': instance.instanceId,
      'activity_id': instance.activityId,
      'repeat_dimension': instance.repeatDimension.jsonValue,
      'context': instance.context.toJson(),
    },
];

List<Map<String, Object?>> _dependencyProjection(
  ConstructionProjectActivityGraph graph,
) => [
  for (final edge in graph.dependencyEdges)
    <String, Object?>{
      'template_dependency_id': edge.templateDependencyId,
      'predecessor_instance_id': edge.predecessorInstanceId,
      'successor_instance_id': edge.successorInstanceId,
      'relationship_type': edge.relationshipType.jsonValue,
      'lag_value': edge.lagValue,
      'lag_unit': edge.lagUnit.jsonValue,
      'scope_rule': edge.scopeRule.jsonValue,
    },
];

String _sha256Canonical(Object? value) =>
    sha256.convert(utf8.encode(jsonEncode(_canonicalize(value)))).toString();

Object? _canonicalize(Object? value) {
  if (value is Map) {
    final keys = value.keys.cast<String>().toList()..sort();
    return <String, Object?>{
      for (final key in keys) key: _canonicalize(value[key]),
    };
  }
  if (value is List) {
    return [for (final item in value) _canonicalize(item)];
  }
  return value;
}

Matcher _throwsCorpusFailure(String code) => throwsA(
  isA<ConstructionCorpusFailure>().having(
    (failure) => failure.code,
    'code',
    code,
  ),
);

class _ReferenceExpectation {
  const _ReferenceExpectation({
    required this.activityCount,
    required this.activitySha,
    required this.dependencyCount,
    required this.dependencySha,
    required this.isolatedCount,
    required this.isolatedSha,
  });

  final int activityCount;
  final String activitySha;
  final int dependencyCount;
  final String dependencySha;
  final int isolatedCount;
  final String isolatedSha;
}
