import 'dart:convert';

import 'package:chief_site_engineer/application/construction_corpus_repository.dart';
import 'package:chief_site_engineer/application/construction_project_graph_builder.dart';
import 'package:chief_site_engineer/application/construction_schedule_date_engine.dart';
import 'package:chief_site_engineer/application/construction_schedule_snapshot_repository.dart';
import 'package:chief_site_engineer/core/record_id.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/construction_corpus_models.dart';
import 'package:chief_site_engineer/domain/construction_living_plan_models.dart';
import 'package:chief_site_engineer/domain/construction_project_graph_models.dart';
import 'package:chief_site_engineer/domain/construction_schedule_models.dart';
import 'package:chief_site_engineer/storage/app_database.dart';
import 'package:sqflite/sqflite.dart';

typedef ConstructionLivingPlanGraphLoader =
    Future<ConstructionProjectActivityGraph> Function(
      ConstructionProjectProfile profile,
    );
typedef ConstructionLivingPlanCorpusLoader =
    Future<ConstructionCorpus> Function();
typedef ConstructionLivingPlanBeforeEventInsertHook = Future<void> Function();
typedef ConstructionLivingPlanBeforeCreateTransactionHook =
    Future<void> Function();

class ConstructionLivingPlanApplication {
  ConstructionLivingPlanApplication({
    required this.database,
    required this.snapshotRepository,
    required this.clock,
    ConstructionProjectActivityGraphBuilder? graphBuilder,
    ConstructionCorpusRepository? corpusRepository,
    ConstructionLivingPlanGraphLoader? graphLoader,
    ConstructionLivingPlanCorpusLoader? corpusLoader,
    this.beforeEventInsert,
    this.beforeCreateTransaction,
  }) : _graphLoader =
           graphLoader ??
           (graphBuilder ?? ConstructionProjectActivityGraphBuilder()).build,
       _corpusLoader =
           corpusLoader ??
           (corpusRepository ?? BundledConstructionCorpusRepository()).load;

  static const defaultSearchLimit = 50;
  static const maximumSearchLimit = 200;

  final AppDatabase database;
  final ConstructionScheduleSnapshotRepository snapshotRepository;
  final UtcClock clock;
  final ConstructionLivingPlanGraphLoader _graphLoader;
  final ConstructionLivingPlanCorpusLoader _corpusLoader;
  final ConstructionLivingPlanBeforeEventInsertHook? beforeEventInsert;
  final ConstructionLivingPlanBeforeCreateTransactionHook?
  beforeCreateTransaction;

  Future<List<ConstructionLivingPlanReferenceCandidate>>
  loadSevenDayReferenceSuggestions({
    required String projectId,
    required DateTime windowStart,
  }) async {
    _requireIdentity(projectId, 'living_plan_invalid_project_id');
    final start = _canonicalDate(windowStart);
    final end = _canonicalDate(windowStart.add(const Duration(days: 6)));
    try {
      final window = await snapshotRepository.loadCurrentActivityWindow(
        projectId: projectId,
        windowStart: parseCanonicalConstructionDate(start),
        windowEnd: parseCanonicalConstructionDate(end),
      );
      if (window == null) {
        throw const ConstructionLivingPlanFailure(
          'living_plan_reference_snapshot_missing',
        );
      }
      final candidates = await _enrichReferenceActivities(
        metadata: window.metadata,
        profile: window.profile,
        activities: window.activities,
        requireFullGraphMatch: false,
      );
      final result = candidates.toList()..sort(_compareSuggestionCandidates);
      return List.unmodifiable(result.map((item) => item.candidate));
    } on ConstructionLivingPlanFailure {
      rethrow;
    } on Object {
      throw const ConstructionLivingPlanFailure(
        'living_plan_reference_integrity_failed',
      );
    }
  }

  Future<List<ConstructionLivingPlanReferenceCandidate>>
  searchCurrentReferenceCandidates({
    required String projectId,
    required String query,
    int limit = defaultSearchLimit,
  }) async {
    _requireIdentity(projectId, 'living_plan_invalid_project_id');
    if (normalizeConstructionSearch(query).isEmpty) {
      throw const ConstructionLivingPlanFailure(
        'living_plan_empty_reference_query',
      );
    }
    if (limit < 1 || limit > maximumSearchLimit) {
      throw const ConstructionLivingPlanFailure(
        'living_plan_invalid_reference_limit',
      );
    }
    try {
      final snapshot = await snapshotRepository.loadCurrentSnapshot(projectId);
      if (snapshot == null) {
        throw const ConstructionLivingPlanFailure(
          'living_plan_reference_snapshot_missing',
        );
      }
      final candidates = await _enrichReferenceActivities(
        metadata: snapshot.metadata,
        profile: snapshot.profile,
        activities: snapshot.activities,
        requireFullGraphMatch: true,
      );
      final matching =
          candidates
              .where((candidate) => candidate.template.matchesSearch(query))
              .map((candidate) => candidate.candidate)
              .toList()
            ..sort(_compareSearchCandidates);
      return List.unmodifiable(matching.take(limit));
    } on ConstructionLivingPlanFailure {
      rethrow;
    } on Object {
      throw const ConstructionLivingPlanFailure(
        'living_plan_reference_integrity_failed',
      );
    }
  }

