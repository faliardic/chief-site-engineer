import 'dart:io';

import 'package:chief_site_engineer/application/construction_living_plan_intelligence_application.dart';
import 'package:chief_site_engineer/application/construction_schedule_date_engine.dart';
import 'package:chief_site_engineer/application/construction_schedule_snapshot_repository.dart';
import 'package:chief_site_engineer/domain/construction_corpus_models.dart';
import 'package:chief_site_engineer/domain/construction_living_plan_forecast_models.dart';
import 'package:chief_site_engineer/domain/construction_living_plan_intelligence_models.dart';
import 'package:chief_site_engineer/domain/construction_living_plan_models.dart';
import 'package:chief_site_engineer/domain/construction_project_graph_models.dart';
import 'package:chief_site_engineer/domain/construction_schedule_dependency_snapshot_models.dart';
import 'package:chief_site_engineer/domain/construction_schedule_models.dart';
import 'package:chief_site_engineer/storage/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/construction_profile_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(sqfliteFfiInit);

  test(
    'batch reads exact snapshot and graph once and resolves exact-version names',
    () async {
      final scenario = _scenario();
      var snapshotReads = 0;
      var graphReads = 0;
      var corpusReads = 0;
      final items = [scenario.item(id: 'item-a'), scenario.item(id: 'item-b')];
      final originalOrder = items.map((item) => item.id).toList();
      final application = ConstructionLivingPlanIntelligenceApplication(
        snapshotLoader: (snapshotId) async {
          snapshotReads += 1;
          expect(snapshotId, scenario.snapshot.metadata.snapshotId);
          return scenario.snapshot;
        },
        dependencyGraphLoader: (snapshotId) async {
          graphReads += 1;
          expect(snapshotId, scenario.dependencyGraph.snapshotId);
          return scenario.dependencyGraph;
        },
        corpusLoader: () async {
          corpusReads += 1;
          return scenario.corpus;
        },
      );

      final result = await application.loadForItems(
        items: items,
        asOfDate: _date('2026-09-10'),
      );

      expect(snapshotReads, 1);
      expect(graphReads, 1);
      expect(corpusReads, 1);
      expect(items.map((item) => item.id), originalOrder);
      expect(result.keys, ['item-a', 'item-b']);
      for (final intelligence in result.values) {
        expect(
          intelligence.forecast.basis,
          ConstructionLivingPlanForecastBasis.startedReferenceRemaining,
        );
        expect(intelligence.forecast.varianceCalendarDays, greaterThan(0));
        expect(intelligence.hasPositiveDownstreamImpact, isTrue);
        expect(intelligence.impactedActivities, hasLength(1));
        expect(
          intelligence.impactedActivities.single.displayName,
          'Beton imalatı',
        );
      }
      expect(
        () => result['other'] = result.values.first,
        throwsUnsupportedError,
      );
      expect(
        () => result.values.first.impactedActivities.clear(),
        throwsUnsupportedError,
      );
    },
  );

  test(
    'SQLite wrapper keeps its database open through non-empty exact reads',
    () async {
      final scenario = _scenario();
      final temporaryRoot = await Directory.systemTemp.createTemp(
        'cse_living_plan_intelligence_',
      );
      final databasePath =
          '${temporaryRoot.path}${Platform.pathSeparator}intelligence.sqlite3';
      final database = AppDatabase(
        path: databasePath,
        factory: databaseFactoryFfi,
        clock: () => DateTime.utc(2026, 9, 1, 9),
      );
      var databaseOpen = false;
      try {
        await database.open();
        databaseOpen = true;
        await database.database.insert('projects', {
          'id': scenario.snapshot.profile.projectId,
          'name': 'Intelligence SQLite test project',
          'created_at': '2026-09-01T09:00:00Z',
          'updated_at': '2026-09-01T09:00:00Z',
        });
        final stored =
            await ConstructionScheduleSnapshotRepository(
              database: database,
              clock: () => DateTime.utc(2026, 9, 1, 9),
              idFactory: () => 'snapshot-sqlite-intelligence',
            ).persistCurrentSnapshot(
              schedule: scenario.schedule,
              profile: scenario.snapshot.profile,
              graph: scenario.graph,
              seedCatalog: scenario.catalog,
            );
        await database.close();
        databaseOpen = false;

        final result =
            await SqliteConstructionLivingPlanIntelligenceApplication(
              databasePath: databasePath,
              databaseFactory: databaseFactoryFfi,
              corpusLoader: () async => scenario.corpus,
            ).loadForItems(
              items: [
                scenario.item(referenceSnapshotId: stored.metadata.snapshotId),
              ],
              asOfDate: _date('2026-09-10'),
            );

        expect(result.values.single.hasPositiveDownstreamImpact, isTrue);
      } finally {
        if (databaseOpen) await database.close();
        if (await temporaryRoot.exists()) {
          await temporaryRoot.delete(recursive: true);
        }
      }
    },
  );

  test(
    'legacy graph unavailable preserves exact-snapshot forecast without impact',
    () async {
      final scenario = _scenario();
      final application = ConstructionLivingPlanIntelligenceApplication(
        snapshotLoader: (_) async => scenario.snapshot,
        dependencyGraphLoader: (_) async =>
            throw const ConstructionScheduleSnapshotFailure(
              'schedule_snapshot_dependency_graph_unavailable',
            ),
        corpusLoader: () async => throw StateError('corpus must not be read'),
      );

      final result = await application.loadForItems(
        items: [scenario.item()],
        asOfDate: _date('2026-09-10'),
      );
      final intelligence = result.values.single;

      expect(intelligence.forecast.forecastFinishDate, isNotNull);
      expect(
        intelligence.impactAvailability,
        ConstructionLivingPlanIntelligenceImpactAvailability
            .dependencyGraphUnavailable,
      );
      expect(intelligence.dependencyImpact, isNull);
      expect(intelligence.impactedActivities, isEmpty);
    },
  );

  test(
    'corpus version mismatch uses stable raw activity id fallback',
    () async {
      final scenario = _scenario();
      final mismatchedCorpus = _corpus('other-corpus');
      final application = ConstructionLivingPlanIntelligenceApplication(
        snapshotLoader: (_) async => scenario.snapshot,
        dependencyGraphLoader: (_) async => scenario.dependencyGraph,
        corpusLoader: () async => mismatchedCorpus,
      );

      final result = await application.loadForItems(
        items: [scenario.item()],
        asOfDate: _date('2026-09-10'),
      );

      expect(result.values.single.impactedActivities.single.displayName, 'B');
    },
  );

  test(
    'missing or wrongly bound exact snapshot fails closed without current fallback',
    () async {
      final scenario = _scenario();
      final missing = ConstructionLivingPlanIntelligenceApplication(
        snapshotLoader: (snapshotId) async => null,
        dependencyGraphLoader: (_) async => scenario.dependencyGraph,
      );
      await expectLater(
        missing.loadForItems(
          items: [scenario.item(referenceSnapshotId: 'legacy-snapshot')],
          asOfDate: _date('2026-09-10'),
        ),
        _throwsIntelligenceFailure('living_plan_intelligence_snapshot_missing'),
      );

      final wrong = ConstructionLivingPlanIntelligenceApplication(
        snapshotLoader: (_) async => scenario.snapshot,
        dependencyGraphLoader: (_) async => scenario.dependencyGraph,
      );
      await expectLater(
        wrong.loadForItems(
          items: [scenario.item(projectId: 'OTHER')],
          asOfDate: _date('2026-09-10'),
        ),
        throwsA(isA<ConstructionLivingPlanForecastFailure>()),
      );
    },
  );

  test(
    'canonical asOfDate and unique item ids are required before reads',
    () async {
      final scenario = _scenario();
      var reads = 0;
      final application = ConstructionLivingPlanIntelligenceApplication(
        snapshotLoader: (_) async {
          reads += 1;
          return scenario.snapshot;
        },
        dependencyGraphLoader: (_) async => scenario.dependencyGraph,
      );
      await expectLater(
        application.loadForItems(
          items: [scenario.item()],
          asOfDate: DateTime(2026, 9, 10),
        ),
        _throwsIntelligenceFailure(
          'living_plan_intelligence_as_of_date_not_canonical',
        ),
      );
      await expectLater(
        application.loadForItems(
          items: [scenario.item(), scenario.item()],
          asOfDate: _date('2026-09-10'),
        ),
        _throwsIntelligenceFailure('living_plan_intelligence_duplicate_item'),
      );
      expect(reads, 0);
    },
  );
}

