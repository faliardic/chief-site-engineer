import 'dart:async';

import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/core/record_id.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:flutter/material.dart';

class ReminderFormPage extends StatefulWidget {
  const ReminderFormPage({required this.agenda, this.log, super.key});

  final AgendaApplication agenda;
  final AgendaLog? log;

  @override
  State<ReminderFormPage> createState() => _ReminderFormPageState();
}

class _ReminderFormPageState extends State<ReminderFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  final _description = TextEditingController();
  final _location = TextEditingController();
  final _relatedPerson = TextEditingController();
  final _condition = TextEditingController();
  late final String _recordId;
  late final String _eventId;
  List<MobileProject> _projects = const [];
  String? _projectId;
  ReminderKind _kind = ReminderKind.action;
  ReminderScheduleKind _schedule = ReminderScheduleKind.in15Minutes;
  late DateTime _customDate;
  TimeOfDay _customTime = const TimeOfDay(hour: 9, minute: 0);
  bool _allDay = false;
  bool _isImportant = false;
  bool _hasDeadline = false;
  late DateTime _deadlineDate;
  TimeOfDay _deadlineTime = const TimeOfDay(hour: 17, minute: 0);
  bool _submitting = false;
  String? _error;
  StreamSubscription<void>? _projectSubscription;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.log?.description ?? '');
    _projectId = widget.log?.projectId;
    _recordId = RecordId.randomUuid();
    _eventId = RecordId.randomUuid();
    final local = CseTimeCodec.toIstanbul(
      CseTimeCodec.encodeUtc(DateTime.now().toUtc()),
    );
    _customDate = DateTime(local.year, local.month, local.day + 1);
    _deadlineDate = _customDate;
    _projectSubscription = widget.agenda.projectChanges.listen(
      (_) => _loadProjects(),
    );
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    try {
      final projects = await widget.agenda.listProjects();
      if (mounted) setState(() => _projects = projects);
    } on Object {
      // Standalone capture remains available without a project.
    }
  }

  @override
  void dispose() {
    _projectSubscription?.cancel();
    _title.dispose();
    _description.dispose();
    _location.dispose();
    _relatedPerson.dispose();
    _condition.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final custom = _schedule == ReminderScheduleKind.custom && !_allDay
          ? CseTimeCodec.canonicalFromIstanbulComponents(
              year: _customDate.year,
              month: _customDate.month,
              day: _customDate.day,
              hour: _customTime.hour,
              minute: _customTime.minute,
            )
          : null;
      final deadline = _hasDeadline
          ? CseTimeCodec.canonicalFromIstanbulComponents(
              year: _deadlineDate.year,
              month: _deadlineDate.month,
              day: _deadlineDate.day,
              hour: _deadlineTime.hour,
              minute: _deadlineTime.minute,
            )
          : null;
      final reminder = await widget.agenda.createReminder(
        CreateReminderCommand(
          id: _recordId,
          eventId: _eventId,
          projectId: widget.log?.projectId ?? _projectId,
          sourceLogId: widget.log?.id,
          captureText: _title.text,
          title: _title.text,
          description: _description.text,
          kind: _kind,
          schedule: _schedule,
          location: _location.text,
          relatedPerson: _relatedPerson.text,
          isImportant: _isImportant,
          deadlineAt: deadline,
          conditionText: _condition.text,
          customAttentionAt: custom,
          allDayLocalDate: _allDay
              ? '${_customDate.year.toString().padLeft(4, '0')}-'
                    '${_customDate.month.toString().padLeft(2, '0')}-'
                    '${_customDate.day.toString().padLeft(2, '0')}'
              : null,
        ),
      );
      var deliveryVerified = reminder.nextAttentionAt == null;
      if (!deliveryVerified) {
        try {
          final detail = await widget.agenda.getReminderLifecycleDetail(
            reminder.id,
          );
          deliveryVerified =
              detail.notification.syncState == NotificationSyncState.scheduled;
        } on Object {
          deliveryVerified = false;
        }
      }
      if (!deliveryVerified && mounted) {
        setState(() => _submitting = false);
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            key: const Key('reminder-delivery-warning'),
            title: const Text('Kayıt oluşturuldu'),
            content: const Text(
              'Hatırlatıcı kaydı korundu ancak arka plan bildirimi '
              'doğrulanamadı. Kayıt detayındaki teslimat tanısını ve sistem '
              'ayarlarını kontrol edin.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Anladım'),
              ),
            ],
          ),
        );
      }
      if (mounted) {
        Navigator.pop(context, reminder);
      }
    } on AgendaValidationFailure catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } on TimeContractViolation {
      if (mounted) {
        setState(() => _error = 'Hatırlatıcı tarih/saat değeri geçersiz.');
      }
    } on Object {
      if (mounted) {
        setState(() => _error = 'Hatırlatıcı güvenli biçimde oluşturulamadı.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _selectAllDay(int dayDelta) {
    final local = CseTimeCodec.toIstanbul(
      CseTimeCodec.encodeUtc(DateTime.now().toUtc()),
    );
    setState(() {
      _customDate = DateTime(local.year, local.month, local.day + dayDelta);
      _schedule = ReminderScheduleKind.custom;
      _allDay = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.log == null ? '+ Unutma' : 'Hatırlatıcı oluştur'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (widget.log != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Kaynak: ${widget.log!.description}',
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            if (_error != null)
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_error!, key: const Key('reminder-form-error')),
                ),
              ),
            TextFormField(
              key: const Key('reminder-title'),
              controller: _title,
              maxLength: 500,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Hatırlatıcı metni',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Hatırlatıcı metni zorunludur.'
                  : null,
            ),
            DropdownButtonFormField<ReminderKind>(
              key: const Key('reminder-kind'),
              initialValue: _kind,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Tür',
                border: OutlineInputBorder(),
              ),
              items: ReminderKind.values
                  .map(
                    (kind) =>
                        DropdownMenuItem(value: kind, child: Text(kind.label)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _kind = value!),
            ),
            const SizedBox(height: 12),
            if (widget.log == null && _projects.isNotEmpty) ...[
              DropdownButtonFormField<String?>(
                key: const Key('reminder-project'),
                initialValue: _projectId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Proje (opsiyonel)',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Kişisel / projesiz'),
                  ),
                  ..._projects.map(
                    (project) => DropdownMenuItem<String?>(
                      value: project.id,
                      child: Text(project.name),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _projectId = value),
              ),
              const SizedBox(height: 12),
            ],
            DropdownButtonFormField<ReminderScheduleKind>(
              key: const Key('reminder-schedule'),
              initialValue: _schedule,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Ne zaman?',
                border: OutlineInputBorder(),
              ),
              items: ReminderScheduleKind.values
                  .map(
                    (schedule) => DropdownMenuItem(
                      value: schedule,
                      child: Text(schedule.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() {
                _schedule = value!;
                _allDay = false;
              }),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  key: const Key('reminder-today'),
                  onPressed: () => _selectAllDay(0),
                  icon: const Icon(Icons.today_outlined),
                  label: const Text('Bugün'),
                ),
                OutlinedButton.icon(
                  key: const Key('reminder-all-day-tomorrow'),
                  onPressed: () => _selectAllDay(1),
                  icon: const Icon(Icons.event_outlined),
                  label: const Text('Yarın • Tam gün'),
                ),
              ],
            ),
            SwitchListTile(
              key: const Key('reminder-all-day'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Tam gün'),
              subtitle: const Text(
                'Saatli bildirim kurulmaz; seçilen gün Bugün’de görünür.',
              ),
              value: _allDay,
              onChanged: (value) => setState(() {
                _allDay = value;
                if (value) {
                  final local = CseTimeCodec.toIstanbul(
                    CseTimeCodec.encodeUtc(DateTime.now().toUtc()),
                  );
                  _customDate = DateTime(local.year, local.month, local.day);
                  _schedule = ReminderScheduleKind.custom;
                }
              }),
            ),
            if (_schedule == ReminderScheduleKind.custom || _allDay) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    key: const Key('reminder-custom-date'),
                    onPressed: () async {
                      final value = await showDatePicker(
                        context: context,
                        initialDate: _customDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (value != null) setState(() => _customDate = value);
                    },
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(
                      '${_customDate.day.toString().padLeft(2, '0')}.'
                      '${_customDate.month.toString().padLeft(2, '0')}.${_customDate.year}',
                    ),
                  ),
                  if (!_allDay)
                    OutlinedButton.icon(
                      key: const Key('reminder-custom-time'),
                      onPressed: () async {
                        final value = await showTimePicker(
                          context: context,
                          initialTime: _customTime,
                        );
                        if (value != null) setState(() => _customTime = value);
                      },
                      icon: const Icon(Icons.schedule),
                      label: Text(_customTime.format(context)),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            ExpansionTile(
              key: const Key('reminder-optional-details'),
              tilePadding: EdgeInsets.zero,
              title: const Text('İsteğe bağlı ayrıntılar'),
              children: [
                TextField(
                  key: const Key('reminder-description'),
                  controller: _description,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Açıklama',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('reminder-location'),
                  controller: _location,
                  decoration: const InputDecoration(
                    labelText: 'Mahál',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('reminder-related-person'),
                  controller: _relatedPerson,
                  decoration: const InputDecoration(
                    labelText: 'İlgili kişi',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('reminder-condition'),
                  controller: _condition,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Koşul/not',
                    border: OutlineInputBorder(),
                  ),
                ),
                SwitchListTile(
                  key: const Key('reminder-important'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Önemli'),
                  value: _isImportant,
                  onChanged: (value) => setState(() => _isImportant = value),
                ),
                SwitchListTile(
                  key: const Key('reminder-has-deadline'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Gerçek son tarih ekle'),
                  value: _hasDeadline,
                  onChanged: (value) => setState(() => _hasDeadline = value),
                ),
                if (_hasDeadline)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        key: const Key('reminder-deadline-date'),
                        onPressed: () async {
                          final value = await showDatePicker(
                            context: context,
                            initialDate: _deadlineDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (value != null) {
                            setState(() => _deadlineDate = value);
                          }
                        },
                        icon: const Icon(Icons.event_available_outlined),
                        label: Text(
                          '${_deadlineDate.day.toString().padLeft(2, '0')}.'
                          '${_deadlineDate.month.toString().padLeft(2, '0')}.'
                          '${_deadlineDate.year}',
                        ),
                      ),
                      OutlinedButton.icon(
                        key: const Key('reminder-deadline-time'),
                        onPressed: () async {
                          final value = await showTimePicker(
                            context: context,
                            initialTime: _deadlineTime,
                          );
                          if (value != null) {
                            setState(() => _deadlineTime = value);
                          }
                        },
                        icon: const Icon(Icons.schedule),
                        label: Text(_deadlineTime.format(context)),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                key: const Key('submit-reminder'),
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_alert_outlined),
                label: Text(
                  _submitting ? 'Oluşturuluyor…' : 'Hatırlatıcı oluştur',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
