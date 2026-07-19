import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/application/concrete_application.dart';
import 'package:chief_site_engineer/core/record_id.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/concrete_models.dart';
import 'package:chief_site_engineer/features/reminders/reminder_detail_page.dart';
import 'package:chief_site_engineer/platform/attachment_gateway.dart';
import 'package:flutter/material.dart';

class ConcretePourDetailPage extends StatefulWidget {
  const ConcretePourDetailPage({
    required this.concrete,
    required this.agenda,
    required this.attachments,
    required this.pourId,
    super.key,
  });

  final ConcreteApplication concrete;
  final AgendaApplication agenda;
  final SafeAttachmentPicker attachments;
  final String pourId;

  @override
  State<ConcretePourDetailPage> createState() => _ConcretePourDetailPageState();
}

class _ConcretePourDetailPageState extends State<ConcretePourDetailPage> {
  ConcretePourDetail? _detail;
  bool _loading = true;
  bool _mutating = false;
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
      final value = await widget.concrete.getPourDetail(widget.pourId);
      if (mounted) setState(() => _detail = value);
    } on Object catch (error) {
      if (mounted) {
        setState(() => _error = _message(error, 'Beton paketi açılamadı.'));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _run(Future<Object?> Function() mutation) async {
    if (_mutating) return;
    setState(() {
      _mutating = true;
      _error = null;
    });
    try {
      await mutation();
      await _reload();
    } on Object catch (error) {
      if (mounted) {
        setState(() => _error = _message(error, 'İşlem tamamlanamadı.'));
      }
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  Future<void> _updateCheck(
    ConcreteCheckItem item,
    ConcreteCheckStatus status,
  ) async {
    String? reason;
    if (status == ConcreteCheckStatus.exception ||
        status == ConcreteCheckStatus.notApplicable) {
      reason = await _askText('Gerekçe', 'Bu durum için açık gerekçe yazın.');
      if (reason == null) return;
    }
    final detail = _detail!;
    await _run(
      () => widget.concrete.updateCheck(
        UpdateConcreteCheckCommand(
          pourId: detail.pour.id,
          checkId: item.id,
          eventId: RecordId.randomUuid(),
          expectedPourRevision: detail.pour.revision,
          expectedCheckRevision: item.revision,
          status: status,
          reason: reason,
        ),
      ),
    );
  }

  Future<void> _transition(ConcretePourStatus target) async {
    String? reason;
    if (target == ConcretePourStatus.cancelled ||
        target == ConcretePourStatus.draft) {
      reason = await _askText(
        target == ConcretePourStatus.cancelled
            ? 'İptal nedeni'
            : 'Yeniden açma nedeni',
        'İşlem gerekçesini yazın.',
      );
      if (reason == null) return;
    }
    final detail = _detail!;
    await _run(
      () => widget.concrete.transitionPour(
        TransitionConcretePourCommand(
          pourId: detail.pour.id,
          eventId: RecordId.randomUuid(),
          expectedRevision: detail.pour.revision,
          targetStatus: target,
          reason: reason,
        ),
      ),
    );
  }

  Future<void> _addTruck() async {
    final detail = _detail!;
    final plate = TextEditingController();
    final note = TextEditingController();
    final volume = TextEditingController();
    final result = await showDialog<(String, String, double)?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mikser / irsaliye ekle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: plate,
                decoration: const InputDecoration(labelText: 'Plaka'),
              ),
              TextField(
                controller: note,
                decoration: const InputDecoration(
                  labelText: 'İrsaliye numarası',
                ),
              ),
              TextField(
                controller: volume,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Metraj (m³)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () {
              final parsed = double.tryParse(volume.text.replaceAll(',', '.'));
              if (plate.text.trim().isNotEmpty &&
                  note.text.trim().isNotEmpty &&
                  parsed != null &&
                  parsed > 0) {
                Navigator.pop(context, (plate.text, note.text, parsed));
              }
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
    plate.dispose();
    note.dispose();
    volume.dispose();
    if (result == null) return;
    await _run(
      () => widget.concrete.saveTruck(
        SaveConcreteTruckCommand(
          id: RecordId.randomUuid(),
          pourId: detail.pour.id,
          eventId: RecordId.randomUuid(),
          expectedPourRevision: detail.pour.revision,
          expectedTruckRevision: 0,
          sequenceNo:
              detail.trucks.fold(
                0,
                (max, item) => item.sequenceNo > max ? item.sequenceNo : max,
              ) +
              1,
          vehiclePlate: result.$1,
          deliveryNoteNumber: result.$2,
          volumeM3: result.$3,
          result: ConcreteTruckResult.received,
          arrivedAt: CseTimeCodec.encodeUtc(DateTime.now().toUtc()),
        ),
      ),
    );
  }

  Future<void> _addSample() async {
    final detail = _detail!;
    final code = TextEditingController();
    final count = TextEditingController(text: '6');
    final result = await showDialog<(String, int)?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Numune seti ekle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: code,
              decoration: const InputDecoration(labelText: 'Numune kodu'),
            ),
            TextField(
              controller: count,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Adet'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () {
              final parsed = int.tryParse(count.text);
              if (code.text.trim().isNotEmpty && parsed != null && parsed > 0) {
                Navigator.pop(context, (code.text, parsed));
              }
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
    code.dispose();
    count.dispose();
    if (result == null) return;
    final now = CseTimeCodec.encodeUtc(DateTime.now().toUtc());
    await _run(
      () => widget.concrete.saveSampleSet(
        SaveConcreteSampleSetCommand(
          id: RecordId.randomUuid(),
          pourId: detail.pour.id,
          eventId: RecordId.randomUuid(),
          expectedPourRevision: detail.pour.revision,
          expectedSampleRevision: 0,
          sampleCode: result.$1,
          sampleCount: result.$2,
          sampleLabels: List.generate(
            result.$2,
            (index) => '${result.$1}-${index + 1}',
          ),
          expectedResultDates: [
            CseTimeCodec.encodeUtc(
              DateTime.now().toUtc().add(const Duration(days: 7)),
            ),
            CseTimeCodec.encodeUtc(
              DateTime.now().toUtc().add(const Duration(days: 28)),
            ),
          ],
          status: ConcreteSampleStatus.sampled,
          sampledAt: now,
          sampledBy: 'Saha ekibi',
        ),
      ),
    );
  }

  Future<void> _attach({
    ConcreteTruck? truck,
    ConcreteSampleSet? sample,
    ConcreteEvidenceType? requestedType,
  }) async {
    final source = await showModalBottomSheet<AttachmentSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Kamera'),
              onTap: () => Navigator.pop(context, AttachmentSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Fotoğraf arşivi'),
              onTap: () =>
                  Navigator.pop(context, AttachmentSource.photoLibrary),
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text('Dosya seç'),
              onTap: () => Navigator.pop(context, AttachmentSource.filePicker),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final selected = await widget.attachments.pick(source);
    if (selected.$1 != AttachmentPickOutcome.selected || selected.$2 == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dosya seçilmedi; Beton kaydı değişmedi.'),
          ),
        );
      }
      return;
    }
    if (!mounted) return;
    var type = requestedType ?? ConcreteEvidenceType.sitePhoto;
    if (truck != null && requestedType == null) {
      type =
          await showDialog<ConcreteEvidenceType>(
            context: context,
            builder: (context) => SimpleDialog(
              title: const Text('Mikser kanıt türü'),
              children: [
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(
                    context,
                    ConcreteEvidenceType.deliveryReceiptScan,
                  ),
                  child: const Text('İrsaliye taraması'),
                ),
                SimpleDialogOption(
                  onPressed: () =>
                      Navigator.pop(context, ConcreteEvidenceType.mixerPhoto),
                  child: const Text('Mikser fotoğrafı'),
                ),
              ],
            ),
          ) ??
          ConcreteEvidenceType.mixerPhoto;
    } else if (sample != null) {
      type = ConcreteEvidenceType.samplePhoto;
    }
    final detail = _detail!;
    await _run(
      () => widget.concrete.attachEvidence(
        AttachConcreteEvidenceCommand(
          id: RecordId.randomUuid(),
          pourId: detail.pour.id,
          eventId: RecordId.randomUuid(),
          expectedPourRevision: detail.pour.revision,
          evidenceType: type,
          originalFileName: selected.$2!.name,
          bytes: selected.$2!.bytes,
          capturedAt: CseTimeCodec.encodeUtc(DateTime.now().toUtc()),
          truckId: truck?.id,
          sampleSetId: sample?.id,
        ),
      ),
    );
  }

  Future<void> _completeFollowUp(
    ConcreteFollowUp item,
    ConcreteFollowUpStatus status,
  ) async {
    String? reason;
    if (status == ConcreteFollowUpStatus.exception) {
      reason = await _askText('Takip istisnası', 'Açık gerekçe yazın.');
      if (reason == null) return;
    }
    final detail = _detail!;
    await _run(
      () => widget.concrete.updateFollowUp(
        UpdateConcreteFollowUpCommand(
          pourId: detail.pour.id,
          followUpId: item.id,
          eventId: RecordId.randomUuid(),
          reminderEventId: RecordId.randomUuid(),
          expectedPourRevision: detail.pour.revision,
          expectedFollowUpRevision: item.revision,
          status: status,
          dueAt: item.dueAt,
          reason: reason,
        ),
      ),
    );
  }

  Future<String?> _askText(String title, String hint) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _detail == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final detail = _detail;
    if (detail == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(_error ?? 'Beton paketi bulunamadı.')),
      );
    }
    final pour = detail.pour;
    return Scaffold(
      appBar: AppBar(
        title: Text(pour.pourCode),
        actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_mutating) const LinearProgressIndicator(),
            if (_error case final error?)
              Text(
                error,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            _section('Özet', [
              ListTile(
                title: Text(pour.elementLocation),
                subtitle: Text(
                  '${pour.projectName}\n${CseTimeCodec.formatIstanbul(pour.plannedAt)} • ${pour.concreteClass} • ${pour.status.label}',
                ),
                isThreeLine: true,
              ),
              ListTile(
                title: const Text('Metraj'),
                subtitle: Text(
                  'Plan ${pour.plannedVolumeM3.toStringAsFixed(2)} m³ • Gelen ${detail.metrics.actualDeliveredM3.toStringAsFixed(2)} m³ • Fark ${detail.metrics.varianceM3.toStringAsFixed(2)} m³',
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _transitionButtons(pour.status),
              ),
            ]),
            _section(
              'Döküm öncesi checklist • ${detail.metrics.pendingCheckCount} açık',
              [
                for (final item in detail.checks)
                  ListTile(
                    title: Text('${item.sortOrder}. ${item.label}'),
                    subtitle: Text(item.reason ?? item.status.label),
                    trailing: PopupMenuButton<ConcreteCheckStatus>(
                      onSelected: (value) => _updateCheck(item, value),
                      itemBuilder: (_) => ConcreteCheckStatus.values
                          .map(
                            (value) => PopupMenuItem(
                              value: value,
                              child: Text(value.label),
                            ),
                          )
                          .toList(),
                    ),
                  ),
              ],
            ),
            _section('Mikser / irsaliye • ${detail.trucks.length}', [
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.tonalIcon(
                  onPressed: _mutating ? null : _addTruck,
                  icon: const Icon(Icons.add),
                  label: const Text('Mikser ekle'),
                ),
              ),
              for (final item in detail.trucks)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '#${item.sequenceNo} ${item.vehiclePlate} • ${item.volumeM3.toStringAsFixed(2)} m³',
                        ),
                        subtitle: Text(
                          'İrsaliye ${item.deliveryNoteNumber} • ${item.result.label}\n'
                          '${detail.attachments.where((evidence) => evidence.truckId == item.id).length} kanıt bağlı'
                          '${item.evidenceExceptionReason == null ? '' : ' • açık istisna'}',
                        ),
                        isThreeLine: true,
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _attach(
                              truck: item,
                              requestedType:
                                  ConcreteEvidenceType.deliveryReceiptScan,
                            ),
                            icon: const Icon(Icons.receipt_long_outlined),
                            label: const Text('İrsaliyeyi tara/fotoğrafla'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _attach(
                              truck: item,
                              requestedType: ConcreteEvidenceType.mixerPhoto,
                            ),
                            icon: const Icon(Icons.add_a_photo_outlined),
                            label: const Text('Mikser fotoğrafı çek'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              if (detail.metrics.missingEvidenceTruckCount > 0)
                Text(
                  '${detail.metrics.missingEvidenceTruckCount} mikserde irsaliye veya mikser kanıtı eksik.',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ]),
            _section('Kanıtlar • ${detail.attachments.length}', [
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () => _attach(),
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Saha kanıtı ekle'),
                ),
              ),
              for (final item in detail.attachments)
                ListTile(
                  leading: Icon(
                    item.integrity == ConcreteAttachmentIntegrity.ok
                        ? Icons.verified_outlined
                        : Icons.warning_amber_rounded,
                  ),
                  title: Text(item.evidenceType.label),
                  subtitle: Text(
                    '${item.originalFileName}\n${item.integrity.label} • ${item.sha256.substring(0, 12)}…',
                  ),
                  isThreeLine: true,
                ),
            ]),
            _section(
              'Numuneler • ${detail.metrics.sampleSetCount} set / ${detail.metrics.sampleCount} adet',
              [
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.tonalIcon(
                    onPressed: _addSample,
                    icon: const Icon(Icons.add),
                    label: const Text('Numune seti ekle'),
                  ),
                ),
                for (final item in detail.sampleSets)
                  ListTile(
                    title: Text(
                      '${item.sampleCode} • ${item.sampleCount} adet',
                    ),
                    subtitle: Text(
                      '${item.status.label}\nSonuç: ${item.expectedResultDates.map(CseTimeCodec.formatIstanbul).join(', ')}',
                    ),
                    trailing: IconButton(
                      onPressed: () => _attach(sample: item),
                      icon: const Icon(Icons.add_a_photo_outlined),
                    ),
                  ),
              ],
            ),
            _section(
              'Takipler / Hatırlatıcılar • ${detail.metrics.openFollowUpCount} açık',
              [
                for (final item in detail.followUps)
                  ListTile(
                    title: Text(item.label),
                    subtitle: Text(
                      '${item.status.label}${item.dueAt == null ? '' : ' • ${CseTimeCodec.formatIstanbul(item.dueAt!)}'}',
                    ),
                    onTap: item.reminderId == null
                        ? null
                        : () => Navigator.of(context).push<void>(
                            MaterialPageRoute(
                              builder: (_) => ReminderDetailPage(
                                agenda: widget.agenda,
                                concrete: widget.concrete,
                                concreteAttachments: widget.attachments,
                                reminderId: item.reminderId!,
                              ),
                            ),
                          ),
                    trailing: item.status == ConcreteFollowUpStatus.pending
                        ? PopupMenuButton<ConcreteFollowUpStatus>(
                            onSelected: (value) =>
                                _completeFollowUp(item, value),
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: ConcreteFollowUpStatus.completed,
                                child: Text('Tamamla'),
                              ),
                              PopupMenuItem(
                                value: ConcreteFollowUpStatus.exception,
                                child: Text('İstisna'),
                              ),
                            ],
                          )
                        : const Icon(Icons.check_circle_outline),
                  ),
              ],
            ),
            _section('Zaman çizelgesi', [
              for (final event in detail.events.reversed)
                ListTile(
                  dense: true,
                  title: Text('${event.sequence}. ${event.eventType}'),
                  subtitle: Text(CseTimeCodec.formatIstanbul(event.occurredAt)),
                ),
            ]),
            FilledButton.icon(
              onPressed: _mutating
                  ? null
                  : () async {
                      final revision = _detail!.pour.revision;
                      await _run(
                        () => widget.concrete.exportPackage(
                          ExportConcretePackageCommand(
                            pourId: pour.id,
                            eventId: RecordId.randomUuid(),
                            expectedRevision: revision,
                          ),
                          share: true,
                        ),
                      );
                    },
              icon: const Icon(Icons.ios_share_outlined),
              label: const Text('UTF-8 Beton paketi raporunu paylaş'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  List<Widget> _transitionButtons(ConcretePourStatus status) {
    final targets = switch (status) {
      ConcretePourStatus.draft => [
        ConcretePourStatus.prepared,
        ConcretePourStatus.cancelled,
      ],
      ConcretePourStatus.prepared => [
        ConcretePourStatus.pouring,
        ConcretePourStatus.draft,
        ConcretePourStatus.cancelled,
      ],
      ConcretePourStatus.pouring => [
        ConcretePourStatus.poured,
        ConcretePourStatus.cancelled,
      ],
      ConcretePourStatus.poured => [
        ConcretePourStatus.followUp,
        ConcretePourStatus.closed,
        ConcretePourStatus.cancelled,
      ],
      ConcretePourStatus.followUp => [
        ConcretePourStatus.closed,
        ConcretePourStatus.cancelled,
      ],
      ConcretePourStatus.closed ||
      ConcretePourStatus.cancelled => [ConcretePourStatus.draft],
    };
    return targets
        .map(
          (target) => FilledButton.tonal(
            onPressed: _mutating ? null : () => _transition(target),
            child: Text(target.label),
          ),
        )
        .toList(growable: false);
  }

  Widget _section(String title, List<Widget> children) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const Divider(),
          ...children,
        ],
      ),
    ),
  );
}

String _message(Object error, String fallback) =>
    error is AgendaValidationFailure ? error.message : fallback;