  Future<ConstructionLivingPlanItem> createLivingPlanItem(
    CreateConstructionLivingPlanItemCommand command,
  ) async {
    _requireUuid(command.itemId, 'living_plan_invalid_item_id');
    _requireUuid(command.eventId, 'living_plan_invalid_event_id');
    _requireIdentity(command.projectId, 'living_plan_invalid_project_id');
    _requireIdentity(
      command.expectedReferenceSnapshotId,
      'living_plan_invalid_reference_snapshot_id',
    );
    _requireIdentity(
      command.activityInstanceId,
      'living_plan_invalid_activity_instance_id',
    );
    final plannedDate = _canonicalDate(command.plannedDate);
    final note = _validatedNote(command.note);
    final intent = <String, Object?>{
      'activity_instance_id': command.activityInstanceId,
      'expected_reference_snapshot_id': command.expectedReferenceSnapshotId,
      'note': note,
      'operation': ConstructionLivingPlanEventType.created.storageValue,
      'planned_date': plannedDate,
      'project_id': command.projectId,
    };

    final initialReplay = await database.database.transaction(
      (transaction) => _tryReplay(
        transaction,
        eventId: command.eventId,
        itemId: command.itemId,
        eventType: ConstructionLivingPlanEventType.created,
        expectedIntent: intent,
      ),
    );
    if (initialReplay != null) {
      return initialReplay;
    }

    final candidate = await _resolveCurrentCandidate(
      projectId: command.projectId,
      expectedSnapshotId: command.expectedReferenceSnapshotId,
      activityInstanceId: command.activityInstanceId,
    );
    await beforeCreateTransaction?.call();

    return database.database.transaction((transaction) async {
      final replay = await _tryReplay(
        transaction,
        eventId: command.eventId,
        itemId: command.itemId,
        eventType: ConstructionLivingPlanEventType.created,
        expectedIntent: intent,
      );
      if (replay != null) {
        return replay;
      }
      await _reconfirmCurrentReference(transaction, candidate.candidate);
      final duplicates = await transaction.query(
        'project_living_plan_items',
        columns: const ['id'],
        where: 'project_id = ? AND activity_instance_id = ?',
        whereArgs: [command.projectId, command.activityInstanceId],
        limit: 2,
      );
      if (duplicates.isNotEmpty) {
        throw const ConstructionLivingPlanFailure(
          'living_plan_item_already_exists',
        );
      }
      final byId = await transaction.query(
        'project_living_plan_items',
        columns: const ['id'],
        where: 'id = ?',
        whereArgs: [command.itemId],
        limit: 1,
      );
      if (byId.isNotEmpty) {
        throw const ConstructionLivingPlanFailure(
          'living_plan_item_id_conflict',
        );
      }

      final occurredAt = _canonicalNow();
      final timestamp = CseTimeCodec.encodeUtc(occurredAt);
      await transaction.insert('project_living_plan_items', {
        'id': command.itemId,
        'project_id': command.projectId,
        'reference_snapshot_id': candidate.candidate.referenceSnapshotId,
        'activity_instance_id': candidate.candidate.activityInstanceId,
        'activity_id': candidate.candidate.activityId,
        'activity_name_snapshot': candidate.candidate.activityName,
        'activity_context_json': encodeConstructionLivingPlanContext(
          candidate.candidate.activityContext,
        ),
        'natural_unit_snapshot': candidate.candidate.naturalUnit,
        'planned_date': plannedDate,
        'status': ConstructionLivingPlanStatus.planned.storageValue,
        'note': note,
        'revision': 1,
        'created_at': timestamp,
        'updated_at': timestamp,
        'status_changed_at': timestamp,
      });
      final inserted = ConstructionLivingPlanItem(
        id: command.itemId,
        projectId: command.projectId,
        referenceSnapshotId: candidate.candidate.referenceSnapshotId,
        activityInstanceId: candidate.candidate.activityInstanceId,
        activityId: candidate.candidate.activityId,
        activityNameSnapshot: candidate.candidate.activityName,
        activityContext: candidate.candidate.activityContext,
        naturalUnitSnapshot: candidate.candidate.naturalUnit,
        plannedDate: parseCanonicalConstructionDate(plannedDate),
        status: ConstructionLivingPlanStatus.planned,
        note: note,
        revision: 1,
        createdAt: occurredAt,
        updatedAt: occurredAt,
        statusChangedAt: occurredAt,
      );
      final payload = _eventPayload(
        intent: intent,
        change: <String, Object?>{
          'reference_snapshot_id': candidate.candidate.referenceSnapshotId,
          'status': ConstructionLivingPlanStatus.planned.storageValue,
        },
        result: inserted,
      );
      await beforeEventInsert?.call();
      await _insertEvent(
        transaction,
        eventId: command.eventId,
        item: inserted,
        eventType: ConstructionLivingPlanEventType.created,
        occurredAt: timestamp,
        payload: payload,
      );
      final stored = await _loadItem(transaction, command.itemId);
      if (stored == null || !_sameItemState(stored, inserted)) {
        throw const ConstructionLivingPlanFailure(
          'living_plan_write_verification_failed',
        );
      }
      return stored;
    });
  }

  Future<ConstructionLivingPlanItem> startLivingPlanItem(
    StartConstructionLivingPlanItemCommand command,
  ) {
    final intent = _revisionIntent(
      ConstructionLivingPlanEventType.started,
      command.expectedRevision,
    );
    return _mutate(
      itemId: command.itemId,
      eventId: command.eventId,
      expectedRevision: command.expectedRevision,
      eventType: ConstructionLivingPlanEventType.started,
      intent: intent,
      decide: (item) {
        if (item.status == ConstructionLivingPlanStatus.started) {
          return _MutationDecision.noOp(item);
        }
        if (item.status != ConstructionLivingPlanStatus.planned &&
            item.status != ConstructionLivingPlanStatus.deferred) {
          throw const ConstructionLivingPlanFailure(
            'living_plan_invalid_transition',
          );
        }
        return _MutationDecision(
          status: ConstructionLivingPlanStatus.started,
          plannedDate: item.plannedDate,
          note: item.note,
          change: {
            'previous_status': item.status.storageValue,
            'status': ConstructionLivingPlanStatus.started.storageValue,
          },
        );
      },
    );
  }

