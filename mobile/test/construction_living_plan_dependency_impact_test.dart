import 'package:chief_site_engineer/application/construction_living_plan_dependency_impact.dart';
import 'package:chief_site_engineer/application/construction_living_plan_forecast.dart';
import 'package:chief_site_engineer/application/construction_schedule_date_engine.dart';
import 'package:chief_site_engineer/domain/construction_corpus_models.dart';
import 'package:chief_site_engineer/domain/construction_living_plan_dependency_impact_models.dart';
import 'package:chief_site_engineer/domain/construction_living_plan_forecast_models.dart';
import 'package:chief_site_engineer/domain/construction_living_plan_models.dart';
import 'package:chief_site_engineer/domain/construction_project_graph_models.dart';
import 'package:chief_site_engineer/domain/construction_schedule_dependency_snapshot_models.dart';
import 'package:chief_site_engineer/domain/construction_schedule_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/construction_profile_fixtures.dart';

void main() {
  const engine = ConstructionLivingPlanDependencyImpactEngine();

  group('exact binding and integrity', () {
    test('accepts exact forecast, snapshot and dependency graph binding', () {
      final scenario = _scenario(
        activities: [_activity('A', 1), _activity('B', 1)],
        edges: [_edge('A', 'B')],
      );
      final result = engine.calculate(
        sourceForecast: scenario.forecast(),
        exactSnapshot: scenario.snapshot,
        exactDependencyGraph: scenario.dependencyGraph,
      );

      expect(result.itemId, 'item-A');
      expect(result.projectId, 'PRJ-IMPACT');
      expect(result.referenceSnapshotId, 'snapshot-impact');
      expect(result.sourceActivityInstanceId, 'A@PROJECT');
      expect(result.asOfDate, _date('2026-09-08'));
      expect(result.sourceReferenceStartDate, _date('2026-09-04'));
      expect(result.sourceReferenceFinishDate, _date('2026-09-04'));
      expect(result.sourceForecastFinishDate, _date('2026-09-08'));
      expect(result.sourceVarianceCalendarDays, 4);
      expect(result.propagatedPositiveSourceDelayCalendarDays, 4);
      expect(result.dependencyProjectionSha256, _dependencySha);
    });

    test('rejects wrong project and wrong snapshot bindings', () {
      final scenario = _scenario(activities: [_activity('A', 1)]);
      final forecast = scenario.forecast();

      expect(
        () => engine.calculate(
          sourceForecast: _copyForecast(forecast, projectId: 'PRJ-OTHER'),
          exactSnapshot: scenario.snapshot,
          exactDependencyGraph: scenario.dependencyGraph,
        ),
        _throwsImpactFailure('impact_project_mismatch'),
      );
      expect(
        () => engine.calculate(
          sourceForecast: _copyForecast(
            forecast,
            referenceSnapshotId: 'snapshot-newer',
          ),
          exactSnapshot: scenario.snapshot,
          exactDependencyGraph: scenario.dependencyGraph,
        ),
        _throwsImpactFailure('impact_reference_snapshot_mismatch'),
      );
    });

    test('rejects missing and duplicate source activity', () {
      final scenario = _scenario(activities: [_activity('A', 1)]);
      final forecast = scenario.forecast();
      expect(
        () => engine.calculate(
          sourceForecast: _copyForecast(
            forecast,
            activityInstanceId: 'missing@PROJECT',
          ),
          exactSnapshot: scenario.snapshot,
          exactDependencyGraph: scenario.dependencyGraph,
        ),
        _throwsImpactFailure('impact_source_activity_missing'),
      );

      final source = scenario.snapshot.activities.single;
      final duplicateSnapshot = _copySnapshot(
        scenario.snapshot,
        activities: [source, source],
      );
      expect(
        () => engine.calculate(
          sourceForecast: forecast,
          exactSnapshot: duplicateSnapshot,
          exactDependencyGraph: scenario.dependencyGraph,
        ),
        _throwsImpactFailure('impact_source_activity_duplicate'),
      );
    });

    test('rejects source reference and provenance mismatch', () {
      final scenario = _scenario(activities: [_activity('A', 1)]);
      final forecast = scenario.forecast();
      expect(
        () => engine.calculate(
          sourceForecast: _copyForecast(
            forecast,
            referenceStartDate: _date('2026-09-05'),
          ),
          exactSnapshot: scenario.snapshot,
          exactDependencyGraph: scenario.dependencyGraph,
        ),
        _throwsImpactFailure('impact_source_reference_mismatch'),
      );
      expect(
        () => engine.calculate(
          sourceForecast: _copyForecast(
            forecast,
            referenceProjectionSha256:
                'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff',
          ),
          exactSnapshot: scenario.snapshot,
          exactDependencyGraph: scenario.dependencyGraph,
        ),
        _throwsImpactFailure('impact_source_provenance_mismatch'),
      );
    });

    test('rejects dependency project, snapshot, count and malformed SHA', () {
      final scenario = _scenario(activities: [_activity('A', 1)]);
      final forecast = scenario.forecast();
      for (final graph in [
        _dependencyGraph(edges: const [], projectId: 'PRJ-OTHER'),
        _dependencyGraph(edges: const [], snapshotId: 'snapshot-newer'),
      ]) {
        expect(
          () => engine.calculate(
            sourceForecast: forecast,
            exactSnapshot: scenario.snapshot,
            exactDependencyGraph: graph,
          ),
          throwsA(isA<ConstructionLivingPlanDependencyImpactFailure>()),
        );
      }
      expect(
        () => engine.calculate(
          sourceForecast: forecast,
          exactSnapshot: scenario.snapshot,
          exactDependencyGraph: _dependencyGraph(
            edges: const [],
            dependencyCount: 1,
          ),
        ),
        _throwsImpactFailure('impact_dependency_count_mismatch'),
      );
      expect(
        () => engine.calculate(
          sourceForecast: forecast,
          exactSnapshot: scenario.snapshot,
          exactDependencyGraph: _dependencyGraph(
            edges: const [],
            projectionSha256: 'ABC',
          ),
        ),
        _throwsImpactFailure('impact_dependency_sha_invalid'),
      );
    });

    test('rejects orphan, duplicate edge key, self edge and cycle', () {
      final scenario = _scenario(
        activities: [_activity('A', 1), _activity('B', 1), _activity('C', 1)],
      );
      final forecast = scenario.forecast();
      final invalid = <ConstructionScheduleSnapshotDependencyGraph>[
        _dependencyGraph(edges: [_edge('A', 'MISSING')]),
        _dependencyGraph(
          edges: [
            _edge('A', 'B', key: 'DUP'),
            _edge('A', 'C', key: 'DUP'),
          ],
        ),
        _dependencyGraph(edges: [_edge('A', 'A')]),
        _dependencyGraph(edges: [_edge('A', 'B'), _edge('B', 'A')]),
      ];
      final codes = [
        'impact_dependency_orphan_endpoint',
        'impact_dependency_edge_key_duplicate',
        'impact_dependency_self_edge',
        'impact_dependency_cycle',
      ];
      for (var index = 0; index < invalid.length; index += 1) {
        expect(
          () => engine.calculate(
            sourceForecast: forecast,
            exactSnapshot: scenario.snapshot,
            exactDependencyGraph: invalid[index],
          ),
          _throwsImpactFailure(codes[index]),
        );
      }
    });
  });

  group('basis behavior', () {
    test('unavailable forecast does not invent downstream dates', () {
      final scenario = _scenario(
        activities: [_activity('A', 1), _activity('B', 1)],
        edges: [_edge('A', 'B')],
      );
      final result = engine.calculate(
        sourceForecast: scenario.forecast(
          status: ConstructionLivingPlanStatus.planned,
          progressPercent: null,
        ),
        exactSnapshot: scenario.snapshot,
        exactDependencyGraph: scenario.dependencyGraph,
      );
      expect(
        result.basis,
        ConstructionLivingPlanDependencyImpactBasis.sourceForecastUnavailable,
      );
      expect(result.impactedActivities, isEmpty);
      expect(result.propagatedPositiveSourceDelayCalendarDays, 0);
    });

    test('zero and early forecasts never pull successors earlier', () {
      final scenario = _scenario(
        activities: [_activity('A', 1), _activity('B', 1)],
        edges: [_edge('A', 'B')],
      );
      for (final asOf in [_date('2026-09-04'), _date('2026-09-03')]) {
        final result = engine.calculate(
          sourceForecast: scenario.forecast(asOfDate: asOf),
          exactSnapshot: scenario.snapshot,
          exactDependencyGraph: scenario.dependencyGraph,
        );
        expect(
          result.basis,
          ConstructionLivingPlanDependencyImpactBasis.noPositiveSourceDelay,
        );
        expect(result.impactedActivities, isEmpty);
        expect(result.propagatedPositiveSourceDelayCalendarDays, 0);
      }
    });

    test('positive source delay with zero-edge graph has no shift', () {
      final scenario = _scenario(activities: [_activity('A', 1)]);
      final result = engine.calculate(
        sourceForecast: scenario.forecast(),
        exactSnapshot: scenario.snapshot,
        exactDependencyGraph: scenario.dependencyGraph,
      );
      expect(
        result.basis,
        ConstructionLivingPlanDependencyImpactBasis
            .sourceDelayNoDownstreamShift,
      );
      expect(result.impactedActivities, isEmpty);
      expect(result.propagatedPositiveSourceDelayCalendarDays, 4);
    });
  });

  group('downstream propagation', () {
    test('projects simple FS and chained FS in topological order', () {
      final scenario = _scenario(
        activities: [_activity('A', 1), _activity('B', 1), _activity('C', 1)],
        edges: [_edge('A', 'B'), _edge('B', 'C')],
      );
      final result = engine.calculate(
        sourceForecast: scenario.forecast(),
        exactSnapshot: scenario.snapshot,
        exactDependencyGraph: scenario.dependencyGraph,
      );

      expect(
        result.basis,
        ConstructionLivingPlanDependencyImpactBasis.downstreamDelayProjected,
      );
      expect(
        result.impactedActivities.map((item) => item.activityInstanceId),
        orderedEquals(const ['B@PROJECT', 'C@PROJECT']),
      );
      expect(
        result.impactedActivities[0].referenceStartDate,
        _date('2026-09-05'),
      );
      expect(
        result.impactedActivities[0].projectedStartDate,
        _date('2026-09-09'),
      );
      expect(
        result.impactedActivities[1].referenceStartDate,
        _date('2026-09-08'),
      );
      expect(
        result.impactedActivities[1].projectedStartDate,
        _date('2026-09-10'),
      );
    });

    test('projects both branches and excludes an unrelated node', () {
      final scenario = _scenario(
        activities: [
          _activity('A', 1),
          _activity('B', 1),
          _activity('C', 1),
          _activity('D', 1),
        ],
        edges: [_edge('A', 'B'), _edge('A', 'C')],
      );
      final result = engine.calculate(
        sourceForecast: scenario.forecast(),
        exactSnapshot: scenario.snapshot,
        exactDependencyGraph: scenario.dependencyGraph,
      );
      expect(
        result.impactedActivities.map((item) => item.activityInstanceId),
        orderedEquals(const ['B@PROJECT', 'C@PROJECT']),
      );
      expect(
        result.impactedActivities.any(
          (item) => item.activityInstanceId == 'D@PROJECT',
        ),
        isFalse,
      );
    });

    test('multiple predecessors recompute the controlling constraint', () {
      final scenario = _scenario(
        activities: [_activity('A', 1), _activity('B', 3), _activity('C', 1)],
        edges: [_edge('A', 'C'), _edge('B', 'C')],
      );
      final nonControlling = engine.calculate(
        sourceForecast: scenario.forecast(asOfDate: _date('2026-09-05')),
        exactSnapshot: scenario.snapshot,
        exactDependencyGraph: scenario.dependencyGraph,
      );
      expect(
        nonControlling.basis,
        ConstructionLivingPlanDependencyImpactBasis
            .sourceDelayNoDownstreamShift,
      );
      expect(nonControlling.impactedActivities, isEmpty);

      final controlling = engine.calculate(
        sourceForecast: scenario.forecast(asOfDate: _date('2026-09-09')),
        exactSnapshot: scenario.snapshot,
        exactDependencyGraph: scenario.dependencyGraph,
      );
      expect(controlling.impactedActivities, hasLength(1));
      expect(
        controlling.impactedActivities.single.activityInstanceId,
        'C@PROJECT',
      );
      expect(
        controlling.impactedActivities.single.referenceStartDate,
        _date('2026-09-09'),
      );
      expect(
        controlling.impactedActivities.single.projectedStartDate,
        _date('2026-09-10'),
      );
    });

    test('source finish delay alone does not move a direct SS successor', () {
      final scenario = _scenario(
        activities: [_activity('A', 3), _activity('B', 1)],
        edges: [_edge('A', 'B', relationship: 'SS')],
      );
      final result = engine.calculate(
        sourceForecast: scenario.forecast(),
        exactSnapshot: scenario.snapshot,
        exactDependencyGraph: scenario.dependencyGraph,
      );
      expect(
        result.basis,
        ConstructionLivingPlanDependencyImpactBasis
            .sourceDelayNoDownstreamShift,
      );
      expect(result.impactedActivities, isEmpty);
    });

    test('an FS-shifted activity propagates its shifted start over SS', () {
      final scenario = _scenario(
        activities: [_activity('A', 1), _activity('B', 1), _activity('C', 1)],
        edges: [
          _edge('A', 'B'),
          _edge('B', 'C', relationship: 'SS'),
        ],
      );
      final result = engine.calculate(
        sourceForecast: scenario.forecast(),
        exactSnapshot: scenario.snapshot,
        exactDependencyGraph: scenario.dependencyGraph,
      );
      expect(
        result.impactedActivities.map((item) => item.activityInstanceId),
        orderedEquals(const ['B@PROJECT', 'C@PROJECT']),
      );
      expect(
        result.impactedActivities.map((item) => item.projectedStartDate),
        everyElement(_date('2026-09-09')),
      );
    });

    test('working-day lag crosses Sunday and configured holiday exactly', () {
      final scenario = _scenario(
        activities: [_activity('A', 1), _activity('B', 1)],
        edges: [_edge('A', 'B', lag: 1)],
      );
      final referenceB = scenario.snapshot.activities.singleWhere(
        (activity) => activity.activityId == 'B',
      );
      expect(referenceB.startDate, _date('2026-09-08'));

      final result = engine.calculate(
        sourceForecast: scenario.forecast(),
        exactSnapshot: scenario.snapshot,
        exactDependencyGraph: scenario.dependencyGraph,
      );
      expect(
        result.impactedActivities.single.projectedStartDate,
        _date('2026-09-10'),
      );
    });

    test(
      'working and calendar successors preserve exact duration semantics',
      () {
        final scenario = _scenario(
          activities: [
            _activity('A', 1),
            _activity('B', 3),
            _activity(
              'C',
              3,
              calendarType:
                  ConstructionActivityDurationCalendarType.calendarDay,
            ),
          ],
          edges: [_edge('A', 'B'), _edge('A', 'C')],
        );
        final result = engine.calculate(
          sourceForecast: scenario.forecast(),
          exactSnapshot: scenario.snapshot,
          exactDependencyGraph: scenario.dependencyGraph,
        );
        final byId = {
          for (final item in result.impactedActivities)
            item.activityInstanceId: item,
        };
        expect(byId['B@PROJECT']!.projectedStartDate, _date('2026-09-09'));
        expect(byId['B@PROJECT']!.projectedFinishDate, _date('2026-09-11'));
        expect(byId['C@PROJECT']!.projectedStartDate, _date('2026-09-09'));
        expect(byId['C@PROJECT']!.projectedFinishDate, _date('2026-09-11'));
        expect(byId['B@PROJECT']!.finishShiftCalendarDays, 2);
        expect(byId['C@PROJECT']!.finishShiftCalendarDays, 4);
      },
    );

    test('fractional reference duration is not changed while dates shift', () {
      final scenario = _scenario(
        activities: [_activity('A', 1), _activity('B', 2.5)],
        edges: [_edge('A', 'B')],
      );
      final before = scenario.snapshot.activities.singleWhere(
        (activity) => activity.activityId == 'B',
      );
      final result = engine.calculate(
        sourceForecast: scenario.forecast(),
        exactSnapshot: scenario.snapshot,
        exactDependencyGraph: scenario.dependencyGraph,
      );
      expect(before.durationDays, 2.5);
      expect(before.roundedSchedulingDays, 3);
      expect(
        result.impactedActivities.single.projectedFinishDate,
        _date('2026-09-11'),
      );
      expect(
        scenario.snapshot.activities
            .singleWhere((activity) => activity.activityId == 'B')
            .durationDays,
        2.5,
      );
    });
  });

  group('determinism and purity', () {
    test('edge order and repeated input produce the exact same projection', () {
      final scenario = _scenario(
        activities: [_activity('A', 1), _activity('B', 1), _activity('C', 1)],
        edges: [_edge('A', 'B'), _edge('A', 'C')],
      );
      final forecast = scenario.forecast();
      final first = engine.calculate(
        sourceForecast: forecast,
        exactSnapshot: scenario.snapshot,
        exactDependencyGraph: scenario.dependencyGraph,
      );
      final reordered = engine.calculate(
        sourceForecast: forecast,
        exactSnapshot: scenario.snapshot,
        exactDependencyGraph: _dependencyGraph(
          edges: scenario.dependencyGraph.edges.reversed,
        ),
      );
      final repeated = engine.calculate(
        sourceForecast: forecast,
        exactSnapshot: scenario.snapshot,
        exactDependencyGraph: scenario.dependencyGraph,
      );
      expect(_impactProjection(reordered), _impactProjection(first));
      expect(_impactProjection(repeated), _impactProjection(first));
    });

    test('does not mutate inputs and exposes an immutable impact list', () {
      final scenario = _scenario(
        activities: [_activity('A', 1), _activity('B', 1)],
        edges: [_edge('A', 'B')],
      );
      final forecast = scenario.forecast();
      final originalActivities = List.of(scenario.snapshot.activities);
      final originalEdges = List.of(scenario.dependencyGraph.edges);
      final result = engine.calculate(
        sourceForecast: forecast,
        exactSnapshot: scenario.snapshot,
        exactDependencyGraph: scenario.dependencyGraph,
      );

      expect(scenario.snapshot.activities, orderedEquals(originalActivities));
      expect(scenario.dependencyGraph.edges, orderedEquals(originalEdges));
      expect(forecast.forecastFinishDate, _date('2026-09-08'));
      expect(() => result.impactedActivities.clear(), throwsUnsupportedError);
    });
  });
}

