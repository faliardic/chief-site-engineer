import 'package:chief_site_engineer/domain/construction_corpus_models.dart';
import 'package:chief_site_engineer/domain/construction_project_graph_models.dart';
import 'package:chief_site_engineer/domain/construction_schedule_models.dart';

class ConstructionScheduleDateEngine {
  static const productionStatus = 'NOT_FOR_PRODUCTION';
  static const durationSource = 'TEST_SEED_ONLY';
  static const baselineStatus = 'NOT_A_BASELINE';
  static const derivedConnectivityId = 'DERIVED-CONNECTIVITY';

  ConstructionProjectReferenceSchedule build({
    required ConstructionProjectProfile profile,
    required ConstructionProjectActivityGraph graph,
    required ConstructionScheduleSeedCatalog seedCatalog,
  }) {
    if (profile.projectId != graph.projectId) {
      throw const ConstructionCorpusFailure('schedule_project_mismatch');
    }
    if (graph.activityInstances.isEmpty) {
      throw const ConstructionCorpusFailure('empty_schedule_graph');
    }

    final topology = _buildTopology(graph);
    final instancesById = {
      for (final instance in graph.activityInstances)
        instance.instanceId: instance,
    };
    final isolatedIds = graph.isolatedInstanceIds.toSet();
    final scheduledById = <String, ConstructionScheduledActivity>{};

    for (final instanceId in topology.orderedInstanceIds) {
      final instance = instancesById[instanceId]!;
      final seed = seedCatalog.seedsByActivityId[instance.activityId];
      if (seed == null) {
        throw const ConstructionCorpusFailure('missing_schedule_seed_activity');
      }
      final incoming = topology.incomingEdges[instanceId]!;
      DateTime startDate;
      if (incoming.isEmpty) {
        startDate =
            seed.durationCalendarType ==
                ConstructionActivityDurationCalendarType.workingDay
            ? nextConstructionWorkday(
                profile.calendar.startDate,
                profile.calendar,
                includeCurrent: true,
              )
            : profile.calendar.startDate;
      } else {
        DateTime? latest;
        for (final edge in incoming) {
          final predecessor = scheduledById[edge.predecessorInstanceId];
          if (predecessor == null) {
            throw const ConstructionCorpusFailure(
              'invalid_schedule_topological_order',
            );
          }
          final anchor = switch (edge.relationshipType) {
            ConstructionDependencyRelationshipType.finishToStart =>
              predecessor.finishDate.add(const Duration(days: 1)),
            ConstructionDependencyRelationshipType.startToStart =>
              predecessor.startDate,
          };
          var candidate = addConstructionWorkdays(
            anchor,
            edge.lagValue,
            profile.calendar,
          );
          if (seed.durationCalendarType ==
              ConstructionActivityDurationCalendarType.workingDay) {
            candidate = nextConstructionWorkday(
              candidate,
              profile.calendar,
              includeCurrent: true,
            );
          }
          if (latest == null || candidate.isAfter(latest)) {
            latest = candidate;
          }
        }
        startDate = latest!;
      }

      final finishDate = constructionDurationFinishDate(
        startDate: startDate,
        roundedSchedulingDays: seed.roundedSchedulingDays,
        calendarType: seed.durationCalendarType,
        calendar: profile.calendar,
      );
      scheduledById[instanceId] = ConstructionScheduledActivity(
        instanceId: instanceId,
        activityId: instance.activityId,
        startDate: startDate,
        finishDate: finishDate,
        durationDays: seed.durationDays,
        roundedSchedulingDays: seed.roundedSchedulingDays,
        durationCalendarType: seed.durationCalendarType,
        durationStatus: seed.durationStatus,
        durationConfidence: seed.durationConfidence,
        isMilestone: seed.isMilestone,
        isIsolated: isolatedIds.contains(instanceId),
      );
    }

    final scheduled = scheduledById.values.toList(growable: false)
      ..sort((left, right) => left.instanceId.compareTo(right.instanceId));
    final schedule = ConstructionProjectReferenceSchedule(
      projectId: graph.projectId,
      corpusVersion: graph.corpusVersion,
      scheduleSeedVersion: seedCatalog.metadata.corpusVersion,
      scheduleSeedProvenance: seedCatalog.metadata.name,
      productionStatus: productionStatus,
      durationSource: durationSource,
      baselineStatus: baselineStatus,
      scheduledActivities: scheduled,
      rootInstanceIds: topology.rootInstanceIds,
      leafInstanceIds: topology.leafInstanceIds,
      isolatedInstanceIds: [...graph.isolatedInstanceIds]..sort(),
      scheduleStart: _minimumDate(
        scheduled.map((activity) => activity.startDate),
      ),
      scheduleFinish: _maximumDate(
        scheduled.map((activity) => activity.finishDate),
      ),
      confidenceInstanceCounts: _counts(
        scheduled.map((activity) => activity.durationConfidence),
      ),
      statusInstanceCounts: _counts(
        scheduled.map((activity) => activity.durationStatus),
      ),
      calendarTypeInstanceCounts: _counts(
        scheduled.map((activity) => activity.durationCalendarType),
      ),
      milestoneInstanceCount: scheduled
          .where((activity) => activity.isMilestone)
          .length,
      workdaySundayViolations: _sundayViolationCount(
        scheduled,
        profile.calendar,
      ),
      workdayHolidayViolations: _holidayViolationCount(
        scheduled,
        profile.calendar,
      ),
      syntheticDependencyCount: _syntheticDependencyCount(graph),
    );
    validateSchedule(
      schedule: schedule,
      profile: profile,
      graph: graph,
      seedCatalog: seedCatalog,
    );
    return schedule;
  }