  Future<ConstructionLivingPlanItem> completeLivingPlanItem(
    CompleteConstructionLivingPlanItemCommand command,
  ) {
    final intent = _revisionIntent(
      ConstructionLivingPlanEventType.completed,
      command.expectedRevision,
    );
    return _mutate(
      itemId: command.itemId,
      eventId: command.eventId,
      expectedRevision: command.expectedRevision,
      eventType: ConstructionLivingPlanEventType.completed,
      intent: intent,
      decide: (item) {
        if (item.status == ConstructionLivingPlanStatus.completed) {
          return _MutationDecision.noOp(item);
        }
        if (item.status != ConstructionLivingPlanStatus.planned &&
            item.status != ConstructionLivingPlanStatus.started &&
            item.status != ConstructionLivingPlanStatus.deferred) {
          throw const ConstructionLivingPlanFailure(
            'living_plan_invalid_transition',
          );
        }
        return _MutationDecision(
          status: ConstructionLivingPlanStatus.completed,
          plannedDate: item.plannedDate,
          note: item.note,
          change: {
            'previous_status': item.status.storageValue,
            'status': ConstructionLivingPlanStatus.completed.storageValue,
          },
        );
      },
    );
  }

  Future<ConstructionLivingPlanItem> deferLivingPlanItem(
    DeferConstructionLivingPlanItemCommand command,
  ) {
    final plannedDate = _canonicalDate(command.plannedDate);
    final intent = <String, Object?>{
      ..._revisionIntent(
        ConstructionLivingPlanEventType.deferred,
        command.expectedRevision,
      ),
      'new_planned_date': plannedDate,
    };
    return _mutate(
      itemId: command.itemId,
      eventId: command.eventId,
      expectedRevision: command.expectedRevision,
      eventType: ConstructionLivingPlanEventType.deferred,
      intent: intent,
      decide: (item) {
        final oldDate = formatCanonicalConstructionDate(item.plannedDate);
        if (item.status == ConstructionLivingPlanStatus.deferred &&
            plannedDate == oldDate) {
          return _MutationDecision.noOp(item);
        }
        if (item.status == ConstructionLivingPlanStatus.completed ||
            plannedDate.compareTo(oldDate) <= 0) {
          throw const ConstructionLivingPlanFailure(
            'living_plan_invalid_transition',
          );
        }
        return _MutationDecision(
          status: ConstructionLivingPlanStatus.deferred,
          plannedDate: parseCanonicalConstructionDate(plannedDate),
          note: item.note,
          change: {
            'new_planned_date': plannedDate,
            'old_planned_date': oldDate,
            'previous_status': item.status.storageValue,
            'status': ConstructionLivingPlanStatus.deferred.storageValue,
          },
        );
      },
    );
  }

  Future<ConstructionLivingPlanItem> reopenLivingPlanItem(
    ReopenConstructionLivingPlanItemCommand command,
  ) {
    final plannedDate = _canonicalDate(command.plannedDate);
    final intent = <String, Object?>{
      ..._revisionIntent(
        ConstructionLivingPlanEventType.reopened,
        command.expectedRevision,
      ),
      'new_planned_date': plannedDate,
    };
    return _mutate(
      itemId: command.itemId,
      eventId: command.eventId,
      expectedRevision: command.expectedRevision,
      eventType: ConstructionLivingPlanEventType.reopened,
      intent: intent,
      decide: (item) {
        final oldDate = formatCanonicalConstructionDate(item.plannedDate);
        if (item.status == ConstructionLivingPlanStatus.planned &&
            plannedDate == oldDate) {
          return _MutationDecision.noOp(item);
        }
        if (item.status != ConstructionLivingPlanStatus.completed) {
          throw const ConstructionLivingPlanFailure(
            'living_plan_invalid_transition',
          );
        }
        return _MutationDecision(
          status: ConstructionLivingPlanStatus.planned,
          plannedDate: parseCanonicalConstructionDate(plannedDate),
          note: item.note,
          change: {
            'new_planned_date': plannedDate,
            'previous_status': item.status.storageValue,
            'status': ConstructionLivingPlanStatus.planned.storageValue,
          },
        );
      },
    );
  }

  Future<ConstructionLivingPlanItem> updateLivingPlanNote(
    UpdateConstructionLivingPlanNoteCommand command,
  ) {
    final note = _validatedNote(command.note);
    final intent = <String, Object?>{
      ..._revisionIntent(
        ConstructionLivingPlanEventType.noteUpdated,
        command.expectedRevision,
      ),
      'note': note,
    };
    return _mutate(
      itemId: command.itemId,
      eventId: command.eventId,
      expectedRevision: command.expectedRevision,
      eventType: ConstructionLivingPlanEventType.noteUpdated,
      intent: intent,
      decide: (item) {
        if (item.note == note) {
          return _MutationDecision.noOp(item);
        }
        return _MutationDecision(
          status: item.status,
          plannedDate: item.plannedDate,
          note: note,
          change: {'new_note': note, 'old_note': item.note},
        );
      },
    );
  }

