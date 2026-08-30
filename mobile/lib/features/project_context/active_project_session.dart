import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:flutter/foundation.dart';

class ActiveProjectSession extends ChangeNotifier {
  String? _selectedProjectId;

  String? get selectedProjectId => _selectedProjectId;

  MobileProject? selectedProject(Iterable<MobileProject> projects) {
    final selectedId = _selectedProjectId;
    if (selectedId == null) return null;
    for (final project in projects) {
      if (!project.isArchived && project.id == selectedId) return project;
    }
    return null;
  }

  bool reconcile(Iterable<MobileProject> projects) {
    final active = projects.where((project) => !project.isArchived).toList();
    var next = _selectedProjectId;
    if (next == null || !active.any((project) => project.id == next)) {
      next = active.length == 1 ? active.single.id : null;
    }
    return _replace(next);
  }

  bool select(String projectId, Iterable<MobileProject> projects) {
    final isActive = projects.any(
      (project) => !project.isArchived && project.id == projectId,
    );
    if (!isActive) return false;
    return _replace(projectId);
  }

  bool clear() => _replace(null);

  bool _replace(String? next) {
    if (_selectedProjectId == next) return false;
    _selectedProjectId = next;
    notifyListeners();
    return true;
  }
}
