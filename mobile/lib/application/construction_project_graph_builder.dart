import 'package:chief_site_engineer/application/construction_corpus_repository.dart';
import 'package:chief_site_engineer/application/construction_dependency_repository.dart';
import 'package:chief_site_engineer/domain/construction_corpus_models.dart';
import 'package:chief_site_engineer/domain/construction_project_graph_models.dart';

class ConstructionProjectActivityGraphBuilder {
  ConstructionProjectActivityGraphBuilder({
    ConstructionCorpusRepository? corpusRepository,
    ConstructionDependencyCatalogRepository? dependencyRepository,
  }) : _corpusRepository =
           corpusRepository ?? BundledConstructionCorpusRepository(),
       _dependencyRepository =
           dependencyRepository ??
           BundledConstructionDependencyCatalogRepository();

  final ConstructionCorpusRepository _corpusRepository;
  final ConstructionDependencyCatalogRepository _dependencyRepository;

  Future<ConstructionProjectActivityGraph> build(
    ConstructionProjectProfile profile,
  ) async {
    final corpus = await _corpusRepository.load();
    final dependencies = await _dependencyRepository.load(corpus);
    return buildFromCatalogs(
      profile: profile,
      corpus: corpus,
      dependencyCatalog: dependencies,
    );
  }

  ConstructionProjectActivityGraph buildFromCatalogs({
    required ConstructionProjectProfile profile,
    required ConstructionCorpus corpus,
    required ConstructionDependencyCatalog dependencyCatalog,
  }) {
    final selectedActivities = corpus.filterActivities(profile);
    final instances = <ConstructionProjectActivityInstance>[];
    final instanceIds = <String>{};
    for (final activity in selectedActivities) {
      for (final context in _contextsFor(activity, profile)) {
        final instance = _createInstance(activity, context);
        if (!instanceIds.add(instance.instanceId)) {
          throw const ConstructionCorpusFailure('duplicate_activity_instance');
        }
        instances.add(instance);
      }
    }
    instances.sort(
      (left, right) => left.instanceId.compareTo(right.instanceId),
    );

    final instancesByActivity =
        <String, List<ConstructionProjectActivityInstance>>{};
    for (final instance in instances) {
      instancesByActivity
          .putIfAbsent(instance.activityId, () => [])
          .add(instance);
    }

    final selectedActivityIds = selectedActivities
        .map((activity) => activity.activityId)
        .toSet();
    final selectedDependencies = dependencyCatalog
        .dependenciesForSelectedActivities(selectedActivityIds, profile);
    final edges = <ConstructionResolvedDependencyEdge>[];
    final edgeKeys = <String>{};
    for (final dependency in selectedDependencies) {
      _validateFloorOffset(dependency);
      final predecessors =
          instancesByActivity[dependency.predecessorActivityId];
      final successors = instancesByActivity[dependency.successorActivityId];
      if (predecessors == null || successors == null) {
        continue;
      }
      for (final pair in _resolvePairs(
        dependency,
        predecessors,
        successors,
        profile,
      )) {
        final predecessor = pair.$1;
        final successor = pair.$2;
        if (!instanceIds.contains(predecessor.instanceId) ||
            !instanceIds.contains(successor.instanceId)) {
          throw const ConstructionCorpusFailure('unknown_dependency_endpoint');
        }
        if (predecessor.instanceId == successor.instanceId) {
          throw const ConstructionCorpusFailure(
            'resolved_dependency_self_loop',
          );
        }
        final edgeKey = _edgeKey(
          dependency.dependencyId,
          predecessor.instanceId,
          successor.instanceId,
        );
        if (!edgeKeys.add(edgeKey)) {
          throw const ConstructionCorpusFailure(
            'duplicate_resolved_dependency',
          );
        }
        edges.add(
          ConstructionResolvedDependencyEdge(
            edgeKey: edgeKey,
            templateDependencyId: dependency.dependencyId,
            predecessorInstanceId: predecessor.instanceId,
            successorInstanceId: successor.instanceId,
            relationshipType: dependency.relationshipType,
            lagValue: dependency.lagValue,
            lagUnit: dependency.lagUnit,
            scopeRule: dependency.scopeRule,
            isMandatory: dependency.isMandatory,
            confidence: dependency.confidence,
            reviewStatus: dependency.reviewStatus,
          ),
        );
      }
    }
    edges.sort(_compareEdges);

    _validateAcyclic(instanceIds, edges);
    final connectedIds = <String>{};
    for (final edge in edges) {
      connectedIds
        ..add(edge.predecessorInstanceId)
        ..add(edge.successorInstanceId);
    }
    final isolatedIds =
        instanceIds
            .where((instanceId) => !connectedIds.contains(instanceId))
            .toList()
          ..sort();

    return ConstructionProjectActivityGraph(
      projectId: profile.projectId,
      activityInstances: instances,
      dependencyEdges: edges,
      isolatedInstanceIds: isolatedIds,
      corpusVersion: corpus.metadata.corpusVersion,
      selectedActivityTemplateCount: selectedActivities.length,
      selectedDependencyTemplateCount: selectedDependencies.length,
    );
  }
}