  void validateSchedule({
    required ConstructionProjectReferenceSchedule schedule,
    required ConstructionProjectProfile profile,
    required ConstructionProjectActivityGraph graph,
    required ConstructionScheduleSeedCatalog seedCatalog,
  }) {
    if (schedule.projectId != graph.projectId ||
        profile.projectId != graph.projectId ||
        schedule.corpusVersion != graph.corpusVersion ||
        schedule.scheduleSeedVersion != seedCatalog.metadata.corpusVersion ||
        schedule.scheduleSeedProvenance != seedCatalog.metadata.name ||
        schedule.productionStatus != productionStatus ||
        schedule.durationSource != durationSource ||
        schedule.baselineStatus != baselineStatus) {
      throw const ConstructionCorpusFailure('invalid_schedule_provenance');
    }

    final topology = _buildTopology(graph);
    final expectedInstanceIds = graph.activityInstances
        .map((instance) => instance.instanceId)
        .toSet();
    final scheduledById = <String, ConstructionScheduledActivity>{};
    String? previousId;
    for (final activity in schedule.scheduledActivities) {
      if (previousId != null &&
          previousId.compareTo(activity.instanceId) >= 0) {
        throw const ConstructionCorpusFailure('unordered_scheduled_activity');
      }
      previousId = activity.instanceId;
      if (scheduledById.containsKey(activity.instanceId)) {
        throw const ConstructionCorpusFailure('duplicate_scheduled_instance');
      }
      scheduledById[activity.instanceId] = activity;
    }
    if (scheduledById.keys.toSet().difference(expectedInstanceIds).isNotEmpty ||
        expectedInstanceIds.difference(scheduledById.keys.toSet()).isNotEmpty) {
      throw const ConstructionCorpusFailure('scheduled_instance_set_mismatch');
    }

    final instancesById = {
      for (final instance in graph.activityInstances)
        instance.instanceId: instance,
    };
    final isolatedIds = graph.isolatedInstanceIds.toSet();
    for (final activity in schedule.scheduledActivities) {
      final instance = instancesById[activity.instanceId]!;
      final seed = seedCatalog.seedsByActivityId[instance.activityId];
      if (seed == null) {
        throw const ConstructionCorpusFailure('missing_schedule_seed_activity');
      }
      if (activity.activityId != instance.activityId ||
          activity.durationDays != seed.durationDays ||
          activity.roundedSchedulingDays != seed.roundedSchedulingDays ||
          activity.durationCalendarType != seed.durationCalendarType ||
          activity.durationStatus != seed.durationStatus ||
          activity.durationConfidence != seed.durationConfidence ||
          activity.isMilestone != seed.isMilestone ||
          activity.isIsolated != isolatedIds.contains(activity.instanceId)) {
        throw const ConstructionCorpusFailure('scheduled_seed_mismatch');
      }
      _requireCanonicalUtcDate(activity.startDate);
      _requireCanonicalUtcDate(activity.finishDate);
      if (activity.finishDate.isBefore(activity.startDate)) {
        throw const ConstructionCorpusFailure('schedule_finish_before_start');
      }
      final expectedFinish = constructionDurationFinishDate(
        startDate: activity.startDate,
        roundedSchedulingDays: activity.roundedSchedulingDays,
        calendarType: activity.durationCalendarType,
        calendar: profile.calendar,
      );
      if (activity.finishDate != expectedFinish) {
        throw const ConstructionCorpusFailure('invalid_schedule_finish');
      }
      if (activity.isMilestone && activity.startDate != activity.finishDate) {
        throw const ConstructionCorpusFailure('invalid_schedule_milestone');
      }
    }

    for (final rootId in topology.rootInstanceIds) {
      final activity = scheduledById[rootId]!;
      final expected =
          activity.durationCalendarType ==
              ConstructionActivityDurationCalendarType.workingDay
          ? nextConstructionWorkday(
              profile.calendar.startDate,
              profile.calendar,
              includeCurrent: true,
            )
          : profile.calendar.startDate;
      if (activity.startDate != expected) {
        throw const ConstructionCorpusFailure('invalid_schedule_root_start');
      }
    }
    for (final edge in graph.dependencyEdges) {
      final predecessor = scheduledById[edge.predecessorInstanceId]!;
      final successor = scheduledById[edge.successorInstanceId]!;
      final anchor = switch (edge.relationshipType) {
        ConstructionDependencyRelationshipType.finishToStart =>
          predecessor.finishDate.add(const Duration(days: 1)),
        ConstructionDependencyRelationshipType.startToStart =>
          predecessor.startDate,
      };
      var minimumStart = addConstructionWorkdays(
        anchor,
        edge.lagValue,
        profile.calendar,
      );
      if (successor.durationCalendarType ==
          ConstructionActivityDurationCalendarType.workingDay) {
        minimumStart = nextConstructionWorkday(
          minimumStart,
          profile.calendar,
          includeCurrent: true,
        );
      }
      if (successor.startDate.isBefore(minimumStart)) {
        throw const ConstructionCorpusFailure(
          'schedule_dependency_constraint_violation',
        );
      }
    }

    _requireSameOrderedValues(
      schedule.rootInstanceIds,
      topology.rootInstanceIds,
      'schedule_root_set_mismatch',
    );
    _requireSameOrderedValues(
      schedule.leafInstanceIds,
      topology.leafInstanceIds,
      'schedule_leaf_set_mismatch',
    );
    final expectedIsolated = [...graph.isolatedInstanceIds]..sort();
    _requireSameOrderedValues(
      schedule.isolatedInstanceIds,
      expectedIsolated,
      'schedule_isolated_set_mismatch',
    );

    if (schedule.scheduleStart !=
            _minimumDate(
              schedule.scheduledActivities.map((item) => item.startDate),
            ) ||
        schedule.scheduleFinish !=
            _maximumDate(
              schedule.scheduledActivities.map((item) => item.finishDate),
            ) ||
        !_sameCounts(
          schedule.confidenceInstanceCounts,
          _counts(
            schedule.scheduledActivities.map((item) => item.durationConfidence),
          ),
        ) ||
        !_sameCounts(
          schedule.statusInstanceCounts,
          _counts(
            schedule.scheduledActivities.map((item) => item.durationStatus),
          ),
        ) ||
        !_sameCounts(
          schedule.calendarTypeInstanceCounts,
          _counts(
            schedule.scheduledActivities.map(
              (item) => item.durationCalendarType,
            ),
          ),
        ) ||
        schedule.milestoneInstanceCount !=
            schedule.scheduledActivities
                .where((item) => item.isMilestone)
                .length) {
      throw const ConstructionCorpusFailure('schedule_summary_mismatch');
    }

    final sundayViolations = _sundayViolationCount(
      schedule.scheduledActivities,
      profile.calendar,
    );
    final holidayViolations = _holidayViolationCount(
      schedule.scheduledActivities,
      profile.calendar,
    );
    final syntheticCount = _syntheticDependencyCount(graph);
    if (sundayViolations != 0 ||
        holidayViolations != 0 ||
        syntheticCount != 0 ||
        schedule.workdaySundayViolations != sundayViolations ||
        schedule.workdayHolidayViolations != holidayViolations ||
        schedule.syntheticDependencyCount != syntheticCount) {
      throw const ConstructionCorpusFailure('schedule_contract_violation');
    }
  }
}