const _dependencySha =
    'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd';
const _snapshotSha =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

_ActivitySpec _activity(
  String id,
  double duration, {
  ConstructionActivityDurationCalendarType calendarType =
      ConstructionActivityDurationCalendarType.workingDay,
}) => _ActivitySpec(id, duration, calendarType);

ConstructionResolvedDependencyEdge _edge(
  String predecessor,
  String successor, {
  String relationship = 'FS',
  int lag = 0,
  String? key,
}) => ConstructionResolvedDependencyEdge(
  edgeKey: key ?? 'EDGE-$predecessor-$successor-$relationship-$lag',
  templateDependencyId: 'DEP-$predecessor-$successor',
  predecessorInstanceId: '$predecessor@PROJECT',
  successorInstanceId: '$successor@PROJECT',
  relationshipType: ConstructionDependencyRelationshipType.fromJson(
    relationship,
  ),
  lagValue: lag,
  lagUnit: ConstructionDependencyLagUnit.workingDay,
  scopeRule: ConstructionDependencyScopeRule.project,
  isMandatory: true,
  confidence: ConstructionDependencyConfidence.supportedInference,
  reviewStatus: ConstructionDependencyReviewStatus.reviewRequired,
);

ConstructionScheduleSnapshotDependencyGraph _dependencyGraph({
  required Iterable<ConstructionResolvedDependencyEdge> edges,
  String snapshotId = 'snapshot-impact',
  String projectId = 'PRJ-IMPACT',
  int? dependencyCount,
  String projectionSha256 = _dependencySha,
}) {
  final orderedInput = List<ConstructionResolvedDependencyEdge>.of(edges);
  return ConstructionScheduleSnapshotDependencyGraph(
    snapshotId: snapshotId,
    projectId: projectId,
    dependencyCount: dependencyCount ?? orderedInput.length,
    projectionSha256: projectionSha256,
    edges: orderedInput,
  );
}

