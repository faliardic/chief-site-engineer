import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/features/reminders/reminder_detail_page.dart';
import 'package:chief_site_engineer/features/reminders/reminder_form_page.dart';
import 'package:flutter/material.dart';

class LogDetailPage extends StatefulWidget {
  const LogDetailPage({required this.agenda, required this.logId, super.key});

  final AgendaApplication agenda;
  final String logId;

  @override
  State<LogDetailPage> createState() => _LogDetailPageState();
}

class _LogDetailPageState extends State<LogDetailPage> {
  late Future<AgendaLogDetail> _detail;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _detail = widget.agenda.getAgendaLogDetail(widget.logId);
  }

  Future<void> _createReminder(AgendaLog log) async {
    final result = await Navigator.of(context).push<MobileReminder>(
      MaterialPageRoute(
        builder: (_) => ReminderFormPage(agenda: widget.agenda, log: log),
      ),
    );
    if (result != null && mounted) setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajanda kaydı')),
      body: FutureBuilder<AgendaLogDetail>(
        future: _detail,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Ajanda kaydı güvenli biçimde okunamadı.'),
              ),
            );
          }
          final detail = snapshot.requireData;
          final log = detail.log;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                log.category.label,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                log.description,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              _DetailRow(label: 'Proje', value: log.projectName),
              _DetailRow(
                label: 'Olay zamanı',
                value: CseTimeCodec.formatIstanbul(log.observedAt),
              ),
              _DetailRow(
                label: 'CSE’ye giriş',
                value: CseTimeCodec.formatIstanbul(log.createdAt),
              ),
              if (log.location != null)
                _DetailRow(label: 'Mahal', value: log.location!),
              if (log.notes != null)
                _DetailRow(label: 'Ayrıntılı not', value: log.notes!),
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  key: const Key('detail-create-reminder'),
                  onPressed: () => _createReminder(log),
                  icon: const Icon(Icons.add_alert_outlined),
                  label: const Text('Hatırlatıcı oluştur'),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Bağlı hatırlatıcılar',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (detail.reminders.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Bu kayda bağlı hatırlatıcı yok.'),
                  ),
                )
              else
                ...detail.reminders.map(
                  (reminder) => Card(
                    child: ListTile(
                      key: Key('linked-reminder-${reminder.id}'),
                      minVerticalPadding: 12,
                      title: Text(
                        reminder.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${reminder.kind.label} • ${reminder.status.label}',
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
                        if (mounted) setState(_reload);
                      },
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 2),
          SelectableText(value),
        ],
      ),
    );
  }
}
