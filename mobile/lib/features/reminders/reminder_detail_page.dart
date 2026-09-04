import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/application/attendance_application.dart';
import 'package:chief_site_engineer/application/concrete_application.dart';
import 'package:chief_site_engineer/core/record_id.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/project_location_models.dart';
import 'package:chief_site_engineer/features/agenda/agenda_photo_viewer_page.dart';
import 'package:chief_site_engineer/features/agenda/log_detail_page.dart';
import 'package:chief_site_engineer/features/attendance/attendance_day_page.dart';
import 'package:chief_site_engineer/features/concrete/concrete_pour_detail_page.dart';
import 'package:chief_site_engineer/platform/attachment_gateway.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';

class ReminderDetailPage extends StatefulWidget {
  const ReminderDetailPage({
    required this.agenda,
    required this.reminderId,
    this.attendance,
    this.concrete,
    this.concreteAttachments,
    this.projectLocations,
    this.istanbulToday,
    super.key,
  });

  final AgendaApplication agenda;
  final String reminderId;
  final AttendanceApplication? attendance;
  final ConcreteApplication? concrete;
  final SafeAttachmentPicker? concreteAttachments;
  final ProjectLocationApplication? projectLocations;
  final String? istanbulToday;

  @override
  State<ReminderDetailPage> createState() => _ReminderDetailPageState();
}

class _ReminderDetailPageState extends State<ReminderDetailPage> {
  ReminderDetail? _detail;
  AgendaLogDetail? _sourceAgendaDetail;
  ReminderDeliveryDiagnostic? _deliveryDiagnostic;
  Future<ReminderSourceAgendaMedia>? _sourceAgendaMedia;
  bool _loading = true;
  bool _readInFlight = false;
  bool _mutating = false;
  bool _syncDialogOpen = false;
  bool _scheduleFlowOpen = false;
  String? _error;
  String? _readError;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload({String? errorAfterReload}) async {
    if (_readInFlight) return;
    _readInFlight = true;
    setState(() {
      _loading = true;
      _error = null;
      _readError = null;
      _sourceAgendaDetail = null;
      _sourceAgendaMedia = null;
    });
    try {
      final detail = await widget.agenda.getReminderLifecycleDetail(
        widget.reminderId,
      );
      AgendaLogDetail? sourceAgendaDetail;
      final sourceLogId = detail.reminder.sourceLogId;
      if (sourceLogId != null) {
        try {
          sourceAgendaDetail = await widget.agenda.getAgendaLogDetail(
            sourceLogId,
          );
        } on Object {
          sourceAgendaDetail = null;
        }
      }
      ReminderDeliveryDiagnostic? diagnostic;
      final application = widget.agenda;
      if (detail.reminder.nextAttentionAt != null &&
          application is ReminderDeliveryApplication) {
        try {
          diagnostic = await (application as ReminderDeliveryApplication)
              .getReminderDeliveryDiagnostic(widget.reminderId);
        } on Object {
          diagnostic = null;
        }
      }
      if (mounted) {
        setState(() {
          _detail = detail;
          _sourceAgendaDetail = sourceAgendaDetail;
          _deliveryDiagnostic = diagnostic;
          _sourceAgendaMedia = sourceLogId == null
              ? null
              : _loadSourceAgendaMedia(sourceLogId);
          _loading = false;
          _error = errorAfterReload;
          _readError = null;
        });
      }
    } on Object {
      if (mounted) {
        setState(() {
          _detail = null;
          _loading = false;
          _error = null;
          _readError = 'Hatırlatıcı güvenli biçimde okunamadı.';
        });
      }
    } finally {
      _readInFlight = false;
    }
  }

  List<_AgendaReminderSyncDiff> _agendaReminderSyncDiffs(
    ReminderDetail detail,
  ) {
    final sourceDetail = _sourceAgendaDetail;
    if (sourceDetail == null) return const [];
    final reminder = detail.reminder;
    final source = sourceDetail.log;
    if (reminder.sourceLogId != source.id ||
        reminder.projectId != source.projectId ||
        source.archivedAt != null ||
        reminder.trashedAt != null ||
        reminder.status == ReminderStatus.completed ||
        reminder.status == ReminderStatus.cancelled ||
        (source.locationId != null && source.stableLocationName == null)) {
      return const [];
    }
    final result = <_AgendaReminderSyncDiff>[];
    if (reminder.title != source.description) {
      result.add(
        _AgendaReminderSyncDiff(
          field: AgendaReminderSyncField.title,
          label: 'Başlık',
          before: reminder.title,
          after: source.description,
        ),
      );
    }
    if (reminder.description != source.notes) {
      result.add(
        _AgendaReminderSyncDiff(
          field: AgendaReminderSyncField.description,
          label: 'Açıklama',
          before: reminder.description,
          after: source.notes,
        ),
      );
    }
    final sourceLocation = source.locationId == null
        ? source.location
        : source.stableLocationName;
    if (reminder.locationId != source.locationId ||
        reminder.location != sourceLocation) {
      result.add(
        _AgendaReminderSyncDiff(
          field: AgendaReminderSyncField.location,
          label: 'Mahal',
          before: reminder.displayLocation,
          after: source.displayLocation,
        ),
      );
    }
    return List.unmodifiable(result);
  }