_Scenario _scenario({
  required List<_ActivitySpec> activities,
  List<ConstructionResolvedDependencyEdge> edges = const [],
  String sourceActivityId = 'A',
}) {
  final profile = validConstructionProjectProfile(
    overrides: const {
      'project_id': 'PRJ-IMPACT',
      'calendar': <String, Object?>{
        'start_date': '2026-09-04',
        'working_weekdays': <Object?>[0, 1, 2, 3, 4, 5],
        'holidays': <Object?>['2026-09-07'],
        'workday_hours': 8,
      },
    },
  );
  final instances = [
    for (final specification in activities)
      ConstructionProjectActivityInstance(
        instanceId: '${specification.id}@PROJECT',
        activityId: specification.id,
        wbsCode: 'TEST',
        packageId: 'TEST',
        activityNameTr: specification.id,
        repeatDimension: ConstructionActivityRepeatDimension.project,
        context: const ConstructionProjectActivityContext(),
        naturalUnit: 'day',
        durationStatus: 'AI_SEED_ESTIMATE',
        durationConfidence: 'D_AI_SEED',
        testSeedDurationDays: specification.duration,
      ),
  ];
  final connected = <String>{};
  for (final edge in edges) {
    connected
      ..add(edge.predecessorInstanceId)
      ..add(edge.successorInstanceId);
  }
  final graph = ConstructionProjectActivityGraph(
    projectId: profile.projectId,
    activityInstances: instances,
    dependencyEdges: edges,
    isolatedInstanceIds: instances
        .map((instance) => instance.instanceId)
        .where((instanceId) => !connected.contains(instanceId)),
    corpusVersion: 'corpus-impact',
    selectedActivityTemplateCount: instances.length,
    selectedDependencyTemplateCount: edges.length,
  );
  final seeds = ConstructionScheduleSeedCatalog(
    metadata: const ConstructionScheduleSeedCatalogMetadata(
      name: 'IMPACT TEST SEEDS',
      corpusVersion: 'seed-impact',
      sourcePublicationStatus: 'TEST',
      sourceProductionStatus: 'NOT_FOR_PRODUCTION',
      sourceZipSha256: 'test',
      warning: 'test',
      runtimeScope: 'TEST',
      activityCount: 0,
      workingDayCount: 0,
      calendarDayCount: 0,
      milestoneCount: 0,
      authoritativeCount: 0,
      aiSeedCount: 0,
      unknownConfidenceCount: 0,
      sourceBackedCount: 0,
      aiSeedEstimateCount: 0,
      unknownStatusCount: 0,
    ),
    seeds: [
      for (final specification in activities)
        ConstructionScheduleSeed(
          activityId: specification.id,
          durationDays: specification.duration,
          durationCalendarType: specification.calendarType,
          durationStatus: ConstructionScheduleDurationStatus.aiSeedEstimate,
          durationConfidence: ConstructionScheduleDurationConfidence.aiSeed,
        ),
    ],
  );
  final schedule = ConstructionScheduleDateEngine().build(
    profile: profile,
    graph: graph,
    seedCatalog: seeds,
  );
  final snapshot = ConstructionScheduleSnapshot(
    metadata: ConstructionScheduleSnapshotMetadata(
      snapshotId: 'snapshot-impact',
      projectId: profile.projectId,
      corpusVersion: schedule.corpusVersion,
      scheduleSeedVersion: schedule.scheduleSeedVersion,
      scheduleSeedProvenance: schedule.scheduleSeedProvenance,
      productionStatus: schedule.productionStatus,
      durationSource: schedule.durationSource,
      baselineStatus: schedule.baselineStatus,
      scheduleStart: schedule.scheduleStart,
      scheduleFinish: schedule.scheduleFinish,
      activityCount: schedule.scheduledActivities.length,
      rootCount: schedule.rootInstanceIds.length,
      leafCount: schedule.leafInstanceIds.length,
      isolatedCount: schedule.isolatedInstanceIds.length,
      milestoneCount: schedule.milestoneInstanceCount,
      projectionSha256: _snapshotSha,
      generatedAt: DateTime.utc(2026, 9, 1, 9),
      supersededAt: null,
    ),
    profile: profile,
    activities: schedule.scheduledActivities,
  );
  return _Scenario(
    snapshot: snapshot,
    dependencyGraph: _dependencyGraph(edges: edges),
    sourceActivityId: sourceActivityId,
  );
}