  Future<List<ConstructionLivingPlanWindowItem>> loadSevenDayPlan({
    required String projectId,
    required DateTime windowStart,
  }) async {
    _requireIdentity(projectId, 'living_plan_invalid_project_id');
    final start = _canonicalDate(windowStart);
    final finish = _canonicalDate(windowStart.add(const Duration(days: 6)));
    final rows = await database.database.rawQuery(
      '''
      SELECT item.*, snapshot.superseded_at AS origin_superseded_at
      FROM project_living_plan_items item
      JOIN project_schedule_snapshots snapshot
        ON snapshot.id = item.reference_snapshot_id
       AND snapshot.project_id = item.project_id
      WHERE item.project_id = ?
        AND (
          (item.status != 'COMPLETED' AND item.planned_date <= ?)
          OR (
            item.status = 'COMPLETED'
            AND item.planned_date >= ?
            AND item.planned_date <= ?
          )
        )
      ''',
      [projectId, finish, start, finish],
    );
    final result = <ConstructionLivingPlanWindowItem>[];
    for (final row in rows) {
      final item = await _itemFromRowAndVerify(database.database, row);
      final itemDate = formatCanonicalConstructionDate(item.plannedDate);
      result.add(
        ConstructionLivingPlanWindowItem(
          item: item,
          isOverdue:
              item.status != ConstructionLivingPlanStatus.completed &&
              itemDate.compareTo(start) < 0,
          originSnapshotIsCurrent: row['origin_superseded_at'] == null,
        ),
      );
    }
    result.sort(_compareWindowItems);
    return List.unmodifiable(result);
  }

  Future<ConstructionLivingPlanItem?> loadLivingPlanItem(String itemId) async {
    _requireUuid(itemId, 'living_plan_invalid_item_id');
    return _loadItem(database.database, itemId);
  }

  Future<List<ConstructionLivingPlanEvent>> listLivingPlanEventHistory(
    String itemId,
  ) async {
    _requireUuid(itemId, 'living_plan_invalid_item_id');
    final item = await _loadItem(database.database, itemId);
    if (item == null) {
      return const <ConstructionLivingPlanEvent>[];
    }
    final rows = await database.database.query(
      'project_living_plan_events',
      where: 'living_plan_item_id = ?',
      whereArgs: [itemId],
      orderBy: 'sequence ASC',
    );
    final events = rows.map(_eventFromRow).toList(growable: false);
    if (events.length != item.revision) {
      throw const ConstructionLivingPlanFailure(
        'living_plan_history_integrity_failed',
      );
    }
    for (var index = 0; index < events.length; index += 1) {
      if (events[index].sequence != index + 1 ||
          events[index].projectId != item.projectId) {
        throw const ConstructionLivingPlanFailure(
          'living_plan_history_integrity_failed',
        );
      }
    }
    return List.unmodifiable(events);
  }

  Future<ConstructionLivingPlanItem> _mutate({
    required String itemId,
    required String eventId,
    required int expectedRevision,
    required ConstructionLivingPlanEventType eventType,
    required Map<String, Object?> intent,
    required _MutationDecision Function(ConstructionLivingPlanItem item) decide,
  }) async {
    _requireUuid(itemId, 'living_plan_invalid_item_id');
    _requireUuid(eventId, 'living_plan_invalid_event_id');
    if (expectedRevision < 1) {
      throw const ConstructionLivingPlanFailure('living_plan_invalid_revision');
    }
    return database.database.transaction((transaction) async {
      final replay = await _tryReplay(
        transaction,
        eventId: eventId,
        itemId: itemId,
        eventType: eventType,
        expectedIntent: intent,
      );
      if (replay != null) {
        return replay;
      }
      final current = await _loadItem(transaction, itemId);
      if (current == null) {
        throw const ConstructionLivingPlanFailure('living_plan_item_not_found');
      }
      if (current.revision != expectedRevision) {
        throw const ConstructionLivingPlanFailure('living_plan_stale_revision');
      }
      final decision = decide(current);
      if (decision.isNoOp) {
        return current;
      }
      final occurred = _canonicalNow();
      if (occurred.isBefore(current.updatedAt)) {
        throw const ConstructionLivingPlanFailure(
          'living_plan_clock_regression',
        );
      }
      final occurredAt = CseTimeCodec.encodeUtc(occurred);
      final statusChanged = decision.status == current.status
          ? current.statusChangedAt
          : occurred;
      final resulting = ConstructionLivingPlanItem(
        id: current.id,
        projectId: current.projectId,
        referenceSnapshotId: current.referenceSnapshotId,
        activityInstanceId: current.activityInstanceId,
        activityId: current.activityId,
        activityNameSnapshot: current.activityNameSnapshot,
        activityContext: current.activityContext,
        naturalUnitSnapshot: current.naturalUnitSnapshot,
        plannedDate: decision.plannedDate,
        status: decision.status,
        note: decision.note,
        revision: current.revision + 1,
        createdAt: current.createdAt,
        updatedAt: occurred,
        statusChangedAt: statusChanged,
      );
      final updated = await transaction.update(
        'project_living_plan_items',
        {
          'planned_date': formatCanonicalConstructionDate(
            resulting.plannedDate,
          ),
          'status': resulting.status.storageValue,
          'note': resulting.note,
          'revision': resulting.revision,
          'updated_at': occurredAt,
          'status_changed_at': CseTimeCodec.encodeUtc(statusChanged),
        },
        where: 'id = ? AND revision = ?',
        whereArgs: [itemId, expectedRevision],
      );
      if (updated != 1) {
        throw const ConstructionLivingPlanFailure('living_plan_stale_revision');
      }
      final payload = _eventPayload(
        intent: intent,
        change: decision.change,
        result: resulting,
      );
      await beforeEventInsert?.call();
      await _insertEvent(
        transaction,
        eventId: eventId,
        item: resulting,
        eventType: eventType,
        occurredAt: occurredAt,
        payload: payload,
      );
      final stored = await _loadItem(transaction, itemId);
      if (stored == null || !_sameItemState(stored, resulting)) {
        throw const ConstructionLivingPlanFailure(
          'living_plan_write_verification_failed',
        );
      }
      return stored;
    });
  }

