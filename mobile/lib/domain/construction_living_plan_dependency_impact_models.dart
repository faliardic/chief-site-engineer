enum ConstructionLivingPlanDependencyImpactBasis {
  sourceForecastUnavailable('SOURCE_FORECAST_UNAVAILABLE'),
  noPositiveSourceDelay('NO_POSITIVE_SOURCE_DELAY'),
  sourceDelayNoDownstreamShift('SOURCE_DELAY_NO_DOWNSTREAM_SHIFT'),
  downstreamDelayProjected('DOWNSTREAM_DELAY_PROJECTED');

  const ConstructionLivingPlanDependencyImpactBasis(this.contractValue);

  final String contractValue;
}

class ConstructionLivingPlanDependencyImpactItem {
  const ConstructionLivingPlanDependencyImpactItem({
    required this.activityInstanceId,
    required this.activityId,
    required this.referenceStartDate,
    required this.referenceFinishDate,
    required this.projectedStartDate,
    required this.projectedFinishDate,
    required this.startShiftCalendarDays,
    required this.finishShiftCalendarDays,
  });

  final String activityInstanceId;
  final String activityId;
  final DateTime referenceStartDate;
  final DateTime referenceFinishDate;
  final DateTime projectedStartDate;
  final DateTime projectedFinishDate;
  final int startShiftCalendarDays;
  final int finishShiftCalendarDays;
}

class ConstructionLivingPlanDependencyImpact {
  ConstructionLivingPlanDependencyImpact({
    required this.itemId,
    required this.projectId,
    required this.referenceSnapshotId,
    required this.sourceActivityInstanceId,
    required this.asOfDate,
    required this.sourceReferenceStartDate,
    required this.sourceReferenceFinishDate,
    required this.sourceForecastFinishDate,
    required this.sourceVarianceCalendarDays,
    required this.propagatedPositiveSourceDelayCalendarDays,
    required this.dependencyProjectionSha256,
    required this.basis,
    required Iterable<ConstructionLivingPlanDependencyImpactItem>
    impactedActivities,
  }) : impactedActivities = List.unmodifiable(impactedActivities);

  final String itemId;
  final String projectId;
  final String referenceSnapshotId;
  final String sourceActivityInstanceId;
  final DateTime asOfDate;
  final DateTime sourceReferenceStartDate;
  final DateTime sourceReferenceFinishDate;
  final DateTime? sourceForecastFinishDate;
  final int? sourceVarianceCalendarDays;
  final int propagatedPositiveSourceDelayCalendarDays;
  final String dependencyProjectionSha256;
  final ConstructionLivingPlanDependencyImpactBasis basis;
  final List<ConstructionLivingPlanDependencyImpactItem> impactedActivities;
}

class ConstructionLivingPlanDependencyImpactFailure implements Exception {
  const ConstructionLivingPlanDependencyImpactFailure(this.code);

  final String code;

  @override
  String toString() => 'ConstructionLivingPlanDependencyImpactFailure($code)';
}