class _Scenario {
  const _Scenario({
    required this.snapshot,
    required this.dependencyGraph,
    required this.corpus,
    required this.graph,
    required this.catalog,
    required this.schedule,
  });

  final ConstructionScheduleSnapshot snapshot;
  final ConstructionScheduleSnapshotDependencyGraph dependencyGraph;
  final ConstructionCorpus corpus;
  final ConstructionProjectActivityGraph graph;
  final ConstructionScheduleSeedCatalog catalog;
  final ConstructionProjectReferenceSchedule schedule;

  ConstructionLivingPlanItem item({
    String id = 'item-a',
    String? referenceSnapshotId,
    String? projectId,
  }) {
    final source = snapshot.activities.singleWhere(
      (activity) => activity.activityId == 'A',
    );
    return ConstructionLivingPlanItem(
      id: id,
      projectId: projectId ?? snapshot.metadata.projectId,
      referenceSnapshotId: referenceSnapshotId ?? snapshot.metadata.snapshotId,
      activityInstanceId: source.instanceId,
      activityId: source.activityId,
      activityNameSnapshot: 'Kaynak imalat',
      activityContext: const ConstructionProjectActivityContext(),
      naturalUnitSnapshot: 'gün',
      plannedDate: _date('2026-09-10'),
      status: ConstructionLivingPlanStatus.started,
      progressPercent: 50,
      note: null,
      revision: 3,
      createdAt: DateTime.utc(2026, 9, 1, 9),
      updatedAt: DateTime.utc(2026, 9, 2, 9),
      statusChangedAt: DateTime.utc(2026, 9, 2, 9),
    );
  }
}

