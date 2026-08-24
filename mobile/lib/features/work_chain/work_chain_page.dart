import 'package:chief_site_engineer/application/work_chain_application.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/work_chain_models.dart';
import 'package:flutter/material.dart';

class WorkChainPage extends StatefulWidget {
  const WorkChainPage.fromAgendaLog({
    required this.application,
    required String agendaLogId,
    super.key,
  }) : sourceId = agendaLogId,
       fromFollowUp = false;

  const WorkChainPage.fromFollowUp({
    required this.application,
    required String followUpId,
    super.key,
  }) : sourceId = followUpId,
       fromFollowUp = true;

  final WorkChainApplicationPort application;
  final String sourceId;
  final bool fromFollowUp;

  @override
  State<WorkChainPage> createState() => _WorkChainPageState();
}

class _WorkChainPageState extends State<WorkChainPage> {
  late Future<WorkChainDetail> _detail;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _detail = widget.fromFollowUp
        ? widget.application.loadFromFollowUp(widget.sourceId)
        : widget.application.loadFromAgendaLog(widget.sourceId);
  }

  void _retry() {
    setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('İş Zinciri')),
      body: FutureBuilder<WorkChainDetail>(
        future: _detail,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _WorkChainReadFailure(
              code: _failureCode(snapshot.error!),
              onRetry: _retry,
            );
          }
          return _WorkChainBody(detail: snapshot.requireData);
        },
      ),
    );
  }
}

class _WorkChainBody extends StatelessWidget {
  const _WorkChainBody({required this.detail});

  final WorkChainDetail detail;