typedef _InstancePair = (
  ConstructionProjectActivityInstance,
  ConstructionProjectActivityInstance,
);

Iterable<ConstructionProjectActivityContext> _contextsFor(
  ConstructionActivity activity,
  ConstructionProjectProfile profile,
) sync* {
  final blocks = [...profile.blocks]
    ..sort((left, right) => left.blockId.compareTo(right.blockId));
  final facades = [...profile.facadeElevations]..sort();

  switch (activity.repeatDimension) {
    case ConstructionActivityRepeatDimension.project:
      yield const ConstructionProjectActivityContext();
    case ConstructionActivityRepeatDimension.block:
      for (final block in blocks) {
        yield ConstructionProjectActivityContext(blockId: block.blockId);
      }
    case ConstructionActivityRepeatDimension.basement:
      for (final block in blocks) {
        for (var index = 1; index <= block.basementCount; index += 1) {
          yield ConstructionProjectActivityContext(
            blockId: block.blockId,
            basementIndex: index,
          );
        }
      }
    case ConstructionActivityRepeatDimension.floor:
      for (final block in blocks) {
        for (var index = 1; index <= block.floorCount; index += 1) {
          yield ConstructionProjectActivityContext(
            blockId: block.blockId,
            floorIndex: index,
          );
        }
      }
    case ConstructionActivityRepeatDimension.zone:
      for (final block in blocks) {
        for (var index = 1; index <= profile.zonesPerBlock; index += 1) {
          yield ConstructionProjectActivityContext(
            blockId: block.blockId,
            zoneId: _minimumTwoDigits(index),
          );
        }
      }
    case ConstructionActivityRepeatDimension.facadeElevation:
      for (final block in blocks) {
        for (final facade in facades) {
          yield ConstructionProjectActivityContext(
            blockId: block.blockId,
            facadeElevation: facade,
          );
        }
      }
    case ConstructionActivityRepeatDimension.roof:
      for (final block in blocks) {
        yield ConstructionProjectActivityContext(
          blockId: block.blockId,
          roofId: 'MAIN',
        );
      }
    case ConstructionActivityRepeatDimension.lot:
      for (var index = 1; index <= profile.lotCount; index += 1) {
        yield ConstructionProjectActivityContext(lotId: index);
      }
    case ConstructionActivityRepeatDimension.system:
      yield ConstructionProjectActivityContext(
        systemId: _systemToken(activity.activityId),
      );
  }
}

ConstructionProjectActivityInstance _createInstance(
  ConstructionActivity activity,
  ConstructionProjectActivityContext context,
) => ConstructionProjectActivityInstance(
  instanceId: _instanceId(activity, context),
  activityId: activity.activityId,
  wbsCode: activity.wbsCode,
  packageId: activity.packageId,
  activityNameTr: activity.activityNameTr,
  repeatDimension: activity.repeatDimension,
  context: context,
  naturalUnit: activity.naturalUnit,
  durationStatus: activity.durationStatus,
  durationConfidence: activity.durationConfidence,
  testSeedDurationDays: activity.testSeedDurationDays,
);

String _instanceId(
  ConstructionActivity activity,
  ConstructionProjectActivityContext context,
) {
  final suffix = switch (activity.repeatDimension) {
    ConstructionActivityRepeatDimension.project => 'PROJECT',
    ConstructionActivityRepeatDimension.block => 'B-${context.blockId}',
    ConstructionActivityRepeatDimension.basement =>
      'B-${context.blockId}/BS-${_minimumTwoDigits(context.basementIndex!)}',
    ConstructionActivityRepeatDimension.floor =>
      'B-${context.blockId}/F-${_minimumTwoDigits(context.floorIndex!)}',
    ConstructionActivityRepeatDimension.zone =>
      'B-${context.blockId}/Z-${context.zoneId}',
    ConstructionActivityRepeatDimension.facadeElevation =>
      'B-${context.blockId}/FA-${context.facadeElevation}',
    ConstructionActivityRepeatDimension.roof =>
      'B-${context.blockId}/R-${context.roofId}',
    ConstructionActivityRepeatDimension.lot =>
      'LOT-${_minimumTwoDigits(context.lotId!)}',
    ConstructionActivityRepeatDimension.system => 'SYS-${context.systemId}',
  };
  return '${activity.activityId}@$suffix';
}