DateTime parseCanonicalConstructionDate(String value) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
  if (match == null) {
    throw const ConstructionCorpusFailure('invalid_construction_date');
  }
  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  final date = DateTime.utc(year, month, day);
  if (formatCanonicalConstructionDate(date) != value) {
    throw const ConstructionCorpusFailure('invalid_construction_date');
  }
  return date;
}

String formatCanonicalConstructionDate(DateTime date) {
  _requireCanonicalUtcDate(date);
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

int canonicalConstructionWeekday(DateTime date) {
  _requireCanonicalUtcDate(date);
  return date.weekday - DateTime.monday;
}

bool isConstructionWorkday(
  DateTime date,
  ConstructionProjectCalendar calendar,
) {
  _requireCanonicalUtcDate(date);
  final weekday = canonicalConstructionWeekday(date);
  if (!calendar.workingWeekdays.contains(weekday)) {
    return false;
  }
  return !calendar.holidays.any((holiday) => holiday == date);
}

DateTime nextConstructionWorkday(
  DateTime date,
  ConstructionProjectCalendar calendar, {
  required bool includeCurrent,
}) {
  _requireCanonicalUtcDate(date);
  var candidate = includeCurrent ? date : date.add(const Duration(days: 1));
  while (!isConstructionWorkday(candidate, calendar)) {
    candidate = candidate.add(const Duration(days: 1));
  }
  return candidate;
}

DateTime addConstructionWorkdays(
  DateTime anchor,
  int workdays,
  ConstructionProjectCalendar calendar,
) {
  _requireCanonicalUtcDate(anchor);
  if (workdays < 0) {
    throw const ConstructionCorpusFailure('invalid_schedule_workday_count');
  }
  var result = nextConstructionWorkday(anchor, calendar, includeCurrent: true);
  for (var index = 0; index < workdays; index += 1) {
    result = nextConstructionWorkday(result, calendar, includeCurrent: false);
  }
  return result;
}

DateTime constructionDurationFinishDate({
  required DateTime startDate,
  required int roundedSchedulingDays,
  required ConstructionActivityDurationCalendarType calendarType,
  required ConstructionProjectCalendar calendar,
}) {
  _requireCanonicalUtcDate(startDate);
  if (roundedSchedulingDays < 0) {
    throw const ConstructionCorpusFailure('invalid_schedule_duration');
  }
  if (roundedSchedulingDays == 0) {
    return startDate;
  }
  return switch (calendarType) {
    ConstructionActivityDurationCalendarType.workingDay =>
      isConstructionWorkday(startDate, calendar)
          ? addConstructionWorkdays(
              startDate,
              roundedSchedulingDays - 1,
              calendar,
            )
          : throw const ConstructionCorpusFailure(
              'working_duration_non_workday_start',
            ),
    ConstructionActivityDurationCalendarType.calendarDay => startDate.add(
      Duration(days: roundedSchedulingDays - 1),
    ),
  };
}

class _ConstructionScheduleTopology {
  const _ConstructionScheduleTopology({
    required this.orderedInstanceIds,
    required this.rootInstanceIds,
    required this.leafInstanceIds,
    required this.incomingEdges,
  });

  final List<String> orderedInstanceIds;
  final List<String> rootInstanceIds;
  final List<String> leafInstanceIds;
  final Map<String, List<ConstructionResolvedDependencyEdge>> incomingEdges;
}

_ConstructionScheduleTopology _buildTopology(
  ConstructionProjectActivityGraph graph,
) {
  final instanceIds = <String>{};
  for (final instance in graph.activityInstances) {
    if (!instanceIds.add(instance.instanceId)) {
      throw const ConstructionCorpusFailure('duplicate_activity_instance');
    }
  }
  final incomingCounts = {for (final id in instanceIds) id: 0};
  final incomingEdges = {
    for (final id in instanceIds) id: <ConstructionResolvedDependencyEdge>[],
  };
  final outgoingEdges = {
    for (final id in instanceIds) id: <ConstructionResolvedDependencyEdge>[],
  };
  for (final edge in graph.dependencyEdges) {
    if (!instanceIds.contains(edge.predecessorInstanceId) ||
        !instanceIds.contains(edge.successorInstanceId)) {
      throw const ConstructionCorpusFailure('unknown_dependency_endpoint');
    }
    if (edge.lagValue < 0) {
      throw const ConstructionCorpusFailure('invalid_dependency_lag');
    }
    if (edge.lagUnit != ConstructionDependencyLagUnit.workingDay) {
      throw const ConstructionCorpusFailure('invalid_dependency_lag_unit');
    }
    if (edge.relationshipType !=
            ConstructionDependencyRelationshipType.finishToStart &&
        edge.relationshipType !=
            ConstructionDependencyRelationshipType.startToStart) {
      throw const ConstructionCorpusFailure(
        'invalid_dependency_relationship_type',
      );
    }
    incomingCounts[edge.successorInstanceId] =
        incomingCounts[edge.successorInstanceId]! + 1;
    incomingEdges[edge.successorInstanceId]!.add(edge);
    outgoingEdges[edge.predecessorInstanceId]!.add(edge);
  }
  for (final edges in incomingEdges.values) {
    edges.sort(_compareScheduleEdges);
  }
  for (final edges in outgoingEdges.values) {
    edges.sort(_compareScheduleEdges);
  }

  final roots =
      incomingCounts.entries
          .where((entry) => entry.value == 0)
          .map((entry) => entry.key)
          .toList()
        ..sort();
  final leaves =
      outgoingEdges.entries
          .where((entry) => entry.value.isEmpty)
          .map((entry) => entry.key)
          .toList()
        ..sort();
  final ready = [...roots];
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
  if (ordered.length != instanceIds.length) {
    throw const ConstructionCorpusFailure('resolved_graph_cycle');
  }
  return _ConstructionScheduleTopology(
    orderedInstanceIds: List.unmodifiable(ordered),
    rootInstanceIds: List.unmodifiable(roots),
    leafInstanceIds: List.unmodifiable(leaves),
    incomingEdges:
        Map<String, List<ConstructionResolvedDependencyEdge>>.unmodifiable({
          for (final entry in incomingEdges.entries)
            entry.key: List<ConstructionResolvedDependencyEdge>.unmodifiable(
              entry.value,
            ),
        }),
  );
}

int _compareScheduleEdges(
  ConstructionResolvedDependencyEdge left,
  ConstructionResolvedDependencyEdge right,
) {
  final successor = left.successorInstanceId.compareTo(
    right.successorInstanceId,
  );
  if (successor != 0) {
    return successor;
  }
  final predecessor = left.predecessorInstanceId.compareTo(
    right.predecessorInstanceId,
  );
  return predecessor != 0 ? predecessor : left.edgeKey.compareTo(right.edgeKey);
}

void _requireCanonicalUtcDate(DateTime date) {
  if (!date.isUtc ||
      date.hour != 0 ||
      date.minute != 0 ||
      date.second != 0 ||
      date.millisecond != 0 ||
      date.microsecond != 0) {
    throw const ConstructionCorpusFailure('invalid_construction_date');
  }
}

DateTime _minimumDate(Iterable<DateTime> values) {
  final iterator = values.iterator;
  if (!iterator.moveNext()) {
    throw const ConstructionCorpusFailure('empty_schedule_graph');
  }
  var result = iterator.current;
  while (iterator.moveNext()) {
    if (iterator.current.isBefore(result)) {
      result = iterator.current;
    }
  }
  return result;
}

DateTime _maximumDate(Iterable<DateTime> values) {
  final iterator = values.iterator;
  if (!iterator.moveNext()) {
    throw const ConstructionCorpusFailure('empty_schedule_graph');
  }
  var result = iterator.current;
  while (iterator.moveNext()) {
    if (iterator.current.isAfter(result)) {
      result = iterator.current;
    }
  }
  return result;
}

Map<T, int> _counts<T>(Iterable<T> values) {
  final result = <T, int>{};
  for (final value in values) {
    result[value] = (result[value] ?? 0) + 1;
  }
  return result;
}

bool _sameCounts<T>(Map<T, int> left, Map<T, int> right) {
  if (left.length != right.length) {
    return false;
  }
  return left.entries.every((entry) => right[entry.key] == entry.value);
}

void _requireSameOrderedValues(
  List<String> actual,
  List<String> expected,
  String failureCode,
) {
  if (actual.length != expected.length) {
    throw ConstructionCorpusFailure(failureCode);
  }
  for (var index = 0; index < actual.length; index += 1) {
    if (actual[index] != expected[index]) {
      throw ConstructionCorpusFailure(failureCode);
    }
  }
}

int _sundayViolationCount(
  Iterable<ConstructionScheduledActivity> activities,
  ConstructionProjectCalendar calendar,
) {
  if (calendar.workingWeekdays.contains(6)) {
    return 0;
  }
  var violations = 0;
  for (final activity in activities) {
    if (activity.durationCalendarType ==
        ConstructionActivityDurationCalendarType.workingDay) {
      if (canonicalConstructionWeekday(activity.startDate) == 6) {
        violations += 1;
      }
      if (canonicalConstructionWeekday(activity.finishDate) == 6) {
        violations += 1;
      }
    }
  }
  return violations;
}

int _holidayViolationCount(
  Iterable<ConstructionScheduledActivity> activities,
  ConstructionProjectCalendar calendar,
) {
  final holidays = calendar.holidays.toSet();
  var violations = 0;
  for (final activity in activities) {
    if (activity.durationCalendarType ==
        ConstructionActivityDurationCalendarType.workingDay) {
      if (holidays.contains(activity.startDate)) {
        violations += 1;
      }
      if (holidays.contains(activity.finishDate)) {
        violations += 1;
      }
    }
  }
  return violations;
}

int _syntheticDependencyCount(ConstructionProjectActivityGraph graph) => graph
    .dependencyEdges
    .where(
      (edge) =>
          edge.templateDependencyId ==
              ConstructionScheduleDateEngine.derivedConnectivityId ||
          edge.edgeKey.contains(
            ConstructionScheduleDateEngine.derivedConnectivityId,
          ),
    )
    .length;
