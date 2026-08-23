import 'package:chief_site_engineer/application/construction_schedule_date_engine.dart';
import 'package:chief_site_engineer/domain/construction_corpus_models.dart';
import 'package:chief_site_engineer/domain/construction_living_plan_dependency_impact_models.dart';
import 'package:chief_site_engineer/domain/construction_living_plan_forecast_models.dart';
import 'package:chief_site_engineer/domain/construction_living_plan_models.dart';
import 'package:chief_site_engineer/domain/construction_project_graph_models.dart';
import 'package:chief_site_engineer/domain/construction_schedule_dependency_snapshot_models.dart';
import 'package:chief_site_engineer/domain/construction_schedule_models.dart';

class ConstructionLivingPlanDependencyImpactEngine {
  const ConstructionLivingPlanDependencyImpactEngine();

  ConstructionLivingPlanDependencyImpact calculate({
    required ConstructionLivingPlanForecast sourceForecast,
    required ConstructionScheduleSnapshot exactSnapshot,
    required ConstructionScheduleSnapshotDependencyGraph exactDependencyGraph,
  }) {
    _requireCanonicalDate(
      sourceForecast.asOfDate,
      'impact_as_of_date_not_canonical',
    );
    final source = _requireExactBinding(
      sourceForecast,
      exactSnapshot,
      exactDependencyGraph,
    );
    final topology = _buildImpactTopology(
      snapshot: exactSnapshot,
      graph: exactDependencyGraph,
    );
    _requireValidReference(
      snapshot: exactSnapshot,
      graph: exactDependencyGraph,
      topology: topology,
    );

    final forecastFinish = sourceForecast.forecastFinishDate;
    if (forecastFinish != null) {
      _requireCanonicalDate(
        forecastFinish,
        'impact_forecast_finish_not_canonical',
      );
    }
    final variance = forecastFinish?.difference(source.finishDate).inDays;
    if (sourceForecast.varianceCalendarDays != variance) {
      throw const ConstructionLivingPlanDependencyImpactFailure(
        'impact_source_variance_mismatch',
      );
    }
    final isActiveForecast =
        sourceForecast.status == ConstructionLivingPlanStatus.started &&
        sourceForecast.basis ==
            ConstructionLivingPlanForecastBasis.startedReferenceRemaining &&
        sourceForecast.progressPercent != null &&
        sourceForecast.progressPercent! >= 0 &&
        sourceForecast.progressPercent! < 100 &&
        forecastFinish != null;
    if (!isActiveForecast) {
      return _result(
        sourceForecast: sourceForecast,
        source: source,
        graph: exactDependencyGraph,
        variance: variance,
        basis: ConstructionLivingPlanDependencyImpactBasis
            .sourceForecastUnavailable,
      );
    }
    if (!forecastFinish.isAfter(source.finishDate)) {
      return _result(
        sourceForecast: sourceForecast,
        source: source,
        graph: exactDependencyGraph,
        variance: variance,
        basis:
            ConstructionLivingPlanDependencyImpactBasis.noPositiveSourceDelay,
      );
    }

    final effectiveById = <String, ConstructionScheduledActivity>{};
    final impacted = <ConstructionLivingPlanDependencyImpactItem>[];
    for (final instanceId in topology.orderedInstanceIds) {
      final reference = topology.activitiesById[instanceId]!;
      if (instanceId == source.instanceId) {
        effectiveById[instanceId] = reference.copyWith(
          finishDate: forecastFinish,
        );
        continue;
      }
      var projectedStart = reference.startDate;
      for (final edge in topology.incomingEdges[instanceId]!) {
        final predecessor = effectiveById[edge.predecessorInstanceId];
        if (predecessor == null) {
          throw const ConstructionLivingPlanDependencyImpactFailure(
            'impact_invalid_topological_order',
          );
        }
        final candidate = _candidateStart(
          predecessor: predecessor,
          successor: reference,
          edge: edge,
          calendar: exactSnapshot.profile.calendar,
        );
        if (candidate.isAfter(projectedStart)) {
          projectedStart = candidate;
        }
      }
      if (!projectedStart.isAfter(reference.startDate)) {
        effectiveById[instanceId] = reference;
        continue;
      }
      final projectedFinish = _finishDate(
        activity: reference,
        startDate: projectedStart,
        calendar: exactSnapshot.profile.calendar,
      );
      effectiveById[instanceId] = reference.copyWith(
        startDate: projectedStart,
        finishDate: projectedFinish,
      );
      impacted.add(
        ConstructionLivingPlanDependencyImpactItem(
          activityInstanceId: reference.instanceId,
          activityId: reference.activityId,
          referenceStartDate: reference.startDate,
          referenceFinishDate: reference.finishDate,
          projectedStartDate: projectedStart,
          projectedFinishDate: projectedFinish,
          startShiftCalendarDays: projectedStart
              .difference(reference.startDate)
              .inDays,
          finishShiftCalendarDays: projectedFinish
              .difference(reference.finishDate)
              .inDays,
        ),
      );
    }

    return _result(
      sourceForecast: sourceForecast,
      source: source,
      graph: exactDependencyGraph,
      variance: variance,
      positiveDelay: variance!,
      impacted: impacted,
      basis: impacted.isEmpty
          ? ConstructionLivingPlanDependencyImpactBasis
                .sourceDelayNoDownstreamShift
          : ConstructionLivingPlanDependencyImpactBasis
                .downstreamDelayProjected,
    );
  }
}

