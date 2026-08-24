import 'package:chief_site_engineer/domain/construction_living_plan_dependency_impact_models.dart';
import 'package:chief_site_engineer/domain/construction_living_plan_forecast_models.dart';

enum ConstructionLivingPlanIntelligenceImpactAvailability {
  available,
  dependencyGraphUnavailable,
}

class ConstructionLivingPlanIntelligenceImpactActivity {
  const ConstructionLivingPlanIntelligenceImpactActivity({
    required this.activityInstanceId,
    required this.activityId,
    required this.displayName,
    required this.projectedStartDate,
    required this.projectedFinishDate,
    required this.finishShiftCalendarDays,
  });

  final String activityInstanceId;
  final String activityId;
  final String displayName;
  final DateTime projectedStartDate;
  final DateTime projectedFinishDate;
  final int finishShiftCalendarDays;
}

class ConstructionLivingPlanIntelligence {
  ConstructionLivingPlanIntelligence({
    required this.itemId,
    required this.forecast,
    required this.impactAvailability,
    required this.dependencyImpact,
    required Iterable<ConstructionLivingPlanIntelligenceImpactActivity>
    impactedActivities,
  }) : impactedActivities = List.unmodifiable(impactedActivities);

  final String itemId;
  final ConstructionLivingPlanForecast forecast;
  final ConstructionLivingPlanIntelligenceImpactAvailability impactAvailability;
  final ConstructionLivingPlanDependencyImpact? dependencyImpact;
  final List<ConstructionLivingPlanIntelligenceImpactActivity>
  impactedActivities;

  bool get hasPositiveDownstreamImpact =>
      impactAvailability ==
          ConstructionLivingPlanIntelligenceImpactAvailability.available &&
      dependencyImpact?.basis ==
          ConstructionLivingPlanDependencyImpactBasis
              .downstreamDelayProjected &&
      impactedActivities.isNotEmpty;
}

class ConstructionLivingPlanIntelligenceFailure implements Exception {
  const ConstructionLivingPlanIntelligenceFailure(this.code);

  final String code;

  @override
  String toString() => 'ConstructionLivingPlanIntelligenceFailure($code)';
}
