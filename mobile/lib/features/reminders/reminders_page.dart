import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/application/attendance_application.dart';
import 'package:chief_site_engineer/core/record_id.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/features/reminders/reminder_detail_page.dart';
import 'package:chief_site_engineer/features/reminders/reminder_form_page.dart';
import 'package:flutter/material.dart';

enum _ReminderPrimaryView { today, tomorrow, other }

enum _ReminderTodaySection { overdue, timedToday, allDayToday }

class RemindersPage extends StatefulWidget {
  const RemindersPage({required this.agenda, this.attendance, super.key});

  final AgendaApplication agenda;
  final AttendanceApplication? attendance;

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
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
  final Set<String> _tomorrowBusy = {};
  final Set<String> _restoreBusy = {};

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

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
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
        });
      }
    } on Object {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Hatırlatıcılar güvenli biçimde okunamadı.';
      });
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
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
        children: [
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              key: const Key('quick-reminder'),
              onPressed: () async {
                final created = await Navigator.of(context)
                    .push<MobileReminder>(
                      MaterialPageRoute(
                        builder: (_) => ReminderFormPage(agenda: widget.agenda),
                      ),
                    );
                if (created != null && mounted) {
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
              },
              icon: const Icon(Icons.add_alert_outlined),
              label: const Text('+ Unutma'),
            ),
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
                view: _ReminderPrimaryView.today,
              ),
              _primaryChip(
                key: const Key('reminder-primary-tomorrow'),
                label: 'Yarın',
                view: _ReminderPrimaryView.tomorrow,
              ),
              _primaryChip(
                key: const Key('reminder-primary-other'),
                label: 'Diğer',
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
          if (_loading)
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
    required _ReminderPrimaryView view,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: ChoiceChip(
        key: key,
        label: Text(label),
        selected: _primaryView == view,
        onSelected: (_) => _selectPrimary(view),
      ),
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
      if (_todayOverview.timedToday.isNotEmpty)
        ..._todaySection(
          title: 'Saatli bugün',
          key: const Key('reminder-section-timed-today'),
          items: _todayOverview.timedToday,
          section: _ReminderTodaySection.timedToday,
        ),
      if (_todayOverview.allDayToday.isNotEmpty)
        ..._todaySection(
          title: 'Tam gün',
          key: const Key('reminder-section-all-day'),
          items: _todayOverview.allDayToday,
          section: _ReminderTodaySection.allDayToday,
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
    return TextButton.icon(
      key: const Key('reminder-inbox-count'),
      style: TextButton.styleFrom(minimumSize: const Size(44, 48)),
      onPressed: _openInbox,
      icon: const Icon(Icons.inbox_outlined),
      label: Text('Unutma Kutusunda ${_todayOverview.inboxCount} kayıt var'),
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
            onTap: () async {
              await Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => ReminderDetailPage(
                    agenda: widget.agenda,
                    attendance: widget.attendance,
                    reminderId: reminder.id,
                    istanbulToday: _todayOverview.istanbulDay.isEmpty
                        ? null
                        : _todayOverview.istanbulDay,
                  ),
                ),
              );
              if (mounted) await _reload();
            },
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
                child: TextButton.icon(
                  key: Key('reminder-tomorrow-${reminder.id}'),
                  style: TextButton.styleFrom(minimumSize: const Size(88, 48)),
                  onPressed: _tomorrowBusy.contains(reminder.id)
                      ? null
                      : () => _moveToTomorrow(reminder),
                  icon: const Icon(Icons.wb_sunny_outlined),
                  label: const Text('Yarına ertele'),
                ),
              ),
            ),
          if (showRestore)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: TextButton.icon(
                  key: Key('restore-reminder-${reminder.id}'),
                  style: TextButton.styleFrom(minimumSize: const Size(112, 48)),
                  onPressed: _restoreBusy.contains(reminder.id)
                      ? null
                      : () => _restoreFromTrash(reminder),
                  icon: const Icon(Icons.restore_from_trash_outlined),
                  label: const Text('Geri yükle'),
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
