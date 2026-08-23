import 'package:chief_site_engineer/application/construction_living_plan_forecast.dart';
import 'package:chief_site_engineer/application/construction_schedule_date_engine.dart';
import 'package:chief_site_engineer/domain/construction_corpus_models.dart';
import 'package:chief_site_engineer/domain/construction_living_plan_forecast_models.dart';
import 'package:chief_site_engineer/domain/construction_living_plan_models.dart';
import 'package:chief_site_engineer/domain/construction_project_graph_models.dart';
import 'package:chief_site_engineer/domain/construction_schedule_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/construction_profile_fixtures.dart';

void main() {
  const engine = ConstructionLivingPlanForecastEngine();

  group('exact source binding', () {
    test('uses the exact bound snapshot activity and preserves provenance', () {
      final snapshot = _snapshot();
      final item = _item();

      final forecast = engine.forecast(
        item: item,
        exactSnapshot: snapshot,
        asOfDate: _date('2026-08-24'),
      );

      expect(forecast.itemId, item.id);
      expect(forecast.projectId, 'PRJ-A');
      expect(forecast.referenceSnapshotId, 'snapshot-a');
      expect(forecast.activityInstanceId, 'activity-a@PRJ-A');
      expect(forecast.referenceStartDate, _date('2026-08-24'));
      expect(forecast.referenceFinishDate, _date('2026-09-03'));
      expect(forecast.referenceDurationDays, 10);
      expect(forecast.referenceRoundedSchedulingDays, 10);
      expect(
        forecast.referenceDurationCalendarType,
        ConstructionActivityDurationCalendarType.workingDay,
      );
      expect(
        forecast.referenceDurationStatus,
        ConstructionScheduleDurationStatus.aiSeedEstimate,
      );
      expect(
        forecast.referenceDurationConfidence,
        ConstructionScheduleDurationConfidence.aiSeed,
      );
      expect(forecast.referenceCorpusVersion, 'corpus-a');
      expect(forecast.referenceScheduleSeedVersion, 'seed-a');
      expect(forecast.referenceScheduleSeedProvenance, 'seed-provenance-a');
      expect(forecast.referenceProductionStatus, 'NOT_FOR_PRODUCTION');
      expect(forecast.referenceDurationSource, 'TEST_SEED_ONLY');
      expect(forecast.referenceBaselineStatus, 'NOT_A_BASELINE');
      expect(forecast.referenceProjectionSha256, 'projection-a');
    });

    test('rejects a project mismatch', () {
      expect(
        () => engine.forecast(
          item: _item(projectId: 'PRJ-B'),
          exactSnapshot: _snapshot(),
          asOfDate: _date('2026-08-24'),
        ),
        _throwsForecastFailure('forecast_project_mismatch'),
      );
    });

    test('rejects a snapshot mismatch instead of using a newer snapshot', () {
      final newerSnapshot = _snapshot(snapshotId: 'snapshot-b');
      final historicalSnapshot = _snapshot();
      final item = _item();

      expect(
        () => engine.forecast(
          item: item,
          exactSnapshot: newerSnapshot,
          asOfDate: _date('2026-08-24'),
        ),
        _throwsForecastFailure('forecast_reference_snapshot_mismatch'),
      );
      expect(
        engine
            .forecast(
              item: item,
              exactSnapshot: historicalSnapshot,
              asOfDate: _date('2026-08-24'),
            )
            .referenceSnapshotId,
        'snapshot-a',
      );
    });

    test('rejects a snapshot profile project mismatch', () {
      expect(
        () => engine.forecast(
          item: _item(),
          exactSnapshot: _snapshot(profileProjectId: 'PRJ-B'),
          asOfDate: _date('2026-08-24'),
        ),
        _throwsForecastFailure('forecast_snapshot_profile_project_mismatch'),
      );
    });

    test('rejects a missing activity instance', () {
      expect(
        () => engine.forecast(
          item: _item(activityInstanceId: 'missing@PRJ-A'),
          exactSnapshot: _snapshot(),
          asOfDate: _date('2026-08-24'),
        ),
        _throwsForecastFailure('forecast_activity_instance_missing'),
      );
    });

    test('rejects an activity id mismatch', () {
      expect(
        () => engine.forecast(
          item: _item(activityId: 'activity-b'),
          exactSnapshot: _snapshot(),
          asOfDate: _date('2026-08-24'),
        ),
        _throwsForecastFailure('forecast_activity_id_mismatch'),
      );
    });

    test('rejects duplicate activity instances', () {
      final activity = _activity();
      expect(
        () => engine.forecast(
          item: _item(),
          exactSnapshot: _snapshot(activities: [activity, activity]),
          asOfDate: _date('2026-08-24'),
        ),
        _throwsForecastFailure('forecast_activity_instance_duplicate'),
      );
    });
  });

  group('status basis', () {
    test('PLANNED keeps reference context without a forecast', () {
      final result = engine.forecast(
        item: _item(
          status: ConstructionLivingPlanStatus.planned,
          progressPercent: null,
        ),
        exactSnapshot: _snapshot(),
        asOfDate: _date('2026-08-24'),
      );

      _expectNoForecast(result);
      expect(
        result.basis,
        ConstructionLivingPlanForecastBasis.plannedNotStarted,
      );
    });

    test('STARTED with unknown progress does not invent a forecast', () {
      final result = engine.forecast(
        item: _item(progressPercent: null),
        exactSnapshot: _snapshot(),
        asOfDate: _date('2026-08-24'),
      );

      _expectNoForecast(result);
      expect(
        result.basis,
        ConstructionLivingPlanForecastBasis.startedProgressUnknown,
      );
    });

    test('DEFERRED exposes remaining duration but remains paused', () {
      final result = engine.forecast(
        item: _item(
          status: ConstructionLivingPlanStatus.deferred,
          progressPercent: 40,
        ),
        exactSnapshot: _snapshot(),
        asOfDate: _date('2026-08-24'),
      );

      expect(result.remainingDurationDays, 6);
      expect(result.remainingRoundedSchedulingDays, 6);
      expect(result.forecastFinishDate, isNull);
      expect(result.varianceCalendarDays, isNull);
      expect(result.basis, ConstructionLivingPlanForecastBasis.deferredPaused);
    });

    test('COMPLETED does not produce a future forecast', () {
      final result = engine.forecast(
        item: _item(
          status: ConstructionLivingPlanStatus.completed,
          progressPercent: 100,
        ),
        exactSnapshot: _snapshot(),
        asOfDate: _date('2026-08-24'),
      );

      _expectNoForecast(result);
      expect(result.basis, ConstructionLivingPlanForecastBasis.completed);
    });
  });

  group('started progress calculation', () {
    test('progress 0 keeps the full reference duration', () {
      final result = _forecast(progressPercent: 0);

      expect(result.remainingDurationDays, 10);
      expect(result.remainingRoundedSchedulingDays, 10);
      expect(result.forecastFinishDate, _date('2026-09-03'));
    });

    test('progress 47 calculates and rounds the remaining fraction', () {
      final result = _forecast(progressPercent: 47);

      expect(result.remainingDurationDays, closeTo(5.3, 0.0000001));
      expect(result.remainingRoundedSchedulingDays, 6);
      expect(result.forecastFinishDate, _date('2026-08-29'));
      expect(
        result.basis,
        ConstructionLivingPlanForecastBasis.startedReferenceRemaining,
      );
    });

    test('progress 99 keeps one scheduling day for a non-milestone', () {
      final result = _forecast(progressPercent: 99);

      expect(result.remainingDurationDays, closeTo(0.1, 0.0000001));
      expect(result.remainingRoundedSchedulingDays, 1);
      expect(result.forecastFinishDate, _date('2026-08-24'));
    });

    test('fractional duration uses ceil after applying progress', () {
      final snapshot = _snapshot(durationDays: 3.5);
      final result = engine.forecast(
        item: _item(progressPercent: 47),
        exactSnapshot: snapshot,
        asOfDate: _date('2026-08-24'),
      );

      expect(result.remainingDurationDays, closeTo(1.855, 0.0000001));
      expect(result.remainingRoundedSchedulingDays, 2);
      expect(result.forecastFinishDate, _date('2026-08-25'));
    });

    test('zero-duration milestone has zero remaining days', () {
      final snapshot = _snapshot(durationDays: 0);
      final result = engine.forecast(
        item: _item(progressPercent: 0),
        exactSnapshot: snapshot,
        asOfDate: _date('2026-08-24'),
      );

      expect(result.remainingDurationDays, 0);
      expect(result.remainingRoundedSchedulingDays, 0);
      expect(result.forecastFinishDate, _date('2026-08-24'));
    });

    test('invalid open progress values fail closed', () {
      for (final progress in [-1, 100, 101]) {
        expect(
          () => engine.forecast(
            item: _item(progressPercent: progress),
            exactSnapshot: _snapshot(),
            asOfDate: _date('2026-08-24'),
          ),
          _throwsForecastFailure('forecast_invalid_progress'),
          reason: 'progress=$progress',
        );
      }
    });
  });

  group('construction calendar behavior', () {
    test('working-day forecast skips Sunday and a configured holiday', () {
      final snapshot = _snapshot(
        durationDays: 10,
        holidays: const ['2026-08-31'],
      );
      final result = engine.forecast(
        item: _item(progressPercent: 60),
        exactSnapshot: snapshot,
        asOfDate: _date('2026-08-28'),
      );

      expect(result.remainingRoundedSchedulingDays, 4);
      expect(result.forecastFinishDate, _date('2026-09-02'));
    });

    test('calendar-day forecast includes Sunday and configured holiday', () {
      final snapshot = _snapshot(
        durationDays: 10,
        calendarType: ConstructionActivityDurationCalendarType.calendarDay,
        holidays: const ['2026-08-31'],
      );
      final result = engine.forecast(
        item: _item(progressPercent: 60),
        exactSnapshot: snapshot,
        asOfDate: _date('2026-08-28'),
      );

      expect(result.remainingRoundedSchedulingDays, 4);
      expect(result.forecastFinishDate, _date('2026-08-31'));
    });

    test('requires caller-supplied canonical UTC-midnight asOfDate', () {
      for (final invalid in [
        DateTime(2026, 8, 24),
        DateTime.utc(2026, 8, 24, 1),
      ]) {
        expect(
          () => engine.forecast(
            item: _item(),
            exactSnapshot: _snapshot(),
            asOfDate: invalid,
          ),
          _throwsForecastFailure('forecast_as_of_date_not_canonical'),
        );
      }
    });

    test('maps a non-workday working-duration asOf to typed failure', () {
      expect(
        () => engine.forecast(
          item: _item(progressPercent: 40),
          exactSnapshot: _snapshot(),
          asOfDate: _date('2026-08-30'),
        ),
        _throwsForecastFailure('forecast_invalid_as_of_calendar'),
      );
    });
  });

  test('variance is a signed calendar-day comparison', () {
    final negative = _forecast(
      progressPercent: 50,
      asOfDate: _date('2026-08-24'),
    );
    final zero = _forecast(progressPercent: 50, asOfDate: _date('2026-08-29'));
    final positive = _forecast(
      progressPercent: 50,
      asOfDate: _date('2026-08-31'),
    );

    expect(negative.varianceCalendarDays, -6);
    expect(zero.varianceCalendarDays, 0);
    expect(positive.varianceCalendarDays, 1);
  });

  test('same input is deterministic and input objects are not mutated', () {
    final snapshot = _snapshot();
    final item = _item(progressPercent: 47);
    final originalActivities = List<ConstructionScheduledActivity>.of(
      snapshot.activities,
    );
    final originalCalendarHolidays = List<DateTime>.of(
      snapshot.profile.calendar.holidays,
    );

    final first = engine.forecast(
      item: item,
      exactSnapshot: snapshot,
      asOfDate: _date('2026-08-24'),
    );
    final second = engine.forecast(
      item: item,
      exactSnapshot: snapshot,
      asOfDate: _date('2026-08-24'),
    );

    expect(_projection(second), _projection(first));
    expect(snapshot.activities, orderedEquals(originalActivities));
    expect(
      snapshot.profile.calendar.holidays,
      orderedEquals(originalCalendarHolidays),
    );
    expect(item.progressPercent, 47);
    expect(item.revision, 7);
  });

  test('invalid reference duration and provenance fail closed', () {
    expect(
      () => engine.forecast(
        item: _item(),
        exactSnapshot: _snapshot(durationDays: -1),
        asOfDate: _date('2026-08-24'),
      ),
      _throwsForecastFailure('forecast_invalid_reference_duration'),
    );
    expect(
      () => engine.forecast(
        item: _item(),
        exactSnapshot: _snapshot(durationSource: ''),
        asOfDate: _date('2026-08-24'),
      ),
      _throwsForecastFailure('forecast_invalid_reference_provenance'),
    );
  });
}

