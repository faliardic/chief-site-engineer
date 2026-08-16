import 'dart:io';

import 'package:chief_site_engineer/application/construction_living_plan_application.dart';
import 'package:chief_site_engineer/application/construction_schedule_date_engine.dart';
import 'package:chief_site_engineer/application/construction_schedule_snapshot_repository.dart';
import 'package:chief_site_engineer/core/environment.dart';
import 'package:chief_site_engineer/domain/construction_corpus_models.dart';
import 'package:chief_site_engineer/domain/construction_living_plan_models.dart';
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
  late _LivingScenario scenario;
  late ConstructionScheduleSnapshotRepository snapshotRepository;
  late ConstructionLivingPlanApplication application;
  late DateTime now;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    temporaryRoot = await Directory.systemTemp.createTemp('cse_living_plan_');
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
    scenario = _livingScenario();
    await database.database.insert('projects', {
      'id': scenario.profile.projectId,
      'name': scenario.profile.projectName,
      'created_at': '2026-08-16T06:00:00Z',
      'updated_at': '2026-08-16T06:00:00Z',
    });
    snapshotRepository = _snapshotRepository(
      database,
      snapshotId: 'snapshot-a',
      generatedAt: DateTime.utc(2026, 8, 16, 8),
    );
    await _persist(snapshotRepository, scenario);
    now = DateTime.utc(2026, 8, 16, 9);
    application = _application(
      database: database,
      repository: snapshotRepository,
      scenario: scenario,
      clock: () => now,
    );
  });

  tearDown(() async {
    await database.close();
    if (await temporaryRoot.exists()) {
      await temporaryRoot.delete(recursive: true);
    }
  });

  test(
    'trusted window suggestions and Turkish search are typed deterministic and marked',
    () async {
      var fullSnapshotLoads = 0;
      final observedRepository = ConstructionScheduleSnapshotRepository(
        database: database,
        clock: () => now,
        afterFullSnapshotMetadataRead: () async {
          fullSnapshotLoads += 1;
        },
      );
      final observed = _application(
        database: database,
        repository: observedRepository,
        scenario: scenario,
        clock: () => now,
      );

      final suggestions = await observed.loadSevenDayReferenceSuggestions(
        projectId: scenario.profile.projectId,
        windowStart: _date('2026-09-04'),
      );
      expect(fullSnapshotLoads, 0);
      expect(suggestions, isNotEmpty);
      expect(suggestions.map((item) => item.referenceSnapshotId).toSet(), {
        'snapshot-a',
      });
      expect(suggestions.map((item) => item.projectId).toSet(), {
        scenario.profile.projectId,
      });
      final floor = suggestions.singleWhere(
        (item) => item.activityId == 'ACT-C',
      );
      expect(floor.activityName, 'Duvar İmalatı');
      expect(floor.activityContext.blockId, 'A');
      expect(floor.activityContext.floorIndex, 2);
      expect(floor.naturalUnit, 'm²');
      expect(floor.existingLivingPlanItemId, isNull);
      expect(
        _candidateOrder(suggestions),
        orderedEquals(suggestions.map((item) => item.activityInstanceId)),
      );

      final alias = await observed.searchCurrentReferenceCandidates(
        projectId: scenario.profile.projectId,
        query: 'BETONAJ',
      );
      expect(fullSnapshotLoads, 1);
      expect(alias.map((item) => item.activityId), ['ACT-B']);
      final normalized = await observed.searchCurrentReferenceCandidates(
        projectId: scenario.profile.projectId,
        query: 'duvar imalati',
      );
      expect(normalized.map((item) => item.activityId), ['ACT-C']);
      final capped = await observed.searchCurrentReferenceCandidates(
        projectId: scenario.profile.projectId,
        query: 'iş',
        limit: 2,
      );
      expect(capped, hasLength(2));
      expect(
        capped.map((item) => item.activitySequence),
        orderedEquals(
          capped.map((item) => item.activitySequence).toList()..sort(),
        ),
      );
      await expectLater(
        observed.searchCurrentReferenceCandidates(
          projectId: scenario.profile.projectId,
          query: '  ',
        ),
        _failure('living_plan_empty_reference_query'),
      );
      await expectLater(
        observed.searchCurrentReferenceCandidates(
          projectId: scenario.profile.projectId,
          query: 'beton',
          limit: 201,
        ),
        _failure('living_plan_invalid_reference_limit'),
      );

      final created = await _create(
        observed,
        scenario,
        activityId: 'ACT-B',
        itemNumber: 1,
        eventNumber: 101,
        plannedDate: '2026-09-08',
      );
      final marked = await observed.loadSevenDayReferenceSuggestions(
        projectId: scenario.profile.projectId,
        windowStart: _date('2026-09-04'),
      );
      final markedBeton = marked.singleWhere(
        (item) => item.activityId == 'ACT-B',
      );
      expect(markedBeton.existingLivingPlanItemId, created.id);
      expect(
        markedBeton.existingLivingPlanStatus,
        ConstructionLivingPlanStatus.planned,
      );
      expect(fullSnapshotLoads, 4);
    },
  );

  test('missing and cross-source mismatched references fail closed', () async {
    final missingProject = 'PRJ-NO-SNAPSHOT';
    await database.database.insert('projects', {
      'id': missingProject,
      'name': 'Snapshot bulunmayan proje',
      'created_at': '2026-08-16T06:00:00Z',
      'updated_at': '2026-08-16T06:00:00Z',
    });
    await expectLater(
      application.loadSevenDayReferenceSuggestions(
        projectId: missingProject,
        windowStart: _date('2026-09-04'),
      ),
      _failure('living_plan_reference_snapshot_missing'),
    );

    final mismatchedGraph = ConstructionProjectActivityGraph(
      projectId: scenario.graph.projectId,
      activityInstances: scenario.graph.activityInstances.skip(1),
      dependencyEdges: const <ConstructionResolvedDependencyEdge>[],
      isolatedInstanceIds: const <String>[],
      corpusVersion: scenario.graph.corpusVersion,
      selectedActivityTemplateCount:
          scenario.graph.activityInstances.length - 1,
      selectedDependencyTemplateCount: 0,
    );
    final mismatched = ConstructionLivingPlanApplication(
      database: database,
      snapshotRepository: snapshotRepository,
      clock: () => now,
      graphLoader: (_) async => mismatchedGraph,
      corpusLoader: () async => scenario.corpus,
    );
    await expectLater(
      mismatched.searchCurrentReferenceCandidates(
        projectId: scenario.profile.projectId,
        query: 'iş',
      ),
      _failure('living_plan_reference_integrity_failed'),
    );

    final wrongCorpusGraph = ConstructionProjectActivityGraph(
      projectId: scenario.graph.projectId,
      activityInstances: scenario.graph.activityInstances,
      dependencyEdges: scenario.graph.dependencyEdges,
      isolatedInstanceIds: scenario.graph.isolatedInstanceIds,
      corpusVersion: 'wrong-corpus',
      selectedActivityTemplateCount: scenario.graph.activityInstances.length,
      selectedDependencyTemplateCount: scenario.graph.dependencyEdges.length,
    );
    final wrongCorpus = ConstructionLivingPlanApplication(
      database: database,
      snapshotRepository: snapshotRepository,
      clock: () => now,
      graphLoader: (_) async => wrongCorpusGraph,
      corpusLoader: () async => scenario.corpus,
    );
    await expectLater(
      wrongCorpus.loadSevenDayReferenceSuggestions(
        projectId: scenario.profile.projectId,
        windowStart: _date('2026-09-04'),
      ),
      _failure('living_plan_reference_integrity_failed'),
    );
  });

  test(
    'create writes exact projection and event with replay conflict and stale race guards',
    () async {
      final created = await _create(
        application,
        scenario,
        activityId: 'ACT-C',
        itemNumber: 2,
        eventNumber: 102,
        plannedDate: '2026-09-09',
        note: 'İkinci kat ekibi hazır',
      );
      expect(created.referenceSnapshotId, 'snapshot-a');
      expect(created.activityNameSnapshot, 'Duvar İmalatı');
      expect(created.activityContext.floorIndex, 2);
      expect(created.naturalUnitSnapshot, 'm²');
      expect(created.status, ConstructionLivingPlanStatus.planned);
      expect(created.revision, 1);
      expect(created.createdAt, now);
      final history = await application.listLivingPlanEventHistory(created.id);
      expect(history, hasLength(1));
      expect(history.single.sequence, 1);
      expect(history.single.eventType, ConstructionLivingPlanEventType.created);
      expect(history.single.payload['intent'], {
        'activity_instance_id': _instanceId(scenario, 'ACT-C'),
        'expected_reference_snapshot_id': 'snapshot-a',
        'note': 'İkinci kat ekibi hazır',
        'operation': 'CREATED',
        'planned_date': '2026-09-09',
        'project_id': scenario.profile.projectId,
      });

      final replayed = await _create(
        application,
        scenario,
        activityId: 'ACT-C',
        itemNumber: 2,
        eventNumber: 102,
        plannedDate: '2026-09-09',
        note: 'İkinci kat ekibi hazır',
      );
      expect(replayed.revision, 1);
      expect(
        await application.listLivingPlanEventHistory(created.id),
        hasLength(1),
      );
      await expectLater(
        _create(
          application,
          scenario,
          activityId: 'ACT-C',
          itemNumber: 2,
          eventNumber: 102,
          plannedDate: '2026-09-10',
          note: 'İkinci kat ekibi hazır',
        ),
        _failure('living_plan_event_id_conflict'),
      );

      var replacementDone = false;
      final racing = _application(
        database: database,
        repository: snapshotRepository,
        scenario: scenario,
        clock: () => now,
        beforeCreateTransaction: () async {
          if (!replacementDone) {
            replacementDone = true;
            await _persist(
              _snapshotRepository(
                database,
                snapshotId: 'snapshot-b',
                generatedAt: DateTime.utc(2026, 8, 16, 10),
              ),
              scenario,
            );
          }
        },
      );
      await expectLater(
        _create(
          racing,
          scenario,
          activityId: 'ACT-D',
          itemNumber: 3,
          eventNumber: 103,
          plannedDate: '2026-09-10',
        ),
        _failure('living_plan_reference_snapshot_stale'),
      );
      expect(
        await database.database.query(
          'project_living_plan_items',
          where: 'id = ?',
          whereArgs: [_uuid(3)],
        ),
        isEmpty,
      );
      expect(
        await database.database.query(
          'project_living_plan_events',
          where: 'id = ?',
          whereArgs: [_uuid(103)],
        ),
        isEmpty,
      );
    },
  );

  test(
    'snapshot replacement retains origin rejects stale add and prevents duplicate rebind',
    () async {
      final original = await _create(
        application,
        scenario,
        activityId: 'ACT-A',
        itemNumber: 4,
        eventNumber: 104,
        plannedDate: '2026-09-05',
      );
      final secondRepository = _snapshotRepository(
        database,
        snapshotId: 'snapshot-b',
        generatedAt: DateTime.utc(2026, 8, 16, 10),
      );
      await _persist(secondRepository, scenario);
      final afterReplacement = _application(
        database: database,
        repository: secondRepository,
        scenario: scenario,
        clock: () => now,
      );

      final loaded = await afterReplacement.loadLivingPlanItem(original.id);
      expect(loaded?.referenceSnapshotId, 'snapshot-a');
      expect(loaded?.activityNameSnapshot, original.activityNameSnapshot);
      expect(loaded?.activityContext.blockId, original.activityContext.blockId);
      final plan = await afterReplacement.loadSevenDayPlan(
        projectId: scenario.profile.projectId,
        windowStart: _date('2026-09-04'),
      );
      expect(plan.single.item.referenceSnapshotId, 'snapshot-a');
      expect(plan.single.originSnapshotIsCurrent, isFalse);

      await expectLater(
        _create(
          application,
          scenario,
          activityId: 'ACT-B',
          itemNumber: 5,
          eventNumber: 105,
          plannedDate: '2026-09-08',
        ),
        _failure('living_plan_reference_snapshot_stale'),
      );
      await expectLater(
        _create(
          afterReplacement,
          scenario,
          activityId: 'ACT-A',
          itemNumber: 6,
          eventNumber: 106,
          plannedDate: '2026-09-06',
          snapshotId: 'snapshot-b',
        ),
        _failure('living_plan_item_already_exists'),
      );
      expect(
        await database.database.query(
          'project_living_plan_items',
          where: 'project_id = ? AND activity_instance_id = ?',
          whereArgs: [
            scenario.profile.projectId,
            _instanceId(scenario, 'ACT-A'),
          ],
        ),
        hasLength(1),
      );
    },
  );

  test(
    'lifecycle transitions are optimistic evented idempotent and no-op safe',
    () async {
      final item = await _create(
        application,
        scenario,
        activityId: 'ACT-A',
        itemNumber: 7,
        eventNumber: 107,
        plannedDate: '2026-09-05',
        note: 'İlk not',
      );
      now = DateTime.utc(2026, 8, 16, 9, 0, 1);
      final started = await application.startLivingPlanItem(
        StartConstructionLivingPlanItemCommand(
          itemId: item.id,
          eventId: _uuid(207),
          expectedRevision: 1,
        ),
      );
      expect(started.status, ConstructionLivingPlanStatus.started);
      expect(started.revision, 2);
      final replayedStart = await application.startLivingPlanItem(
        StartConstructionLivingPlanItemCommand(
          itemId: item.id,
          eventId: _uuid(207),
          expectedRevision: 1,
        ),
      );
      expect(replayedStart.status, ConstructionLivingPlanStatus.started);
      expect(replayedStart.revision, 2);
      final noOpStart = await application.startLivingPlanItem(
        StartConstructionLivingPlanItemCommand(
          itemId: item.id,
          eventId: _uuid(208),
          expectedRevision: 2,
        ),
      );
      expect(noOpStart.revision, 2);
      expect(
        await application.listLivingPlanEventHistory(item.id),
        hasLength(2),
      );
      await expectLater(
        application.completeLivingPlanItem(
          CompleteConstructionLivingPlanItemCommand(
            itemId: item.id,
            eventId: _uuid(207),
            expectedRevision: 2,
          ),
        ),
        _failure('living_plan_event_id_conflict'),
      );
      await expectLater(
        application.completeLivingPlanItem(
          CompleteConstructionLivingPlanItemCommand(
            itemId: item.id,
            eventId: _uuid(209),
            expectedRevision: 1,
          ),
        ),
        _failure('living_plan_stale_revision'),
      );

      now = DateTime.utc(2026, 8, 16, 9, 0, 2);
      final completed = await application.completeLivingPlanItem(
        CompleteConstructionLivingPlanItemCommand(
          itemId: item.id,
          eventId: _uuid(210),
          expectedRevision: 2,
        ),
      );
      expect(completed.status, ConstructionLivingPlanStatus.completed);
      expect(completed.revision, 3);
      final oldReplay = await application.startLivingPlanItem(
        StartConstructionLivingPlanItemCommand(
          itemId: item.id,
          eventId: _uuid(207),
          expectedRevision: 1,
        ),
      );
      expect(oldReplay.status, ConstructionLivingPlanStatus.started);
      expect(oldReplay.revision, 2);
      expect((await application.loadLivingPlanItem(item.id))?.revision, 3);
      await expectLater(
        application.startLivingPlanItem(
          StartConstructionLivingPlanItemCommand(
            itemId: item.id,
            eventId: _uuid(211),
            expectedRevision: 3,
          ),
        ),
        _failure('living_plan_invalid_transition'),
      );

      now = DateTime.utc(2026, 8, 16, 9, 0, 3);
      final reopened = await application.reopenLivingPlanItem(
        ReopenConstructionLivingPlanItemCommand(
          itemId: item.id,
          eventId: _uuid(212),
          expectedRevision: 3,
          plannedDate: _date('2026-09-06'),
        ),
      );
      expect(reopened.status, ConstructionLivingPlanStatus.planned);
      expect(reopened.plannedDate, _date('2026-09-06'));
      expect(reopened.revision, 4);
      final noOpReopen = await application.reopenLivingPlanItem(
        ReopenConstructionLivingPlanItemCommand(
          itemId: item.id,
          eventId: _uuid(213),
          expectedRevision: 4,
          plannedDate: _date('2026-09-06'),
        ),
      );
      expect(noOpReopen.revision, 4);

      await expectLater(
        application.deferLivingPlanItem(
          DeferConstructionLivingPlanItemCommand(
            itemId: item.id,
            eventId: _uuid(214),
            expectedRevision: 4,
            plannedDate: _date('2026-09-06'),
          ),
        ),
        _failure('living_plan_invalid_transition'),
      );
      now = DateTime.utc(2026, 8, 16, 9, 0, 4);
      final deferred = await application.deferLivingPlanItem(
        DeferConstructionLivingPlanItemCommand(
          itemId: item.id,
          eventId: _uuid(215),
          expectedRevision: 4,
          plannedDate: _date('2026-09-09'),
        ),
      );
      expect(deferred.status, ConstructionLivingPlanStatus.deferred);
      expect(deferred.revision, 5);
      final deferEvent = (await application.listLivingPlanEventHistory(
        item.id,
      )).last;
      expect(deferEvent.payload['change'], {
        'new_planned_date': '2026-09-09',
        'old_planned_date': '2026-09-06',
        'previous_status': 'PLANNED',
        'status': 'DEFERRED',
      });

      now = DateTime.utc(2026, 8, 16, 9, 0, 5);
      final completedAfterDefer = await application.completeLivingPlanItem(
        CompleteConstructionLivingPlanItemCommand(
          itemId: item.id,
          eventId: _uuid(216),
          expectedRevision: 5,
        ),
      );
      expect(
        completedAfterDefer.status,
        ConstructionLivingPlanStatus.completed,
      );
      now = DateTime.utc(2026, 8, 16, 9, 0, 6);
      final noted = await application.updateLivingPlanNote(
        UpdateConstructionLivingPlanNoteCommand(
          itemId: item.id,
          eventId: _uuid(217),
          expectedRevision: 6,
          note: 'Tamamlandı, teslim bekleniyor',
        ),
      );
      expect(noted.note, 'Tamamlandı, teslim bekleniyor');
      expect(noted.status, ConstructionLivingPlanStatus.completed);
      expect(noted.revision, 7);
      final events = await application.listLivingPlanEventHistory(item.id);
      expect(
        events.map((event) => event.sequence),
        orderedEquals([1, 2, 3, 4, 5, 6, 7]),
      );
      expect(
        events.last.eventType,
        ConstructionLivingPlanEventType.noteUpdated,
      );

      final direct = await _create(
        application,
        scenario,
        activityId: 'ACT-B',
        itemNumber: 8,
        eventNumber: 108,
        plannedDate: '2026-09-08',
      );
      now = DateTime.utc(2026, 8, 16, 9, 0, 7);
      final directComplete = await application.completeLivingPlanItem(
        CompleteConstructionLivingPlanItemCommand(
          itemId: direct.id,
          eventId: _uuid(218),
          expectedRevision: 1,
        ),
      );
      expect(directComplete.status, ConstructionLivingPlanStatus.completed);
    },
  );

  test(
    'clock regression and injected event failure roll back projection',
    () async {
      final item = await _create(
        application,
        scenario,
        activityId: 'ACT-D',
        itemNumber: 9,
        eventNumber: 109,
        plannedDate: '2026-09-07',
      );
      now = DateTime.utc(2026, 8, 16, 8, 59, 59);
      await expectLater(
        application.updateLivingPlanNote(
          UpdateConstructionLivingPlanNoteCommand(
            itemId: item.id,
            eventId: _uuid(219),
            expectedRevision: 1,
            note: 'Geri saat',
          ),
        ),
        _failure('living_plan_clock_regression'),
      );
      expect((await application.loadLivingPlanItem(item.id))?.revision, 1);
      expect(
        await application.listLivingPlanEventHistory(item.id),
        hasLength(1),
      );

      now = DateTime.utc(2026, 8, 16, 9, 0, 1);
      final failingMutation = _application(
        database: database,
        repository: snapshotRepository,
        scenario: scenario,
        clock: () => now,
        beforeEventInsert: () async =>
            throw StateError('injected event failure'),
      );
      await expectLater(
        failingMutation.startLivingPlanItem(
          StartConstructionLivingPlanItemCommand(
            itemId: item.id,
            eventId: _uuid(220),
            expectedRevision: 1,
          ),
        ),
        throwsA(isA<StateError>()),
      );
      final afterFailure = await application.loadLivingPlanItem(item.id);
      expect(afterFailure?.status, ConstructionLivingPlanStatus.planned);
      expect(afterFailure?.revision, 1);
      expect(
        await application.listLivingPlanEventHistory(item.id),
        hasLength(1),
      );

      final failingCreate = _application(
        database: database,
        repository: snapshotRepository,
        scenario: scenario,
        clock: () => now,
        beforeEventInsert: () async =>
            throw StateError('injected create event failure'),
      );
      await expectLater(
        _create(
          failingCreate,
          scenario,
          activityId: 'ACT-E',
          itemNumber: 10,
          eventNumber: 110,
          plannedDate: '2026-09-12',
        ),
        throwsA(isA<StateError>()),
      );
      expect(await application.loadLivingPlanItem(_uuid(10)), isNull);
      expect(
        await database.database.query(
          'project_living_plan_events',
          where: 'id = ?',
          whereArgs: [_uuid(110)],
        ),
        isEmpty,
      );
    },
  );

  test(
    'seven-day plan includes overdue and exact in-window states only in stable order',
    () async {
      final a = await _create(
        application,
        scenario,
        activityId: 'ACT-A',
        itemNumber: 11,
        eventNumber: 111,
        plannedDate: '2026-09-01',
      );
      final b = await _create(
        application,
        scenario,
        activityId: 'ACT-B',
        itemNumber: 12,
        eventNumber: 112,
        plannedDate: '2026-09-04',
      );
      final c = await _create(
        application,
        scenario,
        activityId: 'ACT-C',
        itemNumber: 13,
        eventNumber: 113,
        plannedDate: '2026-09-04',
      );
      final d = await _create(
        application,
        scenario,
        activityId: 'ACT-D',
        itemNumber: 14,
        eventNumber: 114,
        plannedDate: '2026-09-07',
      );
      await _create(
        application,
        scenario,
        activityId: 'ACT-E',
        itemNumber: 15,
        eventNumber: 115,
        plannedDate: '2026-09-12',
      );
      final f = await _create(
        application,
        scenario,
        activityId: 'ACT-F',
        itemNumber: 16,
        eventNumber: 116,
        plannedDate: '2026-09-01',
      );
      now = DateTime.utc(2026, 8, 16, 9, 0, 1);
      await application.startLivingPlanItem(
        StartConstructionLivingPlanItemCommand(
          itemId: b.id,
          eventId: _uuid(221),
          expectedRevision: 1,
        ),
      );
      now = DateTime.utc(2026, 8, 16, 9, 0, 2);
      await application.deferLivingPlanItem(
        DeferConstructionLivingPlanItemCommand(
          itemId: c.id,
          eventId: _uuid(222),
          expectedRevision: 1,
          plannedDate: _date('2026-09-06'),
        ),
      );
      now = DateTime.utc(2026, 8, 16, 9, 0, 3);
      await application.completeLivingPlanItem(
        CompleteConstructionLivingPlanItemCommand(
          itemId: d.id,
          eventId: _uuid(223),
          expectedRevision: 1,
        ),
      );
      now = DateTime.utc(2026, 8, 16, 9, 0, 4);
      await application.completeLivingPlanItem(
        CompleteConstructionLivingPlanItemCommand(
          itemId: f.id,
          eventId: _uuid(224),
          expectedRevision: 1,
        ),
      );
      await _persist(
        _snapshotRepository(
          database,
          snapshotId: 'snapshot-b',
          generatedAt: DateTime.utc(2026, 8, 16, 10),
        ),
        scenario,
      );

      final plan = await application.loadSevenDayPlan(
        projectId: scenario.profile.projectId,
        windowStart: _date('2026-09-04'),
      );
      expect(
        plan.map((entry) => entry.item.id),
        orderedEquals([a.id, b.id, c.id, d.id]),
      );
      expect(plan.first.isOverdue, isTrue);
      expect(
        plan.skip(1).map((entry) => entry.isOverdue),
        everyElement(isFalse),
      );
      expect(
        plan.map((entry) => entry.item.status),
        orderedEquals([
          ConstructionLivingPlanStatus.planned,
          ConstructionLivingPlanStatus.started,
          ConstructionLivingPlanStatus.deferred,
          ConstructionLivingPlanStatus.completed,
        ]),
      );
      expect(
        plan.map((entry) => entry.originSnapshotIsCurrent),
        everyElement(isFalse),
      );
      expect(plan.map((entry) => entry.item.id), isNot(contains(_uuid(15))));
      expect(plan.map((entry) => entry.item.id), isNot(contains(f.id)));
    },
  );
}

