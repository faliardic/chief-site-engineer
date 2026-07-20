import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/application/concrete_application.dart';
import 'package:chief_site_engineer/core/record_id.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/concrete_models.dart';
import 'package:chief_site_engineer/features/concrete/concrete_attachment_viewer_page.dart';
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

  Future<void> _editFieldNotifications() async {
    final pour = _detail!.pour;
    var laboratoryComplete = pour.laboratoryAppointment != null;
    var inspectionComplete =
        pour.inspectionNotifiedAt != null ||
        (pour.inspectionNotifiedPerson?.trim().isNotEmpty ?? false);
    final inspectionPerson = TextEditingController(
      text: pour.inspectionNotifiedPerson,
    );
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Laboratuvar ve yapı denetim'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  key: const Key('laboratory-appointment-complete'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Laboratuvar randevusu alındı/doğrulandı'),
                  value: laboratoryComplete,
                  onChanged: (value) =>
                      setDialogState(() => laboratoryComplete = value),
                ),
                SwitchListTile(
                  key: const Key('inspection-notification-complete'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Yapı denetime haber verildi'),
                  value: inspectionComplete,
                  onChanged: (value) =>
                      setDialogState(() => inspectionComplete = value),
                ),
                TextField(
                  controller: inspectionPerson,
                  decoration: const InputDecoration(
                    labelText: 'Yapı denetim kişisi (opsiyonel)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
    final person = inspectionPerson.text;
    await Future<void>.delayed(kThemeAnimationDuration);
    inspectionPerson.dispose();
    if (accepted != true) return;
    final now = CseTimeCodec.encodeUtc(DateTime.now().toUtc());
    await _run(
      () => widget.concrete.updatePour(
        UpdateConcretePourCommand(
          id: pour.id,
          eventId: RecordId.randomUuid(),
          expectedRevision: pour.revision,
          elementLocation: pour.elementLocation,
          plannedAt: pour.plannedAt,
          concreteClass: pour.concreteClass,
          plannedVolumeM3: pour.plannedVolumeM3,
          blockName: pour.blockName,
          floorName: pour.floorName,
          axisName: pour.axisName,
          targetSlump: pour.targetSlump,
          orderedVolumeM3: pour.orderedVolumeM3,
          plantName: pour.plantName,
          plantBranch: pour.plantBranch,
          plantContact: pour.plantContact,
          plantAppointmentReference: pour.plantAppointmentReference,
          pumpEquipment: pour.pumpEquipment,
          laboratoryName: pour.laboratoryName,
          laboratoryContact: pour.laboratoryContact,
          laboratoryAppointment: laboratoryComplete
              ? pour.laboratoryAppointment ?? now
              : null,
          inspectionNotifiedAt: inspectionComplete
              ? pour.inspectionNotifiedAt ?? now
              : null,
          inspectionNotifiedPerson: inspectionComplete ? person : null,
          generalNote: pour.generalNote,
          sampleExceptionReason: pour.sampleExceptionReason,
          varianceNote: pour.varianceNote,
        ),
      ),
    );
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

  Future<void> _editTruck([ConcreteTruck? current]) async {
    final detail = _detail!;
    final plate = TextEditingController(text: current?.vehiclePlate);
    final deliveryNote = TextEditingController(
      text: current?.deliveryNoteNumber,
    );
    final volume = TextEditingController(
      text: current?.volumeM3.toStringAsFixed(2),
    );
    final note = TextEditingController(text: current?.note);
    final reason = TextEditingController(text: current?.reason);
    var truckResult = current?.result ?? ConcreteTruckResult.received;
    var arrivedAt = current?.arrivedAt;
    var unloadingStartedAt = current?.unloadingStartedAt;
    var unloadingEndedAt = current?.unloadingEndedAt;
    final result = await showDialog<_TruckDraft>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            current == null ? 'Mikser / irsaliye ekle' : 'Mikseri düzenle',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: plate,
                  decoration: const InputDecoration(labelText: 'Plaka'),
                ),
                TextField(
                  controller: deliveryNote,
                  decoration: const InputDecoration(
                    labelText: 'İrsaliye numarası (opsiyonel)',
                  ),
                ),
                TextField(
                  controller: volume,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Dökülen (m³)'),
                ),
                DropdownButtonFormField<ConcreteTruckResult>(
                  initialValue: truckResult,
                  decoration: const InputDecoration(labelText: 'Sonuç'),
                  items: ConcreteTruckResult.values
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value.label),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) =>
                      setDialogState(() => truckResult = value!),
                ),
                _TruckTimeTile(
                  label: 'Geliş zamanı',
                  value: arrivedAt,
                  onChanged: (value) => setDialogState(() => arrivedAt = value),
                ),
                _TruckTimeTile(
                  label: 'Boşaltma başlangıcı',
                  value: unloadingStartedAt,
                  onChanged: (value) =>
                      setDialogState(() => unloadingStartedAt = value),
                ),
                _TruckTimeTile(
                  label: 'Boşaltma bitişi',
                  value: unloadingEndedAt,
                  onChanged: (value) =>
                      setDialogState(() => unloadingEndedAt = value),
                ),
                TextField(
                  controller: note,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Mikser notu (opsiyonel)',
                  ),
                ),
                if (truckResult != ConcreteTruckResult.received)
                  TextField(
                    controller: reason,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Sonuç nedeni',
                    ),
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
              key: const Key('save-concrete-truck'),
              onPressed: () {
                final parsed = double.tryParse(
                  volume.text.replaceAll(',', '.'),
                );
                final hasRequiredReason =
                    truckResult == ConcreteTruckResult.received ||
                    reason.text.trim().isNotEmpty;
                if (plate.text.trim().isNotEmpty &&
                    parsed != null &&
                    parsed > 0 &&
                    hasRequiredReason) {
                  Navigator.pop(
                    context,
                    _TruckDraft(
                      plate: plate.text,
                      deliveryNote: deliveryNote.text,
                      volume: parsed,
                      result: truckResult,
                      arrivedAt: arrivedAt,
                      unloadingStartedAt: unloadingStartedAt,
                      unloadingEndedAt: unloadingEndedAt,
                      note: note.text,
                      reason: reason.text,
                    ),
                  );
                }
              },
              child: Text(current == null ? 'Ekle' : 'Kaydet'),
            ),
          ],
        ),
      ),
    );
    plate.dispose();
    deliveryNote.dispose();
    volume.dispose();
    note.dispose();
    reason.dispose();
    if (result == null) return;
    await _run(
      () => widget.concrete.saveTruck(
        SaveConcreteTruckCommand(
          id: current?.id ?? RecordId.randomUuid(),
          pourId: detail.pour.id,
          eventId: RecordId.randomUuid(),
          expectedPourRevision: detail.pour.revision,
          expectedTruckRevision: current?.revision ?? 0,
          sequenceNo:
              current?.sequenceNo ??
              detail.trucks.fold(
                    0,
                    (max, item) =>
                        item.sequenceNo > max ? item.sequenceNo : max,
                  ) +
                  1,
          vehiclePlate: result.plate,
          deliveryNoteNumber: result.deliveryNote,
          volumeM3: result.volume,
          result: result.result,
          arrivedAt:
              result.arrivedAt ??
              (current == null
                  ? CseTimeCodec.encodeUtc(DateTime.now().toUtc())
                  : null),
          unloadingStartedAt: result.unloadingStartedAt,
          unloadingEndedAt: result.unloadingEndedAt,
          note: result.note,
          reason: result.reason,
          plantSnapshot: current?.plantSnapshot,
          batchTime: current?.batchTime,
          measuredSlump: current?.measuredSlump,
          concreteTemperature: current?.concreteTemperature,
          evidenceExceptionReason: current?.evidenceExceptionReason,
        ),
      ),
    );
  }

  Future<void> _addSample() async {
    final detail = _detail!;
    final count = TextEditingController(text: '6');
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Numune seti ekle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Numune seti uygulama tarafından sırayla adlandırılır.'),
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
              if (parsed != null && parsed > 0) {
                Navigator.pop(context, parsed);
              }
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
    await Future<void>.delayed(kThemeAnimationDuration);
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
          sampleCount: result,
          sampleLabels: List.generate(result, (index) => 'Numune ${index + 1}'),
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
                    ConcreteEvidenceType.deliveryNoteScan,
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
    if (!mounted) return;
    if (type == ConcreteEvidenceType.deliveryNoteScan) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('İrsaliye belgesini kontrol et'),
          content: Text(
            '${selected.$2!.name}\n\nBelge okunaklıysa kullanın. Değilse '
            'yeniden çekmek/seçmek için vazgeçin.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Yeniden seç'),
            ),
            FilledButton(
              key: const Key('confirm-delivery-note-scan'),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Belgeyi kullan'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
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

  Future<void> _editTargetVolume() async {
    final detail = _detail!;
    final controller = TextEditingController(
      text: detail.pour.plannedVolumeM3.toStringAsFixed(2),
    );
    final value = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hedef toplam m³'),
        content: TextField(
          key: const Key('target-volume-input'),
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Hedef toplam m³',
            helperText:
                'Dökülen: ${_formatM3(detail.metrics.actualDeliveredM3)} m³',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () {
              final parsed = double.tryParse(
                controller.text.replaceAll(',', '.'),
              );
              if (parsed != null && parsed.isFinite && parsed > 0) {
                Navigator.pop(context, parsed);
              }
            },
            child: const Text('Devam'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null) return;
    if (!mounted) return;
    if (value < detail.metrics.actualDeliveredM3) {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Hedef aşılacak'),
          content: const Text(
            'Dökülen hacim hedefi aşacak. Mikser hacimleri değiştirilmeyecek.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Hedefi güncelle'),
            ),
          ],
        ),
      );
      if (accepted != true) return;
    }
    final pour = detail.pour;
    await _run(
      () => widget.concrete.updatePour(
        UpdateConcretePourCommand(
          id: pour.id,
          eventId: RecordId.randomUuid(),
          expectedRevision: pour.revision,
          elementLocation: pour.elementLocation,
          plannedAt: pour.plannedAt,
          concreteClass: pour.concreteClass,
          plannedVolumeM3: value,
          blockName: pour.blockName,
          floorName: pour.floorName,
          axisName: pour.axisName,
          targetSlump: pour.targetSlump,
          orderedVolumeM3: pour.orderedVolumeM3,
          plantName: pour.plantName,
          plantBranch: pour.plantBranch,
          plantContact: pour.plantContact,
          plantAppointmentReference: pour.plantAppointmentReference,
          pumpEquipment: pour.pumpEquipment,
          laboratoryName: pour.laboratoryName,
          laboratoryContact: pour.laboratoryContact,
          laboratoryAppointment: pour.laboratoryAppointment,
          inspectionNotifiedAt: pour.inspectionNotifiedAt,
          inspectionNotifiedPerson: pour.inspectionNotifiedPerson,
          generalNote: pour.generalNote,
          sampleExceptionReason: pour.sampleExceptionReason,
          varianceNote: pour.varianceNote,
        ),
      ),
    );
  }

  Future<void> _bulkComplete() async {
    final detail = _detail!;
    final manualChecks = detail.checks.where(
      (item) =>
          item.status == ConcreteCheckStatus.pending &&
          item.itemKey != 'inspection_notified' &&
          item.itemKey != 'laboratory_appointment',
    );
    final manualFollowUps = detail.followUps.where(
      (item) =>
          item.status == ConcreteFollowUpStatus.pending &&
          item.itemKey != 'inspection_notification_task' &&
          item.itemKey != 'laboratory_appointment_task',
    );
    final count = manualChecks.length + manualFollowUps.length;
    if (count == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Toplu tamamlanacak manuel madde yok.')),
      );
      return;
    }
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tümünü tamamla'),
        content: Text(
          '$count manuel checklist/takip maddesi tek işlemde tamamlanacak. '
          'Laboratuvar ve yapı denetim alan görevleri etkilenmeyecek.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            key: const Key('confirm-bulk-complete'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Tümünü tamamla'),
          ),
        ],
      ),
    );
    if (accepted != true) return;
    await _run(
      () => widget.concrete.bulkComplete(
        BulkCompleteConcreteCommand(
          pourId: detail.pour.id,
          eventId: RecordId.randomUuid(),
          expectedPourRevision: detail.pour.revision,
        ),
      ),
    );
  }

  Future<void> _export({required bool share}) async {
    final detail = _detail!;
    final result = await widget.concrete.exportPackage(
      ExportConcretePackageCommand(
        pourId: detail.pour.id,
        eventId: RecordId.randomUuid(),
        expectedRevision: detail.pour.revision,
      ),
      share: share,
      save: !share,
    );
    if (!mounted) return;
    final message = result.outcome == ConcreteExportOutcome.cancelled
        ? 'Kaydetme iptal edildi; export event’i oluşturulmadı.'
        : share
        ? 'PDF paylaşım akışına gönderildi.'
        : 'PDF seçilen konuma kaydedildi.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
                key: const Key('concrete-live-volume'),
                title: const Text('Canlı metraj'),
                subtitle: Text(
                  'Hedef: ${_formatM3(pour.plannedVolumeM3)} m³\n'
                  'Dökülen: ${_formatM3(detail.metrics.actualDeliveredM3)} m³\n'
                  '${detail.metrics.isTargetExceeded ? 'Aşılan' : 'Kalan'}: '
                  '${_formatM3(detail.metrics.isTargetExceeded ? detail.metrics.excessM3 : detail.metrics.remainingM3)} m³',
                ),
                isThreeLine: true,
                trailing: IconButton(
                  key: const Key('edit-target-volume'),
                  tooltip: 'Hedef hacmi değiştir',
                  onPressed: _mutating ? null : _editTargetVolume,
                  icon: const Icon(Icons.edit_outlined),
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _transitionButtons(pour.status),
              ),
              OutlinedButton.icon(
                key: const Key('edit-concrete-field-notifications'),
                onPressed: _mutating ? null : _editFieldNotifications,
                icon: const Icon(Icons.notifications_active_outlined),
                label: const Text(
                  'Laboratuvar / yapı denetim durumunu güncelle',
                ),
              ),
            ]),
            _section(
              'Döküm öncesi checklist • ${detail.metrics.pendingCheckCount} açık',
              [
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.tonalIcon(
                    key: const Key('bulk-complete-concrete'),
                    onPressed: _mutating ? null : _bulkComplete,
                    icon: const Icon(Icons.done_all),
                    label: const Text('Tümünü tamamla'),
                  ),
                ),
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
                  onPressed: _mutating ? null : () => _editTruck(),
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
                        onTap: _mutating ? null : () => _editTruck(item),
                        title: Text(
                          '#${item.sequenceNo} ${item.vehiclePlate} • ${item.volumeM3.toStringAsFixed(2)} m³',
                        ),
                        subtitle: Text(
                          'İrsaliye ${item.deliveryNoteNumber ?? '—'} • ${item.result.label}\n'
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
                                  ConcreteEvidenceType.deliveryNoteScan,
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
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => ConcreteAttachmentViewerPage(
                        concrete: widget.concrete,
                        attachment: item,
                      ),
                    ),
                  ),
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
                for (
                  var index = 0;
                  index < detail.sampleSets.length;
                  index += 1
                )
                  ListTile(
                    title: Text(
                      'Numune seti ${index + 1} • '
                      '${detail.sampleSets[index].sampleCount} adet',
                    ),
                    subtitle: Text(
                      '${detail.sampleSets[index].status.label}\nSonuç: '
                      '${detail.sampleSets[index].expectedResultDates.map(CseTimeCodec.formatIstanbul).join(', ')}',
                    ),
                    trailing: IconButton(
                      onPressed: () =>
                          _attach(sample: detail.sampleSets[index]),
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
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    key: const Key('share-concrete-pdf'),
                    onPressed: _mutating
                        ? null
                        : () => _run(() => _export(share: true)),
                    icon: const Icon(Icons.ios_share_outlined),
                    label: const Text('PDF paylaş'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('save-concrete-pdf'),
                    onPressed: _mutating
                        ? null
                        : () => _run(() => _export(share: false)),
                    icon: const Icon(Icons.save_alt_outlined),
                    label: const Text('Telefona kaydet'),
                  ),
                ),
              ],
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

