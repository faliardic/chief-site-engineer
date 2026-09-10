import 'dart:async';

import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/application/attendance_application.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/attendance_models.dart';
import 'package:chief_site_engineer/features/attendance/workforce_page.dart';
import 'package:chief_site_engineer/features/attendance/workforce_person_detail_page.dart';
import 'package:chief_site_engineer/features/attendance/workforce_registry_page.dart';
import 'package:chief_site_engineer/features/screen_tool_rail.dart';
import 'package:flutter/material.dart';

class WorkforceDirectoryPage extends StatefulWidget {
  const WorkforceDirectoryPage({
    required this.attendance,
    required this.agenda,
    this.initialProjectId,
    this.activeProjectId,
    this.usesSharedProjectContext = false,
    this.isActive = true,
    this.onProjectSelected,
    super.key,
  });

  final AttendanceApplication attendance;
  final AgendaApplication agenda;
  final String? initialProjectId;
  final String? activeProjectId;
  final bool usesSharedProjectContext;
  final bool isActive;
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
  bool _hasLoadedProjects = false;
  bool _refreshOnActivation = false;
  int _projectLoadGeneration = 0;
  int _directoryLoadGeneration = 0;
  bool _projectDiscoveryFailed = false;
  bool _navigationBusy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _projectIdToValidate = _requestedProjectId;
    _search.addListener(_refreshFilter);
    _projectSubscription = widget.agenda.projectChanges.listen((_) {
      if (widget.isActive) {
        unawaited(_loadProjects());
      } else {
        _refreshOnActivation = true;
      }
    });
    if (widget.isActive) unawaited(_loadProjects());
  }

  String? get _requestedProjectId => widget.usesSharedProjectContext
      ? widget.activeProjectId
      : widget.initialProjectId;

  @override
  void didUpdateWidget(covariant WorkforceDirectoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldRequestedProjectId = oldWidget.usesSharedProjectContext
        ? oldWidget.activeProjectId
        : oldWidget.initialProjectId;
    final requestedProjectChanged =
        oldRequestedProjectId != _requestedProjectId ||
        oldWidget.usesSharedProjectContext != widget.usesSharedProjectContext;
    if (requestedProjectChanged) {
      _projectIdToValidate = _requestedProjectId;
      _refreshOnActivation = true;
    }
    if (!widget.isActive) {
      if (oldWidget.isActive) {
        _projectLoadGeneration += 1;
        _directoryLoadGeneration += 1;
        if (_loading) setState(() => _loading = false);
      }
      return;
    }
    if (!oldWidget.isActive || requestedProjectChanged) {
      if (_refreshOnActivation || !_hasLoadedProjects) {
        unawaited(_loadProjects());
      }
    }
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
    if (!widget.isActive) return;
    final generation = ++_projectLoadGeneration;
    _directoryLoadGeneration += 1;
    final projectIdToValidate = _projectIdToValidate;
    _refreshOnActivation = false;
    setState(() {
      _projects = const [];
      _project = null;
      _members = const [];
      _subcontractors = const [];
      _teams = const [];
      _loading = true;
      _hasLoadedProjects = false;
      _projectDiscoveryFailed = false;
      _error = null;
    });
    try {
      final projects = (await widget.agenda.listProjects())
          .where((project) => !project.isArchived)
          .toList(growable: false);
      if (!mounted ||
          !widget.isActive ||
          generation != _projectLoadGeneration) {
        return;
      }
      final selected = projects
          .where((project) => project.id == projectIdToValidate)
          .firstOrNull;
      final project =
          selected ??
          (!widget.usesSharedProjectContext && widget.initialProjectId == null
              ? projects.firstOrNull
              : null);
      setState(() {
        _projects = projects;
        _project = project;
        _hasLoadedProjects = true;
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
      if (mounted && widget.isActive && generation == _projectLoadGeneration) {
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
      if (mounted && widget.isActive && generation == _projectLoadGeneration) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadDirectory([MobileProject? requestedProject]) async {
    if (!widget.isActive) return;
    final project = requestedProject ?? _project;
    if (project == null) return;
    final generation = ++_directoryLoadGeneration;
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
      if (!mounted ||
          !widget.isActive ||
          generation != _directoryLoadGeneration ||
          _project?.id != project.id) {
        return;
      }
      setState(() {
        _members = values[0] as List<WorkforceMember>;
        _subcontractors = values[1] as List<Subcontractor>;
        _teams = values[2] as List<WorkforceTeam>;
      });
    } on Object catch (error) {
      if (mounted &&
          widget.isActive &&
          generation == _directoryLoadGeneration) {
        setState(() => _error = _message(error, 'Sicil kayıtları açılamadı.'));
      }
    } finally {
      if (mounted &&
          widget.isActive &&
          generation == _directoryLoadGeneration) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> selectProject(String projectId) async {
    if (!widget.isActive || projectId == _project?.id || _loading) return;
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

  Future<void> _openFirstUseFlow() async {
    final project = _project;
    if (project == null || _navigationBusy) return;
    _navigationBusy = true;
    try {
      final subcontractor = await Navigator.of(context).push<Subcontractor>(
        MaterialPageRoute(
          builder: (_) => WorkforceRegistryPage(
            attendance: widget.attendance,
            project: project,
            startWithCompanyForm: true,
          ),
        ),
      );
      if (!mounted) return;
      if (!widget.isActive ||
          _project?.id != project.id ||
          subcontractor == null) {
        return;
      }

      var addAnother = true;
      while (addAnother) {
        if (!mounted) break;
        if (!widget.isActive || _project?.id != project.id) break;
        final member = await Navigator.of(context).push<WorkforceMember>(
          MaterialPageRoute(
            builder: (_) => WorkforceMemberFormPage(
              attendance: widget.attendance,
              project: project,
              initialSubcontractorId: subcontractor.id,
            ),
          ),
        );
        if (!mounted ||
            !widget.isActive ||
            _project?.id != project.id ||
            member == null) {
          break;
        }
        await _loadDirectory(project);
        if (!mounted || !widget.isActive || _project?.id != project.id) {
          break;
        }
        addAnother =
            await showDialog<bool>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Text('Personel kaydedildi'),
                content: Text('${member.fullName} sicile eklendi.'),
                actions: [
                  TextButton(
                    key: const Key('workforce-quick-flow-done'),
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('Sicile dön'),
                  ),
                  FilledButton(
                    key: const Key('workforce-quick-flow-add-another'),
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: const Text('Başka personel ekle'),
                  ),
                ],
              ),
            ) ??
            false;
      }
      if (mounted && widget.isActive && _project?.id == project.id) {
        await _loadDirectory(project);
      }
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
            if (!_usesTechnicalTeam(member)) member.teamName,
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
                    labelText: 'Taşeron / İşveren',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Tüm firmalar'),
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
                  if (_loading ||
                      (!_projectDiscoveryFailed && _projects.isNotEmpty))
                    ScreenToolAction(
                      key: const Key('manage-workforce-directory'),
                      label: 'Sicili yönet',
                      icon: Icons.manage_accounts_outlined,
                      onPressed: _loading || _project == null
                          ? null
                          : _openManagement,
                    ),
                ],
              ),
            ],
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
          'Personel sicili, firma ve ekip bağlarıyla proje kapsamında görünür.',
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
                labelText: 'Ad, telefon, görev, firma veya ekip ara',
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
                    'Firma: ${_subcontractors.where((item) => item.id == _subcontractorId).map((item) => item.name).firstOrNull ?? _subcontractorId}',
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
          else if (project != null &&
              _error == null &&
              members.isEmpty &&
              _members.isEmpty &&
              _subcontractors.isEmpty)
            Card(
              key: const Key('workforce-directory-first-use'),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'İlk firma ve personel kaydınızı oluşturarak sicili başlatın.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      key: const Key('add-first-workforce-company'),
                      onPressed: _openFirstUseFlow,
                      icon: const Icon(Icons.add_business_outlined),
                      label: const Text('Taşeron / İşveren ekle'),
                    ),
                  ],
                ),
              ),
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
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.fullName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        member.roleName,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                  subtitle: Text(
                    '${member.phone ?? 'Telefon yok'}\n'
                    '${_memberRegistryLabel(member)}\n'
                    '${member.isActive ? 'Aktif' : 'Arşiv'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
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

bool _usesTechnicalTeam(WorkforceMember member) => isWorkforceTechnicalTeamLink(
  projectId: member.projectId,
  subcontractorId: member.subcontractorId,
  teamId: member.teamId,
);

String _memberRegistryLabel(WorkforceMember member) {
  final subcontractor = member.subcontractorName ?? 'Tanımsız firma';
  return _usesTechnicalTeam(member)
      ? subcontractor
      : '$subcontractor • ${member.teamName}';
}

enum _DirectoryStatus { active, archived }

String _normalized(String value) => value
    .trim()
    .toLowerCase()
    .replaceAll('\u0131', 'i')
    .replaceAll('\u0307', '');

String _message(Object error, String fallback) =>
    error is AgendaValidationFailure ? error.message : fallback;
