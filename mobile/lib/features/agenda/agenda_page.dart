import 'dart:async';

import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/application/concrete_application.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/features/agenda/log_detail_page.dart';
import 'package:chief_site_engineer/features/agenda/log_form_page.dart';
import 'package:chief_site_engineer/features/reminders/reminder_detail_page.dart';
import 'package:chief_site_engineer/features/screen_tool_rail.dart';
import 'package:chief_site_engineer/platform/attachment_gateway.dart';
import 'package:flutter/material.dart';

class AgendaPage extends StatefulWidget {
  const AgendaPage({
    required this.agenda,
    this.projectLocations,
    this.attachments,
    this.concrete,
    this.concreteAttachments,
    this.activeProjectId,
    super.key,
  });

  final AgendaApplication agenda;
  final ProjectLocationApplication? projectLocations;
  final SafeAttachmentPicker? attachments;
  final ConcreteApplication? concrete;
  final SafeAttachmentPicker? concreteAttachments;
  final String? activeProjectId;

  @override
  State<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final GlobalKey _searchFieldKey = GlobalKey();
  late String _selectedDay;
  bool _calendarMonth = false;
  List<AgendaLog> _logs = const [];
  Map<String, int> _calendarDensity = const {};
  Map<String, MobileReminder> _linkedReminders = const {};
  String? _projectId;
  AgendaCategory? _category;
  String _search = '';
  AgendaArchiveFilter _archiveFilter = AgendaArchiveFilter.active;
  AgendaSortOrder _sortOrder = AgendaSortOrder.newestFirst;
  bool _loading = true;
  String? _error;
  String? _readError;
  StreamSubscription<void>? _projectSubscription;
  bool _detailNavigationBusy = false;
  bool _preservingDetailReload = false;
  int _reloadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _selectedDay = CseTimeCodec.istanbulDayKey(
      CseTimeCodec.encodeUtc(DateTime.now().toUtc()),
    );
    _projectSubscription = widget.agenda.projectChanges.listen(
      (_) => _reload(),
    );
    _reload();
  }

  @override
  void dispose() {
    _projectSubscription?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AgendaPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeProjectId != widget.activeProjectId) {
      unawaited(_reload());
    }
  }

  Future<void> _reload({double? restoreOffset}) async {
    final generation = ++_reloadGeneration;
    final requestedProjectId = widget.activeProjectId;
    setState(() {
      _loading = true;
      _error = null;
      _readError = null;
      _preservingDetailReload = restoreOffset != null;
    });
    try {
      final projects = await widget.agenda.listProjects();
      if (!mounted || generation != _reloadGeneration) return;
      final selectedProjectId =
          requestedProjectId != null &&
              projects.any(
                (project) =>
                    project.id == requestedProjectId && !project.isArchived,
              )
          ? requestedProjectId
          : null;
      final visibleDays = _visibleCalendarDays();
      final otherDensityEntries = selectedProjectId == null
          ? const <MapEntry<String, int>>[]
          : await Future.wait(
              visibleDays.where((day) => day != _selectedDay).map((day) async {
                final dayLogs = await widget.agenda.listAgenda(
                  _agendaQuery(day, selectedProjectId),
                );
                return MapEntry(day, dayLogs.length);
              }),
            );
      final logs = selectedProjectId == null
          ? const <AgendaLog>[]
          : await widget.agenda.listAgenda(
              _agendaQuery(_selectedDay, selectedProjectId),
            );
      final densityEntries = [
        ...otherDensityEntries,
        if (selectedProjectId != null) MapEntry(_selectedDay, logs.length),
      ];
      if (!mounted || generation != _reloadGeneration) return;
      final linkedReminders = <String, MobileReminder>{};
      await Future.wait(
        logs.map((log) async {
          try {
            final detail = await widget.agenda.getAgendaLogDetail(log.id);
            for (final reminder in detail.reminders) {
              if (reminder.sourceLogId == log.id) {
                linkedReminders[log.id] = reminder;
                break;
              }
            }
          } on Object {
            // A single detail read must not hide the remaining Agenda cards.
          }
        }),
      );
      if (!mounted || generation != _reloadGeneration) return;
      setState(() {
        _projectId = selectedProjectId;
        _logs = logs;
        _calendarDensity = Map.unmodifiable(Map.fromEntries(densityEntries));
        _linkedReminders = linkedReminders;
        _loading = false;
        _preservingDetailReload = false;
      });
    } on Object {
      if (!mounted || generation != _reloadGeneration) return;
      setState(() {
        _loading = false;
        _preservingDetailReload = false;
        _readError = 'Ajanda kayıtları güvenli biçimde okunamadı.';
      });
    }
    if (!mounted || generation != _reloadGeneration) return;
    _restoreScrollOffset(restoreOffset);
  }

  AgendaQuery _agendaQuery(String day, String projectId) => AgendaQuery(
    istanbulDay: day,
    projectId: projectId,
    category: _category,
    literalSearch: _search,
    archiveFilter: _archiveFilter,
    sortOrder: _sortOrder,
  );

  List<String> _visibleCalendarDays() {
    final selected = DateTime.parse('${_selectedDay}T00:00:00Z');
    final first = _calendarMonth
        ? DateTime.utc(selected.year, selected.month)
        : selected.subtract(Duration(days: selected.weekday - 1));
    final count = _calendarMonth
        ? DateTime.utc(selected.year, selected.month + 1, 0).day
        : 7;
    return [
      for (var offset = 0; offset < count; offset++)
        _dayKey(first.add(Duration(days: offset))),
    ];
  }

  String _dayKey(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  void _moveDay(int delta) {
    setState(() {
      _selectedDay = CseTimeCodec.shiftIstanbulDay(_selectedDay, delta);
    });
    _reload();
  }

  Future<void> _selectDate() async {
    final parts = _selectedDay.split('-').map(int.parse).toList();
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime(parts[0], parts[1], parts[2]),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _selectedDay =
          '${selected.year.toString().padLeft(4, '0')}-'
          '${selected.month.toString().padLeft(2, '0')}-'
          '${selected.day.toString().padLeft(2, '0')}';
    });
    _reload();
  }

  Future<void> _openCreateLog() async {
    final initialProjectId = _projectId;
    if (initialProjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ajanda kaydı için önce üstten aktif proje seçin.'),
        ),
      );
      return;
    }
    final day = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => LogFormPage(
          agenda: widget.agenda,
          projectLocations: widget.projectLocations,
          attachments: widget.attachments,
          concrete: widget.concrete,
          concreteAttachments: widget.concreteAttachments,
          initialProjectId: initialProjectId,
          initialIstanbulDay: _selectedDay,
        ),
      ),
    );
    if (day == null || !mounted) return;
    setState(() => _selectedDay = day);
    await _reload();
  }

  Future<void> _openDetail(AgendaLog log) async {
    if (_detailNavigationBusy) return;
    final restoreOffset = _currentScrollOffset;
    _searchFocusNode.unfocus();
    _detailNavigationBusy = true;
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => LogDetailPage(
            agenda: widget.agenda,
            projectLocations: widget.projectLocations,
            attachments: widget.attachments,
            concrete: widget.concrete,
            concreteAttachments: widget.concreteAttachments,
            logId: log.id,
          ),
        ),
      );
      if (mounted) await _reload(restoreOffset: restoreOffset);
    } finally {
      _detailNavigationBusy = false;
    }
  }

  Future<void> _openLinkedReminder(MobileReminder reminder) async {
    if (_detailNavigationBusy) return;
    final restoreOffset = _currentScrollOffset;
    _searchFocusNode.unfocus();
    _detailNavigationBusy = true;
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => ReminderDetailPage(
            agenda: widget.agenda,
            reminderId: reminder.id,
          ),
        ),
      );
      if (mounted) await _reload(restoreOffset: restoreOffset);
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

  _AgendaFilterSelection get _filters => _AgendaFilterSelection(
    archiveFilter: _archiveFilter,
    sortOrder: _sortOrder,
    category: _category,
  );

  bool get _hasActiveFilters =>
      _archiveFilter != AgendaArchiveFilter.active ||
      _sortOrder != AgendaSortOrder.newestFirst ||
      _category != null;

  Future<void> _showFilters() async {
    var archiveFilter = _archiveFilter;
    var sortOrder = _sortOrder;
    var category = _category;
    final selection = await showModalBottomSheet<_AgendaFilterSelection>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          key: const Key('agenda-filter-sheet'),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              Text('Filtreler', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              SegmentedButton<AgendaArchiveFilter>(
                key: const Key('agenda-archive-filter'),
                segments: const [
                  ButtonSegment(
                    value: AgendaArchiveFilter.active,
                    icon: Icon(Icons.event_note_outlined),
                    label: Text('Aktif'),
                  ),
                  ButtonSegment(
                    value: AgendaArchiveFilter.archived,
                    icon: Icon(Icons.archive_outlined),
                    label: Text('Arşivlenenler'),
                  ),
                ],
                selected: {archiveFilter},
                onSelectionChanged: (values) =>
                    setSheetState(() => archiveFilter = values.single),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<AgendaSortOrder>(
                key: const Key('agenda-sort-order'),
                initialValue: sortOrder,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Sıralama',
                  border: OutlineInputBorder(),
                ),
                items: AgendaSortOrder.values
                    .map(
                      (order) => DropdownMenuItem(
                        value: order,
                        child: Text(order.label),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) {
                    setSheetState(() => sortOrder = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<AgendaCategory?>(
                key: const Key('agenda-category-filter'),
                initialValue: category,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Tür filtresi',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Tüm türler'),
                  ),
                  ...AgendaCategory.values.map(
                    (item) =>
                        DropdownMenuItem(value: item, child: Text(item.label)),
                  ),
                ],
                onChanged: (value) => setSheetState(() => category = value),
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton(
                    key: const Key('agenda-filter-cancel'),
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: const Text('Vazgeç'),
                  ),
                  FilledButton(
                    key: const Key('agenda-filter-apply'),
                    onPressed: () => Navigator.of(sheetContext).pop(
                      _AgendaFilterSelection(
                        archiveFilter: archiveFilter,
                        sortOrder: sortOrder,
                        category: category,
                      ),
                    ),
                    child: const Text('Uygula'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || selection == null) return;
    await _applyFilters(selection);
  }

  Future<void> _applyFilters(_AgendaFilterSelection selection) async {
    if (selection == _filters) return;
    final sortChanged = selection.sortOrder != _sortOrder;
    setState(() {
      _archiveFilter = selection.archiveFilter;
      _sortOrder = selection.sortOrder;
      _category = selection.category;
    });
    await _reload();
    if (!sortChanged) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final position = _scrollController.position;
      if ((position.pixels - position.minScrollExtent).abs() > 0.5) {
        _scrollController.jumpTo(position.minScrollExtent);
      }
    });
  }

  Future<void> _clearArchiveFilter() => _applyFilters(
    _AgendaFilterSelection(
      archiveFilter: AgendaArchiveFilter.active,
      sortOrder: _sortOrder,
      category: _category,
    ),
  );

  Future<void> _clearSortOrder() => _applyFilters(
    _AgendaFilterSelection(
      archiveFilter: _archiveFilter,
      sortOrder: AgendaSortOrder.newestFirst,
      category: _category,
    ),
  );

  Future<void> _clearCategoryFilter() => _applyFilters(
    _AgendaFilterSelection(
      archiveFilter: _archiveFilter,
      sortOrder: _sortOrder,
      category: null,
    ),
  );

  Future<void> _clearAllFilters() => _applyFilters(
    const _AgendaFilterSelection(
      archiveFilter: AgendaArchiveFilter.active,
      sortOrder: AgendaSortOrder.newestFirst,
      category: null,
    ),
  );

  Future<void> _retryRead() async {
    if (_loading) return;
    await _reload();
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
    if (!mounted) return;
    _searchFocusNode.requestFocus();
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    final fieldContext = _searchFieldKey.currentContext;
    if (fieldContext != null && fieldContext.mounted) {
      await Scrollable.ensureVisible(
        fieldContext,
        duration: const Duration(milliseconds: 200),
        alignment: 0,
      );
    }
  }

  void _movePeriod(int delta) {
    if (!_calendarMonth) {
      _moveDay(delta * 7);
      return;
    }
    final selected = DateTime.parse('${_selectedDay}T00:00:00Z');
    final first = DateTime.utc(selected.year, selected.month + delta);
    final lastDay = DateTime.utc(first.year, first.month + 1, 0).day;
    final target = DateTime.utc(
      first.year,
      first.month,
      selected.day.clamp(1, lastDay),
    );
    _moveDay(target.difference(selected).inDays);
  }

  Widget _buildCalendar() {
    final selected = DateTime.parse('${_selectedDay}T00:00:00Z');
    final first = _calendarMonth
        ? DateTime.utc(selected.year, selected.month)
        : selected.subtract(Duration(days: selected.weekday - 1));
    final leading = _calendarMonth ? first.weekday - 1 : 0;
    final count = _calendarMonth
        ? DateTime.utc(selected.year, selected.month + 1, 0).day
        : 7;
    final rows = ((leading + count) / 7).ceil();
    final today = CseTimeCodec.istanbulDayKey(
      CseTimeCodec.encodeUtc(DateTime.now().toUtc()),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final compact = width < 336;
        final cellWidth = width / 7;
        return Column(
          key: const Key('agenda-calendar'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SingleChildScrollView(
              key: const Key('agenda-calendar-mode-scroll'),
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<bool>(
                key: const Key('agenda-calendar-mode'),
                segments: [
                  ButtonSegment(
                    value: true,
                    label: Semantics(
                      key: const Key('agenda-calendar-mode-month'),
                      label: 'Aylık',
                      excludeSemantics: true,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [Text('Ay'), Text('lık')],
                      ),
                    ),
                  ),
                  ButtonSegment(
                    value: false,
                    label: Semantics(
                      key: const Key('agenda-calendar-mode-week'),
                      label: 'Haftalık',
                      excludeSemantics: true,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [Text('Hafta'), Text('lık')],
                      ),
                    ),
                  ),
                ],
                selected: {_calendarMonth},
                style: const ButtonStyle(
                  minimumSize: WidgetStatePropertyAll(Size(0, 48)),
                ),
                onSelectionChanged: (values) {
                  setState(() => _calendarMonth = values.single);
                  unawaited(_reload());
                },
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _listIconAction(
                  key: const Key('agenda-calendar-previous-period'),
                  onPressed: () => _movePeriod(-1),
                  icon: const Icon(Icons.chevron_left),
                  label: _calendarMonth ? 'Önceki ay' : 'Önceki hafta',
                ),
                _listIconAction(
                  key: const Key('agenda-today'),
                  onPressed: () {
                    setState(() {
                      _selectedDay = CseTimeCodec.istanbulDayKey(
                        CseTimeCodec.encodeUtc(DateTime.now().toUtc()),
                      );
                    });
                    unawaited(_reload());
                  },
                  icon: const Icon(Icons.today_outlined),
                  label: 'Bugüne git',
                ),
                if (!compact) _selectedDayButton(),
                _listIconAction(
                  key: const Key('agenda-calendar-next-period'),
                  onPressed: () => _movePeriod(1),
                  icon: const Icon(Icons.chevron_right),
                  label: _calendarMonth ? 'Sonraki ay' : 'Sonraki hafta',
                ),
              ],
            ),
            if (compact) ...[
              const SizedBox(height: 8),
              Row(
                key: const Key('agenda-compact-day-selector'),
                children: [
                  _listIconAction(
                    key: const Key('previous-day'),
                    onPressed: () => _moveDay(-1),
                    icon: const Icon(Icons.chevron_left),
                    label: 'Önceki gün',
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: _selectedDayButton()),
                  const SizedBox(width: 8),
                  _listIconAction(
                    key: const Key('next-day'),
                    onPressed: () => _moveDay(1),
                    icon: const Icon(Icons.chevron_right),
                    label: 'Sonraki gün',
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Text(
              MaterialLocalizations.of(context).formatMonthYear(selected),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SizedBox(
              key: const Key('agenda-calendar-days'),
              width: width,
              child: Column(
                children: [
                  Row(
                    children: [
                      for (final label in const [
                        'Pzt',
                        'Sal',
                        'Çar',
                        'Per',
                        'Cum',
                        'Cmt',
                        'Paz',
                      ])
                        SizedBox(
                          width: cellWidth,
                          height: 32,
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                label,
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  for (var row = 0; row < rows; row++)
                    Row(
                      children: [
                        for (var column = 0; column < 7; column++)
                          if (row * 7 + column < leading ||
                              row * 7 + column >= leading + count)
                            SizedBox(width: cellWidth, height: 56)
                          else
                            _calendarDay(
                              first.add(
                                Duration(days: row * 7 + column - leading),
                              ),
                              today,
                              width: cellWidth,
                              interactive: !compact,
                            ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _selectedDayButton() => OutlinedButton.icon(
    key: const Key('selected-day'),
    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
    onPressed: _selectDate,
    icon: const Icon(Icons.calendar_month_outlined),
    label: FittedBox(fit: BoxFit.scaleDown, child: Text(_selectedDay)),
  );

  Widget _calendarDay(
    DateTime day,
    String today, {
    required double width,
    required bool interactive,
  }) {
    final key = _dayKey(day);
    final selected = key == _selectedDay;
    final colors = Theme.of(context).colorScheme;
    final count = _calendarDensity[key] ?? 0;
    void select() {
      setState(() => _selectedDay = key);
      unawaited(_reload());
    }

    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: width - 8,
          height: 22,
          child: FittedBox(fit: BoxFit.scaleDown, child: Text('${day.day}')),
        ),
        if (count > 0) ...[
          const SizedBox(height: 2),
          _calendarDensityIndicator(key, count, colors.primary, width - 8),
        ],
      ],
    );
    if (!interactive) {
      return Semantics(
        label: key,
        selected: selected,
        button: true,
        hint: count == 0 ? 'Günü seç' : '$count Ajanda kaydı, günü seç',
        excludeSemantics: true,
        onTap: select,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onTap: select,
          child: Container(
            key: Key('agenda-calendar-day-$key'),
            width: width,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? colors.primaryContainer : null,
              border: key == today ? Border.all(color: colors.outline) : null,
              borderRadius: BorderRadius.circular(12),
            ),
            child: content,
          ),
        ),
      );
    }
    return Semantics(
      label: key,
      selected: selected,
      button: true,
      hint: [
        if (key == today) 'Bugün',
        if (count > 0) '$count Ajanda kaydı',
      ].join(', '),
      excludeSemantics: true,
      onTap: select,
      child: SizedBox(
        width: width,
        height: 56,
        child: TextButton(
          key: Key('agenda-calendar-day-$key'),
          onPressed: select,
          style: TextButton.styleFrom(
            minimumSize: const Size.square(48),
            padding: EdgeInsets.zero,
            foregroundColor: selected
                ? colors.onPrimaryContainer
                : colors.onSurface,
            backgroundColor: selected ? colors.primaryContainer : null,
            side: key == today
                ? BorderSide(color: colors.outline)
                : BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: content,
        ),
      ),
    );
  }

  Widget _calendarDensityIndicator(
    String day,
    int count,
    Color color,
    double maxWidth,
  ) => Semantics(
    key: Key('agenda-calendar-density-$day'),
    label: '$count Ajanda kaydı',
    child: SizedBox(
      width: maxWidth,
      height: 10,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: count <= 3
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var index = 0; index < count; index++)
                    Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Text('$count', style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        bottom: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _reload,
                child: ListView(
                  key: const Key('agenda-day-list'),
                  controller: _scrollController,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(12, 8, 4, 16),
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildCalendar(),
                        const SizedBox(height: 12),
                        KeyedSubtree(
                          key: _searchFieldKey,
                          child: TextField(
                            key: const Key('agenda-literal-search'),
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            decoration: InputDecoration(
                              labelText: 'Literal ara',
                              hintText: 'Açıklama, mahal, not veya proje',
                              border: const OutlineInputBorder(),
                            ),
                            textInputAction: TextInputAction.search,
                            onChanged: (value) => _search = value,
                            onSubmitted: (_) => _reload(),
                            onTapOutside: (_) => _searchFocusNode.unfocus(),
                          ),
                        ),
                      ],
                    ),
                    if (_hasActiveFilters) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (_archiveFilter != AgendaArchiveFilter.active)
                            _filterSummary(
                              key: const Key('agenda-filter-summary-archive'),
                              label: 'Durum: Arşivlenenler',
                              onDeleted: () => unawaited(_clearArchiveFilter()),
                            ),
                          if (_sortOrder != AgendaSortOrder.newestFirst)
                            _filterSummary(
                              key: const Key('agenda-filter-summary-sort'),
                              label: 'Sıralama: ${_sortOrder.label}',
                              onDeleted: () => unawaited(_clearSortOrder()),
                            ),
                          if (_category case final category?)
                            _filterSummary(
                              key: const Key('agenda-filter-summary-category'),
                              label: 'Tür: ${category.label}',
                              onDeleted: () =>
                                  unawaited(_clearCategoryFilter()),
                            ),
                          TextButton(
                            key: const Key('agenda-clear-all-filters'),
                            onPressed: _clearAllFilters,
                            child: const Text('Tüm filtreleri temizle'),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    if (_loading && !_preservingDetailReload)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_error != null)
                      _MessageCard(icon: Icons.error_outline, message: _error!)
                    else if (_readError != null)
                      _MessageCard(
                        icon: Icons.error_outline,
                        message: _readError!,
                        action: _ReadRetryAction(
                          actionKey: const Key('agenda-read-error-retry'),
                          onPressed: _loading ? null : _retryRead,
                        ),
                      )
                    else if (_projectId == null)
                      const _MessageCard(
                        icon: Icons.folder_off_outlined,
                        message:
                            'Ajanda kayıtlarını görmek için üstten aktif proje seçin.',
                      )
                    else if (_logs.isEmpty)
                      _MessageCard(
                        icon: Icons.event_available_outlined,
                        message:
                            _calendarMonth &&
                                _calendarDensity.values.every(
                                  (count) => count == 0,
                                )
                            ? 'Bu ay için Ajanda kaydı bulunmuyor.'
                            : 'Seçili gün için Ajanda kaydı yok.',
                        action: FilledButton.icon(
                          key: const Key('agenda-empty-create'),
                          onPressed: _openCreateLog,
                          icon: const Icon(Icons.note_add_outlined),
                          label: const Text('+ Ajanda kaydı'),
                        ),
                      )
                    else
                      ..._logs.map((log) {
                        final linkedReminder = _linkedReminders[log.id];
                        final VoidCallback? openLinkedReminder =
                            linkedReminder == null
                            ? null
                            : () => _openLinkedReminder(linkedReminder);
                        return Card(
                          key: Key('agenda-log-${log.id}'),
                          child: InkWell(
                            onTap: () => _openDetail(log),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        CseTimeCodec.istanbulTimeLabel(
                                          log.observedAt,
                                        ),
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          log.category.label,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (openLinkedReminder != null)
                                        _listIconAction(
                                          key: Key(
                                            'agenda-log-linked-reminder-${log.id}',
                                          ),
                                          label: 'Bağlı hatırlatıcıyı aç',
                                          onPressed: openLinkedReminder,
                                          icon: const Icon(
                                            Icons.notifications_active_outlined,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    log.description,
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    [
                                      log.projectName,
                                      if (log.displayLocation != null)
                                        log.displayLocation!,
                                    ].join(' • '),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (log.archivedAt != null) ...[
                                    const SizedBox(height: 8),
                                    const Row(
                                      children: [
                                        Icon(Icons.archive_outlined, size: 18),
                                        SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'Arşivde • geri getirilebilir',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
            ScreenToolRail(
              key: const Key('agenda-screen-tool-rail'),
              actions: [
                ScreenToolAction(
                  key: const Key('agenda-search'),
                  label: 'Ara',
                  icon: Icons.search,
                  onPressed: _revealSearch,
                ),
                ScreenToolAction(
                  key: const Key('agenda-filter-action'),
                  label: 'Filtreler',
                  icon: Icons.filter_list_outlined,
                  onPressed: _showFilters,
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Semantics(
          container: true,
          button: true,
          enabled: _projectId != null,
          label: 'Ajanda kaydı ekle',
          excludeSemantics: true,
          onTap: _projectId == null ? null : _openCreateLog,
          child: Tooltip(
            message: 'Ajanda kaydı ekle',
            child: FilledButton(
              key: const Key('create-agenda-log'),
              style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
              onPressed: _projectId == null ? null : _openCreateLog,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.note_add_outlined),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Ajanda kaydı ekle',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget _filterSummary({
  required Key key,
  required String label,
  required VoidCallback onDeleted,
}) => InputChip(
  key: key,
  label: Text(label),
  onDeleted: onDeleted,
  deleteButtonTooltipMessage: '$label filtresini temizle',
);

class _AgendaFilterSelection {
  const _AgendaFilterSelection({
    required this.archiveFilter,
    required this.sortOrder,
    required this.category,
  });

  final AgendaArchiveFilter archiveFilter;
  final AgendaSortOrder sortOrder;
  final AgendaCategory? category;

  @override
  bool operator ==(Object other) =>
      other is _AgendaFilterSelection &&
      other.archiveFilter == archiveFilter &&
      other.sortOrder == sortOrder &&
      other.category == category;

  @override
  int get hashCode => Object.hash(archiveFilter, sortOrder, category);
}

Widget _listIconAction({
  Key? key,
  required Widget icon,
  required String label,
  required VoidCallback? onPressed,
}) => Align(
  alignment: AlignmentDirectional.centerStart,
  widthFactor: 1,
  heightFactor: 1,
  child: Semantics(
    container: true,
    label: label,
    button: true,
    enabled: onPressed != null,
    excludeSemantics: true,
    onTap: onPressed,
    child: IconButton.filledTonal(
      key: key,
      tooltip: label,
      style: IconButton.styleFrom(
        minimumSize: const Size.square(48),
        fixedSize: const Size.square(48),
        maximumSize: const Size.square(48),
        iconSize: 20,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.standard,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: onPressed,
      icon: icon,
    ),
  ),
);

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.icon, required this.message, this.action});

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, size: 44),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            if (action case final action?) ...[
              const SizedBox(height: 12),
              action,
            ],
          ],
        ),
      ),
    );
  }
}

class _ReadRetryAction extends StatelessWidget {
  const _ReadRetryAction({required this.actionKey, required this.onPressed});

  final Key actionKey;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Tekrar dene',
      button: true,
      enabled: onPressed != null,
      excludeSemantics: true,
      onTap: onPressed,
      child: FilledButton(
        key: actionKey,
        style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
        onPressed: onPressed,
        child: const Text('Tekrar dene'),
      ),
    );
  }
}