Iterable<_InstancePair> _resolvePairs(
  ConstructionDependency dependency,
  List<ConstructionProjectActivityInstance> predecessors,
  List<ConstructionProjectActivityInstance> successors,
  ConstructionProjectProfile profile,
) sync* {
  for (final predecessor in predecessors) {
    for (final successor in successors) {
      final matches = switch (dependency.scopeRule) {
        ConstructionDependencyScopeRule.automatic =>
          predecessor.repeatDimension ==
                  ConstructionActivityRepeatDimension.project ||
              successor.repeatDimension ==
                  ConstructionActivityRepeatDimension.project ||
              _sameCommonContext(predecessor.context, successor.context),
        ConstructionDependencyScopeRule.project =>
          (predecessor.repeatDimension ==
                      ConstructionActivityRepeatDimension.project &&
                  successor.repeatDimension ==
                      ConstructionActivityRepeatDimension.project) ||
              _sameCommonContext(predecessor.context, successor.context),
        ConstructionDependencyScopeRule.sameBlock =>
          predecessor.context.blockId != null &&
              predecessor.context.blockId == successor.context.blockId,
        ConstructionDependencyScopeRule.sameFloor =>
          predecessor.context.blockId != null &&
              predecessor.context.blockId == successor.context.blockId &&
              predecessor.context.floorIndex != null &&
              predecessor.context.floorIndex == successor.context.floorIndex,
        ConstructionDependencyScopeRule.nextFloor =>
          predecessor.context.blockId != null &&
              predecessor.context.blockId == successor.context.blockId &&
              predecessor.context.floorIndex != null &&
              successor.context.floorIndex ==
                  predecessor.context.floorIndex! + dependency.floorOffset,
        ConstructionDependencyScopeRule.sameBasement =>
          predecessor.context.blockId != null &&
              predecessor.context.blockId == successor.context.blockId &&
              predecessor.context.basementIndex != null &&
              predecessor.context.basementIndex ==
                  successor.context.basementIndex,
        ConstructionDependencyScopeRule.nextBasement =>
          predecessor.context.blockId != null &&
              predecessor.context.blockId == successor.context.blockId &&
              predecessor.context.basementIndex != null &&
              successor.context.basementIndex ==
                  predecessor.context.basementIndex! + 1,
        ConstructionDependencyScopeRule.sameRoof =>
          predecessor.context.blockId != null &&
              predecessor.context.blockId == successor.context.blockId &&
              predecessor.context.roofId != null &&
              predecessor.context.roofId == successor.context.roofId,
        ConstructionDependencyScopeRule.sameFacade =>
          predecessor.context.blockId != null &&
              predecessor.context.blockId == successor.context.blockId &&
              predecessor.context.facadeElevation != null &&
              predecessor.context.facadeElevation ==
                  successor.context.facadeElevation,
        ConstructionDependencyScopeRule.sameSystem => true,
        ConstructionDependencyScopeRule.blockToFirstBasement =>
          predecessor.context.blockId != null &&
              predecessor.context.blockId == successor.context.blockId &&
              successor.context.basementIndex == 1,
        ConstructionDependencyScopeRule.blockToFirstFloor =>
          predecessor.context.blockId != null &&
              predecessor.context.blockId == successor.context.blockId &&
              successor.context.floorIndex == 1,
        ConstructionDependencyScopeRule.blockToFirstFloorIfNoBasement =>
          predecessor.context.blockId != null &&
              predecessor.context.blockId == successor.context.blockId &&
              successor.context.floorIndex == 1 &&
              _block(profile, predecessor.context.blockId!).basementCount == 0,
        ConstructionDependencyScopeRule.lastBasementToFirstFloor =>
          predecessor.context.blockId != null &&
              predecessor.context.blockId == successor.context.blockId &&
              predecessor.context.basementIndex ==
                  _block(profile, predecessor.context.blockId!).basementCount &&
              successor.context.floorIndex == 1,
        ConstructionDependencyScopeRule.topFloorToRoof =>
          predecessor.context.blockId != null &&
              predecessor.context.blockId == successor.context.blockId &&
              predecessor.context.floorIndex ==
                  _block(profile, predecessor.context.blockId!).floorCount &&
              successor.context.roofId != null,
        ConstructionDependencyScopeRule.floorThresholdToFacade =>
          predecessor.context.blockId != null &&
              predecessor.context.blockId == successor.context.blockId &&
              predecessor.context.floorIndex ==
                  _facadeFloorThreshold(
                    _block(profile, predecessor.context.blockId!).floorCount,
                  ) &&
              successor.context.facadeElevation != null,
        ConstructionDependencyScopeRule.allToProject ||
        ConstructionDependencyScopeRule.projectToAll ||
        ConstructionDependencyScopeRule.allToBlock => true,
        ConstructionDependencyScopeRule.anyZoneToProject =>
          predecessor.repeatDimension ==
                  ConstructionActivityRepeatDimension.zone &&
              successor.repeatDimension ==
                  ConstructionActivityRepeatDimension.project,
      };
      if (matches) {
        yield (predecessor, successor);
      }
    }
  }
}