String _formatM3(double value) => value.toStringAsFixed(2).replaceAll('.', ',');

class _TruckDraft {
  const _TruckDraft({
    required this.plate,
    required this.deliveryNote,
    required this.volume,
    required this.result,
    required this.arrivedAt,
    required this.unloadingStartedAt,
    required this.unloadingEndedAt,
    required this.note,
    required this.reason,
  });

  final String plate;
  final String deliveryNote;
  final double volume;
  final ConcreteTruckResult result;
  final String? arrivedAt;
  final String? unloadingStartedAt;
  final String? unloadingEndedAt;
  final String note;
  final String reason;
}

class _TruckTimeTile extends StatelessWidget {
  const _TruckTimeTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final ValueChanged<String?> onChanged;

  Future<void> _pick(BuildContext context) async {
    final local = value == null
        ? CseTimeCodec.toIstanbul(
            CseTimeCodec.encodeUtc(DateTime.now().toUtc()),
          )
        : CseTimeCodec.toIstanbul(value!);
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(local.year, local.month, local.day),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: local.hour, minute: local.minute),
    );
    if (time == null) return;
    onChanged(
      CseTimeCodec.canonicalFromIstanbulComponents(
        year: date.year,
        month: date.month,
        day: date.day,
        hour: time.hour,
        minute: time.minute,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(
        value == null ? 'Belirtilmedi' : CseTimeCodec.formatIstanbul(value!),
      ),
      onTap: () => _pick(context),
      trailing: value == null
          ? const Icon(Icons.schedule_outlined)
          : IconButton(
              tooltip: 'Zamanı temizle',
              onPressed: () => onChanged(null),
              icon: const Icon(Icons.clear),
            ),
    );
  }
}