  Future<void> _showAgendaSyncConfirmation() async {
    final detail = _detail;
    if (_mutating || _syncDialogOpen || detail == null) return;
    final sourceDetail = _sourceAgendaDetail;
    final diffs = _agendaReminderSyncDiffs(detail);
    if (sourceDetail == null || diffs.isEmpty) return;
    setState(() => _syncDialogOpen = true);
    try {
      final selected = diffs.map((diff) => diff.field).toSet();
      var confirmationSubmitted = false;
      final confirmedFields = await showDialog<Set<AgendaReminderSyncField>>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            key: const Key('agenda-reminder-sync-dialog'),
            title: const Text('Ajanda’dan güncelle'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final diff in diffs)
                    CheckboxListTile(
                      key: Key('agenda-sync-field-${diff.field.storageValue}'),
                      contentPadding: EdgeInsets.zero,
                      value: selected.contains(diff.field),
                      onChanged: (value) => setDialogState(() {
                        if (value == true) {
                          selected.add(diff.field);
                        } else {
                          selected.remove(diff.field);
                        }
                      }),
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(diff.label),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hatırlatıcı: ${_syncDisplayValue(diff.before)}',
                            key: Key(
                              'agenda-sync-before-${diff.field.storageValue}',
                            ),
                          ),
                          Text(
                            'Ajanda: ${_syncDisplayValue(diff.after)}',
                            key: Key(
                              'agenda-sync-after-${diff.field.storageValue}',
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                key: const Key('cancel-agenda-reminder-sync'),
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Vazgeç'),
              ),
              FilledButton(
                key: const Key('confirm-agenda-reminder-sync'),
                onPressed: selected.isEmpty
                    ? null
                    : () {
                        if (confirmationSubmitted) return;
                        confirmationSubmitted = true;
                        Navigator.of(
                          dialogContext,
                        ).pop(Set.unmodifiable(selected));
                      },
                child: const Text('Seçilenleri güncelle'),
              ),
            ],
          ),
        ),
      );
      if (confirmedFields == null || confirmedFields.isEmpty || !mounted) {
        return;
      }
      await _syncAgendaToReminder(
        detail: detail,
        sourceDetail: sourceDetail,
        selectedFields: confirmedFields,
      );
    } finally {
      if (mounted) setState(() => _syncDialogOpen = false);
    }
  }

  Future<void> _syncAgendaToReminder({
    required ReminderDetail detail,
    required AgendaLogDetail sourceDetail,
    required Set<AgendaReminderSyncField> selectedFields,
  }) async {
    if (_mutating) return;
    setState(() {
      _mutating = true;
      _error = null;
    });
    try {
      final result = await widget.agenda.syncAgendaToReminder(
        SyncAgendaToReminderCommand(
          operationId: RecordId.randomUuid(),
          sourceEventId: RecordId.randomUuid(),
          targetEventId: RecordId.randomUuid(),
          sourceLogId: sourceDetail.log.id,
          reminderId: detail.reminder.id,
          expectedSourceRevision: sourceDetail.log.revision,
          expectedTargetRevision: detail.reminder.revision,
          selectedFields: selectedFields,
        ),
      );
      await _reload();
      if (result.changed && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ajanda’dan güncellendi')));
      }
    } on AgendaValidationFailure catch (error) {
      await _reload(errorAfterReload: error.message);
    } on Object {
      await _reload(
        errorAfterReload:
            'Ajanda’dan güncelleme güvenli biçimde tamamlanamadı.',
      );
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  Future<ReminderSourceAgendaMedia> _loadSourceAgendaMedia(
    String sourceLogId,
  ) async {
    final application = widget.agenda;
    if (application is! ReminderSourceAgendaMediaApplication) {
      return ReminderSourceAgendaMedia.unavailable(sourceLogId: sourceLogId);
    }
    try {
      return await (application as ReminderSourceAgendaMediaApplication)
          .getReminderSourceAgendaMedia(sourceLogId);
    } on Object {
      return ReminderSourceAgendaMedia.unavailable(sourceLogId: sourceLogId);
    }
  }

  Future<void> _retryDelivery() async {
    final application = widget.agenda;
    if (_mutating || application is! ReminderDeliveryApplication) return;
    setState(() {
      _mutating = true;
      _error = null;
    });
    try {
      await (application as ReminderDeliveryApplication).retryReminderDelivery(
        widget.reminderId,
      );
      await _reload();
    } on Object {
      if (mounted) {
        setState(
          () => _error =
              'Bildirim teslimatı doğrulanamadı. Tanı bilgilerini kontrol edin.',
        );
      }
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  Future<void> _openDeliverySettings({required bool battery}) async {
    final application = widget.agenda;
    if (application is! ReminderDeliveryApplication) return;
    try {
      if (battery) {
        await (application as ReminderDeliveryApplication)
            .openReminderBatteryOptimizationSettings();
      } else {
        await (application as ReminderDeliveryApplication)
            .openReminderNotificationSettings();
      }
    } on Object {
      if (mounted) {
        setState(() => _error = 'Sistem ayarları güvenli biçimde açılamadı.');
      }
    }
  }

  Future<void> _mutate(
    ReminderMutationAction action, {
    ReminderScheduleKind? schedule,
    String? customAttentionAt,
    String? allDayLocalDate,
    ReminderOutcomeType? outcomeType,
    String? outcomeNote,
    String? title,
    String? description,
    ReminderKind? kind,
    String? locationId,
    String? location,
    String? relatedPerson,
    bool? isImportant,
    String? deadlineAt,
    String? conditionText,
    String? expectedEarlierFromAttentionAt,
    String? confirmedPastAttentionAt,
    String? eventId,
    bool exposePastConfirmation = false,
  }) async {
    if (_mutating || _detail == null) return;
    setState(() {
      _mutating = true;
      _error = null;
    });
    try {
      await widget.agenda.mutateReminder(
        MutateReminderCommand(
          reminderId: widget.reminderId,
          eventId: eventId ?? RecordId.randomUuid(),
          expectedRevision: _detail!.reminder.revision,
          action: action,
          title: title,
          description: description,
          kind: kind,
          locationId: locationId,
          location: location,
          relatedPerson: relatedPerson,
          isImportant: isImportant,
          deadlineAt: deadlineAt,
          conditionText: conditionText,
          schedule: schedule,
          customAttentionAt: customAttentionAt,
          allDayLocalDate: allDayLocalDate,
          expectedEarlierFromAttentionAt: expectedEarlierFromAttentionAt,
          confirmedPastAttentionAt: confirmedPastAttentionAt,
          outcomeType: outcomeType,
          outcomeNote: outcomeNote,
        ),
      );
      await _reload();
    } on ReminderPastAttentionConfirmationRequired catch (error) {
      if (exposePastConfirmation) rethrow;
      if (mounted) setState(() => _error = error.message);
    } on AgendaValidationFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on Object {
      if (mounted) {
        setState(
          () => _error = action == ReminderMutationAction.snoozeTomorrowMorning
              ? 'Hatırlatıcı yarına ertelenemedi.'
              : 'İşlem güvenli biçimde tamamlanamadı.',
        );
      }
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  Future<void> _showTrashConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hatırlatıcı silinsin mi?'),
        content: const Text(
          'Kayıt normal listelerden kaldırılır. Bağlı Ajanda, Puantaj veya '
          'Beton kaydı silinmez. Hatırlatıcı Geri Dönüşüm Kutusu’ndan geri '
          'getirilebilir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            key: const Key('confirm-trash-reminder'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _mutate(ReminderMutationAction.moveToTrash);
    }
  }

  Future<void> _showScheduleSheet() async {
    final current = _detail?.reminder;
    if (_mutating || _scheduleFlowOpen || current == null) return;
    setState(() => _scheduleFlowOpen = true);
    try {
      await _runScheduleSheet(current);
    } finally {
      if (mounted) setState(() => _scheduleFlowOpen = false);
    }
  }

  Future<void> _runScheduleSheet(MobileReminder current) async {
    final scheduleNowUtc = clock.now().toUtc();
    final quickPreviews = {
      for (final schedule in [
        ReminderScheduleKind.tomorrowMorning,
        ReminderScheduleKind.nextWeekStart,
      ])
        schedule: resolveReminderExactQuickScheduleAt(
          schedule,
          scheduleNowUtc,
        )!,
    };
    final choice =
        await showModalBottomSheet<
          ({bool allDay, ReminderScheduleKind? schedule})
        >(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (sheetContext) => SafeArea(
            child: FractionallySizedBox(
              heightFactor: 0.90,
              child: ListView(
                primary: false,
                children: [
                  ...[
                    ReminderScheduleKind.in15Minutes,
                    ReminderScheduleKind.in1Hour,
                    ReminderScheduleKind.in2Hours,
                    ReminderScheduleKind.in3Hours,
                    ReminderScheduleKind.tomorrowMorning,
                    ReminderScheduleKind.nextWeekStart,
                    ReminderScheduleKind.custom,
                  ].map(
                    (schedule) => ListTile(
                      key: Key('reminder-schedule-option-${schedule.name}'),
                      minVerticalPadding: 12,
                      title: Text(schedule.label),
                      subtitle: quickPreviews[schedule] == null
                          ? null
                          : Text(
                              formatReminderExactSchedule(
                                quickPreviews[schedule]!,
                              ),
                              key: Key(
                                'reminder-schedule-preview-${schedule.name}',
                              ),
                            ),
                      onTap: () => Navigator.pop(sheetContext, (
                        allDay: false,
                        schedule: schedule,
                      )),
                    ),
                  ),
                  if (current.attendanceDayId == null)
                    ListTile(
                      key: const Key('reminder-schedule-option-allDay'),
                      minVerticalPadding: 12,
                      title: const Text('Tam gün'),
                      subtitle: const Text(
                        'Saat seçmeden bir takvim günü planla',
                      ),
                      onTap: () => Navigator.pop(sheetContext, (
                        allDay: true,
                        schedule: null,
                      )),
                    ),
                ],
              ),
            ),
          ),
        );
    if (choice == null || !mounted) return;
    if (choice.allDay) {
      final initialDate = _allDayInitialDate(current);
      final today = _dateFromDayKey(_istanbulToday());
      final date = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: DateTime(
          initialDate.year < today.year
              ? initialDate.year - 10
              : today.year - 10,
        ),
        lastDate: DateTime(
          initialDate.year > today.year
              ? initialDate.year + 10
              : today.year + 10,
          12,
          31,
        ),
        currentDate: today,
        helpText: 'Tam gün tarihini seçin',
        cancelText: 'Vazgeç',
        confirmText: 'İleri',
      );
      if (date == null || !mounted) return;
      final allDayLocalDate = _dayKey(date);
      final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Tam gün planlansın mı?'),
          content: Text(
            '${CseTimeCodec.formatIstanbulDay(allDayLocalDate)} • Tam gün',
            key: const Key('reminder-all-day-schedule-preview'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              key: const Key('confirm-reminder-all-day-schedule'),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Tam gün planla'),
            ),
          ],
        ),
      );
      if (accepted != true || !mounted) return;
      await _mutate(
        ReminderMutationAction.schedule,
        schedule: ReminderScheduleKind.custom,
        allDayLocalDate: allDayLocalDate,
      );
      return;
    }
    final schedule = choice.schedule!;
    String? custom;
    if (schedule == ReminderScheduleKind.custom) {
      final now = CseTimeCodec.toIstanbul(
        CseTimeCodec.encodeUtc(clock.now().toUtc()),
      );
      final date = await showDatePicker(
        context: context,
        initialDate: DateTime(now.year, now.month, now.day + 1),
        firstDate: DateTime(now.year, now.month, now.day),
        lastDate: DateTime(now.year + 10),
      );
      if (date == null || !mounted) return;
      final time = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 9, minute: 0),
      );
      if (time == null) return;
      custom = CseTimeCodec.canonicalFromIstanbulComponents(
        year: date.year,
        month: date.month,
        day: date.day,
        hour: time.hour,
        minute: time.minute,
      );
    } else {
      custom = quickPreviews[schedule];
    }
    await _mutate(
      ReminderMutationAction.schedule,
      schedule: schedule,
      customAttentionAt: custom,
    );
  }

  DateTime _allDayInitialDate(MobileReminder reminder) {
    if (reminder.allDayLocalDate case final allDay?) {
      return _dateFromDayKey(allDay);
    }
    if (reminder.nextAttentionAt case final timed?) {
      final local = CseTimeCodec.toIstanbul(timed);
      return DateTime(local.year, local.month, local.day);
    }
    return _dateFromDayKey(_istanbulToday());
  }

  String _istanbulToday() =>
      widget.istanbulToday ??
      CseTimeCodec.istanbulDayKey(CseTimeCodec.encodeUtc(clock.now().toUtc()));

  static DateTime _dateFromDayKey(String value) {
    CseTimeCodec.validateIstanbulDay(value);
    final parts = value.split('-').map(int.parse).toList(growable: false);
    return DateTime(parts[0], parts[1], parts[2]);
  }

  static String _dayKey(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  Future<void> _showEarlierFlow() async {
    final current = _detail?.reminder;
    if (_mutating ||
        current == null ||
        !isReminderEligibleForQuickEarlier(current)) {
      return;
    }
    final earlierFrom = current.nextAttentionAt!;
    final currentLocal = CseTimeCodec.toIstanbul(earlierFrom);
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(
        currentLocal.year,
        currentLocal.month,
        currentLocal.day,
      ),
      firstDate: DateTime(currentLocal.year - 10),
      lastDate: DateTime(currentLocal.year + 10),
      helpText: 'Yeni tarihi seçin',
      cancelText: 'Vazgeç',
      confirmText: 'İleri',
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: currentLocal.hour,
        minute: currentLocal.minute,
      ),
      helpText: 'Yeni saati seçin',
      cancelText: 'Vazgeç',
      confirmText: 'Tamam',
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (time == null || !mounted) return;
    final selectedAt = CseTimeCodec.canonicalFromIstanbulComponents(
      year: date.year,
      month: date.month,
      day: date.day,
      hour: time.hour,
      minute: time.minute,
    );
    if (!CseTimeCodec.decodeCanonicalUtc(
      selectedAt,
    ).isBefore(CseTimeCodec.decodeCanonicalUtc(earlierFrom))) {
      final openSchedule = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Daha erken bir zaman seçin'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatReminderExactSchedule(earlierFrom),
                key: const Key('reminder-earlier-current-time'),
              ),
              const SizedBox(height: 8),
              Text(
                formatReminderExactSchedule(selectedAt),
                key: const Key('reminder-earlier-selected-time'),
              ),
              const SizedBox(height: 12),
              const Text(
                'Yeni zaman mevcut zamandan daha erken olmalıdır. '
                'Daha sonraki bir zaman için Planla akışını kullanın.',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              key: const Key('open-schedule-from-earlier'),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Planla'),
            ),
          ],
        ),
      );
      if (openSchedule == true && mounted) await _showScheduleSheet();
      return;
    }
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hatırlatıcı erkene alınsın mı?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mevcut zaman'),
            Text(
              formatReminderExactSchedule(earlierFrom),
              key: const Key('reminder-earlier-current-time'),
            ),
            const SizedBox(height: 8),
            const Text('Yeni zaman'),
            Text(
              formatReminderExactSchedule(selectedAt),
              key: const Key('reminder-earlier-selected-time'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            key: const Key('confirm-earlier-reminder'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Erkene al'),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    final eventId = RecordId.randomUuid();
    try {
      await _mutate(
        ReminderMutationAction.schedule,
        schedule: ReminderScheduleKind.custom,
        customAttentionAt: selectedAt,
        expectedEarlierFromAttentionAt: earlierFrom,
        eventId: eventId,
        exposePastConfirmation: true,
      );
    } on ReminderPastAttentionConfirmationRequired {
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Geçmiş zamanı açıkça onaylayın'),
          content: Text(
            '${formatReminderExactSchedule(selectedAt)} işlem anında geçmişte '
            'kalıyor. Hatırlatıcı aktif ve gecikmiş olarak kaydedilecek; '
            'gelecek native bildirimi kurulmayacak.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              key: const Key('confirm-past-earlier-reminder'),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Geçmiş zamana al'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      await _mutate(
        ReminderMutationAction.schedule,
        schedule: ReminderScheduleKind.custom,
        customAttentionAt: selectedAt,
        expectedEarlierFromAttentionAt: earlierFrom,
        confirmedPastAttentionAt: selectedAt,
        eventId: eventId,
      );
    }
  }

  Future<void> _showCompletionDialog() async {
    final note = TextEditingController();
    var outcome = ReminderOutcomeType.completed;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Hatırlatıcıyı tamamla'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<ReminderOutcomeType>(
                  initialValue: outcome,
                  decoration: const InputDecoration(labelText: 'Sonuç'),
                  items: ReminderOutcomeType.values
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(item.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setDialogState(() => outcome = value!),
                ),
                TextField(
                  key: const Key('reminder-outcome-note'),
                  controller: note,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Sonuç notu'),
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
              child: const Text('Tamamla'),
            ),
          ],
        ),
      ),
    );
    if (accepted == true) {
      await _mutate(
        ReminderMutationAction.complete,
        outcomeType: outcome,
        outcomeNote: note.text,
      );
    }
    note.dispose();
  }

  Future<void> _showEditDialog() async {
    final reminder = _detail!.reminder;
    final title = TextEditingController(text: reminder.title);
    final description = TextEditingController(text: reminder.description);
    final location = TextEditingController(text: reminder.location);
    var locationId = reminder.locationId;
    List<MobileProjectLocation> locations = const [];
    if (reminder.projectId != null && widget.projectLocations != null) {
      try {
        locations = await widget.projectLocations!.listProjectLocations(
          ProjectLocationQuery(projectId: reminder.projectId!),
        );
      } on Object {
        locations = const [];
      }
    }
    if (!mounted) {
      title.dispose();
      description.dispose();
      location.dispose();
      return;
    }
    final person = TextEditingController(text: reminder.relatedPerson);
    final condition = TextEditingController(text: reminder.conditionText);
    var kind = reminder.kind;
    var important = reminder.isImportant;
    var hasDeadline = reminder.deadlineAt != null;
    final deadlineLocal = CseTimeCodec.toIstanbul(
      reminder.deadlineAt ??
          CseTimeCodec.encodeUtc(
            clock.now().toUtc().add(const Duration(days: 1)),
          ),
    );
    var deadlineDate = DateTime(
      deadlineLocal.year,
      deadlineLocal.month,
      deadlineLocal.day,
    );
    var deadlineTime = TimeOfDay(
      hour: deadlineLocal.hour,
      minute: deadlineLocal.minute,
    );
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Ayrıntıları düzenle'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    key: const Key('edit-reminder-title'),
                    controller: title,
                    decoration: const InputDecoration(labelText: 'Başlık'),
                  ),
                  TextField(
                    controller: description,
                    decoration: const InputDecoration(labelText: 'Açıklama'),
                  ),
                  DropdownButtonFormField<ReminderKind>(
                    initialValue: kind,
                    decoration: const InputDecoration(labelText: 'Tür'),
                    items: ReminderKind.values
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(item.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setDialogState(() => kind = value!),
                  ),
                  if (reminder.projectId == null)
                    TextField(
                      controller: location,
                      decoration: const InputDecoration(labelText: 'Mahál'),
                    )
                  else
                    DropdownButtonFormField<String>(
                      key: const Key('edit-reminder-location-selector'),
                      initialValue: locationId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Mahal (opsiyonel)',
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Mahal seçilmedi'),
                        ),
                        ...locations.map(
                          (item) => DropdownMenuItem<String>(
                            value: item.id,
                            child: Text(item.displayName),
                          ),
                        ),
                        if (locationId != null &&
                            !locations.any((item) => item.id == locationId))
                          DropdownMenuItem<String>(
                            value: locationId,
                            child: Text(
                              '${reminder.stableLocationName ?? reminder.location ?? 'Arşivli mahal'} (Arşivli)',
                            ),
                          ),
                      ],
                      onChanged: (value) =>
                          setDialogState(() => locationId = value),
                    ),
                  TextField(
                    controller: person,
                    decoration: const InputDecoration(labelText: 'İlgili kişi'),
                  ),
                  TextField(
                    controller: condition,
                    decoration: const InputDecoration(labelText: 'Koşul/not'),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Önemli'),
                    value: important,
                    onChanged: (value) =>
                        setDialogState(() => important = value),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Gerçek son tarih'),
                    value: hasDeadline,
                    onChanged: (value) =>
                        setDialogState(() => hasDeadline = value),
                  ),
                  if (hasDeadline)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: () async {
                            final value = await showDatePicker(
                              context: context,
                              initialDate: deadlineDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (value != null) {
                              setDialogState(() => deadlineDate = value);
                            }
                          },
                          child: Text(
                            '${deadlineDate.day.toString().padLeft(2, '0')}.'
                            '${deadlineDate.month.toString().padLeft(2, '0')}.'
                            '${deadlineDate.year}',
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () async {
                            final value = await showTimePicker(
                              context: context,
                              initialTime: deadlineTime,
                            );
                            if (value != null) {
                              setDialogState(() => deadlineTime = value);
                            }
                          },
                          child: Text(deadlineTime.format(context)),
                        ),
                      ],
                    ),
                ],
              ),
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
    if (accepted == true) {
      await _mutate(
        ReminderMutationAction.updateDetails,
        title: title.text,
        description: description.text,
        kind: kind,
        locationId: locationId,
        location: location.text,
        relatedPerson: person.text,
        isImportant: important,
        deadlineAt: hasDeadline
            ? CseTimeCodec.canonicalFromIstanbulComponents(
                year: deadlineDate.year,
                month: deadlineDate.month,
                day: deadlineDate.day,
                hour: deadlineTime.hour,
                minute: deadlineTime.minute,
              )
            : null,
        conditionText: condition.text,
      );
    }
    title.dispose();
    description.dispose();
    location.dispose();
    person.dispose();
    condition.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hatırlatıcı detayı')),
      body: _loading
          ? Center(
              child: Semantics(
                container: true,
                label: 'Hatırlatıcı yükleniyor',
                child: const ExcludeSemantics(
                  child: CircularProgressIndicator(),
                ),
              ),
            )
          : _readError != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_readError!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    _DetailReadRetryAction(
                      actionKey: const Key('reminder-detail-read-error-retry'),
                      onPressed: _readInFlight ? null : _reload,
                    ),
                  ],
                ),
              ),
            )
          : _detail == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_error ?? 'Hatırlatıcı bulunamadı.'),
              ),
            )
          : _buildDetail(context, _detail!),
    );
  }

  Widget _buildDetail(BuildContext context, ReminderDetail detail) {
    final reminder = detail.reminder;
    final agendaSyncDiffs = _agendaReminderSyncDiffs(detail);
    final terminal =
        reminder.status == ReminderStatus.completed ||
        reminder.status == ReminderStatus.cancelled;
    final trashed = reminder.trashedAt != null;
    final istanbulToday =
        widget.istanbulToday ??
        CseTimeCodec.istanbulDayKey(
          CseTimeCodec.encodeUtc(clock.now().toUtc()),
        );
    final tomorrowEligible = isReminderEligibleForTomorrowSnooze(
      reminder,
      istanbulToday: istanbulToday,
    );
    final earlierEligible = isReminderEligibleForQuickEarlier(reminder);
    return ListView(
      key: const Key('reminder-detail'),
      padding: const EdgeInsets.all(16),
      children: [
        if (_error != null)
          Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(_error!, key: const Key('reminder-detail-error')),
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (reminder.isImportant)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.priority_high_rounded),
              ),
            Expanded(
              child: Text(
                reminder.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ReminderRow(label: 'Tür', value: reminder.kind.label),
        _ReminderRow(label: 'Durum', value: reminder.status.label),
        _ReminderRow(
          label: 'Proje',
          value: reminder.projectName ?? 'Kişisel / projesiz',
        ),
        if (reminder.description != null)
          _ReminderRow(label: 'Açıklama', value: reminder.description!),
        if (reminder.displayLocation != null)
          _ReminderRow(
            label: 'Mahal',
            value:
                '${reminder.displayLocation!}${reminder.stableLocationArchivedAt == null ? '' : ' (Arşivli)'}',
          ),
        if (reminder.relatedPerson != null)
          _ReminderRow(label: 'İlgili kişi', value: reminder.relatedPerson!),
        if (reminder.conditionText != null)
          _ReminderRow(label: 'Koşul/not', value: reminder.conditionText!),
        if (reminder.nextAttentionAt != null)
          _ReminderRow(
            label: 'Sonraki dikkat zamanı',
            value: CseTimeCodec.formatIstanbul(reminder.nextAttentionAt!),
          ),
        if (reminder.allDayLocalDate != null)
          _ReminderRow(
            key: const Key('reminder-all-day-value'),
            label: 'Takvim günü',
            value:
                '${CseTimeCodec.formatIstanbulDay(reminder.allDayLocalDate!)}'
                ' • Tam gün',
          ),
        if (_deliveryDiagnostic?.delayClass ==
            ReminderDeliveryDelayClass.overdue)
          const _ReminderRow(
            key: Key('reminder-overdue-status'),
            label: 'Takip durumu',
            value: 'Gecikti',
          ),
        if (reminder.deadlineAt != null)
          _ReminderRow(
            label: 'Gerçek son tarih',
            value: CseTimeCodec.formatIstanbul(reminder.deadlineAt!),
          ),
        _ReminderRow(
          label: 'Bildirim',
          value: reminder.allDayLocalDate != null
              ? 'Tam gün kayıt için saatli native bildirim kurulmaz'
              : [
                  detail.notification.syncState.label,
                  if (detail.notification.safeErrorCode != null)
                    detail.notification.safeErrorCode!,
                ].join(' • '),
        ),
        _ReminderRow(label: 'Revision', value: '${reminder.revision}'),
        if (reminder.trashedAt != null)
          _ReminderRow(
            key: const Key('reminder-trashed-at'),
            label: 'Geri dönüşüm kutusuna taşındı',
            value: CseTimeCodec.formatIstanbul(reminder.trashedAt!),
          ),
        if (reminder.sourceLogId != null) ...[
          const SizedBox(height: 16),
          _ReminderSourceAgendaPhotos(
            agenda: widget.agenda,
            media: _sourceAgendaMedia!,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: _DetailIconAction(
              actionKey: const Key('open-source-agenda-log'),
              label: 'Kaynak Ajanda kaydına dön',
              icon: Icons.event_note_outlined,
              kind: _DetailIconActionKind.tonal,
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => LogDetailPage(
                    agenda: widget.agenda,
                    logId: reminder.sourceLogId!,
                  ),
                ),
              ),
            ),
          ),
          if (agendaSyncDiffs.isNotEmpty) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: _DetailIconAction(
                actionKey: const Key('sync-agenda-to-reminder'),
                label: 'Ajanda’dan güncelle',
                icon: Icons.sync_outlined,
                kind: _DetailIconActionKind.filled,
                onPressed: _mutating || _syncDialogOpen
                    ? null
                    : _showAgendaSyncConfirmation,
              ),
            ),
          ],
        ],
        if (reminder.attendanceDayId != null && widget.attendance != null) ...[
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: _DetailIconAction(
              actionKey: const Key('open-source-attendance-day'),
              label: 'Kaynak Puantaj gününe dön',
              icon: Icons.badge_outlined,
              kind: _DetailIconActionKind.tonal,
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => AttendanceDayPage(
                    attendance: widget.attendance!,
                    agenda: widget.agenda,
                    dayId: reminder.attendanceDayId!,
                  ),
                ),
              ),
            ),
          ),
        ],
        if (reminder.concretePourId != null &&
            widget.concrete != null &&
            widget.concreteAttachments != null) ...[
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: _DetailIconAction(
              actionKey: const Key('open-source-concrete-pour'),
              label: 'Kaynak Beton paketine dön',
              icon: Icons.foundation_outlined,
              kind: _DetailIconActionKind.tonal,
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => ConcretePourDetailPage(
                    concrete: widget.concrete!,
                    agenda: widget.agenda,
                    attachments: widget.concreteAttachments!,
                    projectLocations: widget.projectLocations,
                    pourId: reminder.concretePourId!,
                  ),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (trashed)
              _ActionButton(
                key: const Key('restore-reminder'),
                label: 'Geri yükle',
                icon: Icons.restore_from_trash_outlined,
                onPressed: _mutating
                    ? null
                    : () => _mutate(ReminderMutationAction.restoreFromTrash),
              )
            else ...[
              if (!terminal) ...[
                _ActionButton(
                  key: const Key('complete-reminder'),
                  label: 'Tamamla',
                  icon: Icons.check_circle_outline,
                  onPressed: _mutating ? null : _showCompletionDialog,
                ),
                if (tomorrowEligible)
                  _ActionButton(
                    key: const Key('snooze-tomorrow'),
                    label: reminder.allDayLocalDate == null
                        ? "Yarın 08:00'a ertele"
                        : 'Yarına ertele',
                    icon: Icons.wb_sunny_outlined,
                    onPressed: _mutating
                        ? null
                        : () => _mutate(
                            ReminderMutationAction.snoozeTomorrowMorning,
                          ),
                  ),
                _ActionButton(
                  key: const Key('snooze-15'),
                  label: '15 dk ertele',
                  icon: Icons.snooze,
                  onPressed: _mutating
                      ? null
                      : () => _mutate(ReminderMutationAction.snooze15Minutes),
                ),
                _ActionButton(
                  key: const Key('snooze-1h'),
                  label: '1 saat ertele',
                  icon: Icons.more_time,
                  badgeText: '1',
                  onPressed: _mutating
                      ? null
                      : () => _mutate(ReminderMutationAction.snooze1Hour),
                ),
                _ActionButton(
                  key: const Key('snooze-2h'),
                  label: '2 saat ertele',
                  icon: Icons.more_time,
                  badgeText: '2',
                  onPressed: _mutating
                      ? null
                      : () => _mutate(ReminderMutationAction.snooze2Hours),
                ),
                _ActionButton(
                  key: const Key('snooze-3h'),
                  label: '3 saat ertele',
                  icon: Icons.more_time,
                  badgeText: '3',
                  onPressed: _mutating
                      ? null
                      : () => _mutate(ReminderMutationAction.snooze3Hours),
                ),
                if (earlierEligible)
                  _ActionButton(
                    key: const Key('earlier-reminder'),
                    label: 'Erkene al',
                    icon: Icons.history_toggle_off,
                    onPressed: _mutating ? null : _showEarlierFlow,
                  ),
                _ActionButton(
                  key: const Key('schedule-reminder'),
                  label: 'Yeni tarih',
                  icon: Icons.event_outlined,
                  onPressed: _mutating || _scheduleFlowOpen
                      ? null
                      : _showScheduleSheet,
                ),
              ] else
                _ActionButton(
                  key: const Key('reopen-reminder'),
                  label: 'Yeniden aç',
                  icon: Icons.restart_alt,
                  onPressed: _mutating
                      ? null
                      : () => _mutate(ReminderMutationAction.reopen),
                ),
              _ActionButton(
                key: const Key('edit-reminder'),
                label: 'Düzenle',
                icon: Icons.edit_outlined,
                onPressed: _mutating ? null : _showEditDialog,
              ),
              _ActionButton(
                key: const Key('trash-reminder'),
                label: 'Sil',
                icon: Icons.delete_outline,
                onPressed: _mutating ? null : _showTrashConfirmation,
              ),
              if (!terminal) ...[
                _ActionButton(
                  key: const Key('move-inbox'),
                  label: 'Unutma Kutusu',
                  icon: Icons.inbox_outlined,
                  onPressed: _mutating
                      ? null
                      : () => _mutate(ReminderMutationAction.moveToInbox),
                ),
                _ActionButton(
                  key: const Key('cancel-reminder'),
                  label: 'İptal et',
                  icon: Icons.cancel_outlined,
                  onPressed: _mutating
                      ? null
                      : () => _mutate(ReminderMutationAction.cancel),
                ),
              ],
            ],
          ],
        ),
        if (_deliveryDiagnostic case final diagnostic?
            when !terminal &&
                !trashed &&
                reminder.allDayLocalDate == null &&
                diagnostic.delayClass !=
                    ReminderDeliveryDelayClass.overdue) ...[
          const SizedBox(height: 16),
          _DeliveryDiagnosticCard(
            diagnostic: diagnostic,
            enabled: !_mutating,
            onRetry: _retryDelivery,
            onNotificationSettings: () => _openDeliverySettings(battery: false),
            onBatterySettings: () => _openDeliverySettings(battery: true),
          ),
        ],
        const SizedBox(height: 24),
        Text(
          'Değişiklik geçmişi',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        for (final event in detail.events)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(child: Text('${event.sequence}')),
            title: Text(event.eventType),
            subtitle: Text(CseTimeCodec.formatIstanbul(event.occurredAt)),
          ),
      ],
    );
  }
}

