import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/features/agenda/log_detail_page.dart';
import 'package:flutter/material.dart';

class ReminderDetailPage extends StatelessWidget {
  const ReminderDetailPage({
    required this.agenda,
    required this.reminderId,
    super.key,
  });

  final AgendaApplication agenda;
  final String reminderId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hatırlatıcı detayı')),
      body: FutureBuilder<MobileReminder>(
        future: agenda.getReminderDetail(reminderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Hatırlatıcı güvenli biçimde okunamadı.'),
              ),
            );
          }
          final reminder = snapshot.requireData;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                reminder.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              _ReminderRow(label: 'Tür', value: reminder.kind.label),
              _ReminderRow(label: 'Durum', value: reminder.status.label),
              _ReminderRow(label: 'Proje', value: reminder.projectName),
              if (reminder.nextAttentionAt != null)
                _ReminderRow(
                  label: 'Sonraki dikkat zamanı',
                  value: CseTimeCodec.formatIstanbul(reminder.nextAttentionAt!),
                ),
              _ReminderRow(
                label: 'Oluşturma zamanı',
                value: CseTimeCodec.formatIstanbul(reminder.createdAt),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 52,
                child: FilledButton.tonalIcon(
                  key: const Key('open-source-agenda-log'),
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => LogDetailPage(
                        agenda: agenda,
                        logId: reminder.sourceLogId,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.event_note_outlined),
                  label: const Text('Kaynak Ajanda kaydına dön'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  const _ReminderRow({required this.label, required this.value});

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
