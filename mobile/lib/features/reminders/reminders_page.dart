import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/application/attendance_application.dart';
import 'package:chief_site_engineer/application/context_suggestion_application.dart';
import 'package:chief_site_engineer/core/record_id.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/features/reminders/reminder_detail_page.dart';
import 'package:chief_site_engineer/features/reminders/reminder_form_page.dart';
import 'package:flutter/material.dart';

enum _ReminderPrimaryView { today, tomorrow, other }

enum _ReminderTodaySection { overdue, timedToday, allDayToday }

class RemindersPage extends StatefulWidget {
  const RemindersPage({
    required this.agenda,
    this.attendance,
    this.contextSuggestions,
    this.projectLocations,
    this.preferredProjectId,
    super.key,
  });

  final AgendaApplication agenda;
  final AttendanceApplication? attendance;
  final ContextSuggestionApplication? contextSuggestions;
  final ProjectLocationApplication? projectLocations;
  final String? preferredProjectId;

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  final ScrollController _scrollController = ScrollController();
  _ReminderPrimaryView _primaryView = _ReminderPrimaryView.today;
  ReminderViewGroup _otherGroup = ReminderViewGroup.upcoming;
  ReminderTodayOverview _todayOverview = const ReminderTodayOverview(
    istanbulDay: '',
    overdue: [],
    timedToday: [],
    allDayToday: [],
    inboxCount: 0,
  );
  List<MobileReminder> _items = const [];
  bool _loading = true;
  String? _error;
  String? _readError;
  final Set<String> _tomorrowBusy = {};
  final Set<String> _restoreBusy = {};
  bool _detailNavigationBusy = false;
  bool _preservingDetailReload = false;

  Future<void> _moveToTomorrow(MobileReminder reminder) async {
    if (_tomorrowBusy.contains(reminder.id)) return;
    setState(() => _tomorrowBusy.add(reminder.id));
    try {
      await widget.agenda.mutateReminder(
        MutateReminderCommand(
          reminderId: reminder.id,
          eventId: RecordId.randomUuid(),
          expectedRevision: reminder.revision,
          action: ReminderMutationAction.snoozeTomorrowMorning,
        ),
      );
      await _reload();
    } on Object {
      if (mounted) {
        setState(() => _error = 'Hatırlatıcı yarına ertelenemedi.');
      }
    } finally {
      if (mounted) setState(() => _tomorrowBusy.remove(reminder.id));
    }
  }

