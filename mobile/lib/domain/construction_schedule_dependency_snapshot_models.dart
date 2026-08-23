import 'package:chief_site_engineer/domain/construction_project_graph_models.dart';

class ConstructionScheduleSnapshotDependencyGraph {
  ConstructionScheduleSnapshotDependencyGraph({
    required this.snapshotId,
    required this.projectId,
    required this.dependencyCount,
    required this.projectionSha256,
    required Iterable<ConstructionResolvedDependencyEdge> edges,
  }) : edges = List.unmodifiable(edges);

  final String snapshotId;
  final String projectId;
  final int dependencyCount;
  final String projectionSha256;
  final List<ConstructionResolvedDependencyEdge> edges;
}