ConstructionLivingPlanForecast _copyForecast(
  ConstructionLivingPlanForecast source, {
  String? projectId,
  String? referenceSnapshotId,
  String? activityInstanceId,
  DateTime? referenceStartDate,
  String? referenceProjectionSha256,
}) => ConstructionLivingPlanForecast(
  itemId: source.itemId,
  projectId: projectId ?? source.projectId,
  referenceSnapshotId: referenceSnapshotId ?? source.referenceSnapshotId,
  activityInstanceId: activityInstanceId ?? source.activityInstanceId,
  status: source.status,
  progressPercent: source.progressPercent,
  asOfDate: source.asOfDate,
  referenceStartDate: referenceStartDate ?? source.referenceStartDate,
  referenceFinishDate: source.referenceFinishDate,
  referenceDurationDays: source.referenceDurationDays,
  referenceRoundedSchedulingDays: source.referenceRoundedSchedulingDays,
  referenceDurationCalendarType: source.referenceDurationCalendarType,
  referenceDurationStatus: source.referenceDurationStatus,
  referenceDurationConfidence: source.referenceDurationConfidence,
  referenceCorpusVersion: source.referenceCorpusVersion,
  referenceScheduleSeedVersion: source.referenceScheduleSeedVersion,
  referenceScheduleSeedProvenance: source.referenceScheduleSeedProvenance,
  referenceProductionStatus: source.referenceProductionStatus,
  referenceDurationSource: source.referenceDurationSource,
  referenceBaselineStatus: source.referenceBaselineStatus,
  referenceProjectionSha256:
      referenceProjectionSha256 ?? source.referenceProjectionSha256,
  remainingDurationDays: source.remainingDurationDays,
  remainingRoundedSchedulingDays: source.remainingRoundedSchedulingDays,
  forecastFinishDate: source.forecastFinishDate,
  varianceCalendarDays: source.varianceCalendarDays,
  basis: source.basis,
);