bool _sameCommonContext(
  ConstructionProjectActivityContext left,
  ConstructionProjectActivityContext right,
) {
  final leftValues = left.toJson();
  final rightValues = right.toJson();
  final commonKeys = leftValues.keys.where(rightValues.containsKey);
  return commonKeys.every((key) => leftValues[key] == rightValues[key]);
}

ConstructionProjectBlock _block(
  ConstructionProjectProfile profile,
  String blockId,
) {
  for (final block in profile.blocks) {
    if (block.blockId == blockId) {
      return block;
    }
  }
  throw const ConstructionCorpusFailure('unknown_instance_block');
}

void _validateFloorOffset(ConstructionDependency dependency) {
  final valid =
      dependency.scopeRule == ConstructionDependencyScopeRule.nextFloor
      ? dependency.floorOffset == 1
      : dependency.floorOffset == 0;
  if (!valid) {
    throw const ConstructionCorpusFailure('invalid_scope_floor_offset');
  }
}

void _validateAcyclic(
  Set<String> instanceIds,
  List<ConstructionResolvedDependencyEdge> edges,
) {
  final incoming = {for (final id in instanceIds) id: 0};
  final outgoing = <String, List<String>>{};
  for (final edge in edges) {
    final successorCount = incoming[edge.successorInstanceId];
    if (successorCount == null ||
        !incoming.containsKey(edge.predecessorInstanceId)) {
      throw const ConstructionCorpusFailure('unknown_dependency_endpoint');
    }
    incoming[edge.successorInstanceId] = successorCount + 1;
    outgoing
        .putIfAbsent(edge.predecessorInstanceId, () => [])
        .add(edge.successorInstanceId);
  }
  final ready =
      incoming.entries
          .where((entry) => entry.value == 0)
          .map((entry) => entry.key)
          .toList()
        ..sort();
  var visited = 0;
  while (ready.isNotEmpty) {
    final current = ready.removeAt(0);
    visited += 1;
    final successors = outgoing[current] ?? const <String>[];
    for (final successor in successors) {
      final next = incoming[successor]! - 1;
      incoming[successor] = next;
      if (next == 0) {
        ready.add(successor);
        ready.sort();
      }
    }
  }
  if (visited != instanceIds.length) {
    throw const ConstructionCorpusFailure('resolved_graph_cycle');
  }
}

int _compareEdges(
  ConstructionResolvedDependencyEdge left,
  ConstructionResolvedDependencyEdge right,
) {
  for (final comparison in <int>[
    left.templateDependencyId.compareTo(right.templateDependencyId),
    left.predecessorInstanceId.compareTo(right.predecessorInstanceId),
    left.successorInstanceId.compareTo(right.successorInstanceId),
    left.relationshipType.jsonValue.compareTo(right.relationshipType.jsonValue),
    left.lagValue.compareTo(right.lagValue),
    left.lagUnit.jsonValue.compareTo(right.lagUnit.jsonValue),
    left.scopeRule.jsonValue.compareTo(right.scopeRule.jsonValue),
  ]) {
    if (comparison != 0) {
      return comparison;
    }
  }
  return left.edgeKey.compareTo(right.edgeKey);
}

String _edgeKey(
  String dependencyId,
  String predecessorId,
  String successorId,
) => '$dependencyId|$predecessorId|$successorId';

String _minimumTwoDigits(int value) => value.toString().padLeft(2, '0');

String _systemToken(String activityId) {
  final token = activityId.split('-').last;
  if (token.isEmpty) {
    throw const ConstructionCorpusFailure('invalid_system_activity_id');
  }
  return token;
}

int _facadeFloorThreshold(int topFloor) => topFloor < 3 ? topFloor : 3;
