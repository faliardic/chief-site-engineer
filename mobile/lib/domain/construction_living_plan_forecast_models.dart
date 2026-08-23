import 'package:chief_site_engineer/domain/construction_living_plan_models.dart';
import 'package:chief_site_engineer/domain/construction_schedule_models.dart';

enum ConstructionLivingPlanForecastBasis {
  plannedNotStarted('PLANNED_NOT_STARTED'),
  startedProgressUnknown('STARTED_PROGRESS_UNKNOWN'),
  startedReferenceRemaining('STARTED_REFERENCE_REMAINING'),
  deferredPaused('DEFERRED_PAUSED'),
  completed('COMPLETED');

  const ConstructionLivingPlanForecastBasis(this.contractValue);

  final String contractValue;
}

class ConstructionLivingPlanForecast {
  const ConstructionLivingPlanForecast({
    required this.itemId,
    required this.projectId,
    required this.referenceSnapshotId,
    required this.activityInstanceId,
    required this.status,
    required this.progressPercent,
    required this.asOfDate,
    required this.referenceStartDate,
    required this.referenceFinishDate,
    required this.referenceDurationDays,
    required this.referenceRoundedSchedulingDays,
    required this.referenceDurationCalendarType,
    required this.referenceDurationStatus,
    required this.referenceDurationConfidence,
    required this.referenceCorpusVersion,
    required this.referenceScheduleSeedVersion,
    required this.referenceScheduleSeedProvenance,
    required this.referenceProductionStatus,
    required this.referenceDurationSource,
    required this.referenceBaselineStatus,
    required this.referenceProjectionSha256,
    required this.remainingDurationDays,
    required this.remainingRoundedSchedulingDays,
    required this.forecastFinishDate,
    required this.varianceCalendarDays,
    required this.basis,
  });

  final String itemId;
  final String projectId;
  final String referenceSnapshotId;
  final String activityInstanceId;
  final ConstructionLivingPlanStatus status;
  final int? progressPercent;
  final DateTime asOfDate;
  final DateTime referenceStartDate;
  final DateTime referenceFinishDate;
  final double referenceDurationDays;
  final int referenceRoundedSchedulingDays;
  final ConstructionActivityDurationCalendarType referenceDurationCalendarType;
  final ConstructionScheduleDurationStatus referenceDurationStatus;
  final ConstructionScheduleDurationConfidence referenceDurationConfidence;
  final String referenceCorpusVersion;
  final String referenceScheduleSeedVersion;
  final String referenceScheduleSeedProvenance;
  final String referenceProductionStatus;
  final String referenceDurationSource;
  final String referenceBaselineStatus;
  final String referenceProjectionSha256;
  final double? remainingDurationDays;
  final int? remainingRoundedSchedulingDays;
  final DateTime? forecastFinishDate;
  final int? varianceCalendarDays;
  final ConstructionLivingPlanForecastBasis basis;
}

class ConstructionLivingPlanForecastFailure implements Exception {
  const ConstructionLivingPlanForecastFailure(this.code);

  final String code;

  @override
  String toString() => 'ConstructionLivingPlanForecastFailure($code)';
}
