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
import 'package:flutter/material.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({
    required this.attendance,
    required this.agenda,
    super.key,
  });

  final AttendanceApplication attendance;
  final AgendaApplication agenda;

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
  bool _loading = true;
  String? _error;
  List<ActiveTeamCount> _teamCounts = const [];
  StreamSubscription<void>? _projectSubscription;
  bool _detailNavigationBusy = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now().toUtc();
    _localDate = CseTimeCodec.istanbulDayKey(CseTimeCodec.encodeUtc(now));
    _projectSubscription = widget.agenda.projectChanges.listen(
      (_) => _loadProjects(),
    );
    _loadProjects();
  }

  @override
  void dispose() {
    _projectSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final projects = await widget.agenda.listProjects();
      if (!mounted) return;
      _projects = projects;
      _project = _project == null
          ? projects.firstOrNull
          : projects.where((item) => item.id == _project!.id).firstOrNull;
      if (_project != null) {
        await _loadDay();
      } else {
        _teamCounts = const [];
        _detail = null;
      }
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _error = _message(error, 'Projeler açılamadı.'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadDay({double? restoreOffset}) async {
    final project = _project;
    if (project == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final key = '${project.id}:$_localDate';
      final ids = _ensureIds.putIfAbsent(
        key,
        () => _EnsureIds(RecordId.randomUuid(), RecordId.randomUuid()),
      );
      final day = await widget.attendance.ensureDay(
        EnsureAttendanceDayCommand(
          id: ids.dayId,
          eventId: ids.eventId,
          projectId: project.id,
          localDate: _localDate,
        ),
      );
      await widget.attendance.ensureRollingOccurrences();
      final detail = await widget.attendance.getDayDetail(day.id);
      final teamCounts = await widget.attendance.listActiveTeamCounts(
        project.id,
      );
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _teamCounts = teamCounts;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _error = _message(error, 'Puantaj günü açılamadı.'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
    _restoreScrollOffset(restoreOffset);
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
    return ListView(
      key: const Key('attendance-page'),
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      children: [
        if (_projects.isEmpty && !_loading)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Puantaj için önce Ajanda bölümünden bir proje oluşturun.',
              ),
            ),
          )
        else ...[
          DropdownButtonFormField<String>(
            key: const Key('attendance-project'),
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
                    child: Text(project.name, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(growable: false),
            onChanged: (id) {
              if (id == null) return;
              setState(() {
                _project = _projects.firstWhere((item) => item.id == id);
                _detail = null;
              });
              _loadDay();
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              IconButton.outlined(
                key: const Key('attendance-previous-day'),
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                tooltip: 'Önceki gün',
                onPressed: _loading ? null : () => _shiftDay(-1),
                icon: const Icon(Icons.chevron_left),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('attendance-date-picker'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                  ),
                  onPressed: _loading ? null : _pickDate,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(_localDate),
                ),
              ),
              const SizedBox(width: 6),
              IconButton.outlined(
                key: const Key('attendance-next-day'),
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                tooltip: 'Sonraki gün',
                onPressed: _loading ? null : () => _shiftDay(1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 6),
          OutlinedButton(
            key: const Key('attendance-today'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
            ),
            onPressed: _loading ? null : _today,
            child: const Text('Bugün'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const Key('manage-workforce'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
            ),
            onPressed: _openWorkforce,
            icon: const Icon(Icons.groups_outlined),
            label: const Text('Taşeronlar ve ekipler'),
          ),
          if (_teamCounts.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Aktif ekipler',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            for (final team in _teamCounts)
              Card(
                key: Key('active-team-${team.teamId}'),
                child: ListTile(
                  dense: true,
                  title: Text(
                    '${team.teamName} — ${team.activePersonCount} kişi',
                  ),
                  subtitle: Text(team.subcontractorName),
                ),
              ),
          ],
          const SizedBox(height: 6),
          OutlinedButton.icon(
            key: const Key('attendance-reminder-settings'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
            ),
            onPressed: _openSettings,
            icon: const Icon(Icons.notifications_active_outlined),
            label: const Text('Puantaj hatırlatıcısı'),
          ),
        ],
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              _error!,
              key: const Key('attendance-page-error'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (detail != null)
          Card(
            child: InkWell(
              key: const Key('open-attendance-day'),
              onTap: _openDay,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.day.status.label,
                      style: Theme.of(context).textTheme.titleLarge,
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
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.ellipsis,
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
      ],
    );
  }

  String _message(Object error, String fallback) =>
      error is AgendaValidationFailure ? error.message : fallback;
}

class _EnsureIds {
  const _EnsureIds(this.dayId, this.eventId);

  final String dayId;
  final String eventId;
}