  Future<_EnrichedCandidate> _resolveCurrentCandidate({
    required String projectId,
    required String expectedSnapshotId,
    required String activityInstanceId,
  }) async {
    try {
      final snapshot = await snapshotRepository.loadCurrentSnapshot(projectId);
      if (snapshot == null ||
          snapshot.metadata.snapshotId != expectedSnapshotId) {
        throw const ConstructionLivingPlanFailure(
          'living_plan_reference_snapshot_stale',
        );
      }
      final candidates = await _enrichReferenceActivities(
        metadata: snapshot.metadata,
        profile: snapshot.profile,
        activities: snapshot.activities,
        requireFullGraphMatch: true,
      );
      final matching = candidates
          .where(
            (candidate) =>
                candidate.candidate.activityInstanceId == activityInstanceId,
          )
          .toList(growable: false);
      if (matching.length != 1) {
        throw const ConstructionLivingPlanFailure(
          'living_plan_reference_activity_missing',
        );
      }
      return matching.single;
    } on ConstructionLivingPlanFailure {
      rethrow;
    } on Object {
      throw const ConstructionLivingPlanFailure(
        'living_plan_reference_integrity_failed',
      );
    }
  }

  Future<List<_EnrichedCandidate>> _enrichReferenceActivities({
    required ConstructionScheduleSnapshotMetadata metadata,
    required ConstructionProjectProfile profile,
    required Iterable<ConstructionScheduledActivity> activities,
    required bool requireFullGraphMatch,
  }) async {
    if (metadata.projectId != profile.projectId || !metadata.isCurrent) {
      throw const ConstructionLivingPlanFailure(
        'living_plan_reference_integrity_failed',
      );
    }
    final graph = await _graphLoader(profile);
    final corpus = await _corpusLoader();
    if (graph.projectId != metadata.projectId ||
        graph.corpusVersion != metadata.corpusVersion ||
        corpus.metadata.corpusVersion != metadata.corpusVersion) {
      throw const ConstructionLivingPlanFailure(
        'living_plan_reference_integrity_failed',
      );
    }
    final graphByInstance = <String, ConstructionProjectActivityInstance>{};
    for (final instance in graph.activityInstances) {
      if (graphByInstance.containsKey(instance.instanceId)) {
        throw const ConstructionLivingPlanFailure(
          'living_plan_reference_integrity_failed',
        );
      }
      graphByInstance[instance.instanceId] = instance;
    }
    final templatesById = <String, ConstructionActivity>{};
    for (final template in corpus.activities) {
      if (templatesById.containsKey(template.activityId)) {
        throw const ConstructionLivingPlanFailure(
          'living_plan_reference_integrity_failed',
        );
      }
      templatesById[template.activityId] = template;
    }
    final schedule = activities.toList(growable: false);
    final scheduleIds = <String>{};
    for (final activity in schedule) {
      if (!scheduleIds.add(activity.instanceId)) {
        throw const ConstructionLivingPlanFailure(
          'living_plan_reference_integrity_failed',
        );
      }
    }
    if (requireFullGraphMatch &&
        (scheduleIds.length != graphByInstance.length ||
            !scheduleIds.containsAll(graphByInstance.keys))) {
      throw const ConstructionLivingPlanFailure(
        'living_plan_reference_integrity_failed',
      );
    }
    final markers = await _loadExistingMarkers(metadata.projectId, scheduleIds);
    final result = <_EnrichedCandidate>[];
    for (final activity in schedule) {
      final instance = graphByInstance[activity.instanceId];
      final template = templatesById[activity.activityId];
      if (instance == null ||
          template == null ||
          instance.activityId != activity.activityId ||
          instance.activityNameTr != template.activityNameTr ||
          instance.naturalUnit != template.naturalUnit) {
        throw const ConstructionLivingPlanFailure(
          'living_plan_reference_integrity_failed',
        );
      }
      final marker = markers[activity.instanceId];
      result.add(
        _EnrichedCandidate(
          template: template,
          candidate: ConstructionLivingPlanReferenceCandidate(
            referenceSnapshotId: metadata.snapshotId,
            projectId: metadata.projectId,
            activityInstanceId: activity.instanceId,
            activityId: activity.activityId,
            activityName: instance.activityNameTr,
            activityContext: instance.context,
            naturalUnit: instance.naturalUnit,
            suggestedStartDate: activity.startDate,
            suggestedFinishDate: activity.finishDate,
            durationStatus: activity.durationStatus,
            durationConfidence: activity.durationConfidence,
            activitySequence: template.sequenceIndex,
            existingLivingPlanItemId: marker?.itemId,
            existingLivingPlanStatus: marker?.status,
          ),
        ),
      );
    }
    return List.unmodifiable(result);
  }

