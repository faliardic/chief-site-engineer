import 'package:chief_site_engineer/domain/construction_corpus_models.dart';

class ConstructionProjectActivityContext {
  const ConstructionProjectActivityContext({
    this.blockId,
    this.basementIndex,
    this.floorIndex,
    this.zoneId,
    this.facadeElevation,
    this.roofId,
    this.lotId,
    this.systemId,
  });

  final String? blockId;
  final int? basementIndex;
  final int? floorIndex;
  final String? zoneId;
  final String? facadeElevation;
  final String? roofId;
  final int? lotId;
  final String? systemId;

  Map<String, Object?> toJson() => Map.unmodifiable({
    if (basementIndex != null) 'basement_index': basementIndex,
    if (blockId != null) 'block_id': blockId,
    if (facadeElevation != null) 'facade_elevation': facadeElevation,
    if (floorIndex != null) 'floor_index': floorIndex,
    if (lotId != null) 'lot_id': lotId,
    if (roofId != null) 'roof_id': roofId,
    if (systemId != null) 'system_id': systemId,
    if (zoneId != null) 'zone_id': zoneId,
  });
}

class ConstructionProjectActivityInstance {
  const ConstructionProjectActivityInstance({
    required this.instanceId,
    required this.activityId,
    required this.wbsCode,
    required this.packageId,
    required this.activityNameTr,
    required this.repeatDimension,
    required this.context,
    required this.naturalUnit,
    required this.durationStatus,
    required this.durationConfidence,
    required this.testSeedDurationDays,
  });

  final String instanceId;
  final String activityId;
  final String wbsCode;
  final String packageId;
  final String activityNameTr;
  final ConstructionActivityRepeatDimension repeatDimension;
  final ConstructionProjectActivityContext context;
  final String naturalUnit;
  final String durationStatus;
  final String durationConfidence;
  final double? testSeedDurationDays;
}

class ConstructionResolvedDependencyEdge {
  const ConstructionResolvedDependencyEdge({
    required this.edgeKey,
    required this.templateDependencyId,
    required this.predecessorInstanceId,
    required this.successorInstanceId,
    required this.relationshipType,
    required this.lagValue,
    required this.lagUnit,
    required this.scopeRule,
    required this.isMandatory,
    required this.confidence,
    required this.reviewStatus,
  });

  final String edgeKey;
  final String templateDependencyId;
  final String predecessorInstanceId;
  final String successorInstanceId;
  final ConstructionDependencyRelationshipType relationshipType;
  final int lagValue;
  final ConstructionDependencyLagUnit lagUnit;
  final ConstructionDependencyScopeRule scopeRule;
  final bool isMandatory;
  final ConstructionDependencyConfidence confidence;
  final ConstructionDependencyReviewStatus reviewStatus;
}

class ConstructionProjectActivityGraph {
  ConstructionProjectActivityGraph({
    required this.projectId,
    required Iterable<ConstructionProjectActivityInstance> activityInstances,
    required Iterable<ConstructionResolvedDependencyEdge> dependencyEdges,
    required Iterable<String> isolatedInstanceIds,
    required this.corpusVersion,
    required this.selectedActivityTemplateCount,
    required this.selectedDependencyTemplateCount,
  }) : activityInstances = List.unmodifiable(activityInstances),
       dependencyEdges = List.unmodifiable(dependencyEdges),
       isolatedInstanceIds = List.unmodifiable(isolatedInstanceIds);

  final String projectId;
  final List<ConstructionProjectActivityInstance> activityInstances;
  final List<ConstructionResolvedDependencyEdge> dependencyEdges;
  final List<String> isolatedInstanceIds;
  final String corpusVersion;
  final int selectedActivityTemplateCount;
  final int selectedDependencyTemplateCount;
}