class _AgendaReminderSyncDiff {
  const _AgendaReminderSyncDiff({
    required this.field,
    required this.label,
    required this.before,
    required this.after,
  });

  final AgendaReminderSyncField field;
  final String label;
  final String? before;
  final String? after;
}

String _syncDisplayValue(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? 'Boş' : normalized;
}

class _ReminderSourceAgendaPhotos extends StatelessWidget {
  const _ReminderSourceAgendaPhotos({
    required this.agenda,
    required this.media,
  });

  final AgendaApplication agenda;
  final Future<ReminderSourceAgendaMedia> media;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ReminderSourceAgendaMedia>(
      future: media,
      builder: (context, snapshot) {
        final value = snapshot.data;
        return Column(
          key: const Key('reminder-source-agenda-photos'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kaynak Ajanda fotoğrafları',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (snapshot.connectionState == ConnectionState.done &&
                value?.isAvailable == true &&
                value?.sourceLogArchivedAt != null) ...[
              const Card(
                key: Key('reminder-source-agenda-archived'),
                child: ListTile(
                  leading: Icon(Icons.archive_outlined),
                  title: Text('Kaynak Ajanda arşivde'),
                  subtitle: Text(
                    'Hatırlatıcı değişmedi; kaynak fotoğraflar salt okunur.',
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (snapshot.connectionState != ConnectionState.done)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: LinearProgressIndicator(),
                ),
              )
            else if (value == null || !value.isAvailable)
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Kaynak Ajanda fotoğrafları güvenli biçimde yüklenemedi.\n'
                    'Tanı: ${value?.safeErrorCode ?? 'source_agenda_media_unavailable'}',
                    key: const Key('reminder-source-agenda-photos-error'),
                  ),
                ),
              )
            else if (value.photos.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Kaynak Ajanda kaydında aktif fotoğraf yok.'),
                ),
              )
            else
              for (final photo in value.photos)
                Card(
                  child: ListTile(
                    key: Key('reminder-source-agenda-photo-${photo.id}'),
                    minVerticalPadding: 10,
                    leading: SizedBox.square(
                      dimension: 56,
                      child: AgendaPhotoThumbnail(
                        key: Key(
                          'reminder-source-agenda-thumbnail-${photo.id}',
                        ),
                        agenda: agenda,
                        photo: photo,
                      ),
                    ),
                    title: Text(
                      photo.originalFileName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      [
                        '${photo.integrity.label} • ${photo.byteSize} byte',
                        if (photo.description?.trim().isNotEmpty ?? false)
                          photo.description!.trim(),
                      ].join('\n'),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) =>
                            AgendaPhotoViewerPage(agenda: agenda, photo: photo),
                      ),
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }
}

class _DeliveryDiagnosticCard extends StatelessWidget {
  const _DeliveryDiagnosticCard({
    required this.diagnostic,
    required this.enabled,
    required this.onRetry,
    required this.onNotificationSettings,
    required this.onBatterySettings,
  });

