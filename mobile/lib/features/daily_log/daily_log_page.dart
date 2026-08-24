import 'package:chief_site_engineer/application/daily_log_application.dart';
import 'package:chief_site_engineer/application/work_chain_application.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/daily_log_models.dart';
import 'package:chief_site_engineer/features/work_chain/work_chain_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DailyLogPage extends StatefulWidget {
  const DailyLogPage({required this.dailyLog, this.workChain, super.key});

  final DailyLogApplicationPort dailyLog;
  final WorkChainApplicationPort? workChain;

  @override
  State<DailyLogPage> createState() => _DailyLogPageState();
}

class _DailyLogPageState extends State<DailyLogPage> {
  late String _selectedDay;
  List<DailyLogProject> _projects = const [];
  String? _selectedProjectId;
  DailyLogDay? _day;
  String? _errorCode;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = CseTimeCodec.istanbulDayKey(
      CseTimeCodec.encodeUtc(DateTime.now().toUtc()),
    );
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    try {
      final projects = await widget.dailyLog.listProjects();
      final selectedProjectId = projects.isEmpty ? null : projects.first.id;
      final day = selectedProjectId == null
          ? null
          : await widget.dailyLog.loadDay(
              projectId: selectedProjectId,
              localDay: _selectedDay,
            );
      if (!mounted) return;
      setState(() {
        _projects = projects;
        _selectedProjectId = selectedProjectId;
        _day = day;
        _errorCode = null;
        _loading = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _errorCode = _failureCode(error);
        _loading = false;
      });
    }
  }

  Future<void> _loadDay() async {
    final projectId = _selectedProjectId;
    if (projectId == null) return;
    setState(() {
      _loading = true;
      _errorCode = null;
    });
    try {
      final day = await widget.dailyLog.loadDay(
        projectId: projectId,
        localDay: _selectedDay,
      );
      if (!mounted) return;
      setState(() {
        _day = day;
        _loading = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _day = null;
        _errorCode = _failureCode(error);
        _loading = false;
      });
    }
  }

  Future<void> _selectProject(String? projectId) async {
    if (projectId == null || projectId == _selectedProjectId || _loading) {
      return;
    }
    setState(() => _selectedProjectId = projectId);
    await _loadDay();
  }

  Future<void> _selectDay() async {
    if (_loading) return;
    final components = _selectedDay.split('-').map(int.parse).toList();
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime(components[0], components[1], components[2]),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Günlük Log günü',
    );
    if (selected == null || !mounted) return;
    final dayKey = _dayKey(selected);
    if (dayKey == _selectedDay) return;
    setState(() => _selectedDay = dayKey);
    await _loadDay();
  }

  Future<void> _copyText() async {
    final day = _day;
    if (day == null || _loading) return;
    await Clipboard.setData(
      ClipboardData(text: formatDailyLogAsPlainText(day)),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Günlük Log metni panoya kopyalandı.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final day = _day;
    return Scaffold(
      appBar: AppBar(title: const Text('Günlük Log')),
      body: SafeArea(
        child: ListView(
          key: const Key('daily-log-page'),
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Kaynak kayıtlarınızdan salt-okunur günlük taslağı',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            const Text(
              'Bu önizleme resmî veya yayımlanmış günlük değildir; kaynak kayıtları değiştirmez.',
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              key: ValueKey(
                'daily-log-project-${_selectedProjectId ?? 'none'}',
              ),
              initialValue: _selectedProjectId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Proje',
              ),
              items: _projects
                  .map(
                    (project) => DropdownMenuItem(
                      value: project.id,
                      child: Text(project.name),
                    ),
                  )
                  .toList(growable: false),
              onChanged: _loading ? null : _selectProject,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const Key('daily-log-select-day'),
              onPressed: _projects.isEmpty ? null : _selectDay,
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(CseTimeCodec.formatIstanbulDay(_selectedDay)),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const Key('daily-log-copy-text'),
              onPressed: day == null || _loading ? null : _copyText,
              icon: const Icon(Icons.copy_all_outlined),
              label: const Text('Metni kopyala'),
            ),
            const SizedBox(height: 20),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_errorCode case final code?)
              _DailyLogError(
                code: code,
                onRetry: _selectedProjectId == null ? _loadProjects : _loadDay,
              )
            else if (_projects.isEmpty)
              const _DailyLogEmptyProjects()
            else if (day != null) ...[
              Semantics(
                header: true,
                child: Text(
                  '${CseTimeCodec.formatIstanbulDay(day.localDay)} · ${day.projectName}',
                  key: const Key('daily-log-day-heading'),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: 12),
              for (final section in day.sections)
                _DailyLogSectionCard(
                  section: section,
                  workChain: widget.workChain,
                ),
              const SizedBox(height: 12),
              ExpansionTile(
                key: const Key('daily-log-text-preview'),
                leading: const Icon(Icons.text_snippet_outlined),
                title: const Text('Birleşik metin önizlemesi'),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SelectableText(formatDailyLogAsPlainText(day)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DailyLogSectionCard extends StatelessWidget {
  const _DailyLogSectionCard({required this.section, required this.workChain});

  final DailyLogSection section;
  final WorkChainApplicationPort? workChain;

  @override
  Widget build(BuildContext context) {
    final failure = section.failure;
    final summaryText = section.summaryText;
    return Card(
      key: Key('daily-log-section-${section.kind.name}'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_sectionIcon(section.kind)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    section.kind.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (summaryText != null)
              Text(summaryText)
            else if (failure != null)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(failure.message)),
                ],
              )
            else if (section.entries.isEmpty)
              Text(section.kind.emptyMessage)
            else
              for (var index = 0; index < section.entries.length; index += 1)
                _DailyLogEntryTile(
                  entry: section.entries[index],
                  workChain: workChain,
                  showDivider: index < section.entries.length - 1,
                ),
          ],
        ),
      ),
    );
  }
}

class _DailyLogEntryTile extends StatelessWidget {
  const _DailyLogEntryTile({
    required this.entry,
    required this.workChain,
    required this.showDivider,
  });

  final DailyLogEntry entry;
  final WorkChainApplicationPort? workChain;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final occurredAt = entry.occurredAt;
    final source = _workChainSource(entry);
    final application = workChain;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (occurredAt != null)
          Text(
            CseTimeCodec.istanbulTimeLabel(occurredAt),
            style: Theme.of(context).textTheme.labelMedium,
          ),
        Text(entry.text),
        const SizedBox(height: 5),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: entry.sourceRefs
              .map(
                (source) => Tooltip(
                  message: source.sourceId,
                  child: Chip(
                    visualDensity: VisualDensity.compact,
                    avatar: const Icon(Icons.link_rounded, size: 16),
                    label: Text(source.kind.label),
                  ),
                ),
              )
              .toList(growable: false),
        ),
        if (application != null && source != null)
          TextButton.icon(
            key: Key('daily-log-work-chain-${entry.id}'),
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => source.fromFollowUp
                    ? WorkChainPage.fromFollowUp(
                        application: application,
                        followUpId: source.id,
                      )
                    : WorkChainPage.fromAgendaLog(
                        application: application,
                        agendaLogId: source.id,
                      ),
              ),
            ),
            icon: const Icon(Icons.account_tree_outlined),
            label: const Text('İş Zincirini aç'),
          ),
        if (showDivider) const Divider(height: 24),
      ],
    );
  }
}

