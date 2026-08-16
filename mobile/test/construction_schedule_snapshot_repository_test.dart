import 'dart:async';
import 'dart:io';

import 'package:chief_site_engineer/application/construction_schedule_date_engine.dart';
import 'package:chief_site_engineer/application/construction_schedule_snapshot_repository.dart';
import 'package:chief_site_engineer/core/environment.dart';
import 'package:chief_site_engineer/domain/construction_corpus_models.dart';
import 'package:chief_site_engineer/domain/construction_project_graph_models.dart';
import 'package:chief_site_engineer/domain/construction_schedule_models.dart';
import 'package:chief_site_engineer/storage/app_database.dart';
import 'package:chief_site_engineer/storage/app_directories.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/construction_profile_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temporaryRoot;
  late AppDirectories directories;
  late AppDatabase database;
  late _ScheduleScenario scenario;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    temporaryRoot = await Directory.systemTemp.createTemp(
      'cse_schedule_snapshot_',
    );
    directories = AppDirectories.fromSupportRoot(
      temporaryRoot,
      AppEnvironment.debug,
    );
    await directories.ensureCreated();
    database = AppDatabase(
      path: directories.databaseFile,
      factory: databaseFactoryFfi,
      clock: () => DateTime.utc(2026, 8, 16, 6),
    );
    await database.open();
    scenario = _scheduleScenario();
    await _insertProject(database, scenario.profile.projectId);
  });

  tearDown(() async {
    await database.close();
    if (await temporaryRoot.exists()) {
      await temporaryRoot.delete(recursive: true);
    }
  });

  test(
    'valid snapshot round-trips exact persisted projection and window query',
    () async {
      final repository = _repository(
        database,
        snapshotId: 'snapshot-a',
        generatedAt: DateTime.utc(2026, 8, 16, 7),
      );
      final stored = await _persist(repository, scenario);

      expect(stored.metadata.snapshotId, 'snapshot-a');
      expect(stored.metadata.projectId, scenario.profile.projectId);
      expect(stored.metadata.isCurrent, isTrue);
      expect(stored.metadata.productionStatus, 'NOT_FOR_PRODUCTION');
      expect(stored.metadata.durationSource, 'TEST_SEED_ONLY');
      expect(stored.metadata.baselineStatus, 'NOT_A_BASELINE');
      expect(stored.metadata.activityCount, 4);
      expect(stored.metadata.rootCount, 2);
      expect(stored.metadata.leafCount, 2);
      expect(stored.metadata.isolatedCount, 1);
      expect(stored.metadata.milestoneCount, 1);
      expect(stored.metadata.generatedAt, DateTime.utc(2026, 8, 16, 7));
      expect(stored.profile.projectId, scenario.profile.projectId);
      expect(
        _activityProjection(stored.activities),
        _activityProjection(scenario.schedule.scheduledActivities),
      );
      expect(
        stored.activities.map((item) => item.instanceId),
        orderedEquals(const [
          'ACT-A@PROJECT',
          'ACT-B@PROJECT',
          'ACT-C@PROJECT',
          'ACT-D@PROJECT',
        ]),
      );
      expect(
        stored.metadata.projectionSha256,
        constructionScheduleSnapshotProjectionSha256(
          scenario.schedule.scheduledActivities,
        ),
      );
      expect(
        stored.metadata.projectionSha256,
        'e3fa78d2aa8eebd238d8b2320e35fce6f15d4bc2988caab447057b591d35d617',
      );
      expect(stored.metadata.projectionSha256, matches(r'^[0-9a-f]{64}$'));
      expect(
        constructionScheduleSnapshotProjectionSha256(
          scenario.schedule.scheduledActivities.reversed,
        ),
        stored.metadata.projectionSha256,
      );
      final persistedRows = await database.database.query(
        'project_schedule_snapshot_activities',
        where: 'snapshot_id = ?',
        whereArgs: ['snapshot-a'],
        orderBy: 'instance_id ASC',
      );
      expect(
        persistedRows.map((row) => row['row_sha256']),
        orderedEquals(
          stored.activities.map(constructionScheduleSnapshotActivitySha256),
        ),
      );
      expect(
        persistedRows.map((row) => row['row_sha256']),
        everyElement(matches(r'^[0-9a-f]{64}$')),
      );
      expect(
        stored.activities
            .where(
              (item) =>
                  item.durationConfidence ==
                  ConstructionScheduleDurationConfidence.aiSeed,
            )
            .map((item) => item.activityId),
        contains('ACT-C'),
      );
      expect(
        stored.activities
            .where(
              (item) =>
                  item.durationConfidence ==
                  ConstructionScheduleDurationConfidence.unknown,
            )
            .map((item) => item.activityId),
        contains('ACT-B'),
      );

      final current = await repository.loadCurrentSnapshot(
        scenario.profile.projectId,
      );
      final byId = await repository.loadSnapshotById('snapshot-a');
      expect(current?.metadata.snapshotId, 'snapshot-a');
      expect(byId?.metadata.snapshotId, 'snapshot-a');
      expect(
        (await repository.listSnapshotHistory(
          scenario.profile.projectId,
        )).map((item) => item.snapshotId),
        orderedEquals(const ['snapshot-a']),
      );

      final window = await repository.queryCurrentActivities(
        projectId: scenario.profile.projectId,
        windowStart: _date('2026-09-08'),
        windowEnd: _date('2026-09-09'),
      );
      expect(
        window.map((item) => item.instanceId),
        orderedEquals(const ['ACT-B@PROJECT', 'ACT-C@PROJECT']),
      );
      expect(
        await repository.queryCurrentActivities(
          projectId: scenario.profile.projectId,
          windowStart: _date('2026-09-20'),
          windowEnd: _date('2026-09-21'),
        ),
        isEmpty,
      );
    },
  );

  test(
    'replacement is atomic and retains newest-first immutable history',
    () async {
      final firstRepository = _repository(
        database,
        snapshotId: 'snapshot-a',
        generatedAt: DateTime.utc(2026, 8, 16, 7),
      );
      await _persist(firstRepository, scenario);
      final secondRepository = _repository(
        database,
        snapshotId: 'snapshot-b',
        generatedAt: DateTime.utc(2026, 8, 16, 8),
      );
      await _persist(secondRepository, scenario);

      final current = await secondRepository.loadCurrentSnapshot(
        scenario.profile.projectId,
      );
      final old = await secondRepository.loadSnapshotById('snapshot-a');
      final history = await secondRepository.listSnapshotHistory(
        scenario.profile.projectId,
      );
      expect(current?.metadata.snapshotId, 'snapshot-b');
      expect(old?.metadata.isCurrent, isFalse);
      expect(old?.metadata.supersededAt, DateTime.utc(2026, 8, 16, 8));
      expect(
        history.map((item) => item.snapshotId),
        orderedEquals(const ['snapshot-b', 'snapshot-a']),
      );
      expect(
        await database.database.query(
          'project_schedule_snapshot_activities',
          where: 'snapshot_id = ?',
          whereArgs: ['snapshot-a'],
        ),
        hasLength(4),
      );
    },
  );

  test(
    'mid-insert failure rolls back new snapshot and old supersede',
    () async {
      final firstRepository = _repository(
        database,
        snapshotId: 'snapshot-a',
        generatedAt: DateTime.utc(2026, 8, 16, 7),
      );
      await _persist(firstRepository, scenario);
      final failingRepository = ConstructionScheduleSnapshotRepository(
        database: database,
        clock: () => DateTime.utc(2026, 8, 16, 8),
        idFactory: () => 'snapshot-b',
        beforeActivityInsert: (index, _) async {
          if (index == 2) {
            throw StateError('injected mid-insert failure');
          }
        },
      );

      await expectLater(
        _persist(failingRepository, scenario),
        throwsA(isA<StateError>()),
      );
      final current = await firstRepository.loadCurrentSnapshot(
        scenario.profile.projectId,
      );
      expect(current?.metadata.snapshotId, 'snapshot-a');
      expect(current?.metadata.isCurrent, isTrue);
      expect(await firstRepository.loadSnapshotById('snapshot-b'), isNull);
      expect(
        await database.database.query('project_schedule_snapshots'),
        hasLength(1),
      );
      expect(
        await database.database.query('project_schedule_snapshot_activities'),
        hasLength(4),
      );
    },
  );

  test(
    'backward clock fails before mutation and preserves current snapshot',
    () async {
      final firstRepository = _repository(
        database,
        snapshotId: 'snapshot-a',
        generatedAt: DateTime.utc(2026, 8, 16, 8),
      );
      final first = await _persist(firstRepository, scenario);
      final metadataBefore = await database.database.query(
        'project_schedule_snapshots',
        orderBy: 'id ASC',
      );
      final activitiesBefore = await database.database.query(
        'project_schedule_snapshot_activities',
        orderBy: 'snapshot_id ASC, instance_id ASC',
      );

      final regressedRepository = _repository(
        database,
        snapshotId: 'snapshot-b',
        generatedAt: DateTime.utc(2026, 8, 16, 7),
      );
      await expectLater(
        _persist(regressedRepository, scenario),
        throwsA(
          isA<ConstructionScheduleSnapshotFailure>().having(
            (failure) => failure.code,
            'code',
            'schedule_snapshot_clock_regression',
          ),
        ),
      );

      expect(
        await database.database.query(
          'project_schedule_snapshots',
          orderBy: 'id ASC',
        ),
        metadataBefore,
      );
      expect(
        await database.database.query(
          'project_schedule_snapshot_activities',
          orderBy: 'snapshot_id ASC, instance_id ASC',
        ),
        activitiesBefore,
      );
      final current = await firstRepository.loadCurrentSnapshot(
        scenario.profile.projectId,
      );
      expect(current?.metadata.snapshotId, 'snapshot-a');
      expect(current?.metadata.supersededAt, isNull);
      expect(
        current?.metadata.projectionSha256,
        first.metadata.projectionSha256,
      );
      expect(
        _activityProjection(current!.activities),
        _activityProjection(first.activities),
      );
      expect(await firstRepository.loadSnapshotById('snapshot-b'), isNull);
      expect(
        await database.database.query(
          'project_schedule_snapshot_activities',
          where: 'snapshot_id = ?',
          whereArgs: ['snapshot-b'],
        ),
        isEmpty,
      );
    },
  );

  test(
    'invalid schedule is rejected before any persistence mutation',
    () async {
      final repository = _repository(
        database,
        snapshotId: 'snapshot-invalid',
        generatedAt: DateTime.utc(2026, 8, 16, 7),
      );
      final first = scenario.schedule.scheduledActivities.first;
      final invalid = scenario.schedule.copyWith(
        scheduledActivities: [
          first.copyWith(
            finishDate: first.finishDate.add(const Duration(days: 1)),
          ),
          ...scenario.schedule.scheduledActivities.skip(1),
        ],
      );
      await expectLater(
        repository.persistCurrentSnapshot(
          schedule: invalid,
          profile: scenario.profile,
          graph: scenario.graph,
          seedCatalog: scenario.catalog,
        ),
        throwsA(isA<ConstructionCorpusFailure>()),
      );
      expect(
        await database.database.query('project_schedule_snapshots'),
        isEmpty,
      );
      expect(
        await database.database.query('project_schedule_snapshot_activities'),
        isEmpty,
      );
    },
  );

  test(
    'load fails closed for corrupted fingerprint enum date count and profile',
    () async {
      final repository = _repository(
        database,
        snapshotId: 'snapshot-a',
        generatedAt: DateTime.utc(2026, 8, 16, 7),
      );
      await _persist(repository, scenario);
      final db = database.database;
      await db.execute(
        'DROP TRIGGER project_schedule_snapshots_supersede_only',
      );
      await db.execute(
        'DROP TRIGGER project_schedule_snapshot_activities_immutable_update',
      );
      await db.execute('PRAGMA ignore_check_constraints = ON');

      final originalMetadata = (await db.query(
        'project_schedule_snapshots',
        where: 'id = ?',
        whereArgs: ['snapshot-a'],
      )).single;
      final originalActivity = (await db.query(
        'project_schedule_snapshot_activities',
        where: 'snapshot_id = ? AND instance_id = ?',
        whereArgs: ['snapshot-a', 'ACT-A@PROJECT'],
      )).single;

      Future<void> expectCorruptLoad() => expectLater(
        repository.loadSnapshotById('snapshot-a'),
        throwsA(isA<ConstructionScheduleSnapshotFailure>()),
      );

      await db.update(
        'project_schedule_snapshot_activities',
        {'activity_id': 'ACT-B-CORRUPTED'},
        where: 'snapshot_id = ? AND instance_id = ?',
        whereArgs: ['snapshot-a', 'ACT-B@PROJECT'],
      );
      await expectLater(
        repository.loadCurrentSnapshot(scenario.profile.projectId),
        throwsA(
          isA<ConstructionScheduleSnapshotFailure>().having(
            (failure) => failure.code,
            'code',
            'schedule_snapshot_activity_fingerprint_mismatch',
          ),
        ),
      );
      await expectLater(
        repository.queryCurrentActivities(
          projectId: scenario.profile.projectId,
          windowStart: _date('2026-09-08'),
          windowEnd: _date('2026-09-09'),
        ),
        throwsA(
          isA<ConstructionScheduleSnapshotFailure>().having(
            (failure) => failure.code,
            'code',
            'schedule_snapshot_activity_fingerprint_mismatch',
          ),
        ),
      );
      await db.update(
        'project_schedule_snapshot_activities',
        {'activity_id': 'ACT-B'},
        where: 'snapshot_id = ? AND instance_id = ?',
        whereArgs: ['snapshot-a', 'ACT-B@PROJECT'],
      );

      await db.update(
        'project_schedule_snapshots',
        {'projection_sha256': 'f' * 64},
        where: 'id = ?',
        whereArgs: ['snapshot-a'],
      );
      await expectCorruptLoad();
      await db.update(
        'project_schedule_snapshots',
        {'projection_sha256': originalMetadata['projection_sha256']},
        where: 'id = ?',
        whereArgs: ['snapshot-a'],
      );

      await db.update(
        'project_schedule_snapshot_activities',
        {'duration_status': 'BROKEN'},
        where: 'snapshot_id = ? AND instance_id = ?',
        whereArgs: ['snapshot-a', 'ACT-A@PROJECT'],
      );
      await expectCorruptLoad();
      await db.update(
        'project_schedule_snapshot_activities',
        {'duration_status': originalActivity['duration_status']},
        where: 'snapshot_id = ? AND instance_id = ?',
        whereArgs: ['snapshot-a', 'ACT-A@PROJECT'],
      );

      await db.update(
        'project_schedule_snapshot_activities',
        {'start_date': '2026-9-1'},
        where: 'snapshot_id = ? AND instance_id = ?',
        whereArgs: ['snapshot-a', 'ACT-A@PROJECT'],
      );
      await expectCorruptLoad();
      await db.update(
        'project_schedule_snapshot_activities',
        {'start_date': originalActivity['start_date']},
        where: 'snapshot_id = ? AND instance_id = ?',
        whereArgs: ['snapshot-a', 'ACT-A@PROJECT'],
      );

      await db.update(
        'project_schedule_snapshots',
        {'activity_count': 5},
        where: 'id = ?',
        whereArgs: ['snapshot-a'],
      );
      await expectCorruptLoad();
      await db.update(
        'project_schedule_snapshots',
        {'activity_count': originalMetadata['activity_count']},
        where: 'id = ?',
        whereArgs: ['snapshot-a'],
      );

      final profileJson = originalMetadata['profile_json']! as String;
      await db.update(
        'project_schedule_snapshots',
        {'profile_json': profileJson.replaceFirst('PRJ-SNAPSHOT', 'PRJ-OTHER')},
        where: 'id = ?',
        whereArgs: ['snapshot-a'],
      );
      await expectCorruptLoad();
    },
  );

  test(
    'missing rows duplicate input and multiple currents fail closed',
    () async {
      final repository = _repository(
        database,
        snapshotId: 'snapshot-a',
        generatedAt: DateTime.utc(2026, 8, 16, 7),
      );
      final stored = await _persist(repository, scenario);
      expect(
        () => constructionScheduleSnapshotProjectionSha256([
          scenario.schedule.scheduledActivities.first,
          scenario.schedule.scheduledActivities.first,
        ]),
        throwsA(isA<ConstructionScheduleSnapshotFailure>()),
      );

      final db = database.database;
      await db.execute(
        'DROP TRIGGER project_schedule_snapshot_activities_immutable_delete',
      );
      await db.delete(
        'project_schedule_snapshot_activities',
        where: 'snapshot_id = ? AND instance_id = ?',
        whereArgs: ['snapshot-a', 'ACT-D@PROJECT'],
      );
      await expectLater(
        repository.loadSnapshotById('snapshot-a'),
        throwsA(isA<ConstructionScheduleSnapshotFailure>()),
      );
      await expectLater(
        repository.queryCurrentActivities(
          projectId: scenario.profile.projectId,
          windowStart: _date('2026-09-08'),
          windowEnd: _date('2026-09-09'),
        ),
        throwsA(
          isA<ConstructionScheduleSnapshotFailure>().having(
            (failure) => failure.code,
            'code',
            'schedule_snapshot_activity_count_mismatch',
          ),
        ),
      );

      await db.execute('DROP INDEX project_schedule_snapshots_one_current');
      final metadataRow = (await db.query(
        'project_schedule_snapshots',
        where: 'id = ?',
        whereArgs: ['snapshot-a'],
      )).single;
      await db.insert('project_schedule_snapshots', {
        ...metadataRow,
        'id': 'snapshot-b',
        'generated_at': '2026-08-16T08:00:00Z',
      });
      await expectLater(
        repository.loadCurrentSnapshot(scenario.profile.projectId),
        throwsA(isA<ConstructionScheduleSnapshotFailure>()),
      );
      expect(stored.metadata.isCurrent, isTrue);
    },
  );

  test('window bounds must be canonical UTC and ordered', () async {
    final repository = _repository(
      database,
      snapshotId: 'snapshot-a',
      generatedAt: DateTime.utc(2026, 8, 16, 7),
    );
    await _persist(repository, scenario);
    await expectLater(
      repository.queryCurrentActivities(
        projectId: scenario.profile.projectId,
        windowStart: _date('2026-09-10'),
        windowEnd: _date('2026-09-09'),
      ),
      throwsA(isA<ConstructionScheduleSnapshotFailure>()),
    );
    await expectLater(
      repository.queryCurrentActivities(
        projectId: scenario.profile.projectId,
        windowStart: DateTime(2026, 9, 8),
        windowEnd: DateTime(2026, 9, 9),
      ),
      throwsA(isA<ConstructionCorpusFailure>()),
    );
  });

  test(
    'window read and replacement share one consistent database boundary',
    () async {
      final firstRepository = _repository(
        database,
        snapshotId: 'snapshot-a',
        generatedAt: DateTime.utc(2026, 8, 16, 8),
      );
      await _persist(firstRepository, scenario);
      final replacementScenario = _scheduleScenario(
        scheduleStart: '2026-10-02',
      );

      final integrityChecked = Completer<void>();
      final releaseWindowRead = Completer<void>();
      final replacementEnteredMutation = Completer<void>();
      final readRepository = ConstructionScheduleSnapshotRepository(
        database: database,
        clock: () => DateTime.utc(2026, 8, 16, 8),
        idFactory: () => 'unused-read-id',
        afterWindowIntegrityCheck: () async {
          integrityChecked.complete();
          await releaseWindowRead.future;
        },
      );
      final replacementRepository = ConstructionScheduleSnapshotRepository(
        database: database,
        clock: () => DateTime.utc(2026, 8, 16, 9),
        idFactory: () => 'snapshot-b',
        beforeActivityInsert: (_, _) async {
          if (!replacementEnteredMutation.isCompleted) {
            replacementEnteredMutation.complete();
          }
        },
      );

      final oldWindowFuture = readRepository.queryCurrentActivities(
        projectId: scenario.profile.projectId,
        windowStart: _date('2026-09-01'),
        windowEnd: _date('2026-09-30'),
      );
      await integrityChecked.future;
      final replacementFuture = _persist(
        replacementRepository,
        replacementScenario,
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(replacementEnteredMutation.isCompleted, isFalse);
      releaseWindowRead.complete();

      final oldWindow = await oldWindowFuture;
      await replacementFuture;
      expect(
        _activityProjection(oldWindow),
        _activityProjection(
          _windowOrdered(scenario.schedule.scheduledActivities),
        ),
      );
      expect(replacementEnteredMutation.isCompleted, isTrue);

      final newWindow = await replacementRepository.queryCurrentActivities(
        projectId: scenario.profile.projectId,
        windowStart: _date('2026-10-01'),
        windowEnd: _date('2026-10-31'),
      );
      expect(
        _activityProjection(newWindow),
        _activityProjection(
          _windowOrdered(replacementScenario.schedule.scheduledActivities),
        ),
      );
      expect(
        formatCanonicalConstructionDate(oldWindow.first.startDate),
        isNot(formatCanonicalConstructionDate(newWindow.first.startDate)),
      );
    },
  );
}

