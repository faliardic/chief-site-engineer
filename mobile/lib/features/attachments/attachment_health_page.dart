import 'package:chief_site_engineer/application/attachment_reconciliation_application.dart';
import 'package:chief_site_engineer/domain/attachment_models.dart';
import 'package:flutter/material.dart';

class AttachmentHealthPage extends StatefulWidget {
  const AttachmentHealthPage({this.reconciliation, this.inspector, super.key})
    : assert(reconciliation != null || inspector != null);

  final AttachmentReconciliationApplication? reconciliation;
  final Future<AttachmentReconciliationReport> Function()? inspector;

  Future<AttachmentReconciliationReport> inspect() =>
      inspector?.call() ?? reconciliation!.inspect();

  @override
  State<AttachmentHealthPage> createState() => _AttachmentHealthPageState();
}

class _AttachmentHealthPageState extends State<AttachmentHealthPage> {
  late Future<AttachmentReconciliationReport> _report;

  @override
  void initState() {
    super.initState();
    _inspect();
  }

  void _inspect() {
    _report = widget.inspect();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dosya sağlığı'),
        actions: [
          IconButton(
            key: const Key('refresh-attachment-health'),
            tooltip: 'Yeniden denetle',
            onPressed: () => setState(_inspect),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<AttachmentReconciliationReport>(
        future: _report,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Dosya sağlığı salt-okunur olarak denetlenemedi. Hiçbir dosya değiştirilmedi.',
                  key: Key('attachment-health-error'),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final report = snapshot.requireData;
          final problems = report.findings
              .where(
                (finding) =>
                    finding.type != AttachmentReconciliationFindingType.healthy,
              )
              .toList(growable: false);
          return ListView(
            key: const Key('attachment-health-list'),
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.health_and_safety_outlined, size: 36),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${report.healthyCount} sağlıklı • ${report.problemCount} sorun',
                              key: const Key('attachment-health-summary'),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const Text(
                              'Bu ekran yalnız okur; silme, taşıma veya onarım yapmaz.',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (problems.isEmpty)
                const Card(
                  child: ListTile(
                    key: Key('attachment-health-clean'),
                    leading: Icon(Icons.verified_outlined),
                    title: Text('Görünür dosya sorunu bulunmadı.'),
                  ),
                )
              else
                for (final finding in problems)
                  Card(
                    child: ListTile(
                      key: Key(
                        'attachment-health-${finding.type.code}-${finding.attachmentId ?? finding.linkId ?? finding.relativePath ?? 'item'}',
                      ),
                      leading: const Icon(Icons.warning_amber_rounded),
                      title: Text(_findingLabel(finding.type)),
                      subtitle: Text(_findingContext(finding)),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}

String _findingContext(AttachmentReconciliationFinding finding) => <String?>[
  finding.relativePath,
  finding.attachmentId == null ? null : 'Dosya: ${finding.attachmentId}',
  finding.linkId == null ? null : 'Bağ: ${finding.linkId}',
  finding.relatedAttachmentIds.isEmpty
      ? null
      : 'Benzer adaylar: ${finding.relatedAttachmentIds.length}',
].whereType<String>().join('\n');

String _findingLabel(
  AttachmentReconciliationFindingType type,
) => switch (type) {
  AttachmentReconciliationFindingType.healthy => 'Sağlıklı',
  AttachmentReconciliationFindingType.missingFile => 'Dosya eksik',
  AttachmentReconciliationFindingType.sizeMismatch => 'Boyut uyuşmuyor',
  AttachmentReconciliationFindingType.hashMismatch => 'Hash uyuşmuyor',
  AttachmentReconciliationFindingType.mimeMismatch => 'Dosya türü uyuşmuyor',
  AttachmentReconciliationFindingType.unsafePath => 'Güvensiz dosya yolu',
  AttachmentReconciliationFindingType.brokenTarget => 'Kırık kayıt bağlantısı',
  AttachmentReconciliationFindingType.crossProjectTarget =>
    'Proje bağlantısı uyuşmuyor',
  AttachmentReconciliationFindingType.orphanFinalizedFile =>
    'Bağsız yönetilen dosya',
  AttachmentReconciliationFindingType.staleStagingFile =>
    'Tamamlanmamış geçici dosya',
  AttachmentReconciliationFindingType.duplicateLegacyCandidate =>
    'Benzer eski dosya adayı',
};