  Future<void> _restoreFromTrash(MobileReminder reminder) async {
    if (_restoreBusy.contains(reminder.id)) return;
    setState(() => _restoreBusy.add(reminder.id));
    try {
      await widget.agenda.mutateReminder(
        MutateReminderCommand(
          reminderId: reminder.id,
          eventId: RecordId.randomUuid(),
          expectedRevision: reminder.revision,
          action: ReminderMutationAction.restoreFromTrash,
        ),
      );
      await _reload();
    } on Object {
      if (mounted) setState(() => _error = 'Hatırlatıcı geri yüklenemedi.');
    } finally {
      if (mounted) setState(() => _restoreBusy.remove(reminder.id));
    }
  }

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _reload({double? restoreOffset}) async {
    setState(() {
      _loading = true;
      _error = null;
      _readError = null;
      _preservingDetailReload = restoreOffset != null;
    });
    try {
      if (_primaryView == _ReminderPrimaryView.today) {
        final application = widget.agenda;
        if (application is! ReminderTodayApplication) {
          throw StateError('Today reminder read-model is unavailable.');
        }
        final overview = await (application as ReminderTodayApplication)
            .getReminderTodayOverview();
        if (!mounted) return;
        setState(() {
          _todayOverview = overview;
          _items = const [];
          _loading = false;
          _preservingDetailReload = false;
        });
      } else {
        final group = _primaryView == _ReminderPrimaryView.tomorrow
            ? ReminderViewGroup.tomorrow
            : _otherGroup;
        final items = await widget.agenda.listReminders(group);
        if (!mounted) return;
        setState(() {
          _items = items;
          _loading = false;
          _preservingDetailReload = false;
        });
      }
    } on Object {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _preservingDetailReload = false;
        _readError = 'Hatırlatıcılar güvenli biçimde okunamadı.';
      });
    }
    _restoreScrollOffset(restoreOffset);
  }

  Future<void> _retryRead() async {
    if (_loading) return;
    await _reload();
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

  Future<void> _openDetail(MobileReminder reminder) async {
    if (_detailNavigationBusy) return;
    final restoreOffset = _currentScrollOffset;
    _detailNavigationBusy = true;
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => ReminderDetailPage(
            agenda: widget.agenda,
            attendance: widget.attendance,
            projectLocations: widget.projectLocations,
            reminderId: reminder.id,
            istanbulToday: _todayOverview.istanbulDay.isEmpty
                ? null
                : _todayOverview.istanbulDay,
          ),
        ),
      );
      if (mounted) await _reload(restoreOffset: restoreOffset);
    } finally {
      _detailNavigationBusy = false;
    }
  }

  String _label(ReminderViewGroup group) => switch (group) {
    ReminderViewGroup.now => 'Şimdi ilgilen',
    ReminderViewGroup.overdue => 'Gecikenler',
    ReminderViewGroup.today => 'Bugün',
    ReminderViewGroup.tomorrow => 'Yarın',
    ReminderViewGroup.recheck => 'Tekrar kontrol',
    ReminderViewGroup.upcoming => 'Yaklaşanlar',
    ReminderViewGroup.inbox => 'Unutma Kutusu',
    ReminderViewGroup.history => 'Geçmiş',
    ReminderViewGroup.trash => 'Geri Dönüşüm Kutusu',
  };

  Future<void> _selectPrimary(_ReminderPrimaryView view) async {
    if (view == _ReminderPrimaryView.other) {
      await _showOtherViews();
      return;
    }
    if (_primaryView == view) return;
    setState(() => _primaryView = view);
    await _reload();
  }

  Future<void> _showOtherViews() async {
    final selected = await showModalBottomSheet<ReminderViewGroup>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          key: const Key('reminder-other-menu'),
          shrinkWrap: true,
          children: [
            const ListTile(title: Text('Diğer görünümler')),
            for (final group in const [
              ReminderViewGroup.upcoming,
              ReminderViewGroup.inbox,
              ReminderViewGroup.recheck,
              ReminderViewGroup.history,
              ReminderViewGroup.trash,
            ])
              ListTile(
                key: Key('reminder-other-${group.name}'),
                minVerticalPadding: 12,
                leading: Icon(_otherIcon(group)),
                title: Text(_label(group)),
                trailing: group == _otherGroup
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () => Navigator.pop(context, group),
              ),
          ],
        ),
      ),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _primaryView = _ReminderPrimaryView.other;
      _otherGroup = selected;
    });
    await _reload();
  }

  Future<void> _openInbox() async {
    setState(() {
      _primaryView = _ReminderPrimaryView.other;
      _otherGroup = ReminderViewGroup.inbox;
    });
    await _reload();
  }

  Future<void> _openCreate(ReminderScheduleKind initialSchedule) async {
    final created = await Navigator.of(context).push<MobileReminder>(
      MaterialPageRoute(
        builder: (_) => ReminderFormPage(
          agenda: widget.agenda,
          contextSuggestions: widget.contextSuggestions,
          projectLocations: widget.projectLocations,
          preferredProjectId: widget.preferredProjectId,
          initialSchedule: initialSchedule,
        ),
      ),
    );
    if (created == null || !mounted) return;
    setState(() {
      if (created.status == ReminderStatus.inbox) {
        _primaryView = _ReminderPrimaryView.other;
        _otherGroup = ReminderViewGroup.inbox;
      } else {
        _primaryView = _ReminderPrimaryView.today;
      }
    });
    await _reload();
  }

  IconData _otherIcon(ReminderViewGroup group) => switch (group) {
    ReminderViewGroup.upcoming => Icons.event_note_outlined,
    ReminderViewGroup.inbox => Icons.inbox_outlined,
    ReminderViewGroup.recheck => Icons.fact_check_outlined,
    ReminderViewGroup.history => Icons.history_outlined,
    ReminderViewGroup.trash => Icons.delete_outline,
    _ => Icons.more_horiz,
  };

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        key: const Key('reminder-list'),
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
        children: [
          FilledButton.icon(
            key: const Key('new-reminder'),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
            onPressed: () => _openCreate(ReminderScheduleKind.in15Minutes),
            icon: const Icon(Icons.add_alert_outlined),
            label: const Text('Yeni hatırlatıcı'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const Key('quick-inbox-reminder'),
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
            onPressed: () => _openCreate(ReminderScheduleKind.inbox),
            icon: const Icon(Icons.inbox_outlined),
            label: const Text('Unutma Kutusu'),
          ),
          const SizedBox(height: 12),
          Wrap(
            key: const Key('reminder-primary-filters'),
            spacing: 8,
            runSpacing: 8,
            children: [
              _primaryChip(
                key: const Key('reminder-primary-today'),
                label: 'Bugün',
                icon: Icons.today_outlined,
                view: _ReminderPrimaryView.today,
              ),
              _primaryChip(
                key: const Key('reminder-primary-tomorrow'),
                label: 'Yarın',
                icon: Icons.wb_sunny_outlined,
                view: _ReminderPrimaryView.tomorrow,
              ),
              _primaryChip(
                key: const Key('reminder-primary-other'),
                label: 'Diğer',
                icon: Icons.more_horiz_rounded,
                view: _ReminderPrimaryView.other,
              ),
            ],
          ),
          if (_primaryView == _ReminderPrimaryView.other) ...[
            const SizedBox(height: 12),
            Text(
              _label(_otherGroup),
              key: const Key('reminder-other-title'),
              style: Theme.of(context).textTheme.titleMedium,
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
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(_error!),
              ),
            )
          else if (_readError != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(_readError!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    _ReadRetryAction(
                      actionKey: const Key('reminder-read-error-retry'),
                      onPressed: _loading ? null : _retryRead,
                    ),
                  ],
                ),
              ),
            )
          else if (_primaryView == _ReminderPrimaryView.today)
            ..._buildTodayContent()
          else if (_items.isEmpty)
            _emptyCard(
              _primaryView == _ReminderPrimaryView.tomorrow
                  ? 'Yarın için planlanmış hatırlatıcı yok.'
                  : '${_label(_otherGroup)} boş.',
            )
          else
            ..._items.map(
              (reminder) => _reminderCard(
                reminder,
                showTomorrow:
                    _primaryView == _ReminderPrimaryView.other &&
                    _otherGroup == ReminderViewGroup.upcoming,
                showRestore:
                    _primaryView == _ReminderPrimaryView.other &&
                    _otherGroup == ReminderViewGroup.trash,
              ),
            ),
        ],
      ),
    );
  }

  Widget _primaryChip({
    required Key key,
    required String label,
    required IconData icon,
    required _ReminderPrimaryView view,
  }) {
    final selected = _primaryView == view;
    return _ReminderIconAction(
      actionKey: key,
      icon: icon,
      label: label,
      selected: selected,
      kind: selected
          ? _ReminderIconActionKind.filled
          : _ReminderIconActionKind.outlined,
      onPressed: () => _selectPrimary(view),
    );
  }

  List<Widget> _buildTodayContent() {
    if (_todayOverview.isEmpty) {
      return [
        Card(
          key: const Key('reminder-today-empty'),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(Icons.notifications_none_rounded, size: 44),
                const SizedBox(height: 8),
                const Text(
                  'Bugün için açık hatırlatıcı yok.',
                  textAlign: TextAlign.center,
                ),
                if (_todayOverview.inboxCount > 0) ...[
                  const SizedBox(height: 12),
                  _inboxButton(),
                ],
              ],
            ),
          ),
        ),
      ];
    }

    return [
      if (_todayOverview.overdue.isNotEmpty)
        ..._todaySection(
          title: 'Gecikenler',
          key: const Key('reminder-section-overdue'),
          items: _todayOverview.overdue,
          section: _ReminderTodaySection.overdue,
        ),
      if (_todayOverview.allDayToday.isNotEmpty)
        ..._todaySection(
          title: 'Tam gün',
          key: const Key('reminder-section-all-day'),
          items: _todayOverview.allDayToday,
          section: _ReminderTodaySection.allDayToday,
        ),
      if (_todayOverview.timedToday.isNotEmpty)
        ..._todaySection(
          title: 'Saatli bugün',
          key: const Key('reminder-section-timed-today'),
          items: _todayOverview.timedToday,
          section: _ReminderTodaySection.timedToday,
        ),
      if (_todayOverview.inboxCount > 0)
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: _inboxButton(),
          ),
        ),
    ];
  }

  List<Widget> _todaySection({
    required String title,
    required Key key,
    required List<MobileReminder> items,
    required _ReminderTodaySection section,
  }) {
    return [
      Padding(
        key: key,
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      ),
      for (final reminder in items)
        _reminderCard(reminder, section: section, showTomorrow: true),
    ];
  }

  Widget _inboxButton() {
    final count = _todayOverview.inboxCount;
    return _ReminderIconAction(
      actionKey: const Key('reminder-inbox-count'),
      icon: Icons.inbox_outlined,
      label: 'Unutma Kutusu, $count kayıt',
      badgeText: '$count',
      kind: _ReminderIconActionKind.tonal,
      onPressed: _openInbox,
    );
  }

  Widget _emptyCard(String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.notifications_none_rounded, size: 44),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _reminderCard(
    MobileReminder reminder, {
    _ReminderTodaySection? section,
    required bool showTomorrow,
    bool showRestore = false,
  }) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            key: Key('reminder-${reminder.id}'),
            minVerticalPadding: 12,
            title: Text(
              reminder.title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              [
                reminder.kind.label,
                reminder.status.label,
                _sourceLabel(reminder),
                if (reminder.displayLocation case final location?)
                  '$location${reminder.stableLocationArchivedAt == null ? '' : ' (Arşivli)'}',
                _scheduleLabel(reminder, section),
                if (showRestore && reminder.trashedAt != null)
                  'Taşındı: '
                      '${CseTimeCodec.formatIstanbul(reminder.trashedAt!)}',
              ].join(' • '),
              maxLines: showRestore ? 5 : 3,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: reminder.isImportant
                ? const Icon(Icons.priority_high_rounded)
                : const Icon(Icons.chevron_right),
            onTap: () => _openDetail(reminder),
          ),
          if (showTomorrow &&
              isReminderEligibleForTomorrowSnooze(
                reminder,
                istanbulToday: _todayOverview.istanbulDay,
              ))
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: _ReminderIconAction(
                  actionKey: Key('reminder-tomorrow-${reminder.id}'),
                  icon: Icons.wb_sunny_outlined,
                  label: reminder.allDayLocalDate == null
                      ? "Yarın 08:00'a ertele"
                      : 'Yarına ertele',
                  onPressed: _tomorrowBusy.contains(reminder.id)
                      ? null
                      : () => _moveToTomorrow(reminder),
                ),
              ),
            ),
          if (showRestore)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: _ReminderIconAction(
                  actionKey: Key('restore-reminder-${reminder.id}'),
                  icon: Icons.restore_from_trash_outlined,
                  label: 'Geri yükle',
                  onPressed: _restoreBusy.contains(reminder.id)
                      ? null
                      : () => _restoreFromTrash(reminder),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _sourceLabel(MobileReminder reminder) {
    final project = reminder.projectName ?? 'Kişisel';
    if (reminder.sourceLogId != null) return '$project • Ajanda';
    if (reminder.attendanceDayId != null) return '$project • Puantaj';
    if (reminder.concretePourId != null) return '$project • Beton';
    return project;
  }

  String _scheduleLabel(
    MobileReminder reminder,
    _ReminderTodaySection? section,
  ) {
    switch (section) {
      case _ReminderTodaySection.overdue:
        final nextAttentionAt = reminder.nextAttentionAt;
        if (nextAttentionAt != null) {
          return 'Gecikti • ${CseTimeCodec.formatIstanbul(nextAttentionAt)}';
        }
        return reminder.allDayLocalDate == _todayOverview.istanbulDay
            ? 'Gecikti • Tam gün'
            : 'Gecikti • '
                  '${CseTimeCodec.formatIstanbulDay(reminder.allDayLocalDate!)}'
                  ' • Tam gün';
      case _ReminderTodaySection.timedToday:
        return 'Bugün • '
            '${CseTimeCodec.istanbulTimeLabel(reminder.nextAttentionAt!)}';
      case _ReminderTodaySection.allDayToday:
        return 'Tam gün';
      case null:
        if (_primaryView == _ReminderPrimaryView.tomorrow) {
          final nextAttentionAt = reminder.nextAttentionAt;
          if (nextAttentionAt != null) {
            return 'Yarın • '
                '${CseTimeCodec.istanbulTimeLabel(nextAttentionAt)}';
          }
          return reminder.allDayLocalDate == null
              ? 'Plansız'
              : 'Yarın • Tam gün';
        }
        final nextAttentionAt = reminder.nextAttentionAt;
        if (nextAttentionAt != null) {
          return CseTimeCodec.formatIstanbul(nextAttentionAt);
        }
        if (reminder.allDayLocalDate == null) return 'Plansız';
        return '${CseTimeCodec.formatIstanbulDay(reminder.allDayLocalDate!)}'
            ' • Tam gün';
    }
  }
}

