import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/application/construction_living_plan_application.dart';
import 'package:chief_site_engineer/application/construction_living_plan_intelligence_application.dart';
import 'package:chief_site_engineer/core/record_id.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/construction_living_plan_models.dart';
import 'package:chief_site_engineer/domain/construction_living_plan_forecast_models.dart';
import 'package:chief_site_engineer/domain/construction_living_plan_intelligence_models.dart';
import 'package:chief_site_engineer/domain/construction_project_graph_models.dart';
import 'package:chief_site_engineer/domain/construction_schedule_models.dart';
import 'package:flutter/material.dart';

class LivingPlanPage extends StatefulWidget {
  const LivingPlanPage({
    required this.agenda,
    required this.livingPlan,
    this.initialProjectId,
    this.onProjectSelected,
    this.intelligence =
        const UnavailableConstructionLivingPlanIntelligenceApplication(),
    DateTime Function()? clock,
    super.key,
  }) : clock = clock ?? _systemUtcClock;

  final AgendaApplication agenda;
  final ConstructionLivingPlanApplicationPort livingPlan;
  final String? initialProjectId;
  final ValueChanged<String>? onProjectSelected;
  final ConstructionLivingPlanIntelligenceApplicationPort intelligence;
  final DateTime Function() clock;

  @override
  State<LivingPlanPage> createState() => _LivingPlanPageState();
}

DateTime _systemUtcClock() => DateTime.now().toUtc();

class _LivingPlanPageState extends State<LivingPlanPage> {
  List<MobileProject> _projects = const [];
  List<ConstructionLivingPlanWindowItem> _items = const [];
  List<ConstructionLivingPlanReferenceCandidate> _suggestions = const [];
  Map<String, ConstructionLivingPlanIntelligence> _intelligence = const {};
  String? _projectId;
  late DateTime _windowStart;
  bool _loading = true;
  bool _mutating = false;
  bool _hasTrustedSnapshot = false;
  String? _safeError;

  @override
  void initState() {
    super.initState();
    _projectId = widget.initialProjectId;
    _windowStart = _istanbulToday(widget.clock());
    _reload(includeProjects: true);
  }

