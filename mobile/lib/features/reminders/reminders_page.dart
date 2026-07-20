import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/application/attendance_application.dart';
import 'package:chief_site_engineer/core/record_id.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/features/reminders/reminder_detail_page.dart';
import 'package:chief_site_engineer/features/reminders/reminder_form_page.dart';
import 'package:flutter/material.dart';

class RemindersPage extends StatefulWidget {
  const RemindersPage({required this.agenda, this.attendance, super.key});

  final AgendaApplication agenda;
  final AttendanceApplication? attendance;

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  ReminderViewGroup _group = ReminderViewGroup.now;
  List<MobileReminder> _items = const [];
  bool _loading = true;
  String? _error;
  final Set<String> _tomorrowBusy = {};

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
      if (mounted) setState(() => _error = 'Hatırlatıcı yarına taşınamadı.');
    } finally {
      if (mounted) setState(() => _tomorrowBusy.remove(reminder.id));
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
      final items = await widget.agenda.listReminders(_group);
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
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
    ReminderViewGroup.waiting => 'Bekliyorum',
    ReminderViewGroup.recheck => 'Tekrar kontrol',
    ReminderViewGroup.upcoming => 'Yaklaşanlar',
    ReminderViewGroup.inbox => 'Unutma Kutusu',
    ReminderViewGroup.history => 'Geçmiş',
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
                    _group = created.status == ReminderStatus.inbox
                        ? ReminderViewGroup.inbox
                        : ReminderViewGroup.today;
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
            spacing: 8,
            runSpacing: 8,
            children: ReminderViewGroup.values
                .map(
                  (group) => ChoiceChip(
                    key: Key('reminder-group-${group.name}'),
                    label: Text(_label(group)),
                    selected: _group == group,
                    onSelected: (_) {
                      setState(() => _group = group);
                      _reload();
                    },
                  ),
                )
                .toList(),
          ),
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
          else if (_items.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(Icons.notifications_none_rounded, size: 44),
                    const SizedBox(height: 8),
                    Text('${_label(_group)} boş.', textAlign: TextAlign.center),
                  ],
                ),
              ),
            )
          else
            ..._items.map(
              (reminder) => Card(
                child: ListTile(
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
                      reminder.projectName ?? 'Kişisel',
                      if (reminder.nextAttentionAt != null)
                        CseTimeCodec.formatIstanbul(reminder.nextAttentionAt!),
                    ].join(' • '),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing:
                      (_group == ReminderViewGroup.now ||
                              _group == ReminderViewGroup.overdue) &&
                          (reminder.status == ReminderStatus.active ||
                              reminder.status == ReminderStatus.waiting)
                      ? SizedBox(
                          width: 76,
                          child: TextButton(
                            key: Key('reminder-tomorrow-${reminder.id}'),
                            onPressed: _tomorrowBusy.contains(reminder.id)
                                ? null
                                : () => _moveToTomorrow(reminder),
                            child: const Text('Yarın'),
                          ),
                        )
                      : reminder.isImportant
                      ? const Icon(Icons.priority_high_rounded)
                      : const Icon(Icons.chevron_right),
                  onTap: () async {
                    await Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) => ReminderDetailPage(
                          agenda: widget.agenda,
                          attendance: widget.attendance,
                          reminderId: reminder.id,
                        ),
                      ),
                    );
                    if (mounted) await _reload();
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
