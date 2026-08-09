import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/application/concrete_application.dart';
import 'package:chief_site_engineer/core/record_id.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/concrete_models.dart';
import 'package:chief_site_engineer/domain/project_location_models.dart';
import 'package:chief_site_engineer/features/agenda/log_detail_page.dart';
import 'package:chief_site_engineer/features/concrete/concrete_attachment_viewer_page.dart';
import 'package:chief_site_engineer/features/owned_text_input_dialog.dart';
import 'package:chief_site_engineer/features/reminders/reminder_detail_page.dart';
import 'package:chief_site_engineer/platform/attachment_gateway.dart';
import 'package:flutter/material.dart';

class ConcretePourDetailPage extends StatefulWidget {
  const ConcretePourDetailPage({
    required this.concrete,
    required this.agenda,
    required this.attachments,
    required this.pourId,
    this.projectLocations,
    super.key,
  });

  final ConcreteApplication concrete;
  final AgendaApplication agenda;
  final SafeAttachmentPicker attachments;
  final String pourId;
  final ProjectLocationApplication? projectLocations;

  @override
  State<ConcretePourDetailPage> createState() => _ConcretePourDetailPageState();
}

class _ConcretePourDetailPageState extends State<ConcretePourDetailPage> {
  ConcretePourDetail? _detail;
  bool _loading = true;
  bool _mutating = false;
  String? _error;
  _TruckRetry? _retryTruck;

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

