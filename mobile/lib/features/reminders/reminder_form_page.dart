import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/core/record_id.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:flutter/material.dart';

class ReminderFormPage extends StatefulWidget {
  const ReminderFormPage({required this.agenda, required this.log, super.key});

  final AgendaApplication agenda;
  final AgendaLog log;

  @override
  State<ReminderFormPage> createState() => _ReminderFormPageState();
}

class _ReminderFormPageState extends State<ReminderFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final String _recordId;
  late final String _eventId;
  ReminderKind _kind = ReminderKind.action;
  ReminderScheduleKind _schedule = ReminderScheduleKind.in15Minutes;
  late DateTime _customDate;
  TimeOfDay _customTime = const TimeOfDay(hour: 9, minute: 0);
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.log.description);
    _recordId = RecordId.randomUuid();
    _eventId = RecordId.randomUuid();
    final local = CseTimeCodec.toIstanbul(
      CseTimeCodec.encodeUtc(DateTime.now().toUtc()),
    );
    _customDate = DateTime(local.year, local.month, local.day + 1);
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final custom = _schedule == ReminderScheduleKind.custom
          ? CseTimeCodec.canonicalFromIstanbulComponents(
              year: _customDate.year,
              month: _customDate.month,
              day: _customDate.day,
              hour: _customTime.hour,
              minute: _customTime.minute,
            )
          : null;
      final reminder = await widget.agenda.createReminder(
        CreateReminderCommand(
          id: _recordId,
          eventId: _eventId,
          projectId: widget.log.projectId,
          sourceLogId: widget.log.id,
          title: _title.text,
          kind: _kind,
          schedule: _schedule,
          customAttentionAt: custom,
        ),
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hatırlatıcı oluştur')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Kaynak: ${widget.log.description}',
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
              onChanged: (value) => setState(() => _schedule = value!),
            ),
            if (_schedule == ReminderScheduleKind.custom) ...[
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