  Future<Map<String, _ExistingMarker>> _loadExistingMarkers(
    String projectId,
    Set<String> instanceIds,
  ) async {
    if (instanceIds.isEmpty) {
      return const <String, _ExistingMarker>{};
    }
    final rows = await database.database.query(
      'project_living_plan_items',
      columns: const ['id', 'activity_instance_id', 'status'],
      where: 'project_id = ?',
      whereArgs: [projectId],
    );
    final result = <String, _ExistingMarker>{};
    for (final row in rows) {
      final instanceId = _requiredStoredString(row, 'activity_instance_id');
      if (!instanceIds.contains(instanceId)) {
        continue;
      }
      final marker = _ExistingMarker(
        itemId: _requiredStoredString(row, 'id'),
        status: ConstructionLivingPlanStatus.fromStorage(row['status']),
      );
      if (result.containsKey(instanceId)) {
        throw const ConstructionLivingPlanFailure(
          'living_plan_reference_integrity_failed',
        );
      }
      result[instanceId] = marker;
    }
    return Map.unmodifiable(result);
  }

  Future<void> _reconfirmCurrentReference(
    Transaction transaction,
    ConstructionLivingPlanReferenceCandidate candidate,
  ) async {
    final current = await transaction.query(
      'project_schedule_snapshots',
      columns: const ['id'],
      where: 'project_id = ? AND superseded_at IS NULL',
      whereArgs: [candidate.projectId],
      limit: 2,
    );
    if (current.length != 1 ||
        current.single['id'] != candidate.referenceSnapshotId) {
      throw const ConstructionLivingPlanFailure(
        'living_plan_reference_snapshot_stale',
      );
    }
    final activity = await transaction.query(
      'project_schedule_snapshot_activities',
      columns: const [
        'snapshot_id',
        'project_id',
        'instance_id',
        'activity_id',
      ],
      where: '''
        snapshot_id = ? AND project_id = ?
        AND instance_id = ? AND activity_id = ?
      ''',
      whereArgs: [
        candidate.referenceSnapshotId,
        candidate.projectId,
        candidate.activityInstanceId,
        candidate.activityId,
      ],
      limit: 2,
    );
    if (activity.length != 1) {
      throw const ConstructionLivingPlanFailure(
        'living_plan_reference_integrity_failed',
      );
    }
  }

  Future<ConstructionLivingPlanItem?> _tryReplay(
    DatabaseExecutor executor, {
    required String eventId,
    required String itemId,
    required ConstructionLivingPlanEventType eventType,
    required Map<String, Object?> expectedIntent,
  }) async {
    final rows = await executor.query(
      'project_living_plan_events',
      where: 'id = ?',
      whereArgs: [eventId],
      limit: 2,
    );
    if (rows.isEmpty) {
      return null;
    }
    if (rows.length != 1) {
      throw const ConstructionLivingPlanFailure(
        'living_plan_history_integrity_failed',
      );
    }
    final event = _eventFromRow(rows.single);
    final storedIntent = event.payload['intent'];
    if (event.livingPlanItemId != itemId ||
        event.eventType != eventType ||
        storedIntent is! Map ||
        encodeConstructionLivingPlanJson(storedIntent) !=
            encodeConstructionLivingPlanJson(expectedIntent)) {
      throw const ConstructionLivingPlanFailure(
        'living_plan_event_id_conflict',
      );
    }
    final current = await _loadItem(executor, itemId);
    if (current == null || current.projectId != event.projectId) {
      throw const ConstructionLivingPlanFailure(
        'living_plan_history_integrity_failed',
      );
    }
    return _itemAtEventResult(current, event);
  }

  Future<ConstructionLivingPlanItem?> _loadItem(
    DatabaseExecutor executor,
    String itemId,
  ) async {
    final rows = await executor.query(
      'project_living_plan_items',
      where: 'id = ?',
      whereArgs: [itemId],
      limit: 2,
    );
    if (rows.isEmpty) {
      return null;
    }
    if (rows.length != 1) {
      throw const ConstructionLivingPlanFailure(
        'living_plan_projection_integrity_failed',
      );
    }
    return _itemFromRowAndVerify(executor, rows.single);
  }

  Future<ConstructionLivingPlanItem> _itemFromRowAndVerify(
    DatabaseExecutor executor,
    Map<String, Object?> row,
  ) async {
    final item = _itemFromRow(row);
    final history = await executor.rawQuery(
      '''
      SELECT count(*) AS event_count, min(sequence) AS first_sequence,
             max(sequence) AS last_sequence
      FROM project_living_plan_events
      WHERE living_plan_item_id = ? AND project_id = ?
      ''',
      [item.id, item.projectId],
    );
    final summary = history.single;
    if (summary['event_count'] != item.revision ||
        summary['first_sequence'] != 1 ||
        summary['last_sequence'] != item.revision) {
      throw const ConstructionLivingPlanFailure(
        'living_plan_history_integrity_failed',
      );
    }
    return item;
  }

  Future<void> _insertEvent(
    DatabaseExecutor executor, {
    required String eventId,
    required ConstructionLivingPlanItem item,
    required ConstructionLivingPlanEventType eventType,
    required String occurredAt,
    required Map<String, Object?> payload,
  }) async {
    await executor.insert('project_living_plan_events', {
      'id': eventId,
      'living_plan_item_id': item.id,
      'project_id': item.projectId,
      'sequence': item.revision,
      'event_type': eventType.storageValue,
      'occurred_at': occurredAt,
      'payload_json': encodeConstructionLivingPlanJson(payload),
    });
  }

  DateTime _canonicalNow() {
    try {
      return CseTimeCodec.decodeCanonicalUtc(CseTimeCodec.encodeUtc(clock()));
    } on Object {
      throw const ConstructionLivingPlanFailure('living_plan_invalid_clock');
    }
  }
}