ConstructionLivingPlanApplication _application({
  required AppDatabase database,
  required ConstructionScheduleSnapshotRepository repository,
  required _LivingScenario scenario,
  required DateTime Function() clock,
  ConstructionLivingPlanBeforeEventInsertHook? beforeEventInsert,
  ConstructionLivingPlanBeforeCreateTransactionHook? beforeCreateTransaction,
}) => ConstructionLivingPlanApplication(
  database: database,
  snapshotRepository: repository,
  clock: clock,
  graphLoader: (_) async => scenario.graph,
  corpusLoader: () async => scenario.corpus,
  beforeEventInsert: beforeEventInsert,
  beforeCreateTransaction: beforeCreateTransaction,
);

ConstructionScheduleSnapshotRepository _snapshotRepository(
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
  _LivingScenario scenario,
) => repository.persistCurrentSnapshot(
  schedule: scenario.schedule,
  profile: scenario.profile,
  graph: scenario.graph,
  seedCatalog: scenario.seedCatalog,
);

Future<ConstructionLivingPlanItem> _create(
  ConstructionLivingPlanApplication application,
  _LivingScenario scenario, {
  required String activityId,
  required int itemNumber,
  required int eventNumber,
  required String plannedDate,
  String snapshotId = 'snapshot-a',
  String? note,
}) => application.createLivingPlanItem(
  CreateConstructionLivingPlanItemCommand(
    itemId: _uuid(itemNumber),
    eventId: _uuid(eventNumber),
    projectId: scenario.profile.projectId,
    expectedReferenceSnapshotId: snapshotId,
    activityInstanceId: _instanceId(scenario, activityId),
    plannedDate: _date(plannedDate),
    note: note,
  ),
);