  @override
  Widget build(BuildContext context) {
    final root = detail.root;
    return ListView(
      key: const Key('work-chain-list'),
      padding: const EdgeInsets.all(16),
      children: [
        if (detail.diagnostics.isNotEmpty)
          _WorkChainDiagnostics(diagnostics: detail.diagnostics),
        if (detail.diagnostics.isNotEmpty) const SizedBox(height: 12),
        if (root != null) _WorkChainRootCard(root: root),
        if (root != null) const SizedBox(height: 12),
        Text('Takipler', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (detail.followUps.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Bu kayda bağlı takip bulunamadı.'),
            ),
          )
        else
          for (final followUp in detail.followUps) ...[
            _WorkChainFollowUpCard(followUp: followUp),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _WorkChainDiagnostics extends StatelessWidget {
  const _WorkChainDiagnostics({required this.diagnostics});

  final List<WorkChainDiagnostic> diagnostics;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bağlantı tanıları',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            const Text('Bağlantının bir kısmı okunamadı.'),
            const Text('Kaynak kayıt değiştirilmedi.'),
            const SizedBox(height: 8),
            for (final diagnostic in diagnostics)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '• ${diagnostic.code.message}\n'
                  '  Tanı kodu: ${diagnostic.code.code}'
                  '${diagnostic.followUpId == null ? '' : ' · Takip: ${diagnostic.followUpId}'}',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WorkChainRootCard extends StatelessWidget {
  const _WorkChainRootCard({required this.root});

  final WorkChainRoot root;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: Key('work-chain-root-${root.id}'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Başlangıç', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            Text(
              root.description,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _LabeledValue(label: 'Kaynak kimliği', value: root.id),
            _LabeledValue(label: 'Proje', value: root.projectName),
            _LabeledValue(
              label: 'Zaman',
              value: _formatTimestamp(root.observedAt),
            ),
            _LabeledValue(
              label: 'Tür',
              value: _agendaCategoryLabel(root.category),
            ),
            if (root.location != null)
              _LabeledValue(label: 'Mahal', value: root.location!),
            if (root.notes != null)
              _LabeledValue(label: 'Not', value: root.notes!),
            _LabeledValue(
              label: 'Arşiv',
              value: root.archivedAt == null
                  ? 'Aktif kayıt'
                  : 'Arşivlendi · ${_formatTimestamp(root.archivedAt!)}',
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkChainFollowUpCard extends StatelessWidget {
  const _WorkChainFollowUpCard({required this.followUp});

  final WorkChainFollowUp followUp;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: Key('work-chain-follow-up-${followUp.id}'),
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text(followUp.title),
        subtitle: Text(
          '${followUp.kind.label} · ${followUp.status.label} · rev ${followUp.revision}',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LabeledValue(label: 'Takip kimliği', value: followUp.id),
                if (followUp.description != null)
                  _LabeledValue(
                    label: 'Açıklama',
                    value: followUp.description!,
                  ),
                _LabeledValue(
                  label: 'Sonraki dikkat',
                  value: _attentionText(followUp),
                ),
                _LabeledValue(
                  label: 'Gerçek son tarih',
                  value: followUp.deadlineAt == null
                      ? 'Belirtilmedi'
                      : _formatTimestamp(followUp.deadlineAt!),
                ),
                _LabeledValue(
                  label: 'Koşul/not',
                  value: followUp.conditionText ?? 'Belirtilmedi',
                ),
                _LabeledValue(
                  label: 'Arşiv',
                  value: followUp.trashedAt == null
                      ? 'Aktif kayıt'
                      : 'Geri dönüşüm kutusunda · ${_formatTimestamp(followUp.trashedAt!)}',
                ),
                const Divider(height: 28),
                Text('Geçmiş', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (followUp.events.isEmpty)
                  const Text('Anlamlı lifecycle olayı bulunamadı.')
                else
                  for (final event in followUp.events)
                    ListTile(
                      key: Key('work-chain-event-${event.id}'),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: CircleAvatar(
                        child: Text(event.sequence.toString()),
                      ),
                      title: Text(_eventLabel(event.eventType)),
                      subtitle: Text(_formatTimestamp(event.occurredAt)),
                    ),
                const Divider(height: 28),
                Text('Sonuç', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                _WorkChainResultView(result: followUp.result),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkChainResultView extends StatelessWidget {
  const _WorkChainResultView({required this.result});

  final WorkChainResult result;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LabeledValue(label: 'Güncel durum', value: result.status.label),
        _LabeledValue(
          label: 'Sonuç türü',
          value: result.outcomeType?.label ?? 'Sonuç henüz belirtilmedi',
        ),
        _LabeledValue(
          label: 'Sonuç notu',
          value: result.note ?? 'Sonuç notu girilmedi',
        ),
        _LabeledValue(
          label: 'Tamamlanma',
          value: result.completedAt == null
              ? 'Yok'
              : _formatTimestamp(result.completedAt!),
        ),
        _LabeledValue(
          label: 'İptal',
          value: result.cancelledAt == null
              ? 'Yok'
              : _formatTimestamp(result.cancelledAt!),
        ),
      ],
    );
  }
}

class _LabeledValue extends StatelessWidget {
  const _LabeledValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text('$label: $value'),
    );
  }
}

class _WorkChainReadFailure extends StatelessWidget {
  const _WorkChainReadFailure({required this.code, required this.onRetry});

  final String code;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.link_off_rounded, size: 44),
              const SizedBox(height: 10),
              const Text('İş Zinciri güvenle okunamadı.'),
              const SizedBox(height: 6),
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
      ),
    );
  }
}

String _attentionText(WorkChainFollowUp followUp) {
  if (followUp.nextAttentionAt != null) {
    return _formatTimestamp(followUp.nextAttentionAt!);
  }
  if (followUp.allDayLocalDate != null) {
    return CseTimeCodec.formatIstanbulDay(followUp.allDayLocalDate!);
  }
  return 'Unutma Kutusu';
}

String _formatTimestamp(String value) {
  final day = CseTimeCodec.istanbulDayKey(value);
  final local = CseTimeCodec.toIstanbul(value);
  final time =
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
  return '${CseTimeCodec.formatIstanbulDay(day)} $time';
}

String _failureCode(Object error) => switch (error) {
  WorkChainFailure failure => failure.code,
  _ => 'work_chain_unexpected_failure',
};

String _agendaCategoryLabel(String value) => switch (value) {
  'general_note' => 'Genel not',
  'manufacturing' => 'İmalat',
  'inspection' => 'Kontrol',
  'meeting_decision' => 'Görüşme/karar',
  'delivery' => 'Teslimat',
  'safety' => 'İş güvenliği',
  'concrete' => 'Beton',
  'issue_delay' => 'Sorun/gecikme',
  _ => value,
};

String _eventLabel(String value) => switch (value) {
  'created' => 'Oluşturuldu',
  'scheduled' => 'Planlandı',
  'rescheduled' => 'Yeniden planlandı',
  'details_updated' => 'Detaylar güncellendi',
  'waiting_started' => 'Bekleme başladı',
  'legacy_waiting_normalized' => 'Eski bekleme kaydı uyarlandı',
  'snoozed' => 'Ertelendi',
  'completed' => 'Tamamlandı',
  'cancelled' => 'İptal edildi',
  'reopened' => 'Yeniden açıldı',
  'moved_to_inbox' => 'Unutma Kutusuna taşındı',
  'trashed' => 'Geri dönüşüm kutusuna taşındı',
  'restored_from_trash' => 'Geri dönüşüm kutusundan çıkarıldı',
  _ => value,
};