ConstructionLivingPlanDependencyImpact _result({
  required ConstructionLivingPlanForecast sourceForecast,
  required ConstructionScheduledActivity source,
  required ConstructionScheduleSnapshotDependencyGraph graph,
  required int? variance,
  required ConstructionLivingPlanDependencyImpactBasis basis,
  int positiveDelay = 0,
  Iterable<ConstructionLivingPlanDependencyImpactItem> impacted = const [],
}) => ConstructionLivingPlanDependencyImpact(
  itemId: sourceForecast.itemId,
  projectId: sourceForecast.projectId,
  referenceSnapshotId: sourceForecast.referenceSnapshotId,
  sourceActivityInstanceId: sourceForecast.activityInstanceId,
  asOfDate: sourceForecast.asOfDate,
  sourceReferenceStartDate: source.startDate,
  sourceReferenceFinishDate: source.finishDate,
  sourceForecastFinishDate: sourceForecast.forecastFinishDate,
  sourceVarianceCalendarDays: variance,
  propagatedPositiveSourceDelayCalendarDays: positiveDelay,
  dependencyProjectionSha256: graph.projectionSha256,
  basis: basis,
  impactedActivities: impacted,
);

ConstructionScheduledActivity _requireExactBinding(
  ConstructionLivingPlanForecast forecast,
  ConstructionScheduleSnapshot snapshot,
  ConstructionScheduleSnapshotDependencyGraph graph,
) {
  final metadata = snapshot.metadata;
  if (forecast.projectId != metadata.projectId) {
    throw const ConstructionLivingPlanDependencyImpactFailure(
      'impact_project_mismatch',
    );
  }
  if (snapshot.profile.projectId != metadata.projectId) {
    throw const ConstructionLivingPlanDependencyImpactFailure(
      'impact_snapshot_profile_project_mismatch',
    );
  }
  if (forecast.referenceSnapshotId != metadata.snapshotId) {
    throw const ConstructionLivingPlanDependencyImpactFailure(
      'impact_reference_snapshot_mismatch',
    );
  }
  if (graph.projectId != metadata.projectId) {
    throw const ConstructionLivingPlanDependencyImpactFailure(
      'impact_dependency_project_mismatch',
    );
  }
  if (graph.snapshotId != metadata.snapshotId) {
    throw const ConstructionLivingPlanDependencyImpactFailure(
      'impact_dependency_snapshot_mismatch',
    );
  }
  final matches = snapshot.activities
      .where((activity) => activity.instanceId == forecast.activityInstanceId)
      .toList(growable: false);
  if (matches.isEmpty) {
    throw const ConstructionLivingPlanDependencyImpactFailure(
      'impact_source_activity_missing',
    );
  }
  if (matches.length != 1) {
    throw const ConstructionLivingPlanDependencyImpactFailure(
      'impact_source_activity_duplicate',
    );
  }
  final source = matches.single;
  if (forecast.referenceStartDate != source.startDate ||
      forecast.referenceFinishDate != source.finishDate ||
      forecast.referenceDurationDays != source.durationDays ||
      forecast.referenceRoundedSchedulingDays != source.roundedSchedulingDays ||
      forecast.referenceDurationCalendarType != source.durationCalendarType ||
      forecast.referenceDurationStatus != source.durationStatus ||
      forecast.referenceDurationConfidence != source.durationConfidence) {
    throw const ConstructionLivingPlanDependencyImpactFailure(
      'impact_source_reference_mismatch',
    );
  }
  if (forecast.referenceCorpusVersion != metadata.corpusVersion ||
      forecast.referenceScheduleSeedVersion != metadata.scheduleSeedVersion ||
      forecast.referenceScheduleSeedProvenance !=
          metadata.scheduleSeedProvenance ||
      forecast.referenceProductionStatus != metadata.productionStatus ||
      forecast.referenceDurationSource != metadata.durationSource ||
      forecast.referenceBaselineStatus != metadata.baselineStatus ||
      forecast.referenceProjectionSha256 != metadata.projectionSha256) {
    throw const ConstructionLivingPlanDependencyImpactFailure(
      'impact_source_provenance_mismatch',
    );
  }
  if (graph.dependencyCount < 0 ||
      graph.dependencyCount != graph.edges.length) {
    throw const ConstructionLivingPlanDependencyImpactFailure(
      'impact_dependency_count_mismatch',
    );
  }
  if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(graph.projectionSha256)) {
    throw const ConstructionLivingPlanDependencyImpactFailure(
      'impact_dependency_sha_invalid',
    );
  }
  return source;
}