String _instanceId(_LivingScenario scenario, String activityId) => scenario
    .graph
    .activityInstances
    .singleWhere((instance) => instance.activityId == activityId)
    .instanceId;

String _uuid(int value) =>
    '00000000-0000-4000-8000-${value.toString().padLeft(12, '0')}';

DateTime _date(String value) => parseCanonicalConstructionDate(value);

Matcher _failure(String code) => throwsA(
  isA<ConstructionLivingPlanFailure>().having(
    (failure) => failure.code,
    'code',
    code,
  ),
);

List<String> _candidateOrder(
  Iterable<ConstructionLivingPlanReferenceCandidate> candidates,
) =>
    (candidates.toList()..sort((left, right) {
          final start = left.suggestedStartDate.compareTo(
            right.suggestedStartDate,
          );
          if (start != 0) {
            return start;
          }
          final finish = left.suggestedFinishDate.compareTo(
            right.suggestedFinishDate,
          );
          if (finish != 0) {
            return finish;
          }
          final sequence = left.activitySequence.compareTo(
            right.activitySequence,
          );
          if (sequence != 0) {
            return sequence;
          }
          return left.activityInstanceId.compareTo(right.activityInstanceId);
        }))
        .map((item) => item.activityInstanceId)
        .toList(growable: false);

