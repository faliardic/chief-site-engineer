import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/features/reminders/reminder_detail_page.dart';
import 'package:flutter/material.dart';

class RemindersPage extends StatefulWidget {
  const RemindersPage({required this.agenda, super.key});

  final AgendaApplication agenda;

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  ReminderViewGroup _group = ReminderViewGroup.inbox;
  List<MobileReminder> _items = const [];
  bool _loading = true;
  String? _error;

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
    ReminderViewGroup.inbox => 'Unutma Kutusu',
    ReminderViewGroup.today => 'Bugün',
    ReminderViewGroup.upcoming => 'Yaklaşanlar',
  };

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        key: const Key('reminder-list'),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
        children: [
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
                      reminder.projectName,
                      if (reminder.nextAttentionAt != null)
                        CseTimeCodec.formatIstanbul(reminder.nextAttentionAt!),
                    ].join(' • '),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) => ReminderDetailPage(
                          agenda: widget.agenda,
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
