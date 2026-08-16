import 'package:chief_site_engineer/domain/construction_corpus_models.dart';

enum ConstructionActivityDurationCalendarType {
  workingDay('WORKING_DAY'),
  calendarDay('CALENDAR_DAY');

  const ConstructionActivityDurationCalendarType(this.jsonValue);

  final String jsonValue;

  static ConstructionActivityDurationCalendarType fromJson(Object? value) {
    for (final item in values) {
      if (item.jsonValue == value) {
        return item;
      }
    }
    throw const ConstructionCorpusFailure('invalid_duration_calendar_type');
  }
}

enum ConstructionScheduleDurationStatus {
  sourceBacked('SOURCE_BACKED'),
  aiSeedEstimate('AI_SEED_ESTIMATE'),
  unknown('UNKNOWN');

  const ConstructionScheduleDurationStatus(this.jsonValue);

  final String jsonValue;

  static ConstructionScheduleDurationStatus fromJson(Object? value) {
    for (final item in values) {
      if (item.jsonValue == value) {
        return item;
      }
    }
    throw const ConstructionCorpusFailure('invalid_schedule_duration_status');
  }
}

enum ConstructionScheduleDurationConfidence {
  authoritative('A_AUTHORITATIVE'),
  aiSeed('D_AI_SEED'),
  unknown('E_UNKNOWN');

  const ConstructionScheduleDurationConfidence(this.jsonValue);

  final String jsonValue;

  static ConstructionScheduleDurationConfidence fromJson(Object? value) {
    for (final item in values) {
      if (item.jsonValue == value) {
        return item;
      }
    }
    throw const ConstructionCorpusFailure(
      'invalid_schedule_duration_confidence',
    );
  }
}

class ConstructionScheduleSeed {
  ConstructionScheduleSeed({
    required this.activityId,
    required this.durationDays,
    required this.durationCalendarType,
    required this.durationStatus,
    required this.durationConfidence,
  }) {
    if (activityId.isEmpty) {
      throw const ConstructionCorpusFailure('invalid_schedule_seed_activity');
    }
    if (!durationDays.isFinite || durationDays < 0) {
      throw const ConstructionCorpusFailure('invalid_schedule_seed_duration');
    }
  }

  final String activityId;
  final double durationDays;
  final ConstructionActivityDurationCalendarType durationCalendarType;
  final ConstructionScheduleDurationStatus durationStatus;
  final ConstructionScheduleDurationConfidence durationConfidence;

  int get roundedSchedulingDays => durationDays.ceil();

  bool get isMilestone => roundedSchedulingDays == 0;
}

class ConstructionScheduleSeedCatalogMetadata {
  const ConstructionScheduleSeedCatalogMetadata({
    required this.name,
    required this.corpusVersion,
    required this.sourcePublicationStatus,
    required this.sourceProductionStatus,
    required this.sourceZipSha256,
    required this.warning,
    required this.runtimeScope,
    required this.activityCount,
    required this.workingDayCount,
    required this.calendarDayCount,
    required this.milestoneCount,
    required this.authoritativeCount,
    required this.aiSeedCount,
    required this.unknownConfidenceCount,
    required this.sourceBackedCount,
    required this.aiSeedEstimateCount,
    required this.unknownStatusCount,
  });

  final String name;
  final String corpusVersion;
  final String sourcePublicationStatus;
  final String sourceProductionStatus;
  final String sourceZipSha256;
  final String warning;
  final String runtimeScope;
  final int activityCount;
  final int workingDayCount;
  final int calendarDayCount;
  final int milestoneCount;
  final int authoritativeCount;
  final int aiSeedCount;
  final int unknownConfidenceCount;
  final int sourceBackedCount;
  final int aiSeedEstimateCount;
  final int unknownStatusCount;
}

class ConstructionScheduleSeedCatalog {
  ConstructionScheduleSeedCatalog({
    required this.metadata,
    required Iterable<ConstructionScheduleSeed> seeds,
  }) : seeds = List.unmodifiable(seeds) {
    final index = <String, ConstructionScheduleSeed>{};
    for (final seed in this.seeds) {
      if (index.containsKey(seed.activityId)) {
        throw const ConstructionCorpusFailure('duplicate_schedule_seed');
      }
      index[seed.activityId] = seed;
    }
    seedsByActivityId = Map.unmodifiable(index);
  }

  final ConstructionScheduleSeedCatalogMetadata metadata;
  final List<ConstructionScheduleSeed> seeds;
  late final Map<String, ConstructionScheduleSeed> seedsByActivityId;
}

class ConstructionScheduledActivity {
  const ConstructionScheduledActivity({
    required this.instanceId,
    required this.activityId,
    required this.startDate,
    required this.finishDate,
    required this.durationDays,
    required this.roundedSchedulingDays,
    required this.durationCalendarType,
    required this.durationStatus,
    required this.durationConfidence,
    required this.isMilestone,
    required this.isIsolated,
  });

  final String instanceId;
  final String activityId;
  final DateTime startDate;
  final DateTime finishDate;
  final double durationDays;
  final int roundedSchedulingDays;
  final ConstructionActivityDurationCalendarType durationCalendarType;
  final ConstructionScheduleDurationStatus durationStatus;
  final ConstructionScheduleDurationConfidence durationConfidence;
  final bool isMilestone;
  final bool isIsolated;

  ConstructionScheduledActivity copyWith({
    DateTime? startDate,
    DateTime? finishDate,
  }) => ConstructionScheduledActivity(
    instanceId: instanceId,
    activityId: activityId,
    startDate: startDate ?? this.startDate,
    finishDate: finishDate ?? this.finishDate,
    durationDays: durationDays,
    roundedSchedulingDays: roundedSchedulingDays,
    durationCalendarType: durationCalendarType,
    durationStatus: durationStatus,
    durationConfidence: durationConfidence,
    isMilestone: isMilestone,
    isIsolated: isIsolated,
  );
}