  Future<bool> _run(Future<Object?> Function() mutation) async {
    if (_mutating) return false;
    setState(() {
      _mutating = true;
      _error = null;
    });
    try {
      await mutation();
      await _reload();
      return true;
    } on Object catch (error) {
      if (mounted) {
        setState(() => _error = _message(error, 'İşlem tamamlanamadı.'));
      }
      return false;
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  Future<void> _editFieldNotifications() async {
    final pour = _detail!.pour;
    final draft = await showDialog<_FieldNotificationDraft>(
      context: context,
      builder: (context) => _FieldNotificationsDialog(
        laboratoryComplete: pour.laboratoryAppointment != null,
        inspectionComplete:
            pour.inspectionNotifiedAt != null ||
            (pour.inspectionNotifiedPerson?.trim().isNotEmpty ?? false),
        inspectionPerson: pour.inspectionNotifiedPerson,
      ),
    );
    if (draft == null) return;
    final now = CseTimeCodec.encodeUtc(DateTime.now().toUtc());
    await _run(
      () => widget.concrete.updatePour(
        UpdateConcretePourCommand(
          id: pour.id,
          eventId: RecordId.randomUuid(),
          expectedRevision: pour.revision,
          elementLocation: pour.elementLocation,
          locationId: pour.locationId,
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
          laboratoryAppointment: draft.laboratoryComplete
              ? pour.laboratoryAppointment ?? now
              : null,
          inspectionNotifiedAt: draft.inspectionComplete
              ? pour.inspectionNotifiedAt ?? now
              : null,
          inspectionNotifiedPerson: draft.inspectionComplete
              ? draft.inspectionPerson
              : null,
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

  Future<void> _repairAgenda() async {
    final detail = _detail!;
    await _run(
      () => widget.concrete.repairManagedAgenda(
        RepairConcreteAgendaCommand(
          pourId: detail.pour.id,
          eventId: RecordId.randomUuid(),
          expectedRevision: detail.pour.revision,
        ),
      ),
    );
  }

  Future<void> _openAgenda(String agendaLogId) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => LogDetailPage(
          agenda: widget.agenda,
          concrete: widget.concrete,
          concreteAttachments: widget.attachments,
          attachments: widget.attachments,
          logId: agendaLogId,
        ),
      ),
    );
    if (mounted) await _reload();
  }

  Future<void> _editTruck([ConcreteTruck? current, _TruckRetry? retry]) async {
    final result = await showDialog<_TruckDraft>(
      context: context,
      builder: (context) =>
          _TruckDialog(current: current, initialDraft: retry?.draft),
    );
    if (result == null) return;
    final detail = _detail!;
    final truckId = retry?.truckId ?? current?.id ?? RecordId.randomUuid();
    final eventId = retry?.eventId ?? RecordId.randomUuid();
    final saved = await _run(
      () => widget.concrete.saveTruck(
        SaveConcreteTruckCommand(
          id: truckId,
          pourId: detail.pour.id,
          eventId: eventId,
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
    if (!mounted) return;
    if (saved) {
      setState(() => _retryTruck = null);
      return;
    }
    final failureMessage = _error;
    await _reload();
    if (!mounted) return;
    setState(() {
      _retryTruck = _TruckRetry(
        draft: result,
        currentTruckId: current?.id,
        truckId: truckId,
        eventId: eventId,
      );
      _error = failureMessage;
    });
  }

  Future<void> _reopenTruckDraft() async {
    final retry = _retryTruck;
    if (retry == null) return;
    ConcreteTruck? current;
    if (retry.currentTruckId != null) {
      for (final item in _detail!.trucks) {
        if (item.id == retry.currentTruckId) {
          current = item;
          break;
        }
      }
      if (current == null) {
        setState(() {
          _retryTruck = null;
          _error = 'Düzenlenecek mikser artık bulunamadı.';
        });
        return;
      }
    }
    await _editTruck(current, retry);
  }

  Future<void> _addSample() async {
    final detail = _detail!;
    final countText = await showDialog<String>(
      context: context,
      builder: (context) => OwnedTextInputDialog(
        title: 'Numune seti ekle',
        label: 'Adet',
        confirmLabel: 'Ekle',
        initialValue: '6',
        keyboardType: TextInputType.number,
        validator: (value) {
          final parsed = int.tryParse(value);
          return parsed != null && parsed > 0
              ? null
              : 'Pozitif bir adet yazın.';
        },
      ),
    );
    if (countText == null) return;
    final result = int.parse(countText);
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
    return showDialog<String>(
      context: context,
      builder: (context) => OwnedTextInputDialog(
        title: title,
        label: hint,
        confirmLabel: 'Kaydet',
        maxLines: 3,
        trimResult: true,
        validator: (value) =>
            value.trim().isEmpty ? 'Gerekçe boş bırakılamaz.' : null,
      ),
    );
  }

  Future<void> _editLocation() async {
    final pour = _detail!.pour;
    List<MobileProjectLocation> locations = const [];
    if (widget.projectLocations != null) {
      try {
        locations = await widget.projectLocations!.listProjectLocations(
          ProjectLocationQuery(projectId: pour.projectId),
        );
      } on Object {
        locations = const [];
      }
    }
    if (!mounted) return;
    final draft = await showDialog<_LocationEditDraft>(
      context: context,
      builder: (context) => _LocationEditDialog(
        locations: locations,
        initialLocationId: pour.locationId,
        initialElementLocation: pour.elementLocation,
        archivedLocationName: pour.stableLocationName,
      ),
    );
    if (draft != null) {
      await _run(
        () => widget.concrete.updatePour(
          UpdateConcretePourCommand(
            id: pour.id,
            eventId: RecordId.randomUuid(),
            expectedRevision: pour.revision,
            elementLocation: draft.elementLocation,
            locationId: draft.locationId,
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
  }

  Future<void> _editTargetVolume() async {
    final detail = _detail!;
    final valueText = await showDialog<String>(
      context: context,
      builder: (context) => OwnedTextInputDialog(
        title: 'Hedef toplam m³',
        label:
            'Hedef toplam m³ • Dökülen ${_formatM3(detail.metrics.actualDeliveredM3)} m³',
        confirmLabel: 'Devam',
        inputKey: const Key('target-volume-input'),
        initialValue: detail.pour.plannedVolumeM3.toStringAsFixed(2),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: (value) {
          final parsed = double.tryParse(value.replaceAll(',', '.'));
          return parsed != null && parsed.isFinite && parsed > 0
              ? null
              : 'Pozitif bir hacim yazın.';
        },
      ),
    );
    if (valueText == null) return;
    final value = double.parse(valueText.replaceAll(',', '.'));
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
          locationId: pour.locationId,
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
    final manualChecks = pendingManualConcreteChecks(detail.checks);
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
    var closingDialog = false;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manuel maddeleri tamamla'),
        content: Text(
          '$count manuel checklist/takip maddesi tek işlemde tamamlanacak. '
          'Laboratuvar randevusu ve yapı denetim bildirimi ayrıca ilgili '
          'Beton alanlarından tamamlanmalıdır; bu işlem onları tamamlamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (closingDialog) return;
              closingDialog = true;
              Navigator.pop(context, false);
            },
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            key: const Key('confirm-bulk-complete'),
            onPressed: () {
              if (closingDialog) return;
              closingDialog = true;
              Navigator.pop(context, true);
            },
            child: const Text('Manuel maddeleri tamamla'),
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
            _section('Döküm ilerlemesi', [
              _ConcreteStageTimeline(
                current: pour.stage,
                cancelled: pour.status == ConcretePourStatus.cancelled,
              ),
              if (pour.actualStartedAt case final startedAt?)
                ListTile(
                  key: const Key('concrete-actual-start'),
                  leading: const Icon(Icons.play_circle_outline),
                  title: const Text('Gerçek başlangıç'),
                  subtitle: Text(CseTimeCodec.formatIstanbul(startedAt)),
                ),
              if (pour.actualEndedAt case final endedAt?)
                ListTile(
                  key: const Key('concrete-actual-end'),
                  leading: const Icon(Icons.stop_circle_outlined),
                  title: const Text('Gerçek bitiş'),
                  subtitle: Text(
                    '${CseTimeCodec.formatIstanbul(endedAt)}'
                    '${detail.metrics.pourDurationMinutes == null ? '' : ' • ${detail.metrics.pourDurationMinutes} dk'}',
                  ),
                ),
              if (pour.actualStartedAt == null &&
                  pour.status != ConcretePourStatus.closed &&
                  pour.status != ConcretePourStatus.cancelled)
                FilledButton.icon(
                  key: const Key('start-concrete-pour'),
                  onPressed: _mutating
                      ? null
                      : () => _transition(ConcretePourStatus.pouring),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Dökümü başlat'),
                ),
              if (pour.actualStartedAt != null &&
                  pour.actualEndedAt == null &&
                  (pour.status == ConcretePourStatus.draft ||
                      pour.status == ConcretePourStatus.prepared))
                FilledButton.icon(
                  key: const Key('resume-concrete-pour'),
                  onPressed: _mutating
                      ? null
                      : () => _transition(ConcretePourStatus.pouring),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Döküme devam et'),
                ),
              if (pour.actualStartedAt != null &&
                  pour.actualEndedAt == null &&
                  pour.status == ConcretePourStatus.pouring)
                FilledButton.icon(
                  key: const Key('finish-concrete-pour'),
                  onPressed: _mutating
                      ? null
                      : () => _transition(ConcretePourStatus.poured),
                  icon: const Icon(Icons.stop),
                  label: const Text('Dökümü bitir'),
                ),
              if (detail.agendaLogId case final agendaLogId?)
                OutlinedButton.icon(
                  key: const Key('open-managed-agenda'),
                  onPressed: _mutating ? null : () => _openAgenda(agendaLogId),
                  icon: const Icon(Icons.event_note_outlined),
                  label: const Text('Bağlı Ajanda kaydını aç'),
                )
              else if (pour.actualStartedAt != null)
                OutlinedButton.icon(
                  key: const Key('repair-managed-agenda'),
                  onPressed: _mutating ? null : _repairAgenda,
                  icon: const Icon(Icons.build_circle_outlined),
                  label: const Text('Ajanda kaydını oluştur'),
                ),
            ]),
            _section('Özet', [
              ListTile(
                title: Text(pour.elementLocation),
                subtitle: Text(
                  '${pour.projectName}'
                  '${pour.stableLocationName == null ? '' : '\nKatalog Mahali: ${pour.stableLocationName}${pour.stableLocationArchivedAt == null ? '' : ' (Arşivli)'}'}'
                  '\n${CseTimeCodec.formatIstanbul(pour.plannedAt)} • ${pour.concreteClass} • ${pour.status.label}',
                ),
                isThreeLine: true,
                trailing: IconButton(
                  key: const Key('edit-concrete-location'),
                  tooltip: 'Mahal ve yer tarifini değiştir',
                  onPressed: _mutating ? null : _editLocation,
                  icon: const Icon(Icons.edit_location_alt_outlined),
                ),
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
              'Döküm öncesi checklist • '
              '${detail.pendingRequiredCheckCount} açık',
              [
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.tonalIcon(
                    key: const Key('bulk-complete-concrete'),
                    onPressed: _mutating ? null : _bulkComplete,
                    icon: const Icon(Icons.done_all),
                    label: const Text('Manuel maddeleri tamamla'),
                  ),
                ),
                for (final item in detail.checks) ...[
                  ListTile(
                    title: Text('${item.sortOrder}. ${item.label}'),
                    subtitle: Text(item.reason ?? item.status.label),
                    trailing: item.isSystemOwned
                        ? Icon(
                            item.status == ConcreteCheckStatus.pending
                                ? Icons.lock_outline
                                : Icons.check_circle_outline,
                          )
                        : PopupMenuButton<ConcreteCheckStatus>(
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
                  if (item.isSystemOwned && item.isPendingRequired)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          bottom: 8,
                        ),
                        child: OutlinedButton(
                          key: Key('update-${item.itemKey}'),
                          onPressed: _mutating ? null : _editFieldNotifications,
                          child: Text(
                            item.itemKey ==
                                    concreteLaboratoryAppointmentCheckKey
                                ? 'Laboratuvar randevusunu güncelle'
                                : 'Yapı denetime bildirimi güncelle',
                          ),
                        ),
                      ),
                    ),
                ],
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
              if (_retryTruck != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    key: const Key('reopen-concrete-truck-draft'),
                    onPressed: _mutating ? null : _reopenTruckDraft,
                    icon: const Icon(Icons.edit_note_outlined),
                    label: const Text('Son mikser girdisini yeniden aç'),
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
                          'İrsaliye ${item.deliveryNoteNumber ?? '—'} • ${item.result.label} • Revizyon ${item.revision}\n'
                          '${item.note?.trim().isNotEmpty == true ? item.note!.trim() : 'Not yok'}\n'
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
                  title: Text(
                    '${event.sequence}. ${_eventLabel(event.eventType)}',
                  ),
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
        ConcretePourStatus.draft,
        ConcretePourStatus.cancelled,
      ],
      ConcretePourStatus.pouring => [ConcretePourStatus.cancelled],
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

String _eventLabel(String value) => switch (value) {
  'pour.created' => 'Paket oluşturuldu',
  'pour.prepared' => 'Döküm hazırlığı tamamlandı',
  'pour.started' => 'Döküm başladı',
  'pour.finished' => 'Döküm bitti',
  'pour.cancelled' => 'Paket iptal edildi',
  'pour.reopened' => 'Paket yeniden açıldı',
  'agenda.linked' => 'Yönetilen Ajanda kaydı bağlandı',
  'pour.closed' => 'Paket kapatıldı',
  'pour.follow_up_started' => 'Takip süreci başladı',
  'pour.details_updated' => 'Paket bilgileri güncellendi',
  'check.updated' => 'Checklist güncellendi',
  'truck.added' => 'Mikser eklendi',
  'truck.updated' => 'Mikser güncellendi',
  'evidence.attached' => 'Kanıt eklendi',
  'sample_set.added' => 'Numune seti eklendi',
  'sample_set.updated' => 'Numune seti güncellendi',
  'follow_up.linked' => 'Takip kaydı güncellendi',
  'report.exported' => 'Rapor dışa aktarıldı',
  _ => value,
};

class _ConcreteStageTimeline extends StatelessWidget {
  const _ConcreteStageTimeline({
    required this.current,
    required this.cancelled,
  });

  final ConcretePourStage current;
  final bool cancelled;

  @override
  Widget build(BuildContext context) {
    final currentIndex = ConcretePourStage.values.indexOf(current);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          key: const Key('concrete-stage-timeline'),
          children: [
            for (
              var index = 0;
              index < ConcretePourStage.values.length;
              index += 1
            )
              Expanded(
                child: Semantics(
                  selected: index == currentIndex,
                  label: ConcretePourStage.values[index].label,
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 44),
                    margin: EdgeInsets.only(
                      right: index == ConcretePourStage.values.length - 1
                          ? 0
                          : 6,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: index <= currentIndex
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      ConcretePourStage.values[index].label,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (cancelled)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('İptal edildi • gerçek zaman geçmişi korunuyor.'),
          ),
      ],
    );
  }
}

class _LocationEditDraft {
  const _LocationEditDraft({
    required this.locationId,
    required this.elementLocation,
  });

  final String? locationId;
  final String elementLocation;
}

class _LocationEditDialog extends StatefulWidget {
  const _LocationEditDialog({
    required this.locations,
    required this.initialLocationId,
    required this.initialElementLocation,
    required this.archivedLocationName,
  });

  final List<MobileProjectLocation> locations;
  final String? initialLocationId;
  final String initialElementLocation;
  final String? archivedLocationName;

  @override
  State<_LocationEditDialog> createState() => _LocationEditDialogState();
}

class _LocationEditDialogState extends State<_LocationEditDialog> {
  late final TextEditingController _elementLocation;
  late String? _locationId;

  @override
  void initState() {
    super.initState();
    _elementLocation = TextEditingController(
      text: widget.initialElementLocation,
    );
    _locationId = widget.initialLocationId;
  }

  @override
  void dispose() {
    _elementLocation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Mahal ve yer tarifi'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            key: const Key('edit-concrete-location-selector'),
            initialValue: _locationId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Katalog Mahali (opsiyonel)',
            ),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Mahal seçilmedi'),
              ),
              ...widget.locations.map(
                (item) => DropdownMenuItem<String>(
                  value: item.id,
                  child: Text(item.displayName),
                ),
              ),
              if (_locationId != null &&
                  !widget.locations.any((item) => item.id == _locationId))
                DropdownMenuItem<String>(
                  value: _locationId,
                  child: Text(
                    '${widget.archivedLocationName ?? 'Arşivli mahal'} (Arşivli)',
                  ),
                ),
            ],
            onChanged: (value) => setState(() => _locationId = value),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('edit-concrete-element-location'),
            controller: _elementLocation,
            decoration: const InputDecoration(labelText: 'Eleman / yer tarifi'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            _LocationEditDraft(
              locationId: _locationId,
              elementLocation: _elementLocation.text,
            ),
          ),
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}

class _FieldNotificationDraft {
  const _FieldNotificationDraft({
    required this.laboratoryComplete,
    required this.inspectionComplete,
    required this.inspectionPerson,
  });

  final bool laboratoryComplete;
  final bool inspectionComplete;
  final String inspectionPerson;
}

class _FieldNotificationsDialog extends StatefulWidget {
  const _FieldNotificationsDialog({
    required this.laboratoryComplete,
    required this.inspectionComplete,
    required this.inspectionPerson,
  });

  final bool laboratoryComplete;
  final bool inspectionComplete;
  final String? inspectionPerson;

  @override
  State<_FieldNotificationsDialog> createState() =>
      _FieldNotificationsDialogState();
}

class _FieldNotificationsDialogState extends State<_FieldNotificationsDialog> {
  late final TextEditingController _inspectionPerson;
  late bool _laboratoryComplete;
  late bool _inspectionComplete;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _inspectionPerson = TextEditingController(text: widget.inspectionPerson);
    _laboratoryComplete = widget.laboratoryComplete;
    _inspectionComplete = widget.inspectionComplete;
  }

  @override
  void dispose() {
    _inspectionPerson.dispose();
    super.dispose();
  }

  void _submit() {
    if (_closing) return;
    _closing = true;
    Navigator.pop(
      context,
      _FieldNotificationDraft(
        laboratoryComplete: _laboratoryComplete,
        inspectionComplete: _inspectionComplete,
        inspectionPerson: _inspectionPerson.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Laboratuvar ve yapı denetim'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              key: const Key('laboratory-appointment-complete'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Laboratuvar randevusu alındı/doğrulandı'),
              value: _laboratoryComplete,
              onChanged: _closing
                  ? null
                  : (value) => setState(() => _laboratoryComplete = value),
            ),
            SwitchListTile(
              key: const Key('inspection-notification-complete'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Yapı denetime haber verildi'),
              value: _inspectionComplete,
              onChanged: _closing
                  ? null
                  : (value) => setState(() => _inspectionComplete = value),
            ),
            TextField(
              controller: _inspectionPerson,
              decoration: const InputDecoration(
                labelText: 'Yapı denetim kişisi (opsiyonel)',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _closing ? null : () => Navigator.pop(context),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: _closing ? null : _submit,
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}

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

class _TruckRetry {
  const _TruckRetry({
    required this.draft,
    required this.currentTruckId,
    required this.truckId,
    required this.eventId,
  });

  final _TruckDraft draft;
  final String? currentTruckId;
  final String truckId;
  final String eventId;
}

class _TruckDialog extends StatefulWidget {
  const _TruckDialog({required this.current, required this.initialDraft});

  final ConcreteTruck? current;
  final _TruckDraft? initialDraft;

  @override
  State<_TruckDialog> createState() => _TruckDialogState();
}

class _TruckDialogState extends State<_TruckDialog> {
  late final TextEditingController _plate;
  late final TextEditingController _deliveryNote;
  late final TextEditingController _volume;
  late final TextEditingController _note;
  late final TextEditingController _reason;
  late ConcreteTruckResult _result;
  String? _arrivedAt;
  String? _unloadingStartedAt;
  String? _unloadingEndedAt;
  String? _validationMessage;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    final current = widget.current;
    final draft = widget.initialDraft;
    _plate = TextEditingController(text: draft?.plate ?? current?.vehiclePlate);
    _deliveryNote = TextEditingController(
      text: draft?.deliveryNote ?? current?.deliveryNoteNumber,
    );
    _volume = TextEditingController(
      text:
          draft?.volume.toStringAsFixed(2) ??
          current?.volumeM3.toStringAsFixed(2),
    );
    _note = TextEditingController(text: draft?.note ?? current?.note);
    _reason = TextEditingController(text: draft?.reason ?? current?.reason);
    _result = draft?.result ?? current?.result ?? ConcreteTruckResult.received;
    _arrivedAt = draft?.arrivedAt ?? current?.arrivedAt;
    _unloadingStartedAt =
        draft?.unloadingStartedAt ?? current?.unloadingStartedAt;
    _unloadingEndedAt = draft?.unloadingEndedAt ?? current?.unloadingEndedAt;
  }

  @override
  void dispose() {
    _plate.dispose();
    _deliveryNote.dispose();
    _volume.dispose();
    _note.dispose();
    _reason.dispose();
    super.dispose();
  }

  void _clearValidation() {
    if (_validationMessage != null) {
      setState(() => _validationMessage = null);
    }
  }

  void _submit() {
    if (_closing) return;
    final parsed = double.tryParse(_volume.text.replaceAll(',', '.'));
    String? validationMessage;
    if (_plate.text.trim().isEmpty) {
      validationMessage = 'Plaka boş bırakılamaz.';
    } else if (parsed == null || !parsed.isFinite || parsed <= 0) {
      validationMessage = 'Pozitif bir dökülen hacim yazın.';
    } else if (_result != ConcreteTruckResult.received &&
        _reason.text.trim().isEmpty) {
      validationMessage =
          'Teslim alındı dışındaki sonuçlarda neden zorunludur.';
    }
    if (validationMessage != null) {
      setState(() => _validationMessage = validationMessage);
      return;
    }
    _closing = true;
    Navigator.pop(
      context,
      _TruckDraft(
        plate: _plate.text,
        deliveryNote: _deliveryNote.text,
        volume: parsed!,
        result: _result,
        arrivedAt: _arrivedAt,
        unloadingStartedAt: _unloadingStartedAt,
        unloadingEndedAt: _unloadingEndedAt,
        note: _note.text,
        reason: _reason.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.current == null ? 'Mikser / irsaliye ekle' : 'Mikseri düzenle',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('concrete-truck-plate'),
              controller: _plate,
              onChanged: (_) => _clearValidation(),
              decoration: const InputDecoration(labelText: 'Plaka'),
            ),
            TextField(
              key: const Key('concrete-truck-delivery-note'),
              controller: _deliveryNote,
              decoration: const InputDecoration(
                labelText: 'İrsaliye numarası (opsiyonel)',
              ),
            ),
            TextField(
              key: const Key('concrete-truck-volume'),
              controller: _volume,
              onChanged: (_) => _clearValidation(),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Dökülen (m³)'),
            ),
            DropdownButtonFormField<ConcreteTruckResult>(
              key: const Key('concrete-truck-result'),
              initialValue: _result,
              decoration: const InputDecoration(labelText: 'Sonuç'),
              items: ConcreteTruckResult.values
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(value.label),
                    ),
                  )
                  .toList(growable: false),
              onChanged: _closing
                  ? null
                  : (value) => setState(() {
                      _result = value!;
                      _validationMessage = null;
                    }),
            ),
            _TruckTimeTile(
              key: const Key('concrete-truck-arrived-at'),
              label: 'Geliş zamanı',
              value: _arrivedAt,
              onChanged: (value) => setState(() => _arrivedAt = value),
            ),
            _TruckTimeTile(
              key: const Key('concrete-truck-unloading-started-at'),
              label: 'Boşaltma başlangıcı',
              value: _unloadingStartedAt,
              onChanged: (value) => setState(() => _unloadingStartedAt = value),
            ),
            _TruckTimeTile(
              key: const Key('concrete-truck-unloading-ended-at'),
              label: 'Boşaltma bitişi',
              value: _unloadingEndedAt,
              onChanged: (value) => setState(() => _unloadingEndedAt = value),
            ),
            TextField(
              key: const Key('concrete-truck-note'),
              controller: _note,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Mikser notu (opsiyonel)',
              ),
            ),
            if (_result != ConcreteTruckResult.received)
              TextField(
                key: const Key('concrete-truck-reason'),
                controller: _reason,
                onChanged: (_) => _clearValidation(),
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Sonuç nedeni'),
              ),
            if (_validationMessage case final message?)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  message,
                  key: const Key('concrete-truck-validation'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _closing ? null : () => Navigator.pop(context),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          key: const Key('save-concrete-truck'),
          onPressed: _closing ? null : _submit,
          child: Text(widget.current == null ? 'Ekle' : 'Kaydet'),
        ),
      ],
    );
  }
}

class _TruckTimeTile extends StatelessWidget {
  const _TruckTimeTile({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
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