void _requireValidReference({
  required ConstructionScheduleSnapshot snapshot,
  required ConstructionScheduleSnapshotDependencyGraph graph,
  required _ImpactTopology topology,
}) {
  final metadata = snapshot.metadata;
  if (metadata.activityCount != snapshot.activities.length) {
    throw const ConstructionLivingPlanDependencyImpactFailure(
      'impact_snapshot_activity_count_mismatch',
    );
  }
  final provenance = <String>[
    metadata.snapshotId,
    metadata.projectId,
    metadata.corpusVersion,
    metadata.scheduleSeedVersion,
    metadata.scheduleSeedProvenance,
    metadata.productionStatus,
    metadata.durationSource,
    metadata.baselineStatus,
    metadata.projectionSha256,
  ];
  if (provenance.any((value) => value.isEmpty || value.trim() != value)) {
    throw const ConstructionLivingPlanDependencyImpactFailure(
      'impact_invalid_snapshot_provenance',
    );
  }
  final calendar = snapshot.profile.calendar;
  _requireCanonicalDate(
    calendar.startDate,
    'impact_invalid_reference_calendar',
  );
  if (calendar.workingWeekdays.isEmpty ||
      calendar.workingWeekdays.toSet().length !=
          calendar.workingWeekdays.length ||
      calendar.workingWeekdays.any((day) => day < 0 || day > 6) ||
      !calendar.workdayHours.isFinite ||
      calendar.workdayHours <= 0 ||
      calendar.workdayHours > 24) {
    throw const ConstructionLivingPlanDependencyImpactFailure(
      'impact_invalid_reference_calendar',
    );
  }
  final holidays = <DateTime>{};
  for (final holiday in calendar.holidays) {
    _requireCanonicalDate(holiday, 'impact_invalid_reference_calendar');
    if (!holidays.add(holiday)) {
      throw const ConstructionLivingPlanDependencyImpactFailure(
        'impact_invalid_reference_calendar',
      );
    }
  }
  for (final activity in snapshot.activities) {
    if (activity.instanceId.isEmpty ||
        activity.instanceId.trim() != activity.instanceId ||
        activity.activityId.isEmpty ||
        activity.activityId.trim() != activity.activityId ||
        !activity.durationDays.isFinite ||
        activity.durationDays < 0 ||
        activity.roundedSchedulingDays != activity.durationDays.ceil() ||
        activity.isMilestone != (activity.roundedSchedulingDays == 0)) {
      throw const ConstructionLivingPlanDependencyImpactFailure(
        'impact_invalid_reference_activity',
      );
    }
    _requireCanonicalDate(
      activity.startDate,
      'impact_invalid_reference_activity',
    );
    _requireCanonicalDate(
      activity.finishDate,
      'impact_invalid_reference_activity',
    );
    if (_finishDate(
          activity: activity,
          startDate: activity.startDate,
          calendar: calendar,
        ) !=
        activity.finishDate) {
      throw const ConstructionLivingPlanDependencyImpactFailure(
        'impact_invalid_reference_activity',
      );
    }
  }
  for (final edge in graph.edges) {
    final predecessor = topology.activitiesById[edge.predecessorInstanceId]!;
    final successor = topology.activitiesById[edge.successorInstanceId]!;
    final candidate = _candidateStart(
      predecessor: predecessor,
      successor: successor,
      edge: edge,
      calendar: calendar,
    );
    if (successor.startDate.isBefore(candidate)) {
      throw const ConstructionLivingPlanDependencyImpactFailure(
        'impact_invalid_reference_dependency_constraint',
      );
    }
  }
}

