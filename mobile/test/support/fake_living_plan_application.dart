import 'dart:async';

import 'package:chief_site_engineer/application/construction_living_plan_application.dart';
import 'package:chief_site_engineer/domain/construction_living_plan_models.dart';

class FakeLivingPlanApplication
    implements ConstructionLivingPlanApplicationPort {
  FakeLivingPlanApplication({
    this.snapshotAvailable = true,
    this.suggestions = const [],
    List<ConstructionLivingPlanReferenceCandidate>? searchResults,
    this.items = const [],
  }) : searchResults = searchResults ?? suggestions;

  bool snapshotAvailable;
  List<ConstructionLivingPlanReferenceCandidate> suggestions;
  List<ConstructionLivingPlanReferenceCandidate> searchResults;
  List<ConstructionLivingPlanWindowItem> items;
  Object? nextMutationFailure;
  Object? planFailure;
  Completer<void>? mutationGate;
  int createCalls = 0;
  int mutationCalls = 0;
  CreateConstructionLivingPlanItemCommand? lastCreateCommand;
  Object? lastMutationCommand;

  @override
  Future<List<ConstructionLivingPlanReferenceCandidate>>
  loadSevenDayReferenceSuggestions({
    required String projectId,
    required DateTime windowStart,
  }) async {
    if (!snapshotAvailable) {
      throw const ConstructionLivingPlanFailure(
        'living_plan_reference_snapshot_missing',
      );
    }
    return suggestions;
  }

  @override
  Future<List<ConstructionLivingPlanReferenceCandidate>>
  searchCurrentReferenceCandidates({
    required String projectId,
    required String query,
    int limit = ConstructionLivingPlanApplication.defaultSearchLimit,
  }) async {
    if (!snapshotAvailable) {
      throw const ConstructionLivingPlanFailure(
        'living_plan_reference_snapshot_missing',
      );
    }
    if (query.trim().isEmpty) {
      throw const ConstructionLivingPlanFailure(
        'living_plan_empty_reference_query',
      );
    }
    return searchResults.take(limit).toList(growable: false);
  }

  @override
  Future<ConstructionLivingPlanItem> createLivingPlanItem(
    CreateConstructionLivingPlanItemCommand command,
  ) async {
    createCalls += 1;
    lastCreateCommand = command;
    await _beforeMutation();
    final candidate = suggestions
        .followedBy(searchResults)
        .firstWhere(
          (item) => item.activityInstanceId == command.activityInstanceId,
        );
    final existing = items.where(
      (entry) =>
          entry.item.projectId == command.projectId &&
          entry.item.activityInstanceId == command.activityInstanceId,
    );
    if (existing.isNotEmpty) {
      throw const ConstructionLivingPlanFailure(
        'living_plan_item_already_exists',
      );
    }
    final now = DateTime.utc(2026, 8, 16, 12);
    final item = ConstructionLivingPlanItem(
      id: command.itemId,
      projectId: command.projectId,
      referenceSnapshotId: command.expectedReferenceSnapshotId,
      activityInstanceId: candidate.activityInstanceId,
      activityId: candidate.activityId,
      activityNameSnapshot: candidate.activityName,
      activityContext: candidate.activityContext,
      naturalUnitSnapshot: candidate.naturalUnit,
      plannedDate: command.plannedDate,
      status: ConstructionLivingPlanStatus.planned,
      progressPercent: null,
      note: command.note,
      revision: 1,
      createdAt: now,
      updatedAt: now,
      statusChangedAt: now,
    );
    items = [
      ...items,
      ConstructionLivingPlanWindowItem(
        item: item,
        isOverdue: false,
        originSnapshotIsCurrent: true,
      ),
    ];
    suggestions = _markCandidate(suggestions, candidate, item);
    searchResults = _markCandidate(searchResults, candidate, item);
    return item;
  }

  @override
  Future<ConstructionLivingPlanItem> startLivingPlanItem(
    StartConstructionLivingPlanItemCommand command,
  ) => _mutate(
    command,
    command.itemId,
    command.expectedRevision,
    status: ConstructionLivingPlanStatus.started,
  );

  @override
  Future<ConstructionLivingPlanItem> completeLivingPlanItem(
    CompleteConstructionLivingPlanItemCommand command,
  ) => _mutate(
    command,
    command.itemId,
    command.expectedRevision,
    status: ConstructionLivingPlanStatus.completed,
    progressPercent: 100,
    replaceProgress: true,
  );

  @override
  Future<ConstructionLivingPlanItem> deferLivingPlanItem(
    DeferConstructionLivingPlanItemCommand command,
  ) => _mutate(
    command,
    command.itemId,
    command.expectedRevision,
    status: ConstructionLivingPlanStatus.deferred,
    date: command.plannedDate,
  );

  @override
  Future<ConstructionLivingPlanItem> reopenLivingPlanItem(
    ReopenConstructionLivingPlanItemCommand command,
  ) => _mutate(
    command,
    command.itemId,
    command.expectedRevision,
    status: ConstructionLivingPlanStatus.planned,
    date: command.plannedDate,
    progressPercent: null,
    replaceProgress: true,
  );

  @override
  Future<ConstructionLivingPlanItem> updateLivingPlanNote(
    UpdateConstructionLivingPlanNoteCommand command,
  ) => _mutate(
    command,
    command.itemId,
    command.expectedRevision,
    note: command.note,
    replaceNote: true,
  );

  @override
  Future<ConstructionLivingPlanItem> updateLivingPlanProgress(
    UpdateConstructionLivingPlanProgressCommand command,
  ) => _mutate(
    command,
    command.itemId,
    command.expectedRevision,
    progressPercent: command.progressPercent,
    replaceProgress: true,
  );

  Future<ConstructionLivingPlanItem> _mutate(
    Object command,
    String itemId,
    int expectedRevision, {
    ConstructionLivingPlanStatus? status,
    DateTime? date,
    String? note,
    bool replaceNote = false,
    int? progressPercent,
    bool replaceProgress = false,
  }) async {
    mutationCalls += 1;
    lastMutationCommand = command;
    await _beforeMutation();
    final index = items.indexWhere((entry) => entry.item.id == itemId);
    if (index < 0) {
      throw const ConstructionLivingPlanFailure('living_plan_item_not_found');
    }
    final current = items[index];
    if (current.item.revision != expectedRevision) {
      throw const ConstructionLivingPlanFailure('living_plan_stale_revision');
    }
    final now = DateTime.utc(2026, 8, 16, 12, 1);
    final item = ConstructionLivingPlanItem(
      id: current.item.id,
      projectId: current.item.projectId,
      referenceSnapshotId: current.item.referenceSnapshotId,
      activityInstanceId: current.item.activityInstanceId,
      activityId: current.item.activityId,
      activityNameSnapshot: current.item.activityNameSnapshot,
      activityContext: current.item.activityContext,
      naturalUnitSnapshot: current.item.naturalUnitSnapshot,
      plannedDate: date ?? current.item.plannedDate,
      status: status ?? current.item.status,
      progressPercent: replaceProgress
          ? progressPercent
          : current.item.progressPercent,
      note: replaceNote ? note : current.item.note,
      revision: current.item.revision + 1,
      createdAt: current.item.createdAt,
      updatedAt: now,
      statusChangedAt: status == null ? current.item.statusChangedAt : now,
    );
    items = [...items]
      ..[index] = ConstructionLivingPlanWindowItem(
        item: item,
        isOverdue: current.isOverdue,
        originSnapshotIsCurrent: current.originSnapshotIsCurrent,
      );
    return item;
  }

  Future<void> _beforeMutation() async {
    final failure = nextMutationFailure;
    nextMutationFailure = null;
    if (failure != null) throw failure;
    await mutationGate?.future;
  }

  @override
  Future<List<ConstructionLivingPlanWindowItem>> loadSevenDayPlan({
    required String projectId,
    required DateTime windowStart,
  }) async {
    if (planFailure case final failure?) throw failure;
    return items;
  }

  @override
  Future<ConstructionLivingPlanItem?> loadLivingPlanItem(String itemId) async {
    for (final entry in items) {
      if (entry.item.id == itemId) return entry.item;
    }
    return null;
  }

  @override
  Future<List<ConstructionLivingPlanEvent>> listLivingPlanEventHistory(
    String itemId,
  ) async => const [];
}

List<ConstructionLivingPlanReferenceCandidate> _markCandidate(
  List<ConstructionLivingPlanReferenceCandidate> values,
  ConstructionLivingPlanReferenceCandidate selected,
  ConstructionLivingPlanItem item,
) => [
  for (final candidate in values)
    if (candidate.activityInstanceId == selected.activityInstanceId)
      ConstructionLivingPlanReferenceCandidate(
        referenceSnapshotId: candidate.referenceSnapshotId,
        projectId: candidate.projectId,
        activityInstanceId: candidate.activityInstanceId,
        activityId: candidate.activityId,
        activityName: candidate.activityName,
        activityContext: candidate.activityContext,
        naturalUnit: candidate.naturalUnit,
        suggestedStartDate: candidate.suggestedStartDate,
        suggestedFinishDate: candidate.suggestedFinishDate,
        durationStatus: candidate.durationStatus,
        durationConfidence: candidate.durationConfidence,
        activitySequence: candidate.activitySequence,
        existingLivingPlanItemId: item.id,
        existingLivingPlanStatus: item.status,
      )
    else
      candidate,
];