class ConstructionProjectReferenceSchedule {
  ConstructionProjectReferenceSchedule({
    required this.projectId,
    required this.corpusVersion,
    required this.scheduleSeedVersion,
    required this.scheduleSeedProvenance,
    required this.productionStatus,
    required this.durationSource,
    required this.baselineStatus,
    required Iterable<ConstructionScheduledActivity> scheduledActivities,
    required Iterable<String> rootInstanceIds,
    required Iterable<String> leafInstanceIds,
    required Iterable<String> isolatedInstanceIds,
    required this.scheduleStart,
    required this.scheduleFinish,
    required Map<ConstructionScheduleDurationConfidence, int>
    confidenceInstanceCounts,
    required Map<ConstructionScheduleDurationStatus, int> statusInstanceCounts,
    required Map<ConstructionActivityDurationCalendarType, int>
    calendarTypeInstanceCounts,
    required this.milestoneInstanceCount,
    required this.workdaySundayViolations,
    required this.workdayHolidayViolations,
    required this.syntheticDependencyCount,
  }) : scheduledActivities = List.unmodifiable(scheduledActivities),
       rootInstanceIds = List.unmodifiable(rootInstanceIds),
       leafInstanceIds = List.unmodifiable(leafInstanceIds),
       isolatedInstanceIds = List.unmodifiable(isolatedInstanceIds),
       confidenceInstanceCounts = Map.unmodifiable(confidenceInstanceCounts),
       statusInstanceCounts = Map.unmodifiable(statusInstanceCounts),
       calendarTypeInstanceCounts = Map.unmodifiable(
         calendarTypeInstanceCounts,
       );

  final String projectId;
  final String corpusVersion;
  final String scheduleSeedVersion;
  final String scheduleSeedProvenance;
  final String productionStatus;
  final String durationSource;
  final String baselineStatus;
  final List<ConstructionScheduledActivity> scheduledActivities;
  final List<String> rootInstanceIds;
  final List<String> leafInstanceIds;
  final List<String> isolatedInstanceIds;
  final DateTime scheduleStart;
  final DateTime scheduleFinish;
  final Map<ConstructionScheduleDurationConfidence, int>
  confidenceInstanceCounts;
  final Map<ConstructionScheduleDurationStatus, int> statusInstanceCounts;
  final Map<ConstructionActivityDurationCalendarType, int>
  calendarTypeInstanceCounts;
  final int milestoneInstanceCount;
  final int workdaySundayViolations;
  final int workdayHolidayViolations;
  final int syntheticDependencyCount;

  ConstructionProjectReferenceSchedule copyWith({
    Iterable<ConstructionScheduledActivity>? scheduledActivities,
  }) => ConstructionProjectReferenceSchedule(
    projectId: projectId,
    corpusVersion: corpusVersion,
    scheduleSeedVersion: scheduleSeedVersion,
    scheduleSeedProvenance: scheduleSeedProvenance,
    productionStatus: productionStatus,
    durationSource: durationSource,
    baselineStatus: baselineStatus,
    scheduledActivities: scheduledActivities ?? this.scheduledActivities,
    rootInstanceIds: rootInstanceIds,
    leafInstanceIds: leafInstanceIds,
    isolatedInstanceIds: isolatedInstanceIds,
    scheduleStart: scheduleStart,
    scheduleFinish: scheduleFinish,
    confidenceInstanceCounts: confidenceInstanceCounts,
    statusInstanceCounts: statusInstanceCounts,
    calendarTypeInstanceCounts: calendarTypeInstanceCounts,
    milestoneInstanceCount: milestoneInstanceCount,
    workdaySundayViolations: workdaySundayViolations,
    workdayHolidayViolations: workdayHolidayViolations,
    syntheticDependencyCount: syntheticDependencyCount,
  );
}

class ConstructionScheduleSnapshotFailure implements Exception {
  const ConstructionScheduleSnapshotFailure(this.code);

  final String code;

  @override
  String toString() => 'ConstructionScheduleSnapshotFailure($code)';
}

class ConstructionScheduleSnapshotMetadata {
  const ConstructionScheduleSnapshotMetadata({
    required this.snapshotId,
    required this.projectId,
    required this.corpusVersion,
    required this.scheduleSeedVersion,
    required this.scheduleSeedProvenance,
    required this.productionStatus,
    required this.durationSource,
    required this.baselineStatus,
    required this.scheduleStart,
    required this.scheduleFinish,
    required this.activityCount,
    required this.rootCount,
    required this.leafCount,
    required this.isolatedCount,
    required this.milestoneCount,
    required this.projectionSha256,
    required this.generatedAt,
    required this.supersededAt,
  });

  final String snapshotId;
  final String projectId;
  final String corpusVersion;
  final String scheduleSeedVersion;
  final String scheduleSeedProvenance;
  final String productionStatus;
  final String durationSource;
  final String baselineStatus;
  final DateTime scheduleStart;
  final DateTime scheduleFinish;
  final int activityCount;
  final int rootCount;
  final int leafCount;
  final int isolatedCount;
  final int milestoneCount;
  final String projectionSha256;
  final DateTime generatedAt;
  final DateTime? supersededAt;

  bool get isCurrent => supersededAt == null;
}

class ConstructionScheduleSnapshot {
  ConstructionScheduleSnapshot({
    required this.metadata,
    required this.profile,
    required Iterable<ConstructionScheduledActivity> activities,
  }) : activities = List.unmodifiable(activities);

  final ConstructionScheduleSnapshotMetadata metadata;
  final ConstructionProjectProfile profile;
  final List<ConstructionScheduledActivity> activities;
}