ConstructionScheduleSnapshot _copySnapshot(
  ConstructionScheduleSnapshot source, {
  required Iterable<ConstructionScheduledActivity> activities,
}) {
  final copiedActivities = List<ConstructionScheduledActivity>.of(activities);
  final metadata = source.metadata;
  return ConstructionScheduleSnapshot(
    metadata: ConstructionScheduleSnapshotMetadata(
      snapshotId: metadata.snapshotId,
      projectId: metadata.projectId,
      corpusVersion: metadata.corpusVersion,
      scheduleSeedVersion: metadata.scheduleSeedVersion,
      scheduleSeedProvenance: metadata.scheduleSeedProvenance,
      productionStatus: metadata.productionStatus,
      durationSource: metadata.durationSource,
      baselineStatus: metadata.baselineStatus,
      scheduleStart: metadata.scheduleStart,
      scheduleFinish: metadata.scheduleFinish,
      activityCount: copiedActivities.length,
      rootCount: metadata.rootCount,
      leafCount: metadata.leafCount,
      isolatedCount: metadata.isolatedCount,
      milestoneCount: metadata.milestoneCount,
      projectionSha256: metadata.projectionSha256,
      generatedAt: metadata.generatedAt,
      supersededAt: metadata.supersededAt,
    ),
    profile: source.profile,
    activities: copiedActivities,
  );
}