class _DailyLogError extends StatelessWidget {
  const _DailyLogError({required this.code, required this.onRetry});

  final String code;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.error_outline_rounded, size: 42),
            const SizedBox(height: 8),
            const Text('Günlük Log güvenle okunamadı.'),
            const SizedBox(height: 4),
            Text('Tanı kodu: $code'),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tekrar oku'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyLogEmptyProjects extends StatelessWidget {
  const _DailyLogEmptyProjects();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Text('Günlük Log için aktif proje bulunamadı.'),
      ),
    );
  }
}

({bool fromFollowUp, String id})? _workChainSource(DailyLogEntry entry) {
  for (final source in entry.sourceRefs) {
    if (source.kind == DailyLogSourceKind.reminder) {
      return (fromFollowUp: true, id: source.sourceId);
    }
    if (source.kind == DailyLogSourceKind.agendaLog) {
      return (fromFollowUp: false, id: source.sourceId);
    }
  }
  return null;
}

IconData _sectionIcon(DailyLogSectionKind kind) => switch (kind) {
  DailyLogSectionKind.summary => Icons.summarize_outlined,
  DailyLogSectionKind.attendance => Icons.badge_outlined,
  DailyLogSectionKind.livingPlan => Icons.calendar_view_week_outlined,
  DailyLogSectionKind.concrete => Icons.foundation_outlined,
  DailyLogSectionKind.agenda => Icons.event_note_outlined,
  DailyLogSectionKind.openFollowUps => Icons.notifications_none_rounded,
};

String _failureCode(Object error) => switch (error) {
  DailyLogFailure failure => failure.code,
  _ => 'daily_log_unexpected_failure',
};

String _dayKey(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';