ConstructionLivingPlanForecast _forecast({
  required int progressPercent,
  DateTime? asOfDate,
}) => const ConstructionLivingPlanForecastEngine().forecast(
  item: _item(progressPercent: progressPercent),
  exactSnapshot: _snapshot(),
  asOfDate: asOfDate ?? _date('2026-08-24'),
);

ConstructionLivingPlanItem _item({
  String projectId = 'PRJ-A',
  String referenceSnapshotId = 'snapshot-a',
  String activityInstanceId = 'activity-a@PRJ-A',
  String activityId = 'activity-a',
  ConstructionLivingPlanStatus status = ConstructionLivingPlanStatus.started,
  int? progressPercent = 40,
}) => ConstructionLivingPlanItem(
  id: 'item-a',
  projectId: projectId,
  referenceSnapshotId: referenceSnapshotId,
  activityInstanceId: activityInstanceId,
  activityId: activityId,
  activityNameSnapshot: 'Activity A',
  activityContext: const ConstructionProjectActivityContext(),
  naturalUnitSnapshot: 'day',
  plannedDate: _date('2026-08-24'),
  status: status,
  progressPercent: progressPercent,
  note: null,
  revision: 7,
  createdAt: DateTime.utc(2026, 8, 20, 9),
  updatedAt: DateTime.utc(2026, 8, 23, 9),
  statusChangedAt: DateTime.utc(2026, 8, 21, 9),
);

