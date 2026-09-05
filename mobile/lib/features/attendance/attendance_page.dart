import 'dart:async';

import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/application/attendance_application.dart';
import 'package:chief_site_engineer/core/record_id.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/attendance_models.dart';
import 'package:chief_site_engineer/features/attendance/attendance_day_page.dart';
import 'package:chief_site_engineer/features/attendance/attendance_settings_page.dart';
import 'package:chief_site_engineer/features/attendance/workforce_page.dart';
import 'package:chief_site_engineer/features/screen_tool_rail.dart';
import 'package:chief_site_engineer/features/projects/project_create_page.dart';
import 'package:flutter/material.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({
    required this.attendance,
    required this.agenda,
    required this.activeProjectId,
    required this.isActive,
    this.onProjectSelected,
    super.key,
  });

  final AttendanceApplication attendance;
  final AgendaApplication agenda;
  final String? activeProjectId;
  final bool isActive;
  final ValueChanged<String>? onProjectSelected;

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, _EnsureIds> _ensureIds = {};
  List<MobileProject> _projects = const [];
  MobileProject? _project;
  AttendanceDayDetail? _detail;
  late String _localDate;
  bool _loading = false;
  bool _projectsDiscovered = false;
  bool _projectReadFailed = false;
  bool _dayReadFailed = false;
  bool _creatingProject = false;
  String? _error;
  List<ActiveTeamCount> _teamCounts = const [];
  StreamSubscription<void>? _projectSubscription;
  bool _detailNavigationBusy = false;
  int _projectFieldGeneration = 0;
  int _projectLoadGeneration = 0;
  int _dayLoadGeneration = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now().toUtc();
    _localDate = CseTimeCodec.istanbulDayKey(CseTimeCodec.encodeUtc(now));
    _projectSubscription = widget.agenda.projectChanges.listen((_) {
      if (widget.isActive) unawaited(_loadProjects());
    });
    if (widget.isActive) unawaited(_loadProjects());
  }

  @override
  void didUpdateWidget(covariant AttendancePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isActive) {
      _projectLoadGeneration += 1;
      _dayLoadGeneration += 1;
      if (oldWidget.isActive && _loading) setState(() => _loading = false);
      return;
    }
    final becameActive = !oldWidget.isActive;
    final sharedProjectChanged =
        oldWidget.activeProjectId != widget.activeProjectId;
    final currentProjectIsShared =
        _project?.id == widget.activeProjectId && _detail != null;
    if (becameActive || (sharedProjectChanged && !currentProjectIsShared)) {
      unawaited(_loadProjects());
    }
  }

  @override
  void dispose() {
    _projectSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    if (!widget.isActive) return;
    final generation = ++_projectLoadGeneration;
    final preserveDetail =
        _detail != null && _project?.id == widget.activeProjectId;
    setState(() {
      _loading = true;
      _error = null;
      _projectReadFailed = false;
      _dayReadFailed = false;
      if (!preserveDetail) {
        _detail = null;
        _teamCounts = const [];
      }
    });
    try {
      final discoveredProjects = await widget.agenda.listProjects();
      if (!mounted ||
          !widget.isActive ||
          generation != _projectLoadGeneration) {
        return;
      }
      final projects = discoveredProjects
          .where((project) => !project.isArchived)
          .toList(growable: false);
      final activeProjectId = widget.activeProjectId;
      final project = activeProjectId == null
          ? null
          : projects
                .where((candidate) => candidate.id == activeProjectId)
                .firstOrNull;
      setState(() {
        _projectsDiscovered = true;
        if (_project?.id != project?.id) {
          _detail = null;
          _teamCounts = const [];
        }
        _projects = projects;
        _project = project;
        _projectFieldGeneration += 1;
      });
      if (project != null) await _loadDay(project: project);
    } on Object {
      if (!mounted ||
          !widget.isActive ||
          generation != _projectLoadGeneration) {
        return;
      }
      setState(() {
        _projectsDiscovered = false;
        _projectReadFailed = true;
        if (!preserveDetail) {
          _projects = const [];
          _project = null;
          _projectFieldGeneration += 1;
          _detail = null;
          _teamCounts = const [];
        }
        _error = 'Projeler açılamadı. Lütfen tekrar deneyin.';
      });
    } finally {
      if (mounted && widget.isActive && generation == _projectLoadGeneration) {
        setState(() => _loading = false);
      }
    }
  }

  Future<bool> _loadDay({MobileProject? project, double? restoreOffset}) async {
    if (!widget.isActive) return false;
    final selectedProject = project ?? _project;
    if (selectedProject == null) return false;
    final generation = ++_dayLoadGeneration;
    setState(() {
      _loading = true;
      _error = null;
      _dayReadFailed = false;
      _projectReadFailed = false;
    });
    try {
      final key = '${selectedProject.id}:$_localDate';
      final ids = _ensureIds.putIfAbsent(
        key,
        () => _EnsureIds(RecordId.randomUuid(), RecordId.randomUuid()),
      );
      final day = await widget.attendance.ensureDay(
        EnsureAttendanceDayCommand(
          id: ids.dayId,
          eventId: ids.eventId,
          projectId: selectedProject.id,
          localDate: _localDate,
        ),
      );
      await widget.attendance.ensureRollingOccurrences();
      final detail = await widget.attendance.getDayDetail(day.id);
      final teamCounts = await widget.attendance.listActiveTeamCounts(
        selectedProject.id,
      );
      if (!mounted ||
          !widget.isActive ||
          generation != _dayLoadGeneration ||
          _project?.id != selectedProject.id) {
        return false;
      }
      setState(() {
        _detail = detail;
        _teamCounts = teamCounts;
      });
      _restoreScrollOffset(restoreOffset);
      return true;
    } on Object {
      if (mounted && widget.isActive && generation == _dayLoadGeneration) {
        setState(() {
          _dayReadFailed = true;
          _error = 'Puantaj günü açılamadı.';
        });
        _restoreScrollOffset(restoreOffset);
      }
      return false;
    } finally {
      if (mounted && widget.isActive && generation == _dayLoadGeneration) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _selectProject(String projectId) async {
    final project = _projects
        .where((candidate) => candidate.id == projectId)
        .firstOrNull;
    if (project == null) return;
    final previousProject = _project;
    final previousDetail = _detail;
    final previousTeamCounts = _teamCounts;
    setState(() {
      _project = project;
      _projectFieldGeneration += 1;
      _detail = null;
      _teamCounts = const [];
    });
    final loaded = await _loadDay(project: project);
    if (!mounted || !widget.isActive || _project?.id != projectId) return;
    if (loaded) {
      widget.onProjectSelected?.call(projectId);
      return;
    }
    setState(() {
      _project = previousProject;
      _projectFieldGeneration += 1;
      _detail = previousDetail;
      _teamCounts = previousTeamCounts;
      _dayReadFailed = false;
      _error =
          'Proje açılamadı. Önceki seçim korundu. Yeniden proje seçerek deneyebilirsiniz.';
    });
  }

  Future<void> _retryRead() async {
    if (_loading || !widget.isActive) return;
    final offset = _currentScrollOffset;
    if (_projectReadFailed) {
      await _loadProjects();
      _restoreScrollOffset(offset);
    } else if (_dayReadFailed) {
      await _loadDay(restoreOffset: offset);
    }
  }

  Future<void> _createProject() async {
    if (_creatingProject || _loading || !widget.isActive) return;
    setState(() => _creatingProject = true);
    try {
      final project = await Navigator.of(context).push<MobileProject>(
        MaterialPageRoute(
          builder: (_) => ProjectCreatePage(agenda: widget.agenda),
        ),
      );
      if (!mounted || !widget.isActive || project == null) return;
      final onSelected = widget.onProjectSelected;
      if (onSelected != null) {
        onSelected(project.id);
      } else {
        await _loadProjects();
      }
    } finally {
      if (mounted) setState(() => _creatingProject = false);
    }
  }

  Future<void> _shiftDay(int delta) async {
    setState(() {
      _localDate = CseTimeCodec.shiftIstanbulDay(_localDate, delta);
      _detail = null;
    });
    await _loadDay();
  }

  Future<void> _today() async {
    final now = DateTime.now().toUtc();
    setState(() {
      _localDate = CseTimeCodec.istanbulDayKey(CseTimeCodec.encodeUtc(now));
      _detail = null;
    });
    await _loadDay();
  }

  Future<void> _pickDate() async {
    final initial = DateTime.parse(_localDate);
    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selected == null) return;
    setState(() {
      _localDate =
          '${selected.year.toString().padLeft(4, '0')}-'
          '${selected.month.toString().padLeft(2, '0')}-'
          '${selected.day.toString().padLeft(2, '0')}';
      _detail = null;
    });
    await _loadDay();
  }

  Future<void> _openDay() async {
    final detail = _detail;
    if (detail == null || _detailNavigationBusy) return;
    final restoreOffset = _currentScrollOffset;
    _detailNavigationBusy = true;
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => AttendanceDayPage(
            attendance: widget.attendance,
            agenda: widget.agenda,
            dayId: detail.day.id,
          ),
        ),
      );
      if (mounted) await _loadDay(restoreOffset: restoreOffset);
    } finally {
      _detailNavigationBusy = false;
    }
  }

  Future<void> _openWorkforce() async {
    final project = _project;
    if (project == null || _detailNavigationBusy) return;
    final restoreOffset = _currentScrollOffset;
    _detailNavigationBusy = true;
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) =>
              WorkforcePage(attendance: widget.attendance, project: project),
        ),
      );
      if (mounted) await _loadDay(restoreOffset: restoreOffset);
    } finally {
      _detailNavigationBusy = false;
    }
  }

  Future<void> _openSettings() async {
    final project = _project;
    if (project == null || _detailNavigationBusy) return;
    final restoreOffset = _currentScrollOffset;
    _detailNavigationBusy = true;
    try {
      await Navigator.of(context).push<AttendanceReminderSetting>(
        MaterialPageRoute(
          builder: (_) => AttendanceSettingsPage(
            attendance: widget.attendance,
            project: project,
          ),
        ),
      );
      if (mounted) await _loadDay(restoreOffset: restoreOffset);
    } finally {
      _detailNavigationBusy = false;
    }
  }

  double? get _currentScrollOffset =>
      _scrollController.hasClients ? _scrollController.offset : null;

  void _restoreScrollOffset(double? requestedOffset) {
    if (requestedOffset == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final position = _scrollController.position;
      final target = requestedOffset
          .clamp(position.minScrollExtent, position.maxScrollExtent)
          .toDouble();
      if ((position.pixels - target).abs() > 0.5) {
        _scrollController.jumpTo(target);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
    final activePersonCount = _teamCounts.fold<int>(
      0,
      (total, team) => total + team.activePersonCount,
    );
    final needsWorkforce =
        !_loading &&
        !_projectReadFailed &&
        !_dayReadFailed &&
        detail != null &&
        detail.day.status == AttendanceDayStatus.draft &&
        detail.entries.isEmpty &&
        activePersonCount == 0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ListView(
            key: const Key('attendance-page'),
            controller: _scrollController,
            padding: const EdgeInsets.all(12),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 840),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_projectsDiscovered && _projects.isEmpty && !_loading)
                        Card(
                          key: const Key('attendance-no-project'),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Puantaj için önce Ajanda bölümünden bir proje oluşturun.',
                                ),
                                const SizedBox(height: 12),
                                FilledButton(
                                  key: const Key('attendance-create-project'),
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size(48, 48),
                                  ),
                                  onPressed: _creatingProject
                                      ? null
                                      : _createProject,
                                  child: const Text('Yeni proje oluştur'),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (_projects.isNotEmpty) ...[
                        KeyedSubtree(
                          key: const Key('attendance-project'),
                          child: DropdownButtonFormField<String>(
                            key: ValueKey(
                              'attendance-project-field-$_projectFieldGeneration',
                            ),
                            initialValue: _project?.id,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Proje',
                              border: OutlineInputBorder(),
                            ),
                            items: _projects
                                .map(
                                  (project) => DropdownMenuItem(
                                    value: project.id,
                                    child: Text(
                                      project.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                            onChanged: (id) {
                              if (id != null) unawaited(_selectProject(id));
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Seçili gün',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          key: const Key('attendance-date-picker'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(48, 48),
                          ),
                          onPressed: _loading ? null : _pickDate,
                          child: Text(_localDate),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            IconButton.outlined(
                              key: const Key('attendance-previous-day'),
                              style: IconButton.styleFrom(
                                minimumSize: const Size.square(48),
                                visualDensity: VisualDensity.standard,
                              ),
                              tooltip: 'Önceki gün',
                              onPressed: _loading ? null : () => _shiftDay(-1),
                              icon: const Icon(Icons.chevron_left),
                            ),
                            OutlinedButton(
                              key: const Key('attendance-today'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(48, 48),
                              ),
                              onPressed: _loading ? null : _today,
                              child: const Text('Bugün'),
                            ),
                            IconButton.outlined(
                              key: const Key('attendance-next-day'),
                              style: IconButton.styleFrom(
                                minimumSize: const Size.square(48),
                                visualDensity: VisualDensity.standard,
                              ),
                              tooltip: 'Sonraki gün',
                              onPressed: _loading ? null : () => _shiftDay(1),
                              icon: const Icon(Icons.chevron_right),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                _error!,
                                key: const Key('attendance-page-error'),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                              if (_projectReadFailed || _dayReadFailed) ...[
                                const SizedBox(height: 8),
                                OutlinedButton(
                                  key: const Key('attendance-retry'),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(48, 48),
                                  ),
                                  onPressed: _loading ? null : _retryRead,
                                  child: const Text('Tekrar dene'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      if (detail != null)
                        SizedBox(
                          height: 4,
                          child: _loading
                              ? const LinearProgressIndicator(
                                  key: Key('attendance-refreshing'),
                                )
                              : null,
                        ),
                      if (_loading && detail == null)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      if (needsWorkforce)
                        Card(
                          key: const Key('attendance-workforce-prerequisite'),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Önce personeli hazırlayın',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Bu projede aktif personel yok. Günlük puantaj '
                                  'girişi için Personel bölümünden aktif personeli hazırlayın.',
                                ),
                                const SizedBox(height: 12),
                                FilledButton(
                                  key: const Key('attendance-setup-workforce'),
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size(48, 48),
                                    visualDensity: VisualDensity.standard,
                                  ),
                                  onPressed: _openWorkforce,
                                  child: const Text('Personel yönetimini aç'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (detail != null)
                        Card(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          child: InkWell(
                            key: const Key('open-attendance-day'),
                            onTap: _loading ? null : _openDay,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Puantaj günü',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelLarge,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    detail.day.status.label,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${detail.totals.personDayEquivalent.toStringAsFixed(1)} kişi-gün • '
                                    '${detail.totals.overtimeMinutes} dk fazla mesai',
                                  ),
                                  const SizedBox(height: 8),
                                  const Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Puantaj gününü aç',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Icon(Icons.chevron_right),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      if (_teamCounts.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          '${_teamCounts.length} aktif ekip • $activePersonCount aktif personel',
                          key: const Key('attendance-team-summary'),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        ScreenToolRail(
          actions: [
            ScreenToolAction(
              key: const Key('manage-workforce'),
              label: 'Personel',
              icon: Icons.groups_outlined,
              onPressed: _project == null ? null : _openWorkforce,
            ),
            ScreenToolAction(
              key: const Key('attendance-reminder-settings'),
              label: 'Hatırlatıcı',
              icon: Icons.notifications_active_outlined,
              onPressed: _project == null ? null : _openSettings,
            ),
          ],
        ),
      ],
    );
  }
}

class _EnsureIds {
  const _EnsureIds(this.dayId, this.eventId);

  final String dayId;
  final String eventId;
}
