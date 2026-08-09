import 'dart:async';

import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/core/record_id.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/project_location_models.dart';
import 'package:chief_site_engineer/features/owned_text_input_dialog.dart';
import 'package:flutter/material.dart';

class ProjectLocationCatalogPage extends StatefulWidget {
  const ProjectLocationCatalogPage({
    required this.application,
    this.initialProjectId,
    super.key,
  });

  final ProjectLocationApplication application;
  final String? initialProjectId;

  @override
  State<ProjectLocationCatalogPage> createState() =>
      _ProjectLocationCatalogPageState();
}

class _ProjectLocationCatalogPageState
    extends State<ProjectLocationCatalogPage> {
  List<MobileProject> _projects = const [];
  List<MobileProjectLocation> _activeLocations = const [];
  List<MobileProjectLocation> _archivedLocations = const [];
  String? _projectId;
  ProjectLocationArchiveFilter _archiveFilter =
      ProjectLocationArchiveFilter.active;
  StreamSubscription<void>? _projectSubscription;
  StreamSubscription<void>? _locationSubscription;
  bool _initialProjectResolved = false;
  bool _loading = true;
  bool _mutationBusy = false;
  String? _readError;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _subscribe();
    unawaited(_reload(reloadProjects: true));
  }

  @override
  void didUpdateWidget(covariant ProjectLocationCatalogPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.application == widget.application) return;
    unawaited(_projectSubscription?.cancel());
    unawaited(_locationSubscription?.cancel());
    _initialProjectResolved = false;
    _projectId = null;
    _subscribe();
    unawaited(_reload(reloadProjects: true));
  }

  void _subscribe() {
    _projectSubscription = widget.application.projectChanges.listen(
      (_) => unawaited(_reload(reloadProjects: true)),
    );
    _locationSubscription = widget.application.projectLocationChanges.listen(
      (_) => unawaited(_reload(reloadProjects: false)),
    );
  }

  @override
  void dispose() {
    _loadGeneration += 1;
    _projectSubscription?.cancel();
    _locationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _reload({required bool reloadProjects}) async {
    final generation = ++_loadGeneration;
    if (mounted) {
      setState(() {
        _loading = true;
        _readError = null;
      });
    }
    try {
      final projects = reloadProjects
          ? await widget.application.listProjects()
          : _projects;
      var selectedProjectId = _projectId;
      final selectedStillActive = projects.any(
        (project) => project.id == selectedProjectId,
      );
      if (!_initialProjectResolved) {
        final initial = widget.initialProjectId;
        selectedProjectId =
            initial != null && projects.any((project) => project.id == initial)
            ? initial
            : projects.firstOrNull?.id;
        _initialProjectResolved = true;
      } else if (!selectedStillActive) {
        selectedProjectId = projects.firstOrNull?.id;
      }

      List<MobileProjectLocation> activeLocations = const [];
      List<MobileProjectLocation> archivedLocations = const [];
      if (selectedProjectId != null) {
        final results = await Future.wait([
          widget.application.listProjectLocations(
            ProjectLocationQuery(
              projectId: selectedProjectId,
              archiveFilter: ProjectLocationArchiveFilter.active,
            ),
          ),
          widget.application.listProjectLocations(
            ProjectLocationQuery(
              projectId: selectedProjectId,
              archiveFilter: ProjectLocationArchiveFilter.archived,
            ),
          ),
        ]);
        activeLocations = results[0];
        archivedLocations = results[1];
      }
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _projects = projects;
        _projectId = selectedProjectId;
        _activeLocations = activeLocations;
        _archivedLocations = archivedLocations;
        _loading = false;
      });
    } on Object {
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _loading = false;
        _readError = 'Mahal Kataloğu güvenli biçimde okunamadı.';
      });
    }
  }

  Future<void> _selectProject(String? projectId) async {
    if (projectId == null || projectId == _projectId) return;
    setState(() => _projectId = projectId);
    await _reload(reloadProjects: false);
  }

  Future<void> _createLocation({String? parentLocationId}) async {
    if (_mutationBusy || _projectId == null) return;
    final name = await showDialog<String>(
      context: context,
      builder: (context) => OwnedTextInputDialog(
        title: parentLocationId == null ? 'Yeni mahal' : 'Yeni alt mahal',
        label: 'Mahal adı',
        confirmLabel: 'Oluştur',
        inputKey: const Key('project-location-name-input'),
        confirmKey: const Key('save-project-location'),
        maxLength: 160,
        trimResult: true,
        validator: _validateName,
      ),
    );
    if (name == null || !mounted) return;
    final projectId = _projectId;
    if (projectId == null) return;
    await _runMutation(
      failureMessage: 'Mahal oluşturulamadı.',
      successMessage: 'Mahal oluşturuldu.',
      action: () => widget.application.createProjectLocation(
        CreateProjectLocationCommand(
          id: RecordId.randomUuid(),
          eventId: RecordId.randomUuid(),
          projectId: projectId,
          displayName: name,
          parentLocationId: parentLocationId,
        ),
      ),
    );
  }

  Future<void> _renameLocation(MobileProjectLocation location) async {
    if (_mutationBusy) return;
    final name = await showDialog<String>(
      context: context,
      builder: (context) => OwnedTextInputDialog(
        title: 'Mahali yeniden adlandır',
        label: 'Mahal adı',
        confirmLabel: 'Kaydet',
        initialValue: location.displayName,
        inputKey: const Key('rename-project-location-input'),
        confirmKey: const Key('save-project-location-rename'),
        maxLength: 160,
        trimResult: true,
        validator: _validateName,
      ),
    );
    if (name == null || !mounted) return;
    await _runMutation(
      failureMessage: 'Mahal adı değiştirilemedi.',
      successMessage: 'Mahal adı güncellendi.',
      action: () => widget.application.renameProjectLocation(
        RenameProjectLocationCommand(
          locationId: location.id,
          eventId: RecordId.randomUuid(),
          expectedRevision: location.revision,
          displayName: name,
        ),
      ),
    );
  }

  Future<void> _reparentLocation(MobileProjectLocation location) async {
    if (_mutationBusy) return;
    final blockedIds = _descendantIds(location.id)..add(location.id);
    final result = await showDialog<_ParentSelectionResult>(
      context: context,
      builder: (context) => _ParentSelectionDialog(
        title: 'Üst mahali değiştir',
        locations: _activeLocations,
        initialParentId: location.parentLocationId,
        blockedIds: blockedIds,
      ),
    );
    if (result == null || !mounted) return;
    await _runMutation(
      failureMessage: 'Üst mahal değiştirilemedi.',
      successMessage: 'Üst mahal güncellendi.',
      action: () => widget.application.reparentProjectLocation(
        ReparentProjectLocationCommand(
          locationId: location.id,
          eventId: RecordId.randomUuid(),
          expectedRevision: location.revision,
          parentLocationId: result.parentLocationId,
        ),
      ),
    );
  }

  Future<void> _archiveLocation(MobileProjectLocation location) async {
    if (_mutationBusy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mahali arşivle?'),
        content: Text(
          '${location.displayName} aktif katalogdan çıkarılacak. Kayıtlar silinmez.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            key: const Key('confirm-project-location-archive'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Arşivle'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _mutateArchive(location, archive: true);
  }

  Future<void> _mutateArchive(
    MobileProjectLocation location, {
    required bool archive,
  }) {
    return _runMutation(
      failureMessage: archive
          ? 'Mahal arşivlenemedi.'
          : 'Mahal geri getirilemedi.',
      successMessage: archive ? 'Mahal arşivlendi.' : 'Mahal geri getirildi.',
      action: () => widget.application.mutateProjectLocationArchive(
        MutateProjectLocationArchiveCommand(
          locationId: location.id,
          eventId: RecordId.randomUuid(),
          expectedRevision: location.revision,
          archive: archive,
        ),
      ),
    );
  }

  Future<void> _runMutation({
    required Future<Object?> Function() action,
    required String successMessage,
    required String failureMessage,
  }) async {
    if (_mutationBusy) return;
    setState(() => _mutationBusy = true);
    String? message;
    try {
      await action();
      message = successMessage;
    } on Object catch (error) {
      message = error is AgendaValidationFailure
          ? error.message
          : failureMessage;
    }
    if (!mounted) return;
    await _reload(reloadProjects: false);
    if (!mounted) return;
    setState(() => _mutationBusy = false);
    _showFeedback(message);
  }

  void _showFeedback(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Set<String> _descendantIds(String locationId) {
    final descendants = <String>{};
    final pending = <String>[locationId];
    while (pending.isNotEmpty) {
      final parentId = pending.removeLast();
      for (final location in _activeLocations) {
        if (location.parentLocationId == parentId &&
            descendants.add(location.id)) {
          pending.add(location.id);
        }
      }
    }
    return descendants;
  }

  String? _validateName(String value) =>
      value.trim().isEmpty ? 'Mahal adı zorunludur.' : null;

  @override
  Widget build(BuildContext context) {
    final visibleLocations =
        _archiveFilter == ProjectLocationArchiveFilter.active
        ? _activeLocations
        : _archivedLocations;
    final hierarchy = _buildHierarchy(visibleLocations, [
      ..._activeLocations,
      ..._archivedLocations,
    ]);
    return Scaffold(
      appBar: AppBar(title: const Text('Mahal Kataloğu')),
      body: SafeArea(
        child: ListView(
          key: const Key('project-location-catalog-list'),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
          children: [
            DropdownButtonFormField<String>(
              key: ValueKey('catalog-project-selector-$_projectId'),
              initialValue: _projectId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Aktif proje',
                border: OutlineInputBorder(),
              ),
              hint: const Text('Aktif proje yok'),
              items: _projects
                  .map(
                    (project) => DropdownMenuItem(
                      value: project.id,
                      child: Text(
                        project.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(growable: false),
              onChanged: _loading || _projects.isEmpty
                  ? null
                  : (value) => unawaited(_selectProject(value)),
            ),
            const SizedBox(height: 12),
            Semantics(
              label: 'Mahal durumu filtresi',
              child: SegmentedButton<ProjectLocationArchiveFilter>(
                key: const Key('catalog-archive-filter'),
                segments: const [
                  ButtonSegment(
                    value: ProjectLocationArchiveFilter.active,
                    icon: Icon(Icons.account_tree_outlined),
                    label: Text('Aktif'),
                  ),
                  ButtonSegment(
                    value: ProjectLocationArchiveFilter.archived,
                    icon: Icon(Icons.archive_outlined),
                    label: Text('Arşivlenenler'),
                  ),
                ],
                selected: {_archiveFilter},
                onSelectionChanged: _mutationBusy
                    ? null
                    : (values) =>
                          setState(() => _archiveFilter = values.single),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                key: const Key('create-project-location'),
                onPressed: _projectId == null || _loading || _mutationBusy
                    ? null
                    : _createLocation,
                icon: const Icon(Icons.add_location_alt_outlined),
                label: const Text('Yeni mahal'),
              ),
            ),
            if (_mutationBusy) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(
                key: Key('project-location-mutation-progress'),
              ),
            ],
            const SizedBox(height: 12),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_readError != null)
              _CatalogMessage(
                icon: Icons.error_outline,
                message: _readError!,
                action: FilledButton.tonalIcon(
                  key: const Key('retry-project-location-catalog'),
                  onPressed: () => unawaited(_reload(reloadProjects: true)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Yeniden dene'),
                ),
              )
            else if (_projects.isEmpty)
              const _CatalogMessage(
                icon: Icons.folder_off_outlined,
                message: 'Mahal yönetmek için önce aktif bir proje oluşturun.',
              )
            else if (visibleLocations.isEmpty)
              _CatalogMessage(
                icon: _archiveFilter == ProjectLocationArchiveFilter.active
                    ? Icons.account_tree_outlined
                    : Icons.archive_outlined,
                message: _archiveFilter == ProjectLocationArchiveFilter.active
                    ? 'Bu projede aktif mahal yok.'
                    : 'Bu projede arşivlenmiş mahal yok.',
              )
            else ...[
              if (hierarchy.corrupt)
                const _CatalogMessage(
                  icon: Icons.warning_amber_rounded,
                  message:
                      'Bazı mahal ilişkileri güvenle gösterilemedi. Veriler değiştirilmedi.',
                ),
              ...hierarchy.rows.map(_buildLocationRow),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow(_LocationRowData row) {
    final location = row.location;
    final parentLabel = row.parentName == null
        ? 'Kök mahal'
        : 'Üst mahal: ${row.parentName}';
    return Padding(
      padding: EdgeInsets.only(left: row.depth * 20.0),
      child: Semantics(
        container: true,
        label: '${location.displayName}. $parentLabel',
        child: Card(
          key: Key('project-location-${location.id}'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
            child: Row(
              children: [
                Icon(
                  row.depth == 0
                      ? Icons.location_on_outlined
                      : Icons.subdirectory_arrow_right,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        location.displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        parentLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (location.isArchived)
                  IconButton(
                    key: Key('restore-project-location-${location.id}'),
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    onPressed: _mutationBusy
                        ? null
                        : () => _mutateArchive(location, archive: false),
                    icon: const Icon(Icons.unarchive_outlined),
                    tooltip: 'Mahali geri getir',
                  )
                else
                  PopupMenuButton<_LocationAction>(
                    key: Key('project-location-actions-${location.id}'),
                    enabled: !_mutationBusy,
                    tooltip: 'Mahal işlemleri',
                    icon: const Icon(Icons.more_vert),
                    onSelected: (action) {
                      switch (action) {
                        case _LocationAction.createChild:
                          unawaited(
                            _createLocation(parentLocationId: location.id),
                          );
                          break;
                        case _LocationAction.rename:
                          unawaited(_renameLocation(location));
                          break;
                        case _LocationAction.reparent:
                          unawaited(_reparentLocation(location));
                          break;
                        case _LocationAction.archive:
                          unawaited(_archiveLocation(location));
                          break;
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: _LocationAction.createChild,
                        child: Text('Alt mahal oluştur'),
                      ),
                      PopupMenuItem(
                        value: _LocationAction.rename,
                        child: Text('Yeniden adlandır'),
                      ),
                      PopupMenuItem(
                        value: _LocationAction.reparent,
                        child: Text('Üst mahali değiştir'),
                      ),
                      PopupMenuItem(
                        value: _LocationAction.archive,
                        child: Text('Arşivle'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

({List<_LocationRowData> rows, bool corrupt}) _buildHierarchy(
  List<MobileProjectLocation> visible,
  List<MobileProjectLocation> all,
) {
  final allById = {for (final location in all) location.id: location};
  final visibleIds = visible.map((location) => location.id).toSet();
  final children = <String, List<MobileProjectLocation>>{};
  final roots = <MobileProjectLocation>[];
  var corrupt = false;
  for (final location in visible) {
    final parentId = location.parentLocationId;
    if (parentId == null || !visibleIds.contains(parentId)) {
      roots.add(location);
      if (parentId != null && !allById.containsKey(parentId)) corrupt = true;
    } else {
      children.putIfAbsent(parentId, () => []).add(location);
    }
  }

  final rows = <_LocationRowData>[];
  final rendered = <String>{};
  final visiting = <String>{};

  void visit(MobileProjectLocation location, int depth) {
    if (!visiting.add(location.id)) {
      corrupt = true;
      return;
    }
    if (!rendered.add(location.id)) {
      visiting.remove(location.id);
      return;
    }
    rows.add(
      _LocationRowData(
        location: location,
        depth: depth,
        parentName: location.parentLocationId == null
            ? null
            : allById[location.parentLocationId]?.displayName ??
                  'Bilinmeyen mahal',
      ),
    );
    for (final child in children[location.id] ?? const []) {
      visit(child, depth + 1);
    }
    visiting.remove(location.id);
  }

  for (final root in roots) {
    visit(root, 0);
  }
  for (final location in visible) {
    if (rendered.contains(location.id)) continue;
    corrupt = true;
    rows.add(
      _LocationRowData(
        location: location,
        depth: 0,
        parentName: location.parentLocationId == null
            ? null
            : allById[location.parentLocationId]?.displayName ??
                  'Bilinmeyen mahal',
      ),
    );
    rendered.add(location.id);
  }
  return (rows: rows, corrupt: corrupt);
}

class _LocationRowData {
  const _LocationRowData({
    required this.location,
    required this.depth,
    required this.parentName,
  });

  final MobileProjectLocation location;
  final int depth;
  final String? parentName;
}

class _CatalogMessage extends StatelessWidget {
  const _CatalogMessage({
    required this.icon,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, size: 40),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 12), action!],
          ],
        ),
      ),
    );
  }
}

enum _LocationAction { createChild, rename, reparent, archive }

class _ParentSelectionResult {
  const _ParentSelectionResult(this.parentLocationId);

  final String? parentLocationId;
}

class _ParentSelectionDialog extends StatefulWidget {
  const _ParentSelectionDialog({
    required this.title,
    required this.locations,
    required this.initialParentId,
    required this.blockedIds,
  });

  final String title;
  final List<MobileProjectLocation> locations;
  final String? initialParentId;
  final Set<String> blockedIds;

  @override
  State<_ParentSelectionDialog> createState() => _ParentSelectionDialogState();
}

class _ParentSelectionDialogState extends State<_ParentSelectionDialog> {
  static const _rootValue = '__root__';
  late String _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.initialParentId ?? _rootValue;
    if (widget.blockedIds.contains(_selectedValue)) {
      _selectedValue = _rootValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final candidates = widget.locations
        .where((location) => !widget.blockedIds.contains(location.id))
        .toList(growable: false);
    if (_selectedValue != _rootValue &&
        !candidates.any((location) => location.id == _selectedValue)) {
      _selectedValue = _rootValue;
    }
    return AlertDialog(
      title: Text(widget.title),
      content: DropdownButtonFormField<String>(
        key: const Key('project-location-parent-selector'),
        initialValue: _selectedValue,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Yeni üst mahal',
          border: OutlineInputBorder(),
        ),
        items: [
          const DropdownMenuItem(value: _rootValue, child: Text('Kök mahal')),
          ...candidates.map(
            (location) => DropdownMenuItem(
              value: location.id,
              child: Text(
                location.displayName,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
        onChanged: (value) {
          if (value != null) setState(() => _selectedValue = value);
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          key: const Key('save-project-location-parent'),
          onPressed: () => Navigator.pop(
            context,
            _ParentSelectionResult(
              _selectedValue == _rootValue ? null : _selectedValue,
            ),
          ),
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}
