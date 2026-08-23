import 'package:chief_site_engineer/application/construction_schedule_date_engine.dart';
import 'package:chief_site_engineer/domain/construction_corpus_models.dart';
import 'package:chief_site_engineer/domain/construction_living_plan_forecast_models.dart';
import 'package:chief_site_engineer/domain/construction_living_plan_models.dart';
import 'package:chief_site_engineer/domain/construction_schedule_models.dart';

class ConstructionLivingPlanForecastEngine {
  const ConstructionLivingPlanForecastEngine();

  ConstructionLivingPlanForecast forecast({
    required ConstructionLivingPlanItem item,
    required ConstructionScheduleSnapshot exactSnapshot,
    required DateTime asOfDate,
  }) {
    _requireCanonicalUtcDate(asOfDate);
    _requireExactBinding(item, exactSnapshot);
    final activity = _exactActivity(item, exactSnapshot);
    _requireValidReference(activity, exactSnapshot);
    _requireValidProgress(item);

    final calculation = _calculationFor(
      item: item,
      activity: activity,
      snapshot: exactSnapshot,
      asOfDate: asOfDate,
    );
    final metadata = exactSnapshot.metadata;

    return ConstructionLivingPlanForecast(
      itemId: item.id,
      projectId: item.projectId,
      referenceSnapshotId: item.referenceSnapshotId,
      activityInstanceId: item.activityInstanceId,
      status: item.status,
      progressPercent: item.progressPercent,
      asOfDate: asOfDate,
      referenceStartDate: activity.startDate,
      referenceFinishDate: activity.finishDate,
      referenceDurationDays: activity.durationDays,
      referenceRoundedSchedulingDays: activity.roundedSchedulingDays,
      referenceDurationCalendarType: activity.durationCalendarType,
      referenceDurationStatus: activity.durationStatus,
      referenceDurationConfidence: activity.durationConfidence,
      referenceCorpusVersion: metadata.corpusVersion,
      referenceScheduleSeedVersion: metadata.scheduleSeedVersion,
      referenceScheduleSeedProvenance: metadata.scheduleSeedProvenance,
      referenceProductionStatus: metadata.productionStatus,
      referenceDurationSource: metadata.durationSource,
      referenceBaselineStatus: metadata.baselineStatus,
      referenceProjectionSha256: metadata.projectionSha256,
      remainingDurationDays: calculation.remainingDurationDays,
      remainingRoundedSchedulingDays:
          calculation.remainingRoundedSchedulingDays,
      forecastFinishDate: calculation.forecastFinishDate,
      varianceCalendarDays: calculation.varianceCalendarDays,
      basis: calculation.basis,
    );
  }
}

void _requireExactBinding(
  ConstructionLivingPlanItem item,
  ConstructionScheduleSnapshot snapshot,
) {
  final metadata = snapshot.metadata;
  if (item.projectId != metadata.projectId) {
    throw const ConstructionLivingPlanForecastFailure(
      'forecast_project_mismatch',
    );
  }
  if (snapshot.profile.projectId != metadata.projectId) {
    throw const ConstructionLivingPlanForecastFailure(
      'forecast_snapshot_profile_project_mismatch',
    );
  }
  if (item.referenceSnapshotId != metadata.snapshotId) {
    throw const ConstructionLivingPlanForecastFailure(
      'forecast_reference_snapshot_mismatch',
    );
  }
}

ConstructionScheduledActivity _exactActivity(
  ConstructionLivingPlanItem item,
  ConstructionScheduleSnapshot snapshot,
) {
  final matches = snapshot.activities
      .where((activity) => activity.instanceId == item.activityInstanceId)
      .toList(growable: false);
  if (matches.isEmpty) {
    throw const ConstructionLivingPlanForecastFailure(
      'forecast_activity_instance_missing',
    );
  }
  if (matches.length != 1) {
    throw const ConstructionLivingPlanForecastFailure(
      'forecast_activity_instance_duplicate',
    );
  }
  final activity = matches.single;
  if (activity.activityId != item.activityId) {
    throw const ConstructionLivingPlanForecastFailure(
      'forecast_activity_id_mismatch',
    );
  }
  return activity;
}