class _EnrichedCandidate {
  const _EnrichedCandidate({required this.candidate, required this.template});

  final ConstructionLivingPlanReferenceCandidate candidate;
  final ConstructionActivity template;
}

class _ExistingMarker {
  const _ExistingMarker({required this.itemId, required this.status});

  final String itemId;
  final ConstructionLivingPlanStatus status;
}

class _MutationDecision {
  const _MutationDecision({
    required this.status,
    required this.plannedDate,
    required this.note,
    required this.change,
  }) : isNoOp = false;

  _MutationDecision.noOp(ConstructionLivingPlanItem item)
    : status = item.status,
      plannedDate = item.plannedDate,
      note = item.note,
      change = const <String, Object?>{},
      isNoOp = true;

  final ConstructionLivingPlanStatus status;
  final DateTime plannedDate;
  final String? note;
  final Map<String, Object?> change;
  final bool isNoOp;
}

Map<String, Object?> _revisionIntent(
  ConstructionLivingPlanEventType type,
  int expectedRevision,
) => <String, Object?>{
  'expected_revision': expectedRevision,
  'operation': type.storageValue,
};

Map<String, Object?> _eventPayload({
  required Map<String, Object?> intent,
  required Map<String, Object?> change,
  required ConstructionLivingPlanItem result,
}) => <String, Object?>{
  'change': change,
  'intent': intent,
  'result': <String, Object?>{
    'note': result.note,
    'planned_date': formatCanonicalConstructionDate(result.plannedDate),
    'revision': result.revision,
    'status': result.status.storageValue,
    'status_changed_at': CseTimeCodec.encodeUtc(result.statusChangedAt),
    'updated_at': CseTimeCodec.encodeUtc(result.updatedAt),
  },
};

ConstructionLivingPlanItem _itemAtEventResult(
  ConstructionLivingPlanItem current,
  ConstructionLivingPlanEvent event,
) {
  final rawResult = event.payload['result'];
  if (rawResult is! Map) {
    throw const ConstructionLivingPlanFailure(
      'living_plan_history_integrity_failed',
    );
  }
  final result = rawResult.cast<String, Object?>();
  final revision = result['revision'];
  final note = result['note'];
  if (revision != event.sequence ||
      (note != null && note is! String) ||
      result['updated_at'] != CseTimeCodec.encodeUtc(event.occurredAt)) {
    throw const ConstructionLivingPlanFailure(
      'living_plan_history_integrity_failed',
    );
  }
  try {
    return ConstructionLivingPlanItem(
      id: current.id,
      projectId: current.projectId,
      referenceSnapshotId: current.referenceSnapshotId,
      activityInstanceId: current.activityInstanceId,
      activityId: current.activityId,
      activityNameSnapshot: current.activityNameSnapshot,
      activityContext: current.activityContext,
      naturalUnitSnapshot: current.naturalUnitSnapshot,
      plannedDate: parseCanonicalConstructionDate(
        _requiredStoredString(result, 'planned_date'),
      ),
      status: ConstructionLivingPlanStatus.fromStorage(result['status']),
      note: note as String?,
      revision: revision as int,
      createdAt: current.createdAt,
      updatedAt: CseTimeCodec.decodeCanonicalUtc(
        _requiredStoredString(result, 'updated_at'),
      ),
      statusChangedAt: CseTimeCodec.decodeCanonicalUtc(
        _requiredStoredString(result, 'status_changed_at'),
      ),
    );
  } on ConstructionLivingPlanFailure {
    rethrow;
  } on Object {
    throw const ConstructionLivingPlanFailure(
      'living_plan_history_integrity_failed',
    );
  }
}

ConstructionLivingPlanItem _itemFromRow(Map<String, Object?> row) {
  try {
    final note = row['note'];
    if (note != null && note is! String) {
      throw const FormatException();
    }
    final parsedNote = _validatedNote(note as String?);
    final revision = row['revision'];
    if (revision is! int || revision < 1) {
      throw const FormatException();
    }
    final createdAt = CseTimeCodec.decodeCanonicalUtc(
      _requiredStoredString(row, 'created_at'),
    );
    final updatedAt = CseTimeCodec.decodeCanonicalUtc(
      _requiredStoredString(row, 'updated_at'),
    );
    final statusChangedAt = CseTimeCodec.decodeCanonicalUtc(
      _requiredStoredString(row, 'status_changed_at'),
    );
    if (updatedAt.isBefore(createdAt) || statusChangedAt.isAfter(updatedAt)) {
      throw const FormatException();
    }
    return ConstructionLivingPlanItem(
      id: _requiredStoredString(row, 'id'),
      projectId: _requiredStoredString(row, 'project_id'),
      referenceSnapshotId: _requiredStoredString(row, 'reference_snapshot_id'),
      activityInstanceId: _requiredStoredString(row, 'activity_instance_id'),
      activityId: _requiredStoredString(row, 'activity_id'),
      activityNameSnapshot: _requiredStoredString(
        row,
        'activity_name_snapshot',
      ),
      activityContext: decodeConstructionLivingPlanContext(
        _requiredStoredString(row, 'activity_context_json', trim: false),
      ),
      naturalUnitSnapshot: _requiredStoredString(row, 'natural_unit_snapshot'),
      plannedDate: parseCanonicalConstructionDate(
        _requiredStoredString(row, 'planned_date'),
      ),
      status: ConstructionLivingPlanStatus.fromStorage(row['status']),
      note: parsedNote,
      revision: revision,
      createdAt: createdAt,
      updatedAt: updatedAt,
      statusChangedAt: statusChangedAt,
    );
  } on ConstructionLivingPlanFailure {
    rethrow;
  } on Object {
    throw const ConstructionLivingPlanFailure(
      'living_plan_projection_integrity_failed',
    );
  }
}