List<Map<String, Object?>> _impactProjection(
  ConstructionLivingPlanDependencyImpact result,
) => [
  {
    'basis': result.basis.contractValue,
    'source_variance': result.sourceVarianceCalendarDays,
    'positive_delay': result.propagatedPositiveSourceDelayCalendarDays,
  },
  for (final item in result.impactedActivities)
    {
      'instance': item.activityInstanceId,
      'activity': item.activityId,
      'reference_start': item.referenceStartDate.toIso8601String(),
      'reference_finish': item.referenceFinishDate.toIso8601String(),
      'projected_start': item.projectedStartDate.toIso8601String(),
      'projected_finish': item.projectedFinishDate.toIso8601String(),
      'start_shift': item.startShiftCalendarDays,
      'finish_shift': item.finishShiftCalendarDays,
    },
];

Matcher _throwsImpactFailure(String code) => throwsA(
  isA<ConstructionLivingPlanDependencyImpactFailure>().having(
    (failure) => failure.code,
    'code',
    code,
  ),
);

DateTime _date(String value) {
  final parts = value.split('-').map(int.parse).toList(growable: false);
  return DateTime.utc(parts[0], parts[1], parts[2]);
}

class _ActivitySpec {
  const _ActivitySpec(this.id, this.duration, this.calendarType);