ConstructionScheduleSnapshotRepository _repository(
  AppDatabase database, {
  required String snapshotId,
  required DateTime generatedAt,
}) => ConstructionScheduleSnapshotRepository(
  database: database,
  clock: () => generatedAt,
  idFactory: () => snapshotId,
);

Future<ConstructionScheduleSnapshot> _persist(
  ConstructionScheduleSnapshotRepository repository,
  _ScheduleScenario scenario,
) => repository.persistCurrentSnapshot(
  schedule: scenario.schedule,
  profile: scenario.profile,
  graph: scenario.graph,
  seedCatalog: scenario.catalog,
);

Future<void> _insertProject(AppDatabase database, String projectId) =>
    database.database.insert('projects', {
      'id': projectId,
      'name': 'Schedule snapshot test project',
      'created_at': '2026-08-16T06:00:00Z',
      'updated_at': '2026-08-16T06:00:00Z',
    });

_ScheduleScenario _scheduleScenario({String scheduleStart = '2026-09-04'}) {
  final profile = validConstructionProjectProfile(
    overrides: {
      'project_id': 'PRJ-SNAPSHOT',
      'calendar': <String, Object?>{
        'start_date': scheduleStart,
        'working_weekdays': <Object?>[0, 1, 2, 3, 4, 5],
        'holidays': <Object?>['2026-09-07'],
        'workday_hours': 8,
      },
    },
  );
  final seeds = [
    _seed(
      'ACT-A',
      2,
      status: ConstructionScheduleDurationStatus.sourceBacked,
      confidence: ConstructionScheduleDurationConfidence.authoritative,
    ),
    _seed(
      'ACT-B',
      0,
      status: ConstructionScheduleDurationStatus.unknown,
      confidence: ConstructionScheduleDurationConfidence.unknown,
    ),
    _seed(
      'ACT-C',
      3,
      type: ConstructionActivityDurationCalendarType.calendarDay,
      status: ConstructionScheduleDurationStatus.aiSeedEstimate,
      confidence: ConstructionScheduleDurationConfidence.aiSeed,
    ),
    _seed(
      'ACT-D',
      1,
      type: ConstructionActivityDurationCalendarType.calendarDay,
      status: ConstructionScheduleDurationStatus.unknown,
      confidence: ConstructionScheduleDurationConfidence.unknown,
    ),
  ];
  final instances = [for (final seed in seeds) _instance(seed.activityId)];
  final edges = [
    _edge(0, 'ACT-A@PROJECT', 'ACT-B@PROJECT'),
    _edge(1, 'ACT-B@PROJECT', 'ACT-C@PROJECT'),
  ];
  final graph = ConstructionProjectActivityGraph(
    projectId: profile.projectId,
    activityInstances: instances,
    dependencyEdges: edges,
    isolatedInstanceIds: const ['ACT-D@PROJECT'],
    corpusVersion: '0.3-yfk-resource-seed',
    selectedActivityTemplateCount: instances.length,
    selectedDependencyTemplateCount: edges.length,
  );
  final catalog = ConstructionScheduleSeedCatalog(
    metadata: const ConstructionScheduleSeedCatalogMetadata(
      name: 'SNAPSHOT TEST SEEDS',
      corpusVersion: '0.3-yfk-resource-seed',
      sourcePublicationStatus: 'RESEARCH_RESOURCE_SEED',
      sourceProductionStatus: 'NOT_FOR_PRODUCTION',
      sourceZipSha256: 'test',
      warning: 'test',
      runtimeScope: 'SCHEDULE_SEED_CATALOG_READ_ONLY_NOT_A_BASELINE',
      activityCount: 4,
      workingDayCount: 2,
      calendarDayCount: 2,
      milestoneCount: 1,
      authoritativeCount: 1,
      aiSeedCount: 1,
      unknownConfidenceCount: 2,
      sourceBackedCount: 1,
      aiSeedEstimateCount: 1,
      unknownStatusCount: 2,
    ),
    seeds: seeds,
  );
  final schedule = ConstructionScheduleDateEngine().build(
    profile: profile,
    graph: graph,
    seedCatalog: catalog,
  );
  return _ScheduleScenario(profile, graph, catalog, schedule);
}