ConstructionScheduleSnapshot _snapshot({
  String snapshotId = 'snapshot-a',
  String projectId = 'PRJ-A',
  String? profileProjectId,
  double durationDays = 10,
  ConstructionActivityDurationCalendarType calendarType =
      ConstructionActivityDurationCalendarType.workingDay,
  List<String> holidays = const [],
  String durationSource = 'TEST_SEED_ONLY',
  List<ConstructionScheduledActivity>? activities,
}) {
  final profile = validConstructionProjectProfile(
    overrides: {
      'project_id': profileProjectId ?? projectId,
      'calendar': <String, Object?>{
        'start_date': '2026-08-24',
        'working_weekdays': <Object?>[0, 1, 2, 3, 4, 5],
        'holidays': <Object?>[...holidays],
        'workday_hours': 8,
      },
    },
  );
  final activity = _activity(
    durationDays: durationDays,
    calendarType: calendarType,
    calendar: profile.calendar,
  );
  final scheduled = activities ?? [activity];
  return ConstructionScheduleSnapshot(
    metadata: ConstructionScheduleSnapshotMetadata(
      snapshotId: snapshotId,
      projectId: projectId,
      corpusVersion: 'corpus-a',
      scheduleSeedVersion: 'seed-a',
      scheduleSeedProvenance: 'seed-provenance-a',
      productionStatus: 'NOT_FOR_PRODUCTION',
      durationSource: durationSource,
      baselineStatus: 'NOT_A_BASELINE',
      scheduleStart: activity.startDate,
      scheduleFinish: activity.finishDate,
      activityCount: scheduled.length,
      rootCount: 1,
      leafCount: 1,
      isolatedCount: 1,
      milestoneCount: durationDays == 0 ? 1 : 0,
      projectionSha256: 'projection-a',
      generatedAt: DateTime.utc(2026, 8, 20, 9),
      supersededAt: null,
    ),
    profile: profile,
    activities: scheduled,
  );
}