  Future<void> _reload({bool includeProjects = false}) async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _safeError = null;
    });
    try {
      var projects = _projects;
      if (includeProjects) {
        projects = (await widget.agenda.listProjects())
            .where((project) => !project.isArchived)
            .toList(growable: false);
      }
      var selected = _projectId;
      if (selected == null || !projects.any((item) => item.id == selected)) {
        selected = widget.initialProjectId == null && projects.isNotEmpty
            ? projects.first.id
            : null;
      }
      if (selected == null) {
        if (!mounted) return;
        setState(() {
          _projects = projects;
          _projectId = null;
          _items = const [];
          _suggestions = const [];
          _intelligence = const {};
          _hasTrustedSnapshot = false;
          _loading = false;
        });
        return;
      }

      final windowStart = _canonicalCalendarDay(_windowStart);
      final items = await widget.livingPlan.loadSevenDayPlan(
        projectId: selected,
        windowStart: windowStart,
      );
      List<ConstructionLivingPlanReferenceCandidate> suggestions;
      var hasTrustedSnapshot = true;
      try {
        suggestions = await widget.livingPlan.loadSevenDayReferenceSuggestions(
          projectId: selected,
          windowStart: windowStart,
        );
      } on ConstructionLivingPlanFailure catch (failure) {
        if (failure.code != 'living_plan_reference_snapshot_missing') {
          rethrow;
        }
        suggestions = const [];
        hasTrustedSnapshot = false;
      }
      Map<String, ConstructionLivingPlanIntelligence> intelligence;
      try {
        intelligence = await widget.intelligence.loadForItems(
          items: items.map((entry) => entry.item),
          asOfDate: _istanbulToday(widget.clock()),
        );
      } on Object {
        intelligence = const {};
      }
      if (!mounted) return;
      setState(() {
        _projects = projects;
        _projectId = selected;
        _items = items;
        _suggestions = suggestions;
        _intelligence = intelligence;
        _hasTrustedSnapshot = hasTrustedSnapshot;
        _loading = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _safeError = 'Plan güvenli biçimde okunamadı. Kayıtlar değiştirilmedi.';
      });
    }
  }

  Future<void> _selectProject(String? projectId) async {
    if (projectId == null || projectId == _projectId || _loading) return;
    setState(() => _projectId = projectId);
    widget.onProjectSelected?.call(projectId);
    await _reload();
  }

  Future<void> _shiftWindow(int days) async {
    if (_loading || _mutating) return;
    setState(
      () => _windowStart = _canonicalCalendarDay(
        _windowStart.add(Duration(days: days)),
      ),
    );
    await _reload();
  }

  Future<void> _pickWindowStart() async {
    if (_loading || _mutating) return;
    final selected = await showDatePicker(
      context: context,
      initialDate: _windowStart,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Pencere başlangıcını seçin',
    );
    if (selected == null || !mounted) return;
    setState(() => _windowStart = _canonicalCalendarDay(selected));
    await _reload();
  }

  Future<void> _openAdd() async {
    final projectId = _projectId;
    if (projectId == null || !_hasTrustedSnapshot || _mutating || _loading) {
      return;
    }
    var didPersistChange = false;
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _AddLivingPlanSheet(
        livingPlan: widget.livingPlan,
        projectId: projectId,
        windowStart: _canonicalCalendarDay(_windowStart),
        initialSuggestions: _suggestions,
        onPersistedChange: () => didPersistChange = true,
      ),
    );
    if (didPersistChange && mounted) await _reload();
  }

  Future<void> _runMutation(
    Future<ConstructionLivingPlanItem> Function() operation, {
    required String successMessage,
  }) async {
    if (_mutating) return;
    setState(() => _mutating = true);
    try {
      await operation();
      if (!mounted) return;
      _showMessage(successMessage);
    } on ConstructionLivingPlanFailure catch (failure) {
      if (!mounted) return;
      _showMessage(_mutationFailureMessage(failure.code));
    } on Object {
      if (!mounted) return;
      _showMessage('İşlem tamamlanamadı; plan değişmedi.');
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
    await _reload();
  }

  Future<void> _start(ConstructionLivingPlanItem item) => _runMutation(
    () => widget.livingPlan.startLivingPlanItem(
      StartConstructionLivingPlanItemCommand(
        itemId: item.id,
        eventId: RecordId.randomUuid(),
        expectedRevision: item.revision,
      ),
    ),
    successMessage: 'İmalat başlatıldı.',
  );

  Future<void> _complete(ConstructionLivingPlanItem item) => _runMutation(
    () => widget.livingPlan.completeLivingPlanItem(
      CompleteConstructionLivingPlanItemCommand(
        itemId: item.id,
        eventId: RecordId.randomUuid(),
        expectedRevision: item.revision,
      ),
    ),
    successMessage: 'İmalat tamamlandı.',
  );

  Future<void> _defer(ConstructionLivingPlanItem item) async {
    final firstDate = item.plannedDate.add(const Duration(days: 1));
    final selected = await showDatePicker(
      context: context,
      initialDate: firstDate,
      firstDate: firstDate,
      lastDate: firstDate.add(const Duration(days: 730)),
      helpText: 'Daha ileri plan gününü seçin',
    );
    if (selected == null) return;
    await _runMutation(
      () => widget.livingPlan.deferLivingPlanItem(
        DeferConstructionLivingPlanItemCommand(
          itemId: item.id,
          eventId: RecordId.randomUuid(),
          expectedRevision: item.revision,
          plannedDate: _canonicalCalendarDay(selected),
        ),
      ),
      successMessage: 'İmalat ertelendi.',
    );
  }

  Future<void> _reopen(ConstructionLivingPlanItem item) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _windowStart,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Yeniden açma gününü seçin',
    );
    if (selected == null) return;
    await _runMutation(
      () => widget.livingPlan.reopenLivingPlanItem(
        ReopenConstructionLivingPlanItemCommand(
          itemId: item.id,
          eventId: RecordId.randomUuid(),
          expectedRevision: item.revision,
          plannedDate: _canonicalCalendarDay(selected),
        ),
      ),
      successMessage: 'İmalat yeniden açıldı.',
    );
  }

  Future<void> _editNote(ConstructionLivingPlanItem item) async {
    final note = await showDialog<String?>(
      context: context,
      builder: (_) => _NoteEditorDialog(initialNote: item.note),
    );
    if (note == null) return;
    final normalized = note.trim();
    await _runMutation(
      () => widget.livingPlan.updateLivingPlanNote(
        UpdateConstructionLivingPlanNoteCommand(
          itemId: item.id,
          eventId: RecordId.randomUuid(),
          expectedRevision: item.revision,
          note: normalized.isEmpty ? null : normalized,
        ),
      ),
      successMessage: normalized.isEmpty ? 'Not silindi.' : 'Not kaydedildi.',
    );
  }

  Future<void> _editProgress(ConstructionLivingPlanItem item) async {
    final progress = await showDialog<int>(
      context: context,
      builder: (_) =>
          _ProgressEditorDialog(initialProgress: item.progressPercent),
    );
    if (progress == null || progress == item.progressPercent) return;
    await _runMutation(
      () => widget.livingPlan.updateLivingPlanProgress(
        UpdateConstructionLivingPlanProgressCommand(
          itemId: item.id,
          eventId: RecordId.randomUuid(),
          expectedRevision: item.revision,
          progressPercent: progress,
        ),
      ),
      successMessage: 'İlerleme %$progress olarak kaydedildi.',
    );
  }

  Future<void> _openIntelligenceImpact(
    ConstructionLivingPlanIntelligence intelligence,
  ) => showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (_) =>
        _LivingPlanIntelligenceImpactSheet(intelligence: intelligence),
  );

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final projectId = _projectId;
    return Scaffold(
      appBar: AppBar(title: const Text('7 Günlük Plan')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add-living-plan-item'),
        tooltip: _hasTrustedSnapshot
            ? 'İmalat ekle'
            : 'Güvenilir öneri programı gerekli',
        onPressed:
            projectId != null && _hasTrustedSnapshot && !_loading && !_mutating
            ? _openAdd
            : null,
        icon: const Icon(Icons.add_task_rounded),
        label: const Text('İmalat ekle'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _reload(includeProjects: true),
          child: ListView(
            key: const Key('living-plan-scroll'),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 104),
            children: [
              if (_projects.isNotEmpty)
                KeyedSubtree(
                  key: const Key('living-plan-project-selector'),
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('living-plan-project-${projectId ?? 'none'}'),
                    initialValue: projectId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Proje',
                      border: OutlineInputBorder(),
                    ),
                    selectedItemBuilder: (_) => [
                      for (final project in _projects)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            project.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    items: [
                      for (final project in _projects)
                        DropdownMenuItem(
                          value: project.id,
                          child: Text(
                            project.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: _loading ? null : _selectProject,
                  ),
                ),
              const SizedBox(height: 12),
              _WindowControls(
                windowStart: _windowStart,
                disabled: _loading || _mutating,
                onPrevious: () => _shiftWindow(-7),
                onNext: () => _shiftWindow(7),
                onPick: _pickWindowStart,
                onRefresh: () => _reload(includeProjects: true),
              ),
              const SizedBox(height: 12),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Önerilen tarihler tahmin niteliğindedir; resmî iş programı değildir.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_loading) ...[
                const SizedBox(height: 28),
                Semantics(
                  label: '7 günlük plan yükleniyor',
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ] else if (_safeError case final error?) ...[
                const SizedBox(height: 20),
                _MessagePanel(
                  icon: Icons.error_outline_rounded,
                  message: error,
                ),
              ] else if (_projects.isEmpty) ...[
                const SizedBox(height: 20),
                const _MessagePanel(
                  icon: Icons.folder_off_outlined,
                  message: 'Önce bir proje oluşturun.',
                ),
              ] else if (projectId == null) ...[
                const SizedBox(height: 20),
                const KeyedSubtree(
                  key: Key('living-plan-project-context-unavailable'),
                  child: _MessagePanel(
                    icon: Icons.folder_off_outlined,
                    message:
                        'Dashboard projesi artık kullanılamıyor. Devam etmek için bir proje seçin.',
                  ),
                ),
              ] else ...[
                if (!_hasTrustedSnapshot) ...[
                  const SizedBox(height: 12),
                  const _MessagePanel(
                    icon: Icons.event_busy_outlined,
                    message:
                        'Bu proje için güvenilir öneri programı henüz hazırlanmadı.',
                  ),
                ],
                if (_items.isEmpty) ...[
                  const SizedBox(height: 12),
                  const _MessagePanel(
                    icon: Icons.playlist_add_rounded,
                    message:
                        'Bu pencerede planlanmış imalat yok. İmalat ekleyebilirsiniz.',
                  ),
                ] else
                  ..._buildSections(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSections() {
    final widgets = <Widget>[];
    final overdue = _items.where((entry) => entry.isOverdue).toList();
    if (overdue.isNotEmpty) {
      widgets.addAll(_section('Geciken', overdue, key: 'overdue'));
    }
    for (var offset = 0; offset < 7; offset += 1) {
      final date = _windowStart.add(Duration(days: offset));
      final entries = _items
          .where(
            (entry) =>
                !entry.isOverdue && _sameDate(entry.item.plannedDate, date),
          )
          .toList();
      final title = offset == 0
          ? 'Bugün • ${_displayDate(date)}'
          : _displayDateWithWeekday(date);
      widgets.addAll(_section(title, entries, key: 'day-$offset'));
    }
    return widgets;
  }

  List<Widget> _section(
    String title,
    List<ConstructionLivingPlanWindowItem> entries, {
    required String key,
  }) => [
    const SizedBox(height: 18),
    Text(
      title,
      key: Key('living-plan-section-$key'),
      style: Theme.of(context).textTheme.titleMedium,
    ),
    const SizedBox(height: 6),
    if (entries.isEmpty)
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 6),
        child: Text('Kayıt yok.'),
      )
    else
      for (final entry in entries)
        _LivingPlanItemCard(
          entry: entry,
          intelligence: _intelligence[entry.item.id],
          busy: _mutating,
          onStart: () => _start(entry.item),
          onComplete: () => _complete(entry.item),
          onDefer: () => _defer(entry.item),
          onReopen: () => _reopen(entry.item),
          onNote: () => _editNote(entry.item),
          onProgress: () => _editProgress(entry.item),
          onImpact: (intelligence) => _openIntelligenceImpact(intelligence),
        ),
  ];
}

class _WindowControls extends StatelessWidget {
  const _WindowControls({
    required this.windowStart,
    required this.disabled,
    required this.onPrevious,
    required this.onNext,
    required this.onPick,
    required this.onRefresh,
  });

  final DateTime windowStart;
  final bool disabled;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onPick;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 4,
    runSpacing: 4,
    children: [
      IconButton(
        key: const Key('living-plan-previous-window'),
        tooltip: 'Önceki yedi gün',
        onPressed: disabled ? null : onPrevious,
        icon: const Icon(Icons.chevron_left_rounded),
      ),
      OutlinedButton.icon(
        key: const Key('living-plan-pick-window-start'),
        onPressed: disabled ? null : onPick,
        icon: const Icon(Icons.calendar_today_outlined),
        label: Text('${_displayDate(windowStart)} başlangıç'),
      ),
      IconButton(
        key: const Key('living-plan-next-window'),
        tooltip: 'Sonraki yedi gün',
        onPressed: disabled ? null : onNext,
        icon: const Icon(Icons.chevron_right_rounded),
      ),
      IconButton(
        key: const Key('living-plan-refresh'),
        tooltip: 'Planı yenile',
        onPressed: disabled ? null : onRefresh,
        icon: const Icon(Icons.refresh_rounded),
      ),
    ],
  );
}

class _LivingPlanItemCard extends StatelessWidget {
  const _LivingPlanItemCard({
    required this.entry,
    required this.intelligence,
    required this.busy,
    required this.onStart,
    required this.onComplete,
    required this.onDefer,
    required this.onReopen,
    required this.onNote,
    required this.onProgress,
    required this.onImpact,
  });

  final ConstructionLivingPlanWindowItem entry;
  final ConstructionLivingPlanIntelligence? intelligence;
  final bool busy;
  final VoidCallback onStart;
  final VoidCallback onComplete;
  final VoidCallback onDefer;
  final VoidCallback onReopen;
  final VoidCallback onNote;
  final VoidCallback onProgress;
  final ValueChanged<ConstructionLivingPlanIntelligence> onImpact;

  @override
  Widget build(BuildContext context) {
    final item = entry.item;
    final open = item.status != ConstructionLivingPlanStatus.completed;
    final canStart =
        item.status == ConstructionLivingPlanStatus.planned ||
        item.status == ConstructionLivingPlanStatus.deferred;
    final canEditProgress =
        item.status == ConstructionLivingPlanStatus.started ||
        item.status == ConstructionLivingPlanStatus.deferred;
    final semanticsIdentity = _livingPlanItemSemanticsIdentity(item);
    final progressLabel = _progressLabel(item);
    final progressSemanticsValue = _progressSemanticsValue(item);
    final activeIntelligence =
        item.status == ConstructionLivingPlanStatus.started &&
            item.progressPercent != null &&
            intelligence?.forecast.basis ==
                ConstructionLivingPlanForecastBasis.startedReferenceRemaining
        ? intelligence
        : null;

    Widget actionSemantics({
      required String action,
      required VoidCallback? onPressed,
      required Widget child,
    }) => Semantics(
      container: true,
      label: '$semanticsIdentity · Eylem · $action',
      button: true,
      enabled: onPressed != null,
      onTap: onPressed,
      excludeSemantics: true,
      child: child,
    );

    return Card(
      key: Key('living-plan-item-${item.id}'),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.activityNameSnapshot,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Semantics(
                  container: true,
                  label:
                      '$semanticsIdentity · Durum · ${_statusLabel(item.status)} · Kayıt sürümü · ${item.revision}',
                  excludeSemantics: true,
                  child: Chip(label: Text(_statusLabel(item.status))),
                ),
                Semantics(
                  container: true,
                  label:
                      '$semanticsIdentity · Plan günü · ${_displayDate(item.plannedDate)}',
                  excludeSemantics: true,
                  child: Text(_displayDate(item.plannedDate)),
                ),
                Semantics(
                  key: Key('living-plan-progress-${item.id}'),
                  container: true,
                  label:
                      '$semanticsIdentity · İlerleme · $progressSemanticsValue',
                  excludeSemantics: true,
                  child: Chip(label: Text(progressLabel)),
                ),
                if (!entry.originSnapshotIsCurrent)
                  const Chip(
                    avatar: Icon(Icons.history_rounded, size: 18),
                    label: Text('Eski öneri kaynağı'),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(_contextLabel(item.activityContext)),
            if (activeIntelligence case final value?) ...[
              const SizedBox(height: 8),
              _LivingPlanForecastSummary(itemId: item.id, intelligence: value),
            ],
            if (item.note case final note?) ...[
              const SizedBox(height: 8),
              Semantics(
                container: true,
                label: '$semanticsIdentity · Not · $note',
                excludeSemantics: true,
                child: Text(note, key: Key('living-plan-note-${item.id}')),
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (canStart)
                  actionSemantics(
                    action: 'Başlat',
                    onPressed: busy ? null : onStart,
                    child: FilledButton.tonalIcon(
                      key: Key('start-living-plan-${item.id}'),
                      onPressed: busy ? null : onStart,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Başlat'),
                    ),
                  ),
                if (open)
                  actionSemantics(
                    action: 'Tamamla',
                    onPressed: busy ? null : onComplete,
                    child: FilledButton.tonalIcon(
                      key: Key('complete-living-plan-${item.id}'),
                      onPressed: busy ? null : onComplete,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Tamamla'),
                    ),
                  ),
                if (open)
                  actionSemantics(
                    action: 'Ertele',
                    onPressed: busy ? null : onDefer,
                    child: OutlinedButton.icon(
                      key: Key('defer-living-plan-${item.id}'),
                      onPressed: busy ? null : onDefer,
                      icon: const Icon(Icons.update_rounded),
                      label: const Text('Ertele'),
                    ),
                  ),
                if (!open)
                  actionSemantics(
                    action: 'Yeniden aç',
                    onPressed: busy ? null : onReopen,
                    child: OutlinedButton.icon(
                      key: Key('reopen-living-plan-${item.id}'),
                      onPressed: busy ? null : onReopen,
                      icon: const Icon(Icons.replay_rounded),
                      label: const Text('Yeniden aç'),
                    ),
                  ),
                if (canEditProgress)
                  actionSemantics(
                    action: 'İlerleme',
                    onPressed: busy ? null : onProgress,
                    child: OutlinedButton.icon(
                      key: Key('progress-living-plan-${item.id}'),
                      onPressed: busy ? null : onProgress,
                      icon: const Icon(Icons.percent_rounded),
                      label: const Text('İlerleme'),
                    ),
                  ),
                if (activeIntelligence case final value?
                    when value.hasPositiveDownstreamImpact)
                  actionSemantics(
                    action:
                        '${value.impactedActivities.length} sonraki iş etkilenebilir',
                    onPressed: busy ? null : () => onImpact(value),
                    child: OutlinedButton.icon(
                      key: Key('living-plan-impact-${item.id}'),
                      onPressed: busy ? null : () => onImpact(value),
                      icon: const Icon(Icons.account_tree_outlined),
                      label: Text(
                        '${value.impactedActivities.length} sonraki iş etkilenebilir',
                      ),
                    ),
                  ),
                actionSemantics(
                  action: 'Not',
                  onPressed: busy ? null : onNote,
                  child: OutlinedButton.icon(
                    key: Key('note-living-plan-${item.id}'),
                    onPressed: busy ? null : onNote,
                    icon: const Icon(Icons.note_alt_outlined),
                    label: Text(
                      item.note == null ? 'Not ekle' : 'Notu düzenle',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LivingPlanForecastSummary extends StatelessWidget {
  const _LivingPlanForecastSummary({
    required this.itemId,
    required this.intelligence,
  });

  final String itemId;
  final ConstructionLivingPlanIntelligence intelligence;

  @override
  Widget build(BuildContext context) {
    final forecast = intelligence.forecast;
    final remaining = forecast.remainingRoundedSchedulingDays!;
    final finish = forecast.forecastFinishDate!;
    final remainingLabel =
        'Tahmini kalan: $remaining ${_schedulingDayLabel(forecast.referenceDurationCalendarType)}';
    final finishLabel = 'Tahmini bitiş: ${_displayDate(finish)}';
    final varianceLabel = _forecastVarianceLabel(
      forecast.varianceCalendarDays!,
    );
    return Semantics(
      key: Key('living-plan-intelligence-$itemId'),
      container: true,
      label: '$itemId · $remainingLabel · $finishLabel · $varianceLabel',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(remainingLabel),
          Text(finishLabel),
          Text(varianceLabel),
        ],
      ),
    );
  }
}

class _LivingPlanIntelligenceImpactSheet extends StatelessWidget {
  const _LivingPlanIntelligenceImpactSheet({required this.intelligence});

  final ConstructionLivingPlanIntelligence intelligence;

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: 0.65,
    minChildSize: 0.4,
    maxChildSize: 0.9,
    builder: (context, controller) => ListView(
      key: const Key('living-plan-impact-detail'),
      controller: controller,
      padding: const EdgeInsets.all(20),
      children: [
        Text('Tahmini etki', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text('Bu bir önizlemedir; plan tarihleri değişmedi.'),
        const SizedBox(height: 16),
        for (final activity in intelligence.impactedActivities)
          Card(
            key: Key(
              'living-plan-impact-activity-${activity.activityInstanceId}',
            ),
            child: ListTile(
              title: Text(activity.displayName),
              subtitle: Text(
                'Tahmini başlangıç: ${_displayDate(activity.projectedStartDate)}\n'
                'Tahmini bitiş: ${_displayDate(activity.projectedFinishDate)}',
              ),
              trailing: Text('+${activity.finishShiftCalendarDays} gün'),
            ),
          ),
      ],
    ),
  );
}

class _ProgressEditorDialog extends StatefulWidget {
  const _ProgressEditorDialog({required this.initialProgress});

  final int? initialProgress;

  @override
  State<_ProgressEditorDialog> createState() => _ProgressEditorDialogState();
}

class _ProgressEditorDialogState extends State<_ProgressEditorDialog> {
  late final TextEditingController _controller;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialProgress?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int? get _validProgress {
    final value = _controller.text;
    if (!RegExp(r'^(0|[1-9][0-9]?)$').hasMatch(value)) return null;
    return int.parse(value);
  }

  bool get _canSubmit {
    final progress = _validProgress;
    return !_submitting &&
        progress != null &&
        progress != widget.initialProgress;
  }

  void _submit() {
    final progress = _validProgress;
    if (!_canSubmit || progress == null) return;
    setState(() => _submitting = true);
    Navigator.of(context).pop(progress);
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_submitting,
    child: AlertDialog(
      title: const Text('İlerlemeyi güncelle'),
      content: TextField(
        key: const Key('living-plan-progress-field'),
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(
          labelText: 'Yüzde',
          hintText: '0–99',
          suffixText: '%',
        ),
      ),
      actions: [
        TextButton(
          key: const Key('cancel-living-plan-progress'),
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        FilledButton(
          key: const Key('save-living-plan-progress'),
          onPressed: _canSubmit ? _submit : null,
          child: const Text('Kaydet'),
        ),
      ],
    ),
  );
}

class _NoteEditorDialog extends StatefulWidget {
  const _NoteEditorDialog({required this.initialNote});

  final String? initialNote;

  @override
  State<_NoteEditorDialog> createState() => _NoteEditorDialogState();
}

class _NoteEditorDialogState extends State<_NoteEditorDialog> {
  late final TextEditingController _controller;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNote ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_submitting) return;
    _submitting = true;
    Navigator.of(context).pop(_controller.text);
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_submitting,
    child: AlertDialog(
      title: const Text('Kısa not'),
      content: TextField(
        key: const Key('living-plan-note-field'),
        controller: _controller,
        maxLength: 500,
        maxLines: 3,
        decoration: const InputDecoration(hintText: 'İsteğe bağlı not'),
      ),
      actions: [
        TextButton(
          key: const Key('cancel-living-plan-note'),
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        FilledButton(
          key: const Key('save-living-plan-note'),
          onPressed: _submitting ? null : _submit,
          child: const Text('Kaydet'),
        ),
      ],
    ),
  );
}

class _AddLivingPlanSheet extends StatefulWidget {
  const _AddLivingPlanSheet({
    required this.livingPlan,
    required this.projectId,
    required this.windowStart,
    required this.initialSuggestions,
    required this.onPersistedChange,
  });

  final ConstructionLivingPlanApplicationPort livingPlan;
  final String projectId;
  final DateTime windowStart;
  final List<ConstructionLivingPlanReferenceCandidate> initialSuggestions;
  final VoidCallback onPersistedChange;

  @override
  State<_AddLivingPlanSheet> createState() => _AddLivingPlanSheetState();
}

class _AddLivingPlanSheetState extends State<_AddLivingPlanSheet> {
  final _queryController = TextEditingController();
  late List<ConstructionLivingPlanReferenceCandidate> _suggestions;
  List<ConstructionLivingPlanReferenceCandidate> _searchResults = const [];
  bool _searching = false;
  bool _adding = false;
  bool _changed = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _suggestions = widget.initialSuggestions;
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _queryController.text.trim();
    if (query.isEmpty || _searching || _adding) {
      setState(() => _message = 'Aramak için bir imalat adı yazın.');
      return;
    }
    setState(() {
      _searching = true;
      _message = null;
    });
    try {
      final results = await widget.livingPlan.searchCurrentReferenceCandidates(
        projectId: widget.projectId,
        query: query,
        limit: 50,
      );
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _message = results.isEmpty ? 'Eşleşen imalat bulunamadı.' : null;
      });
    } on Object {
      if (mounted) {
        setState(
          () =>
              _message = 'İmalatlar güvenli biçimde aranamadı. Plan değişmedi.',
        );
      }
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _add(ConstructionLivingPlanReferenceCandidate candidate) async {
    if (_adding || candidate.existingLivingPlanItemId != null) return;
    final input = await showDialog<_CandidateInput>(
      context: context,
      builder: (_) => _CandidateInputDialog(candidate: candidate),
    );
    if (input == null || !mounted) return;
    setState(() {
      _adding = true;
      _message = null;
    });
    try {
      try {
        await widget.livingPlan.createLivingPlanItem(
          CreateConstructionLivingPlanItemCommand(
            itemId: RecordId.randomUuid(),
            eventId: RecordId.randomUuid(),
            projectId: widget.projectId,
            expectedReferenceSnapshotId: candidate.referenceSnapshotId,
            activityInstanceId: candidate.activityInstanceId,
            plannedDate: _canonicalCalendarDay(input.date),
            note: input.note,
          ),
        );
      } on ConstructionLivingPlanFailure catch (failure) {
        if (!mounted) return;
        setState(() => _message = _mutationFailureMessage(failure.code));
        if (failure.code == 'living_plan_item_already_exists' ||
            failure.code == 'living_plan_reference_snapshot_stale') {
          try {
            await _refreshCandidates();
          } on Object {
            // The mutation failure above remains the authoritative result.
          }
        }
        return;
      } on Object {
        if (mounted) {
          setState(() => _message = 'İmalat eklenemedi; plan değişmedi.');
        }
        return;
      }

      _markPersistedChange();
      try {
        await _refreshCandidates();
        if (mounted) setState(() => _message = 'İmalat plana eklendi.');
      } on Object {
        if (mounted) {
          setState(
            () => _message = 'İmalat plana eklendi; aday listesi yenilenemedi.',
          );
        }
      }
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  void _markPersistedChange() {
    if (_changed) return;
    _changed = true;
    widget.onPersistedChange();
  }

  Future<void> _refreshCandidates() async {
    final suggestions = await widget.livingPlan
        .loadSevenDayReferenceSuggestions(
          projectId: widget.projectId,
          windowStart: _canonicalCalendarDay(widget.windowStart),
        );
    List<ConstructionLivingPlanReferenceCandidate> searchResults = const [];
    final query = _queryController.text.trim();
    if (query.isNotEmpty) {
      searchResults = await widget.livingPlan.searchCurrentReferenceCandidates(
        projectId: widget.projectId,
        query: query,
        limit: 50,
      );
    }
    if (!mounted) return;
    setState(() {
      _suggestions = suggestions;
      _searchResults = searchResults;
    });
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_adding,
    child: SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .82,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'İmalat ekle',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Kapat',
                    onPressed: _adding
                        ? null
                        : () => Navigator.pop(context, _changed),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              TextField(
                key: const Key('living-plan-search'),
                controller: _queryController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _search(),
                decoration: InputDecoration(
                  labelText: 'İmalat ara',
                  hintText: 'Türkçe ad veya diğer adı',
                  suffixIcon: IconButton(
                    key: const Key('living-plan-search-submit'),
                    tooltip: 'İmalat ara',
                    onPressed: _searching || _adding ? null : _search,
                    icon: const Icon(Icons.search_rounded),
                  ),
                ),
              ),
              if (_searching || _adding) const LinearProgressIndicator(),
              if (_message case final message?)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Semantics(liveRegion: true, child: Text(message)),
                ),
              Expanded(
                child: ListView(
                  key: const Key('living-plan-candidate-list'),
                  children: [
                    if (_searchResults.isNotEmpty) ...[
                      const _CandidateHeading('Arama sonuçları'),
                      for (final candidate in _searchResults)
                        _CandidateCard(
                          candidate: candidate,
                          disabled: _adding,
                          onAdd: () => _add(candidate),
                        ),
                    ],
                    const _CandidateHeading('Bu haftaya önerilenler'),
                    if (_suggestions.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('Bu pencere için öneri yok.'),
                      )
                    else
                      for (final candidate in _suggestions)
                        if (!_searchResults.any(
                          (result) =>
                              result.activityInstanceId ==
                              candidate.activityInstanceId,
                        ))
                          _CandidateCard(
                            candidate: candidate,
                            disabled: _adding,
                            onAdd: () => _add(candidate),
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _CandidateHeading extends StatelessWidget {
  const _CandidateHeading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
}

class _CandidateCard extends StatelessWidget {
  const _CandidateCard({
    required this.candidate,
    required this.disabled,
    required this.onAdd,
  });

  final ConstructionLivingPlanReferenceCandidate candidate;
  final bool disabled;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final inPlan = candidate.existingLivingPlanItemId != null;
    return Card(
      key: Key('living-plan-candidate-${candidate.activityInstanceId}'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              candidate.activityName,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(_contextLabel(candidate.activityContext)),
            Text('Birim: ${candidate.naturalUnit}'),
            Text(
              'Öneri: ${_displayDate(candidate.suggestedStartDate)} – '
              '${_displayDate(candidate.suggestedFinishDate)}',
            ),
            Text(_confidenceLabel(candidate)),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonal(
                key: Key('add-candidate-${candidate.activityInstanceId}'),
                onPressed: disabled || inPlan ? null : onAdd,
                child: Text(inPlan ? 'Planda' : 'Plana ekle'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CandidateInput {
  const _CandidateInput(this.date, this.note);
  final DateTime date;
  final String? note;
}

class _CandidateInputDialog extends StatefulWidget {
  const _CandidateInputDialog({required this.candidate});
  final ConstructionLivingPlanReferenceCandidate candidate;

  @override
  State<_CandidateInputDialog> createState() => _CandidateInputDialogState();
}

class _CandidateInputDialogState extends State<_CandidateInputDialog> {
  final _noteController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: widget.candidate.suggestedStartDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Plan gününü seçin',
    );
    if (selected != null && mounted) {
      setState(() => _selectedDate = _canonicalCalendarDay(selected));
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Plan gününü belirle'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.candidate.activityName),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const Key('select-candidate-date'),
            onPressed: _pickDate,
            icon: const Icon(Icons.event_outlined),
            label: Text(
              _selectedDate == null
                  ? 'Plan gününü seç'
                  : _displayDate(_selectedDate!),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('candidate-note-field'),
            controller: _noteController,
            maxLength: 500,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Kısa not (isteğe bağlı)',
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('İptal'),
      ),
      FilledButton(
        key: const Key('confirm-add-candidate'),
        onPressed: _selectedDate == null
            ? null
            : () {
                final note = _noteController.text.trim();
                Navigator.pop(
                  context,
                  _CandidateInput(_selectedDate!, note.isEmpty ? null : note),
                );
              },
        child: const Text('Plana ekle'),
      ),
    ],
  );
}

class _MessagePanel extends StatelessWidget {
  const _MessagePanel({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
    label: message,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    ),
  );
}

String _mutationFailureMessage(String code) => switch (code) {
  'living_plan_stale_revision' =>
    'Kayıt başka bir işlemde değişti; plan yenilendi.',
  'living_plan_reference_snapshot_stale' ||
  'living_plan_reference_snapshot_missing' =>
    'Öneri kaynağı değişti; liste yenilendi.',
  'living_plan_item_already_exists' =>
    'Bu imalat zaten planda; mevcut kayıt gösterildi.',
  'living_plan_invalid_transition' =>
    'Bu işlem kaydın mevcut durumunda uygulanamaz.',
  _ => 'İşlem tamamlanamadı; plan değişmedi.',
};

String _statusLabel(ConstructionLivingPlanStatus status) => switch (status) {
  ConstructionLivingPlanStatus.planned => 'Planlandı',
  ConstructionLivingPlanStatus.started => 'Başladı',
  ConstructionLivingPlanStatus.completed => 'Tamamlandı',
  ConstructionLivingPlanStatus.deferred => 'Ertelendi',
};

String _progressLabel(ConstructionLivingPlanItem item) {
  if (item.status == ConstructionLivingPlanStatus.completed) {
    return 'İlerleme %100';
  }
  final progress = item.progressPercent;
  return progress == null ? 'İlerleme girilmedi' : 'İlerleme %$progress';
}

String _progressSemanticsValue(ConstructionLivingPlanItem item) {
  if (item.status == ConstructionLivingPlanStatus.completed) return '%100';
  final progress = item.progressPercent;
  return progress == null ? 'Raporlanmadı' : '%$progress';
}

String _schedulingDayLabel(
  ConstructionActivityDurationCalendarType calendarType,
) => switch (calendarType) {
  ConstructionActivityDurationCalendarType.workingDay => 'iş günü',
  ConstructionActivityDurationCalendarType.calendarDay => 'takvim günü',
};

String _forecastVarianceLabel(int varianceCalendarDays) {
  if (varianceCalendarDays > 0) {
    return 'Referansa göre: +$varianceCalendarDays gün';
  }
  if (varianceCalendarDays < 0) {
    return 'Referansa göre: ${-varianceCalendarDays} gün erken';
  }
  return 'Referansla aynı gün';
}

String _livingPlanItemSemanticsIdentity(ConstructionLivingPlanItem item) =>
    'Yaşayan plan öğesi · ${item.activityNameSnapshot} · '
    '${_contextLabel(item.activityContext)} · ${item.id}';

String _confidenceLabel(ConstructionLivingPlanReferenceCandidate candidate) {
  if (candidate.durationStatus == ConstructionScheduleDurationStatus.unknown ||
      candidate.durationConfidence ==
          ConstructionScheduleDurationConfidence.unknown) {
    return 'Süre güveni sınırlı';
  }
  if (candidate.durationStatus ==
          ConstructionScheduleDurationStatus.aiSeedEstimate ||
      candidate.durationConfidence ==
          ConstructionScheduleDurationConfidence.aiSeed) {
    return 'Düşük güvenli test-seed önerisi';
  }
  return 'Kaynak destekli süre önerisi';
}

String _contextLabel(ConstructionProjectActivityContext context) {
  final parts = <String>[
    if (context.blockId case final value?) 'Blok $value',
    if (context.basementIndex case final value?) 'Bodrum $value',
    if (context.floorIndex case final value?) '$value. kat',
    if (context.zoneId case final value?) 'Bölge $value',
    if (context.facadeElevation case final value?) _facadeLabel(value),
    if (context.roofId case final value?) 'Çatı $value',
    if (context.lotId case final value?) 'Lot $value',
    if (context.systemId case final value?) 'Sistem $value',
  ];
  return parts.isEmpty ? 'Genel proje alanı' : parts.join(' • ');
}

String _facadeLabel(String value) => switch (value) {
  'NORTH' => 'Kuzey cephe',
  'SOUTH' => 'Güney cephe',
  'EAST' => 'Doğu cephe',
  'WEST' => 'Batı cephe',
  _ => 'Cephe $value',
};

DateTime _istanbulToday(DateTime now) {
  final canonical = CseTimeCodec.encodeUtc(now.toUtc());
  return _canonicalCalendarDay(
    DateTime.parse(CseTimeCodec.istanbulDayKey(canonical)),
  );
}

DateTime _canonicalCalendarDay(DateTime value) =>
    DateTime.utc(value.year, value.month, value.day);

bool _sameDate(DateTime left, DateTime right) =>
    left.year == right.year &&
    left.month == right.month &&
    left.day == right.day;

String _displayDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}.'
    '${value.month.toString().padLeft(2, '0')}.${value.year}';

String _displayDateWithWeekday(DateTime value) {
  const weekdays = <String>[
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
    'Cumartesi',
    'Pazar',
  ];
  return '${weekdays[value.weekday - 1]} • ${_displayDate(value)}';
}