  final ReminderDeliveryDiagnostic diagnostic;
  final bool enabled;
  final VoidCallback onRetry;
  final VoidCallback onNotificationSettings;
  final VoidCallback onBatterySettings;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      key: const Key('reminder-delivery-diagnostic'),
      color: diagnostic.deliveryGuaranteed
          ? colors.secondaryContainer
          : colors.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              diagnostic.deliveryGuaranteed
                  ? 'Arka plan teslimatı native olarak doğrulandı'
                  : 'Arka plan teslimatı garanti edilemiyor',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Kayıt ${diagnostic.safeReminderId} • '
              '${diagnostic.scheduleKind} • '
              '${diagnostic.delayClass.label}',
            ),
            Text(
              'Native plan: '
              '${diagnostic.nativeSchedulePresent ? 'var' : 'yok'} • '
              'İzin: ${diagnostic.permissionState} • '
              'Kanal: ${diagnostic.channelState} • '
              'Exact: ${diagnostic.exactAlarmState}',
            ),
            Text(
              'Batarya: ${diagnostic.batteryOptimizationState} • '
              'Arka plan: ${diagnostic.backgroundRestrictionState} • '
              'Standby: ${diagnostic.standbyBucket}',
            ),
            Text(
              'Boot yeniden planlama: ${diagnostic.bootRescheduleState}'
              '${diagnostic.bootRescheduledAt == null ? '' : ' • ${diagnostic.bootRescheduledAt}'}',
            ),
            if (diagnostic.safeErrorCode case final code?) Text('Tanı: $code'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _DetailIconAction(
                  actionKey: const Key('retry-reminder-delivery'),
                  label: 'Yeniden doğrula',
                  icon: Icons.sync,
                  onPressed: enabled ? onRetry : null,
                ),
                _DetailIconAction(
                  actionKey: const Key('open-notification-settings'),
                  label: 'Bildirim ayarları',
                  icon: Icons.notifications_outlined,
                  onPressed: enabled ? onNotificationSettings : null,
                ),
                _DetailIconAction(
                  actionKey: const Key('open-battery-settings'),
                  label: 'Batarya ayarları',
                  icon: Icons.battery_saver_outlined,
                  onPressed: enabled ? onBatterySettings : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum _DetailIconActionKind { outlined, filled, tonal }

class _DetailIconAction extends StatelessWidget {
  const _DetailIconAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.actionKey,
    this.badgeText,
    this.kind = _DetailIconActionKind.outlined,
  });

  final Key? actionKey;
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final String? badgeText;
  final _DetailIconActionKind kind;

  @override
  Widget build(BuildContext context) {
    final style = IconButton.styleFrom(
      minimumSize: const Size.square(48),
      fixedSize: const Size.square(48),
      maximumSize: const Size.square(48),
      iconSize: 20,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.standard,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
    final iconWidget = _DetailBadgedIcon(icon: icon, badgeText: badgeText);
    final button = switch (kind) {
      _DetailIconActionKind.outlined => IconButton.outlined(
        key: actionKey,
        tooltip: label,
        style: style,
        onPressed: onPressed,
        icon: iconWidget,
      ),
      _DetailIconActionKind.filled => IconButton.filled(
        key: actionKey,
        tooltip: label,
        style: style,
        onPressed: onPressed,
        icon: iconWidget,
      ),
      _DetailIconActionKind.tonal => IconButton.filledTonal(
        key: actionKey,
        tooltip: label,
        style: style,
        onPressed: onPressed,
        icon: iconWidget,
      ),
    };
    return Semantics(
      label: label,
      button: true,
      enabled: onPressed != null,
      excludeSemantics: true,
      child: button,
    );
  }
}

class _DetailBadgedIcon extends StatelessWidget {
  const _DetailBadgedIcon({required this.icon, this.badgeText});

  final IconData icon;
  final String? badgeText;

  @override
  Widget build(BuildContext context) {
    final badge = badgeText;
    if (badge == null) return Icon(icon);
    final colors = Theme.of(context).colorScheme;
    return SizedBox.square(
      dimension: 30,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(left: 3, bottom: 3, child: Icon(icon, size: 20)),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
              padding: const EdgeInsets.symmetric(horizontal: 3),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.error,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badge,
                maxLines: 1,
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                  color: colors.onError,
                  fontSize: 10,
                  height: 1,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.badgeText,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final String? badgeText;

  @override
  Widget build(BuildContext context) {
    return _DetailIconAction(
      label: label,
      icon: icon,
      badgeText: badgeText,
      onPressed: onPressed,
    );
  }
}

class _ReminderRow extends StatelessWidget {
  const _ReminderRow({required this.label, required this.value, super.key});

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

class _DetailReadRetryAction extends StatelessWidget {
  const _DetailReadRetryAction({
    required this.actionKey,
    required this.onPressed,
  });

  final Key actionKey;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Tekrar dene',
      button: true,
      enabled: onPressed != null,
      excludeSemantics: true,
      onTap: onPressed,
      child: FilledButton(
        key: actionKey,
        style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
        onPressed: onPressed,
        child: const Text('Tekrar dene'),
      ),
    );
  }
}
