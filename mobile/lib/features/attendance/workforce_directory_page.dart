import 'dart:async';

import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/application/attendance_application.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/attendance_models.dart';
import 'package:chief_site_engineer/features/attendance/workforce_page.dart';
import 'package:chief_site_engineer/features/attendance/workforce_person_detail_page.dart';
import 'package:chief_site_engineer/features/screen_tool_rail.dart';
import 'package:flutter/material.dart';

class WorkforceDirectoryPage extends StatefulWidget {
  const WorkforceDirectoryPage({
    required this.attendance,
    required this.agenda,
    this.initialProjectId,
    this.onProjectSelected,
    super.key,
  });

  final AttendanceApplication attendance;
  final AgendaApplication agenda;
  final String? initialProjectId;
  final ValueChanged<String>? onProjectSelected;

  @override
  State<WorkforceDirectoryPage> createState() => WorkforceDirectoryPageState();
}

class WorkforceDirectoryPageState extends State<WorkforceDirectoryPage> {
  final TextEditingController _search = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final GlobalKey _searchFieldKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<void>? _projectSubscription;
  List<MobileProject> _projects = const [];
  String? _projectIdToValidate;
  MobileProject? _project;
  List<WorkforceMember> _members = const [];
  List<Subcontractor> _subcontractors = const [];
  List<WorkforceTeam> _teams = const [];
  _DirectoryStatus _status = _DirectoryStatus.active;
  String? _subcontractorId;
  String? _teamId;
  bool _loading = true;
  bool _projectDiscoveryFailed = false;
  bool _navigationBusy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _projectIdToValidate = widget.initialProjectId;
    _search.addListener(_refreshFilter);
    _projectSubscription = widget.agenda.projectChanges.listen(
      (_) => _loadProjects(),
    );
    _loadProjects();
  }

  @override
  void dispose() {
    _projectSubscription?.cancel();
    _searchFocus.dispose();
    _scrollController.dispose();
    _search
      ..removeListener(_refreshFilter)
      ..dispose();
    super.dispose();
  }

  void _refreshFilter() {
    if (mounted) setState(() {});
  }

  Future<void> _loadProjects() async {
    final projectIdToValidate = _projectIdToValidate;
    setState(() {
      _projects = const [];
      _project = null;
      _members = const [];
      _subcontractors = const [];
      _teams = const [];
      _loading = true;
      _projectDiscoveryFailed = false;
      _error = null;
    });
    try {
      final projects = (await widget.agenda.listProjects())
          .where((project) => !project.isArchived)
          .toList(growable: false);
      if (!mounted) return;
      final selected = projects
          .where((project) => project.id == projectIdToValidate)
          .firstOrNull;
      final project =
          selected ??
          (widget.initialProjectId == null ? projects.firstOrNull : null);
      setState(() {
        _projects = projects;
        _project = project;
        if (project != null) _projectIdToValidate = project.id;
        _subcontractorId = null;
        _teamId = null;
      });
      if (project == null) {
        setState(() {
          _members = const [];
          _subcontractors = const [];
          _teams = const [];
        });
      } else {
        await _loadDirectory(project);
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _projects = const [];
          _project = null;
          _members = const [];
          _subcontractors = const [];
          _teams = const [];
          _projectDiscoveryFailed = true;
          _error = _message(error, 'Saha Rehberi açılamadı.');
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadDirectory([MobileProject? requestedProject]) async {
    final project = requestedProject ?? _project;
    if (project == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final values = await Future.wait([
        widget.attendance.listMembers(project.id, includeInactive: true),
        widget.attendance.listSubcontractors(project.id, includeArchived: true),
        widget.attendance.listTeams(project.id, includeArchived: true),
      ]);
      if (!mounted || _project?.id != project.id) return;
      setState(() {
        _members = values[0] as List<WorkforceMember>;
        _subcontractors = values[1] as List<Subcontractor>;
        _teams = values[2] as List<WorkforceTeam>;
      });
    } on Object catch (error) {
      if (mounted) {
        setState(() => _error = _message(error, 'Sicil kayıtları açılamadı.'));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> selectProject(String projectId) async {
    if (projectId == _project?.id || _loading) return;
    final project = _projects
        .where((candidate) => candidate.id == projectId)
        .firstOrNull;
    if (project == null) return;
    setState(() {
      _projectIdToValidate = projectId;
      _project = project;
      _subcontractorId = null;
      _teamId = null;
    });
    widget.onProjectSelected?.call(projectId);
    await _loadDirectory(project);
  }

  Future<void> _openManagement() async {
    final project = _project;
    if (project == null || _navigationBusy) return;
    _navigationBusy = true;
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) =>
              WorkforcePage(attendance: widget.attendance, project: project),
        ),
      );
      if (mounted) await _loadDirectory(project);
    } finally {
      _navigationBusy = false;
    }
  }

  Future<void> _openPerson(WorkforceMember member) async {
    if (_navigationBusy) return;
    _navigationBusy = true;
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => WorkforcePersonDetailPage(
            attendance: widget.attendance,
            memberId: member.id,
          ),
        ),
      );
      if (mounted && _project != null) await _loadDirectory();
    } finally {
      _navigationBusy = false;
    }
  }

  List<WorkforceMember> get _visibleMembers {
    final query = _normalized(_search.text);
    return _members
        .where((member) {
          if (_status == _DirectoryStatus.active && !member.isActive) {
            return false;
          }
          if (_status == _DirectoryStatus.archived && member.isActive) {
            return false;
          }
          if (_subcontractorId != null &&
              member.subcontractorId != _subcontractorId) {
            return false;
          }
          if (_teamId != null && member.teamId != _teamId) return false;
          if (query.isEmpty) return true;
          return [
            member.fullName,
            member.phone,
            member.roleName,
            member.subcontractorName,
            member.teamName,
          ].whereType<String>().any(
            (value) => _normalized(value).contains(query),
          );
        })
        .toList(growable: false);
  }

  Future<void> _revealSearch() async {
    if (_searchFieldKey.currentContext == null &&
        _scrollController.hasClients) {
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
    // On short screens the introductory text can put the field beyond the
    // ListView's initial cache. Build that part of the list before requesting focus.
    while (mounted &&
        _searchFieldKey.currentContext == null &&
        _scrollController.hasClients) {
      final position = _scrollController.position;
      final target = (position.pixels + position.viewportDimension)
          .clamp(position.minScrollExtent, position.maxScrollExtent)
          .toDouble();
      if (target <= position.pixels) break;
      await _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
    }
    if (!mounted) return;
    _searchFocus.requestFocus();
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    final fieldContext = _searchFieldKey.currentContext;
    if (fieldContext != null && fieldContext.mounted) {
      await Scrollable.ensureVisible(
        fieldContext,
        alignment: 0,
        duration: const Duration(milliseconds: 200),
      );
    }
  }

  Future<void> _showFilters() async {
    final project = _project;
    if (project == null || _loading) return;
    var status = _status;
    var subcontractorId = _subcontractorId;
    var teamId = _teamId;
    final subcontractors = List.of(_subcontractors);
    final teams = List.of(_teams);
    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setDraftState) {
          final availableTeams = subcontractorId == null
              ? teams
              : teams
                    .where((team) => team.subcontractorId == subcontractorId)
                    .toList();
          return SafeArea(
            child: ListView(
              key: const Key('workforce-directory-filter-sheet'),
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                Text(
                  'Filtreler',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                SegmentedButton<_DirectoryStatus>(
                  key: const Key('workforce-directory-status'),
                  segments: const [
                    ButtonSegment(
                      value: _DirectoryStatus.active,
                      label: Text('Aktif'),
                      icon: Icon(Icons.check_circle_outline),
                    ),
                    ButtonSegment(
                      value: _DirectoryStatus.archived,
                      label: Text('Arşiv'),
                      icon: Icon(Icons.archive_outlined),
                    ),
                  ],
                  selected: {status},
                  onSelectionChanged: (value) =>
                      setDraftState(() => status = value.single),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  key: const Key('workforce-directory-subcontractor'),
                  initialValue: subcontractorId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Taşeron',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Tüm taşeronlar'),
                    ),
                    for (final item in subcontractors)
                      DropdownMenuItem(
                        value: item.id,
                        child: Text(item.name, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (value) => setDraftState(() {
                    subcontractorId = value;
                    if (!teams.any(
                      (item) =>
                          item.id == teamId &&
                          (value == null || item.subcontractorId == value),
                    )) {
                      teamId = null;
                    }
                  }),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  key: ValueKey(
                    'workforce-directory-team-$subcontractorId-$teamId',
                  ),
                  initialValue: teamId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Ekip',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Tüm ekipler'),
                    ),
                    for (final item in availableTeams)
                      DropdownMenuItem(
                        value: item.id,
                        child: Text(item.name, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (value) => setDraftState(() => teamId = value),
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TextButton(
                      key: const Key('workforce-directory-filter-cancel'),
                      onPressed: () => Navigator.pop(sheetContext, false),
                      child: const Text('Vazgeç'),
                    ),
                    FilledButton(
                      key: const Key('workforce-directory-filter-apply'),
                      onPressed: () => Navigator.pop(sheetContext, true),
                      child: const Text('Uygula'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
    if (applied != true || !mounted || _loading || _project?.id != project.id) {
      return;
    }
    if (subcontractorId != null &&
        !_subcontractors.any((item) => item.id == subcontractorId)) {
      return;
    }
    if (teamId != null &&
        !_teams.any(
          (item) =>
              item.id == teamId &&
              (subcontractorId == null ||
                  item.subcontractorId == subcontractorId),
        )) {
      return;
    }
    if (_status == status &&
        _subcontractorId == subcontractorId &&
        _teamId == teamId) {
      return;
    }
    setState(() {
      _status = status;
      _subcontractorId = subcontractorId;
      _teamId = teamId;
    });
  }

  bool get _hasActiveFilters =>
      _status != _DirectoryStatus.active ||
      _subcontractorId != null ||
      _teamId != null;

  Widget _filterChip(String key, String label, VoidCallback clear) => InputChip(
    key: Key(key),
    label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    tooltip: label,
    deleteButtonTooltipMessage: '$label filtresini temizle',
    onDeleted: () => setState(clear),
  );

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildContent(context)),
              ScreenToolRail(
                key: const Key('workforce-directory-tool-rail'),
                actions: [
                  ScreenToolAction(
                    key: const Key('workforce-directory-search-action'),
                    label: 'Ara',
                    icon: Icons.search,
                    onPressed: _loading || _project == null
                        ? null
                        : _revealSearch,
                  ),
                  ScreenToolAction(
                    key: const Key('workforce-directory-filter-action'),
                    label: 'Filtreler',
                    icon: Icons.filter_list_outlined,
                    onPressed: _loading || _project == null
                        ? null
                        : _showFilters,
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_loading || (!_projectDiscoveryFailed && _projects.isNotEmpty))
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: FilledButton(
              key: const Key('manage-workforce-directory'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: _loading || _project == null ? null : _openManagement,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.manage_accounts_outlined),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text('Sicili yönet', textAlign: TextAlign.center),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    ),
  );

  Widget _buildContent(BuildContext context) {
    final project = _project;
    final members = _visibleMembers;
    return ListView(
      key: const Key('workforce-directory'),
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 16),
      children: [
        Text('Saha Rehberi', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        const Text(
          'Personel sicili, taşeron ve ekip bağlarıyla proje kapsamında görünür.',
        ),
        const SizedBox(height: 12),
        if (_projectDiscoveryFailed && !_loading)
          Card(
            key: const Key('workforce-directory-project-error'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(_error ?? 'Projeler güvenli biçimde okunamadı.'),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    key: const Key('workforce-directory-project-retry'),
                    onPressed: _loadProjects,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Projeleri yeniden dene'),
                  ),
                ],
              ),
            ),
          )
        else if (_projects.isEmpty && !_loading)
          const Card(
            key: Key('workforce-directory-no-projects'),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Saha Rehberi için önce Ajanda bölümünden aktif bir proje oluşturun.',
              ),
            ),
          )
        else ...[
          if (project != null)
            Text(
              'Görünen proje: ${project.name}',
              key: const Key('workforce-directory-project-scope'),
              style: Theme.of(context).textTheme.labelLarge,
            ),
          if (project == null)
            const Card(
              key: Key('workforce-directory-project-context-unavailable'),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Başlangıç projesi artık kullanılamıyor. Aktif projeyi üst çubuktan seçin.',
                ),
              ),
            ),
          const SizedBox(height: 8),
          KeyedSubtree(
            key: _searchFieldKey,
            child: TextField(
              key: const Key('workforce-directory-search'),
              focusNode: _searchFocus,
              controller: _search,
              decoration: const InputDecoration(
                labelText: 'Ad, telefon, görev, taşeron veya ekip ara',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          if (_hasActiveFilters) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_status != _DirectoryStatus.active)
                  _filterChip(
                    'workforce-directory-summary-status',
                    'Durum: Arşiv',
                    () => _status = _DirectoryStatus.active,
                  ),
                if (_subcontractorId != null)
                  _filterChip(
                    'workforce-directory-summary-subcontractor',
                    'Taşeron: ${_subcontractors.where((item) => item.id == _subcontractorId).map((item) => item.name).firstOrNull ?? _subcontractorId}',
                    () => _subcontractorId = null,
                  ),
                if (_teamId != null)
                  _filterChip(
                    'workforce-directory-summary-team',
                    'Ekip: ${_teams.where((item) => item.id == _teamId).map((item) => item.name).firstOrNull ?? _teamId}',
                    () => _teamId = null,
                  ),
                TextButton(
                  key: const Key('workforce-directory-clear-filters'),
                  onPressed: () => setState(() {
                    _status = _DirectoryStatus.active;
                    _subcontractorId = null;
                    _teamId = null;
                  }),
                  child: const Text('Tüm filtreleri temizle'),
                ),
              ],
            ),
          ],
          if (_error case final error?)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                error,
                key: const Key('workforce-directory-error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (members.isEmpty)
            const Card(
              key: Key('workforce-directory-empty'),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Bu kapsam ve filtrelerde personel bulunmuyor.'),
              ),
            )
          else
            for (final member in members)
              Card(
                key: Key('workforce-directory-member-${member.id}'),
                child: ListTile(
                  onTap: () => _openPerson(member),
                  contentPadding: const EdgeInsets.all(12),
                  leading: Icon(
                    member.isActive
                        ? Icons.person_outline
                        : Icons.person_off_outlined,
                  ),
                  title: Text(member.fullName),
                  subtitle: Text(
                    '${member.phone ?? 'Telefon yok'} • ${member.roleName}\n'
                    '${member.subcontractorName ?? 'Tanımsız taşeron'} • ${member.teamName}\n'
                    '${member.isActive ? 'Aktif' : 'Arşiv'}',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                ),
              ),
        ],
      ],
    );
  }
}

enum _DirectoryStatus { active, archived }

String _normalized(String value) => value
    .trim()
    .toLowerCase()
    .replaceAll('\u0131', 'i')
    .replaceAll('\u0307', '');

String _message(Object error, String fallback) =>
    error is AgendaValidationFailure ? error.message : fallback;