enum _ReminderIconActionKind { standard, filled, tonal, outlined }

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

class _ReminderIconAction extends StatelessWidget {
  const _ReminderIconAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.actionKey,
    this.kind = _ReminderIconActionKind.standard,
    this.badgeText,
    this.selected,
  });

  final Key? actionKey;
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final _ReminderIconActionKind kind;
  final String? badgeText;
  final bool? selected;

  @override
  Widget build(BuildContext context) {
    final style = IconButton.styleFrom(
      minimumSize: const Size.square(48),
      fixedSize: const Size.square(48),
      maximumSize: const Size.square(48),
      iconSize: 20,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.standard,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
    final iconWidget = _ReminderBadgedIcon(icon: icon, badgeText: badgeText);
    final button = switch (kind) {
      _ReminderIconActionKind.standard => IconButton(
        key: actionKey,
        tooltip: label,
        style: style,
        isSelected: selected,
        selectedIcon: iconWidget,
        onPressed: onPressed,
        icon: iconWidget,
      ),
      _ReminderIconActionKind.filled => IconButton.filled(
        key: actionKey,
        tooltip: label,
        style: style,
        isSelected: selected,
        selectedIcon: iconWidget,
        onPressed: onPressed,
        icon: iconWidget,
      ),
      _ReminderIconActionKind.tonal => IconButton.filledTonal(
        key: actionKey,
        tooltip: label,
        style: style,
        isSelected: selected,
        selectedIcon: iconWidget,
        onPressed: onPressed,
        icon: iconWidget,
      ),
      _ReminderIconActionKind.outlined => IconButton.outlined(
        key: actionKey,
        tooltip: label,
        style: style,
        isSelected: selected,
        selectedIcon: iconWidget,
        onPressed: onPressed,
        icon: iconWidget,
      ),
    };
    return Semantics(
      label: label,
      button: true,
      enabled: onPressed != null,
      selected: selected,
      excludeSemantics: true,
      child: button,
    );
  }
}

class _ReminderBadgedIcon extends StatelessWidget {
  const _ReminderBadgedIcon({required this.icon, this.badgeText});

  final IconData icon;
  final String? badgeText;

  @override
  Widget build(BuildContext context) {
    final badge = badgeText;
    if (badge == null) return Icon(icon);
    final colors = Theme.of(context).colorScheme;
    return SizedBox.square(
      dimension: 30,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(left: 3, bottom: 3, child: Icon(icon, size: 20)),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
              padding: const EdgeInsets.symmetric(horizontal: 3),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.error,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badge,
                maxLines: 1,
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                  color: colors.onError,
                  fontSize: 10,
                  height: 1,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