void _requireValidReference(
  ConstructionScheduledActivity activity,
  ConstructionScheduleSnapshot snapshot,
) {
  final metadata = snapshot.metadata;
  final provenance = <String>[
    metadata.snapshotId,
    metadata.corpusVersion,
    metadata.scheduleSeedVersion,
    metadata.scheduleSeedProvenance,
    metadata.productionStatus,
    metadata.durationSource,
    metadata.baselineStatus,
    metadata.projectionSha256,
  ];
  if (provenance.any((value) => value.isEmpty || value.trim() != value)) {
    throw const ConstructionLivingPlanForecastFailure(
      'forecast_invalid_reference_provenance',
    );
  }
  if (!activity.durationDays.isFinite || activity.durationDays < 0) {
    throw const ConstructionLivingPlanForecastFailure(
      'forecast_invalid_reference_duration',
    );
  }
  final expectedRounded = activity.durationDays.ceil();
  if (activity.roundedSchedulingDays != expectedRounded ||
      activity.isMilestone != (expectedRounded == 0)) {
    throw const ConstructionLivingPlanForecastFailure(
      'forecast_invalid_reference_duration',
    );
  }
  _requireCanonicalReferenceDate(activity.startDate);
  _requireCanonicalReferenceDate(activity.finishDate);
  _requireValidCalendar(snapshot.profile.calendar);
  try {
    final expectedFinish = constructionDurationFinishDate(
      startDate: activity.startDate,
      roundedSchedulingDays: activity.roundedSchedulingDays,
      calendarType: activity.durationCalendarType,
      calendar: snapshot.profile.calendar,
    );
    if (expectedFinish != activity.finishDate) {
      throw const ConstructionLivingPlanForecastFailure(
        'forecast_invalid_reference_calendar',
      );
    }
  } on ConstructionLivingPlanForecastFailure {
    rethrow;
  } on ConstructionCorpusFailure {
    throw const ConstructionLivingPlanForecastFailure(
      'forecast_invalid_reference_calendar',
    );
  }
}

void _requireValidCalendar(ConstructionProjectCalendar calendar) {
  _requireCanonicalReferenceDate(calendar.startDate);
  if (calendar.workingWeekdays.isEmpty ||
      calendar.workingWeekdays.toSet().length !=
          calendar.workingWeekdays.length ||
      calendar.workingWeekdays.any((weekday) => weekday < 0 || weekday > 6) ||
      !calendar.workdayHours.isFinite ||
      calendar.workdayHours <= 0 ||
      calendar.workdayHours > 24) {
    throw const ConstructionLivingPlanForecastFailure(
      'forecast_invalid_reference_calendar',
    );
  }
  final holidays = <DateTime>{};
  for (final holiday in calendar.holidays) {
    _requireCanonicalReferenceDate(holiday);
    if (!holidays.add(holiday)) {
      throw const ConstructionLivingPlanForecastFailure(
        'forecast_invalid_reference_calendar',
      );
    }
  }
}

void _requireValidProgress(ConstructionLivingPlanItem item) {
  final progress = item.progressPercent;
  if (progress != null && (progress < 0 || progress > 100)) {
    throw const ConstructionLivingPlanForecastFailure(
      'forecast_invalid_progress',
    );
  }
  if (item.status == ConstructionLivingPlanStatus.completed) {
    if (progress != 100) {
      throw const ConstructionLivingPlanForecastFailure(
        'forecast_invalid_progress',
      );
    }
    return;
  }
  if (progress == 100) {
    throw const ConstructionLivingPlanForecastFailure(
      'forecast_invalid_progress',
    );
  }
}

