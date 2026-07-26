import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/application/attendance_application.dart';
import 'package:chief_site_engineer/application/concrete_application.dart';
import 'package:chief_site_engineer/core/record_id.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/features/agenda/log_detail_page.dart';
import 'package:chief_site_engineer/features/attendance/attendance_day_page.dart';
import 'package:chief_site_engineer/features/concrete/concrete_pour_detail_page.dart';
import 'package:chief_site_engineer/platform/attachment_gateway.dart';
import 'package:flutter/material.dart';

class ReminderDetailPage extends StatefulWidget {
  const ReminderDetailPage({
    required this.agenda,
    required this.reminderId,
    this.attendance,
    this.concrete,
    this.concreteAttachments,
    super.key,
  });

  final AgendaApplication agenda;
  final String reminderId;
  final AttendanceApplication? attendance;
  final ConcreteApplication? concrete;
  final SafeAttachmentPicker? concreteAttachments;

  @override
  State<ReminderDetailPage> createState() => _ReminderDetailPageState();
}

class _ReminderDetailPageState extends State<ReminderDetailPage> {
  ReminderDetail? _detail;
  ReminderDeliveryDiagnostic? _deliveryDiagnostic;
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
      final detail = await widget.agenda.getReminderLifecycleDetail(
        widget.reminderId,
      );
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
          _deliveryDiagnostic = diagnostic;
          _loading = false;
        });
      }
    } on Object {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Hatırlatıcı güvenli biçimde okunamadı.';
        });
      }
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
    ReminderOutcomeType? outcomeType,
    String? outcomeNote,
    String? title,
    String? description,
    ReminderKind? kind,
    String? location,
    String? relatedPerson,
    bool? isImportant,
    String? deadlineAt,
    String? conditionText,
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
          eventId: RecordId.randomUuid(),
          expectedRevision: _detail!.reminder.revision,
          action: action,
          title: title,
          description: description,
          kind: kind,
          location: location,
          relatedPerson: relatedPerson,
          isImportant: isImportant,
          deadlineAt: deadlineAt,
          conditionText: conditionText,
          schedule: schedule,
          customAttentionAt: customAttentionAt,
          outcomeType: outcomeType,
          outcomeNote: outcomeNote,
        ),
      );
      await _reload();
    } on AgendaValidationFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on Object {
      if (mounted) {
        setState(() => _error = 'İşlem güvenli biçimde tamamlanamadı.');
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
    final choice = await showModalBottomSheet<ReminderScheduleKind>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final schedule in [
              ReminderScheduleKind.in15Minutes,
              ReminderScheduleKind.in1Hour,
              ReminderScheduleKind.tomorrowMorning,
              ReminderScheduleKind.custom,
            ])
              ListTile(
                minVerticalPadding: 12,
                title: Text(schedule.label),
                onTap: () => Navigator.pop(context, schedule),
              ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    String? custom;
    if (choice == ReminderScheduleKind.custom) {
      final now = CseTimeCodec.toIstanbul(
        CseTimeCodec.encodeUtc(DateTime.now().toUtc()),
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
    }
    await _mutate(
      ReminderMutationAction.schedule,
      schedule: choice,
      customAttentionAt: custom,
    );
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
    final person = TextEditingController(text: reminder.relatedPerson);
    final condition = TextEditingController(text: reminder.conditionText);
    var kind = reminder.kind;
    var important = reminder.isImportant;
    var hasDeadline = reminder.deadlineAt != null;
    final deadlineLocal = CseTimeCodec.toIstanbul(
      reminder.deadlineAt ??
          CseTimeCodec.encodeUtc(
            DateTime.now().toUtc().add(const Duration(days: 1)),
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
                  TextField(
                    controller: location,
                    decoration: const InputDecoration(labelText: 'Mahál'),
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
          ? const Center(child: CircularProgressIndicator())
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
    final terminal =
        reminder.status == ReminderStatus.completed ||
        reminder.status == ReminderStatus.cancelled;
    final trashed = reminder.trashedAt != null;
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
        if (reminder.location != null)
          _ReminderRow(label: 'Mahál', value: reminder.location!),
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
          SizedBox(
            height: 52,
            child: FilledButton.tonalIcon(
              key: const Key('open-source-agenda-log'),
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => LogDetailPage(
                    agenda: widget.agenda,
                    logId: reminder.sourceLogId!,
                  ),
                ),
              ),
              icon: const Icon(Icons.event_note_outlined),
              label: const Text('Kaynak Ajanda kaydına dön'),
            ),
          ),
        ],
        if (reminder.attendanceDayId != null && widget.attendance != null) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: FilledButton.tonalIcon(
              key: const Key('open-source-attendance-day'),
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => AttendanceDayPage(
                    attendance: widget.attendance!,
                    agenda: widget.agenda,
                    dayId: reminder.attendanceDayId!,
                  ),
                ),
              ),
              icon: const Icon(Icons.badge_outlined),
              label: const Text('Kaynak Puantaj gününe dön'),
            ),
          ),
        ],
        if (reminder.concretePourId != null &&
            widget.concrete != null &&
            widget.concreteAttachments != null) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: FilledButton.tonalIcon(
              key: const Key('open-source-concrete-pour'),
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => ConcretePourDetailPage(
                    concrete: widget.concrete!,
                    agenda: widget.agenda,
                    attachments: widget.concreteAttachments!,
                    pourId: reminder.concretePourId!,
                  ),
                ),
              ),
              icon: const Icon(Icons.foundation_outlined),
              label: const Text('Kaynak Beton paketine dön'),
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
                _ActionButton(
                  key: const Key('snooze-tomorrow'),
                  label: 'Yarın',
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
                  onPressed: _mutating
                      ? null
                      : () => _mutate(ReminderMutationAction.snooze1Hour),
                ),
                _ActionButton(
                  key: const Key('schedule-reminder'),
                  label: 'Yeni tarih',
                  icon: Icons.event_outlined,
                  onPressed: _mutating ? null : _showScheduleSheet,
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
                OutlinedButton.icon(
                  key: const Key('retry-reminder-delivery'),
                  onPressed: enabled ? onRetry : null,
                  icon: const Icon(Icons.sync),
                  label: const Text('Yeniden doğrula'),
                ),
                OutlinedButton.icon(
                  key: const Key('open-notification-settings'),
                  onPressed: enabled ? onNotificationSettings : null,
                  icon: const Icon(Icons.notifications_outlined),
                  label: const Text('Bildirim ayarları'),
                ),
                OutlinedButton.icon(
                  key: const Key('open-battery-settings'),
                  onPressed: enabled ? onBatterySettings : null,
                  icon: const Icon(Icons.battery_saver_outlined),
                  label: const Text('Batarya ayarları'),
                ),
              ],
            ),
          ],
        ),
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
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      ),
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