ConstructionLivingPlanEvent _eventFromRow(Map<String, Object?> row) {
  try {
    final sequence = row['sequence'];
    if (sequence is! int || sequence < 1) {
      throw const FormatException();
    }
    final payloadJson = _requiredStoredString(row, 'payload_json', trim: false);
    final decoded = jsonDecode(payloadJson);
    if (decoded is! Map ||
        encodeConstructionLivingPlanJson(decoded) != payloadJson) {
      throw const FormatException();
    }
    return ConstructionLivingPlanEvent(
      id: _requiredStoredString(row, 'id'),
      livingPlanItemId: _requiredStoredString(row, 'living_plan_item_id'),
      projectId: _requiredStoredString(row, 'project_id'),
      sequence: sequence,
      eventType: ConstructionLivingPlanEventType.fromStorage(row['event_type']),
      occurredAt: CseTimeCodec.decodeCanonicalUtc(
        _requiredStoredString(row, 'occurred_at'),
      ),
      payloadJson: payloadJson,
      payload: decoded.cast<String, Object?>(),
    );
  } on ConstructionLivingPlanFailure {
    rethrow;
  } on Object {
    throw const ConstructionLivingPlanFailure(
      'living_plan_history_integrity_failed',
    );
  }
}

String _requiredStoredString(
  Map<String, Object?> row,
  String key, {
  bool trim = true,
}) {
  final value = row[key];
  if (value is! String || value.isEmpty || (trim && value.trim() != value)) {
    throw const ConstructionLivingPlanFailure(
      'living_plan_projection_integrity_failed',
    );
  }
  return value;
}

String _canonicalDate(DateTime value) {
  try {
    return formatCanonicalConstructionDate(value);
  } on Object {
    throw const ConstructionLivingPlanFailure('living_plan_invalid_date');
  }
}

String? _validatedNote(String? value) {
  if (value == null) {
    return null;
  }
  if (value.isEmpty || value.trim() != value || value.runes.length > 1000) {
    throw const ConstructionLivingPlanFailure('living_plan_invalid_note');
  }
  return value;
}

void _requireUuid(String value, String code) {
  if (!RecordId.isUuid(value)) {
    throw ConstructionLivingPlanFailure(code);
  }
}

void _requireIdentity(String value, String code) {
  if (value.isEmpty || value.trim() != value) {
    throw ConstructionLivingPlanFailure(code);
  }
}

int _compareSuggestionCandidates(
  _EnrichedCandidate left,
  _EnrichedCandidate right,
) {
  final start = left.candidate.suggestedStartDate.compareTo(
    right.candidate.suggestedStartDate,
  );
  if (start != 0) {
    return start;
  }
  final finish = left.candidate.suggestedFinishDate.compareTo(
    right.candidate.suggestedFinishDate,
  );
  if (finish != 0) {
    return finish;
  }
  return _compareSearchCandidates(left.candidate, right.candidate);
}

int _compareSearchCandidates(
  ConstructionLivingPlanReferenceCandidate left,
  ConstructionLivingPlanReferenceCandidate right,
) {
  final sequence = left.activitySequence.compareTo(right.activitySequence);
  if (sequence != 0) {
    return sequence;
  }
  return left.activityInstanceId.compareTo(right.activityInstanceId);
}

int _compareWindowItems(
  ConstructionLivingPlanWindowItem left,
  ConstructionLivingPlanWindowItem right,
) {
  int classification(ConstructionLivingPlanWindowItem value) {
    if (value.isOverdue) {
      return 0;
    }
    return value.item.status == ConstructionLivingPlanStatus.completed ? 2 : 1;
  }

  final group = classification(left).compareTo(classification(right));
  if (group != 0) {
    return group;
  }
  final date = left.item.plannedDate.compareTo(right.item.plannedDate);
  if (date != 0) {
    return date;
  }
  const statusPriority = {
    ConstructionLivingPlanStatus.started: 0,
    ConstructionLivingPlanStatus.planned: 1,
    ConstructionLivingPlanStatus.deferred: 2,
    ConstructionLivingPlanStatus.completed: 3,
  };
  final status = statusPriority[left.item.status]!.compareTo(
    statusPriority[right.item.status]!,
  );
  if (status != 0) {
    return status;
  }
  final name = left.item.activityNameSnapshot.compareTo(
    right.item.activityNameSnapshot,
  );
  if (name != 0) {
    return name;
  }
  return left.item.id.compareTo(right.item.id);
}

bool _sameItemState(
  ConstructionLivingPlanItem left,
  ConstructionLivingPlanItem right,
) =>
    left.id == right.id &&
    left.projectId == right.projectId &&
    left.referenceSnapshotId == right.referenceSnapshotId &&
    left.activityInstanceId == right.activityInstanceId &&
    left.activityId == right.activityId &&
    left.activityNameSnapshot == right.activityNameSnapshot &&
    encodeConstructionLivingPlanContext(left.activityContext) ==
        encodeConstructionLivingPlanContext(right.activityContext) &&
    left.naturalUnitSnapshot == right.naturalUnitSnapshot &&
    left.plannedDate == right.plannedDate &&
    left.status == right.status &&
    left.note == right.note &&
    left.revision == right.revision &&
    left.createdAt == right.createdAt &&
    left.updatedAt == right.updatedAt &&
    left.statusChangedAt == right.statusChangedAt;