ConstructionScheduledActivity _activity({
  double durationDays = 10,
  ConstructionActivityDurationCalendarType calendarType =
      ConstructionActivityDurationCalendarType.workingDay,
  ConstructionProjectCalendar? calendar,
}) {
  final effectiveCalendar =
      calendar ??
      validConstructionProjectProfile(
        overrides: const {
          'project_id': 'PRJ-A',
          'calendar': <String, Object?>{
            'start_date': '2026-08-24',
            'working_weekdays': <Object?>[0, 1, 2, 3, 4, 5],
            'holidays': <Object?>[],
            'workday_hours': 8,
          },
        },
      ).calendar;
  final rounded = durationDays.isFinite ? durationDays.ceil() : 0;
  final start = _date('2026-08-24');
  final finish = durationDays.isFinite && durationDays >= 0
      ? constructionDurationFinishDate(
          startDate: start,
          roundedSchedulingDays: rounded,
          calendarType: calendarType,
          calendar: effectiveCalendar,
        )
      : start;
  return ConstructionScheduledActivity(
    instanceId: 'activity-a@PRJ-A',
    activityId: 'activity-a',
    startDate: start,
    finishDate: finish,
    durationDays: durationDays,
    roundedSchedulingDays: rounded,
    durationCalendarType: calendarType,
    durationStatus: ConstructionScheduleDurationStatus.aiSeedEstimate,
    durationConfidence: ConstructionScheduleDurationConfidence.aiSeed,
    isMilestone: durationDays == 0,
    isIsolated: true,
  );
}