DateTime _candidateStart({
  required ConstructionScheduledActivity predecessor,
  required ConstructionScheduledActivity successor,
  required ConstructionResolvedDependencyEdge edge,
  required ConstructionProjectCalendar calendar,
}) {
  try {
    return constructionDependencyCandidateStart(
      predecessor: predecessor,
      successorCalendarType: successor.durationCalendarType,
      edge: edge,
      calendar: calendar,
    );
  } on ConstructionCorpusFailure {
    throw const ConstructionLivingPlanDependencyImpactFailure(
      'impact_invalid_reference_calendar',
    );
  }
}

DateTime _finishDate({
  required ConstructionScheduledActivity activity,
  required DateTime startDate,
  required ConstructionProjectCalendar calendar,
}) {
  try {
    return constructionDurationFinishDate(
      startDate: startDate,
      roundedSchedulingDays: activity.roundedSchedulingDays,
      calendarType: activity.durationCalendarType,
      calendar: calendar,
    );
  } on ConstructionCorpusFailure {
    throw const ConstructionLivingPlanDependencyImpactFailure(
      'impact_invalid_reference_calendar',
    );
  }
}

_ImpactTopology _buildImpactTopology({
  required ConstructionScheduleSnapshot snapshot,
  required ConstructionScheduleSnapshotDependencyGraph graph,
}) {
  final activitiesById = <String, ConstructionScheduledActivity>{};
  for (final activity in snapshot.activities) {
    if (activitiesById.containsKey(activity.instanceId)) {
      throw const ConstructionLivingPlanDependencyImpactFailure(
        'impact_snapshot_activity_instance_duplicate',
      );
    }
    activitiesById[activity.instanceId] = activity;
  }
  final incomingCounts = {
    for (final instanceId in activitiesById.keys) instanceId: 0,
  };
  final incomingEdges = {
    for (final instanceId in activitiesById.keys)
      instanceId: <ConstructionResolvedDependencyEdge>[],
  };
  final outgoingEdges = {
    for (final instanceId in activitiesById.keys)
      instanceId: <ConstructionResolvedDependencyEdge>[],
  };
  final edgeKeys = <String>{};
  for (final edge in graph.edges) {
    if (edge.edgeKey.isEmpty || edge.edgeKey.trim() != edge.edgeKey) {
      throw const ConstructionLivingPlanDependencyImpactFailure(
        'impact_dependency_edge_key_invalid',
      );
    }
    if (!edgeKeys.add(edge.edgeKey)) {
      throw const ConstructionLivingPlanDependencyImpactFailure(
        'impact_dependency_edge_key_duplicate',
      );
    }
    if (edge.predecessorInstanceId == edge.successorInstanceId) {
      throw const ConstructionLivingPlanDependencyImpactFailure(
        'impact_dependency_self_edge',
      );
    }
    if (!activitiesById.containsKey(edge.predecessorInstanceId) ||
        !activitiesById.containsKey(edge.successorInstanceId)) {
      throw const ConstructionLivingPlanDependencyImpactFailure(
        'impact_dependency_orphan_endpoint',
      );
    }
    if (edge.lagValue < 0 ||
        edge.lagUnit != ConstructionDependencyLagUnit.workingDay) {
      throw const ConstructionLivingPlanDependencyImpactFailure(
        'impact_dependency_lag_invalid',
      );
    }
    incomingCounts[edge.successorInstanceId] =
        incomingCounts[edge.successorInstanceId]! + 1;
    incomingEdges[edge.successorInstanceId]!.add(edge);
    outgoingEdges[edge.predecessorInstanceId]!.add(edge);
  }
  for (final edges in incomingEdges.values) {
    edges.sort((left, right) => left.edgeKey.compareTo(right.edgeKey));
  }
  for (final edges in outgoingEdges.values) {
    edges.sort((left, right) {
      final successor = left.successorInstanceId.compareTo(
        right.successorInstanceId,
      );
      return successor != 0 ? successor : left.edgeKey.compareTo(right.edgeKey);
    });
  }

  final ready =
      incomingCounts.entries
          .where((entry) => entry.value == 0)
          .map((entry) => entry.key)
          .toList()
        ..sort();
  final ordered = <String>[];
  while (ready.isNotEmpty) {
    final current = ready.removeAt(0);
    ordered.add(current);
    for (final edge in outgoingEdges[current]!) {
      final successor = edge.successorInstanceId;
      incomingCounts[successor] = incomingCounts[successor]! - 1;
      if (incomingCounts[successor] == 0) {
        ready.add(successor);
        ready.sort();
      }
    }
  }
  if (ordered.length != activitiesById.length) {
    throw const ConstructionLivingPlanDependencyImpactFailure(
      'impact_dependency_cycle',
    );
  }
  return _ImpactTopology(
    orderedInstanceIds: List.unmodifiable(ordered),
    activitiesById: Map<String, ConstructionScheduledActivity>.unmodifiable(
      activitiesById,
    ),
    incomingEdges:
        Map<String, List<ConstructionResolvedDependencyEdge>>.unmodifiable({
          for (final entry in incomingEdges.entries)
            entry.key: List<ConstructionResolvedDependencyEdge>.unmodifiable(
              entry.value,
            ),
        }),
  );
}

void _requireCanonicalDate(DateTime date, String failureCode) {
  if (!date.isUtc ||
      date.hour != 0 ||
      date.minute != 0 ||
      date.second != 0 ||
      date.millisecond != 0 ||
      date.microsecond != 0) {
    throw ConstructionLivingPlanDependencyImpactFailure(failureCode);
  }
}

class _ImpactTopology {
  const _ImpactTopology({
    required this.orderedInstanceIds,
    required this.activitiesById,
    required this.incomingEdges,
  });

  final List<String> orderedInstanceIds;
  final Map<String, ConstructionScheduledActivity> activitiesById;
  final Map<String, List<ConstructionResolvedDependencyEdge>> incomingEdges;
}