_LivingScenario _livingScenario() {
  const corpusVersion = '0.3-yfk-resource-seed';
  final profile = validConstructionProjectProfile(
    overrides: {
      'project_id': 'PRJ-LIVING',
      'project_name': 'Yaşayan Plan Test Projesi',
      'calendar': <String, Object?>{
        'start_date': '2026-09-04',
        'working_weekdays': <Object?>[0, 1, 2, 3, 4, 5],
        'holidays': <Object?>['2026-09-07'],
        'workday_hours': 8,
      },
    },
  );
  final templates = <ConstructionActivity>[
    _activity(
      id: 'ACT-A',
      name: 'Temel Kalıbı',
      aliases: const ['radye kalıp', 'temel işi'],
      unit: 'm²',
      sequence: 1,
      repeat: ConstructionActivityRepeatDimension.project,
    ),
    _activity(
      id: 'ACT-B',
      name: 'Beton Dökümü',
      aliases: const ['betonaj', 'beton işi'],
      unit: 'm³',
      sequence: 2,
      repeat: ConstructionActivityRepeatDimension.block,
    ),
    _activity(
      id: 'ACT-C',
      name: 'Duvar İmalatı',
      aliases: const ['gazbeton', 'duvar işi'],
      unit: 'm²',
      sequence: 3,
      repeat: ConstructionActivityRepeatDimension.floor,
    ),
    _activity(
      id: 'ACT-D',
      name: 'Bodrum Kontrolü',
      aliases: const ['bodrum işi'],
      unit: 'adet',
      sequence: 4,
      repeat: ConstructionActivityRepeatDimension.basement,
    ),
    _activity(
      id: 'ACT-E',
      name: 'Bölge Temizliği',
      aliases: const ['zone işi'],
      unit: 'm²',
      sequence: 5,
      repeat: ConstructionActivityRepeatDimension.zone,
    ),
    _activity(
      id: 'ACT-F',
      name: 'Mekanik Sistem Kontrolü',
      aliases: const ['mekanik iş', 'havalandırma'],
      unit: 'sistem',
      sequence: 6,
      repeat: ConstructionActivityRepeatDimension.system,
    ),
  ];
  final corpus = ConstructionCorpus(
    metadata: const ConstructionCorpusMetadata(
      name: 'LIVING PLAN TEST CORPUS',
      corpusVersion: corpusVersion,
      sourcePublicationStatus: 'RESEARCH_RESOURCE_SEED',
      sourceProductionStatus: 'NOT_FOR_PRODUCTION',
      warning: 'test',
      runtimeScope: 'ACTIVITY_CATALOG_READ_ONLY_NO_YFK_RESOURCE_COEFFICIENTS',
      wbsCount: 1,
      activityCount: 6,
    ),
    profileFields: const <String>[],
    wbsPackages: const [
      ConstructionWbsPackage(
        wbsCode: 'TEST',
        packageId: 'TEST',
        packageNameTr: 'Test',
        packageNameEn: 'Test',
        frequencyClass: 'TEST',
      ),
    ],
    activities: templates,
  );
  final instances = <ConstructionProjectActivityInstance>[
    _instance(
      templates[0],
      const ConstructionProjectActivityContext(),
      'ACT-A@PROJECT',
    ),
    _instance(
      templates[1],
      const ConstructionProjectActivityContext(blockId: 'A'),
      'ACT-B@B-A',
    ),
    _instance(
      templates[2],
      const ConstructionProjectActivityContext(blockId: 'A', floorIndex: 2),
      'ACT-C@B-A/F-02',
    ),
    _instance(
      templates[3],
      const ConstructionProjectActivityContext(blockId: 'A', basementIndex: 1),
      'ACT-D@B-A/BS-01',
    ),
    _instance(
      templates[4],
      const ConstructionProjectActivityContext(blockId: 'A', zoneId: 'Z1'),
      'ACT-E@B-A/Z-Z1',
    ),
    _instance(
      templates[5],
      const ConstructionProjectActivityContext(systemId: 'HVAC'),
      'ACT-F@SYS-HVAC',
    ),
  ];
  final edges = <ConstructionResolvedDependencyEdge>[
    _edge(1, instances[0].instanceId, instances[1].instanceId),
    _edge(2, instances[1].instanceId, instances[2].instanceId),
  ];
  final graph = ConstructionProjectActivityGraph(
    projectId: profile.projectId,
    activityInstances: instances,
    dependencyEdges: edges,
    isolatedInstanceIds: [
      instances[3].instanceId,
      instances[4].instanceId,
      instances[5].instanceId,
    ],
    corpusVersion: corpusVersion,
    selectedActivityTemplateCount: instances.length,
    selectedDependencyTemplateCount: edges.length,
  );
  final seeds = <ConstructionScheduleSeed>[
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
    _seed(
      'ACT-E',
      1,
      status: ConstructionScheduleDurationStatus.unknown,
      confidence: ConstructionScheduleDurationConfidence.unknown,
    ),
    _seed(
      'ACT-F',
      1,
      status: ConstructionScheduleDurationStatus.unknown,
      confidence: ConstructionScheduleDurationConfidence.unknown,
    ),
  ];
  final seedCatalog = ConstructionScheduleSeedCatalog(
    metadata: const ConstructionScheduleSeedCatalogMetadata(
      name: 'LIVING PLAN TEST SEEDS',
      corpusVersion: corpusVersion,
      sourcePublicationStatus: 'RESEARCH_RESOURCE_SEED',
      sourceProductionStatus: 'NOT_FOR_PRODUCTION',
      sourceZipSha256: 'test',
      warning: 'test',
      runtimeScope: 'SCHEDULE_SEED_CATALOG_READ_ONLY_NOT_A_BASELINE',
      activityCount: 6,
      workingDayCount: 4,
      calendarDayCount: 2,
      milestoneCount: 1,
      authoritativeCount: 1,
      aiSeedCount: 1,
      unknownConfidenceCount: 4,
      sourceBackedCount: 1,
      aiSeedEstimateCount: 1,
      unknownStatusCount: 4,
    ),
    seeds: seeds,
  );
  final schedule = ConstructionScheduleDateEngine().build(
    profile: profile,
    graph: graph,
    seedCatalog: seedCatalog,
  );
  return _LivingScenario(
    profile: profile,
    corpus: corpus,
    graph: graph,
    seedCatalog: seedCatalog,
    schedule: schedule,
  );
}