  final String id;
  final double duration;
  final ConstructionActivityDurationCalendarType calendarType;
}

class _Scenario {
  const _Scenario({
    required this.snapshot,
    required this.dependencyGraph,
    required this.sourceActivityId,
  });

  final ConstructionScheduleSnapshot snapshot;
  final ConstructionScheduleSnapshotDependencyGraph dependencyGraph;
  final String sourceActivityId;

  ConstructionLivingPlanForecast forecast({
    ConstructionLivingPlanStatus status = ConstructionLivingPlanStatus.started,
    int? progressPercent = 0,
    DateTime? asOfDate,
  }) {
    final source = snapshot.activities.singleWhere(
      (activity) => activity.activityId == sourceActivityId,
    );
    final item = ConstructionLivingPlanItem(
      id: 'item-$sourceActivityId',
      projectId: snapshot.metadata.projectId,
      referenceSnapshotId: snapshot.metadata.snapshotId,
      activityInstanceId: source.instanceId,
      activityId: source.activityId,
      activityNameSnapshot: source.activityId,
      activityContext: const ConstructionProjectActivityContext(),
      naturalUnitSnapshot: 'day',
      plannedDate: source.startDate,
      status: status,
      progressPercent: progressPercent,
      note: null,
      revision: 7,
      createdAt: DateTime.utc(2026, 9, 1, 9),
      updatedAt: DateTime.utc(2026, 9, 2, 9),
      statusChangedAt: DateTime.utc(2026, 9, 2, 9),
    );
    return const ConstructionLivingPlanForecastEngine().forecast(
      item: item,
      exactSnapshot: snapshot,
      asOfDate: asOfDate ?? _date('2026-09-08'),
    );
  }
}