_ForecastCalculation _calculationFor({
  required ConstructionLivingPlanItem item,
  required ConstructionScheduledActivity activity,
  required ConstructionScheduleSnapshot snapshot,
  required DateTime asOfDate,
}) {
  switch (item.status) {
    case ConstructionLivingPlanStatus.planned:
      return const _ForecastCalculation(
        basis: ConstructionLivingPlanForecastBasis.plannedNotStarted,
      );
    case ConstructionLivingPlanStatus.started:
      final progress = item.progressPercent;
      if (progress == null) {
        return const _ForecastCalculation(
          basis: ConstructionLivingPlanForecastBasis.startedProgressUnknown,
        );
      }
      final remaining = _remaining(activity.durationDays, progress);
      DateTime forecastFinish;
      try {
        forecastFinish = constructionDurationFinishDate(
          startDate: asOfDate,
          roundedSchedulingDays: remaining.roundedSchedulingDays,
          calendarType: activity.durationCalendarType,
          calendar: snapshot.profile.calendar,
        );
      } on ConstructionCorpusFailure {
        throw const ConstructionLivingPlanForecastFailure(
          'forecast_invalid_as_of_calendar',
        );
      }
      return _ForecastCalculation(
        basis: ConstructionLivingPlanForecastBasis.startedReferenceRemaining,
        remainingDurationDays: remaining.durationDays,
        remainingRoundedSchedulingDays: remaining.roundedSchedulingDays,
        forecastFinishDate: forecastFinish,
        varianceCalendarDays: forecastFinish
            .difference(activity.finishDate)
            .inDays,
      );
    case ConstructionLivingPlanStatus.deferred:
      final progress = item.progressPercent;
      final remaining = progress == null
          ? null
          : _remaining(activity.durationDays, progress);
      return _ForecastCalculation(
        basis: ConstructionLivingPlanForecastBasis.deferredPaused,
        remainingDurationDays: remaining?.durationDays,
        remainingRoundedSchedulingDays: remaining?.roundedSchedulingDays,
      );
    case ConstructionLivingPlanStatus.completed:
      return const _ForecastCalculation(
        basis: ConstructionLivingPlanForecastBasis.completed,
      );
  }
}

_RemainingDuration _remaining(double referenceDurationDays, int progress) {
  final remainingFraction = (100 - progress) / 100;
  final remainingDurationDays = referenceDurationDays * remainingFraction;
  if (!remainingDurationDays.isFinite || remainingDurationDays < 0) {
    throw const ConstructionLivingPlanForecastFailure(
      'forecast_invalid_reference_duration',
    );
  }
  final roundedSchedulingDays = referenceDurationDays == 0
      ? 0
      : remainingDurationDays.ceil();
  return _RemainingDuration(
    durationDays: remainingDurationDays,
    roundedSchedulingDays: roundedSchedulingDays,
  );
}

void _requireCanonicalUtcDate(DateTime value) {
  if (!_isCanonicalUtcDate(value)) {
    throw const ConstructionLivingPlanForecastFailure(
      'forecast_as_of_date_not_canonical',
    );
  }
}

void _requireCanonicalReferenceDate(DateTime value) {
  if (!_isCanonicalUtcDate(value)) {
    throw const ConstructionLivingPlanForecastFailure(
      'forecast_invalid_reference_calendar',
    );
  }
}

bool _isCanonicalUtcDate(DateTime value) =>
    value.isUtc &&
    value.hour == 0 &&
    value.minute == 0 &&
    value.second == 0 &&
    value.millisecond == 0 &&
    value.microsecond == 0;

class _RemainingDuration {
  const _RemainingDuration({
    required this.durationDays,
    required this.roundedSchedulingDays,
  });

  final double durationDays;
  final int roundedSchedulingDays;
}

class _ForecastCalculation {
  const _ForecastCalculation({
    required this.basis,
    this.remainingDurationDays,
    this.remainingRoundedSchedulingDays,
    this.forecastFinishDate,
    this.varianceCalendarDays,
  });

  final ConstructionLivingPlanForecastBasis basis;
  final double? remainingDurationDays;
  final int? remainingRoundedSchedulingDays;
  final DateTime? forecastFinishDate;
  final int? varianceCalendarDays;
}