ConstructionActivity _activity({
  required String id,
  required String name,
  required List<String> aliases,
  required String unit,
  required int sequence,
  required ConstructionActivityRepeatDimension repeat,
}) => ConstructionActivity(
  activityId: id,
  wbsCode: 'TEST',
  packageId: 'TEST',
  activityNameTr: name,
  aliasesTr: aliases,
  applicability: const ConstructionAlwaysRule(),
  repeatDimension: repeat,
  naturalUnit: unit,
  durationStatus: 'TEST',
  durationConfidence: 'TEST',
  testSeedDurationDays: 1,
  sequenceConfidence: 'TEST',
  sequenceIndex: sequence,
);

ConstructionProjectActivityInstance _instance(
  ConstructionActivity activity,
  ConstructionProjectActivityContext context,
  String instanceId,
) => ConstructionProjectActivityInstance(
  instanceId: instanceId,
  activityId: activity.activityId,
  wbsCode: activity.wbsCode,
  packageId: activity.packageId,
  activityNameTr: activity.activityNameTr,
  repeatDimension: activity.repeatDimension,
  context: context,
  naturalUnit: activity.naturalUnit,
  durationStatus: activity.durationStatus,
  durationConfidence: activity.durationConfidence,
  testSeedDurationDays: activity.testSeedDurationDays,
);

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

class _LivingScenario {
  const _LivingScenario({
    required this.profile,
    required this.corpus,
    required this.graph,
    required this.seedCatalog,
    required this.schedule,
  });

  final ConstructionProjectProfile profile;
  final ConstructionCorpus corpus;
  final ConstructionProjectActivityGraph graph;
  final ConstructionScheduleSeedCatalog seedCatalog;
  final ConstructionProjectReferenceSchedule schedule;
}