void _expectNoForecast(ConstructionLivingPlanForecast result) {
  expect(result.remainingDurationDays, isNull);
  expect(result.remainingRoundedSchedulingDays, isNull);
  expect(result.forecastFinishDate, isNull);
  expect(result.varianceCalendarDays, isNull);
}

Map<String, Object?> _projection(ConstructionLivingPlanForecast result) => {
  'item': result.itemId,
  'project': result.projectId,
  'snapshot': result.referenceSnapshotId,
  'instance': result.activityInstanceId,
  'status': result.status.storageValue,
  'progress': result.progressPercent,
  'as_of': result.asOfDate.toIso8601String(),
  'reference_finish': result.referenceFinishDate.toIso8601String(),
  'reference_duration': result.referenceDurationDays,
  'remaining_duration': result.remainingDurationDays,
  'remaining_rounded': result.remainingRoundedSchedulingDays,
  'forecast_finish': result.forecastFinishDate?.toIso8601String(),
  'variance': result.varianceCalendarDays,
  'basis': result.basis.contractValue,
  'status_source': result.referenceDurationStatus.jsonValue,
  'confidence': result.referenceDurationConfidence.jsonValue,
  'provenance': result.referenceDurationSource,
};

Matcher _throwsForecastFailure(String code) => throwsA(
  isA<ConstructionLivingPlanForecastFailure>().having(
    (failure) => failure.code,
    'code',
    code,
  ),
);

DateTime _date(String value) {
  final parts = value.split('-').map(int.parse).toList(growable: false);
  return DateTime.utc(parts[0], parts[1], parts[2]);
}