_Scenario _scenario() {
  final profile = validConstructionProjectProfile(
    overrides: const {
      'project_id': 'PRJ-INTELLIGENCE',
      'calendar': <String, Object?>{
        'start_date': '2026-09-01',
        'working_weekdays': <Object?>[0, 1, 2, 3, 4, 5],
        'holidays': <Object?>[],
        'workday_hours': 8,
      },
    },
  );
  final edge = ConstructionResolvedDependencyEdge(
    edgeKey: 'EDGE-A-B-FS-0',
    templateDependencyId: 'DEP-A-B',
    predecessorInstanceId: 'A@PROJECT',
    successorInstanceId: 'B@PROJECT',
    relationshipType: ConstructionDependencyRelationshipType.finishToStart,
    lagValue: 0,
    lagUnit: ConstructionDependencyLagUnit.workingDay,
    scopeRule: ConstructionDependencyScopeRule.project,
    isMandatory: true,
    confidence: ConstructionDependencyConfidence.supportedInference,
    reviewStatus: ConstructionDependencyReviewStatus.reviewRequired,
  );
  final graph = ConstructionProjectActivityGraph(
    projectId: profile.projectId,
    activityInstances: const [
      ConstructionProjectActivityInstance(
        instanceId: 'A@PROJECT',
        activityId: 'A',
        wbsCode: 'TEST',
        packageId: 'TEST',
        activityNameTr: 'Kaynak imalat',
        repeatDimension: ConstructionActivityRepeatDimension.project,
        context: ConstructionProjectActivityContext(),
        naturalUnit: 'gün',
        durationStatus: 'AI_SEED_ESTIMATE',
        durationConfidence: 'D_AI_SEED',
        testSeedDurationDays: 2,
      ),
      ConstructionProjectActivityInstance(
        instanceId: 'B@PROJECT',
        activityId: 'B',
        wbsCode: 'TEST',
        packageId: 'TEST',
        activityNameTr: 'Beton imalatı',
        repeatDimension: ConstructionActivityRepeatDimension.project,
        context: ConstructionProjectActivityContext(),
        naturalUnit: 'gün',
        durationStatus: 'AI_SEED_ESTIMATE',
        durationConfidence: 'D_AI_SEED',
        testSeedDurationDays: 2,
      ),
    ],
    dependencyEdges: [edge],
    isolatedInstanceIds: const [],
    corpusVersion: 'corpus-intelligence',
    selectedActivityTemplateCount: 2,
    selectedDependencyTemplateCount: 1,
  );
  final seeds = ConstructionScheduleSeedCatalog(
    metadata: const ConstructionScheduleSeedCatalogMetadata(
      name: 'INTELLIGENCE TEST SEEDS',
      corpusVersion: 'seed-intelligence',
      sourcePublicationStatus: 'TEST',
      sourceProductionStatus: 'NOT_FOR_PRODUCTION',
      sourceZipSha256: 'test',
      warning: 'test',
      runtimeScope: 'TEST',
      activityCount: 2,
      workingDayCount: 2,
      calendarDayCount: 0,
      milestoneCount: 0,
      authoritativeCount: 0,
      aiSeedCount: 2,
      unknownConfidenceCount: 0,
      sourceBackedCount: 0,
      aiSeedEstimateCount: 2,
      unknownStatusCount: 0,
    ),
    seeds: [
      ConstructionScheduleSeed(
        activityId: 'A',
        durationDays: 2,
        durationCalendarType:
            ConstructionActivityDurationCalendarType.workingDay,
        durationStatus: ConstructionScheduleDurationStatus.aiSeedEstimate,
        durationConfidence: ConstructionScheduleDurationConfidence.aiSeed,
      ),
      ConstructionScheduleSeed(
        activityId: 'B',
        durationDays: 2,
        durationCalendarType:
            ConstructionActivityDurationCalendarType.workingDay,
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
      snapshotId: 'snapshot-intelligence',
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
      projectionSha256: 'snapshot-projection-intelligence',
      generatedAt: DateTime.utc(2026, 9, 1, 9),
      supersededAt: null,
    ),
    profile: profile,
    activities: schedule.scheduledActivities,
  );
  return _Scenario(
    snapshot: snapshot,
    dependencyGraph: ConstructionScheduleSnapshotDependencyGraph(
      snapshotId: snapshot.metadata.snapshotId,
      projectId: snapshot.metadata.projectId,
      dependencyCount: 1,
      projectionSha256:
          'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      edges: [edge],
    ),
    corpus: _corpus(snapshot.metadata.corpusVersion),
    graph: graph,
    catalog: seeds,
    schedule: schedule,
  );
}

ConstructionCorpus _corpus(String version) => ConstructionCorpus(
  metadata: ConstructionCorpusMetadata(
    name: 'INTELLIGENCE TEST CORPUS',
    corpusVersion: version,
    sourcePublicationStatus: 'TEST',
    sourceProductionStatus: 'NOT_FOR_PRODUCTION',
    warning: 'test',
    runtimeScope: 'TEST',
    wbsCount: 1,
    activityCount: 2,
  ),
  profileFields: const [],
  wbsPackages: const [
    ConstructionWbsPackage(
      wbsCode: 'TEST',
      packageId: 'TEST',
      packageNameTr: 'Test',
      packageNameEn: 'Test',
      frequencyClass: 'TEST',
    ),
  ],
  activities: [
    ConstructionActivity(
      activityId: 'A',
      wbsCode: 'TEST',
      packageId: 'TEST',
      activityNameTr: 'Kaynak imalat',
      aliasesTr: [],
      applicability: ConstructionAlwaysRule(),
      repeatDimension: ConstructionActivityRepeatDimension.project,
      naturalUnit: 'gün',
      durationStatus: 'AI_SEED_ESTIMATE',
      durationConfidence: 'D_AI_SEED',
      testSeedDurationDays: 2,
      sequenceConfidence: 'TEST',
      sequenceIndex: 1,
    ),
    ConstructionActivity(
      activityId: 'B',
      wbsCode: 'TEST',
      packageId: 'TEST',
      activityNameTr: 'Beton imalatı',
      aliasesTr: [],
      applicability: ConstructionAlwaysRule(),
      repeatDimension: ConstructionActivityRepeatDimension.project,
      naturalUnit: 'gün',
      durationStatus: 'AI_SEED_ESTIMATE',
      durationConfidence: 'D_AI_SEED',
      testSeedDurationDays: 2,
      sequenceConfidence: 'TEST',
      sequenceIndex: 2,
    ),
  ],
);

Matcher _throwsIntelligenceFailure(String code) => throwsA(
  isA<ConstructionLivingPlanIntelligenceFailure>().having(
    (failure) => failure.code,
    'code',
    code,
  ),
);

DateTime _date(String value) {
  final parts = value.split('-').map(int.parse).toList(growable: false);
  return DateTime.utc(parts[0], parts[1], parts[2]);
}