ConstructionScheduleSeed _seed(
  String activityId,
  double duration, {
  ConstructionActivityDurationCalendarType type =
      ConstructionActivityDurationCalendarType.workingDay,
  required ConstructionScheduleDurationStatus status,
  required ConstructionScheduleDurationConfidence confidence,
}) => ConstructionScheduleSeed(
  activityId: activityId,
  durationDays: duration,
  durationCalendarType: type,
  durationStatus: status,
  durationConfidence: confidence,
);

ConstructionProjectActivityInstance _instance(String activityId) =>
    ConstructionProjectActivityInstance(
      instanceId: '$activityId@PROJECT',
      activityId: activityId,
      wbsCode: 'TEST',
      packageId: 'TEST',
      activityNameTr: activityId,
      repeatDimension: ConstructionActivityRepeatDimension.project,
      context: const ConstructionProjectActivityContext(),
      naturalUnit: 'TEST',
      durationStatus: 'TEST',
      durationConfidence: 'TEST',
      testSeedDurationDays: 1,
    );

ConstructionResolvedDependencyEdge _edge(
  int index,
  String predecessor,
  String successor,
) => ConstructionResolvedDependencyEdge(
  edgeKey: 'EDGE-$index',
  templateDependencyId: 'DEP-$index',
  predecessorInstanceId: predecessor,
  successorInstanceId: successor,
  relationshipType: ConstructionDependencyRelationshipType.finishToStart,
  lagValue: 0,
  lagUnit: ConstructionDependencyLagUnit.workingDay,
  scopeRule: ConstructionDependencyScopeRule.project,
  isMandatory: true,
  confidence: ConstructionDependencyConfidence.supportedInference,
  reviewStatus: ConstructionDependencyReviewStatus.reviewRequired,
);

