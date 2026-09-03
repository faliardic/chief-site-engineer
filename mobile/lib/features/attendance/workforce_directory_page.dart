import 'dart:async';

import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/application/attendance_application.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/attendance_models.dart';
import 'package:chief_site_engineer/features/attendance/workforce_page.dart';
import 'package:chief_site_engineer/features/attendance/workforce_person_detail_page.dart';
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
  State<WorkforceDirectoryPage> createState() => _WorkforceDirectoryPageState();
}

class _WorkforceDirectoryPageState extends State<WorkforceDirectoryPage> {
  final TextEditingController _search = TextEditingController();
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

  Future<void> _selectProject(String? id) async {
    if (id == null || id == _project?.id || _loading) return;
    final project = _projects.firstWhere((item) => item.id == id);
    setState(() {
      _projectIdToValidate = id;
      _project = project;
      _subcontractorId = null;
      _teamId = null;
    });
    widget.onProjectSelected?.call(id);
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

  List<WorkforceTeam> get _availableTeams => _subcontractorId == null
      ? _teams
      : _teams
            .where((item) => item.subcontractorId == _subcontractorId)
            .toList(growable: false);

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

  @override
  Widget build(BuildContext context) {
    final project = _project;
    final members = _visibleMembers;
    return ListView(
      key: const Key('workforce-directory'),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
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
          DropdownButtonFormField<String>(
            key: ValueKey('workforce-directory-project-${project?.id}'),
            initialValue: project?.id,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Proje',
              border: OutlineInputBorder(),
            ),
            items: _projects
                .map(
                  (item) => DropdownMenuItem(
                    value: item.id,
                    child: Text(item.name, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(growable: false),
            onChanged: _loading ? null : _selectProject,
          ),
          const SizedBox(height: 8),
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
                  'Başlangıç projesi artık kullanılamıyor. Devam etmek için bir proje seçin.',
                ),
              ),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const Key('manage-workforce-directory'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: _loading || project == null ? null : _openManagement,
            icon: const Icon(Icons.manage_accounts_outlined),
            label: const Text('Sicili yönet'),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('workforce-directory-search'),
            controller: _search,
            decoration: const InputDecoration(
              labelText: 'Ad, telefon, görev, taşeron veya ekip ara',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
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
            selected: {_status},
            onSelectionChanged: (value) {
              setState(() => _status = value.single);
            },
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            key: const Key('workforce-directory-subcontractor'),
            initialValue: _subcontractorId,
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
              ..._subcontractors.map(
                (item) => DropdownMenuItem(
                  value: item.id,
                  child: Text(item.name, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _subcontractorId = value;
                if (!_availableTeams.any((item) => item.id == _teamId)) {
                  _teamId = null;
                }
              });
            },
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            key: ValueKey(
              'workforce-directory-team-$_subcontractorId-$_teamId',
            ),
            initialValue: _teamId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Ekip',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Tüm ekipler')),
              ..._availableTeams.map(
                (item) => DropdownMenuItem(
                  value: item.id,
                  child: Text(item.name, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
            onChanged: (value) => setState(() => _teamId = value),
          ),
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