DateTime _date(String value) => parseCanonicalConstructionDate(value);

List<ConstructionScheduledActivity> _windowOrdered(
  Iterable<ConstructionScheduledActivity> activities,
) => activities.toList(growable: false)
  ..sort((left, right) {
    final start = left.startDate.compareTo(right.startDate);
    if (start != 0) {
      return start;
    }
    final finish = left.finishDate.compareTo(right.finishDate);
    if (finish != 0) {
      return finish;
    }
    return left.instanceId.compareTo(right.instanceId);
  });

List<Map<String, Object?>> _activityProjection(
  Iterable<ConstructionScheduledActivity> activities,
) => [
  for (final item in activities)
    {
      'instance': item.instanceId,
      'activity': item.activityId,
      'start': formatCanonicalConstructionDate(item.startDate),
      'finish': formatCanonicalConstructionDate(item.finishDate),
      'days': item.durationDays,
      'rounded': item.roundedSchedulingDays,
      'calendar': item.durationCalendarType.jsonValue,
      'status': item.durationStatus.jsonValue,
      'confidence': item.durationConfidence.jsonValue,
      'milestone': item.isMilestone,
      'isolated': item.isIsolated,
    },
];

class _ScheduleScenario {
  const _ScheduleScenario(
    this.profile,
    this.graph,
    this.catalog,
    this.schedule,
  );

  final ConstructionProjectProfile profile;
  final ConstructionProjectActivityGraph graph;
  final ConstructionScheduleSeedCatalog catalog;
  final ConstructionProjectReferenceSchedule schedule;
}
