import 'package:chief_site_engineer/application/attendance_application.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/attendance_models.dart';
import 'package:flutter/material.dart';

class AttendanceSettingsPage extends StatefulWidget {
  const AttendanceSettingsPage({
    required this.attendance,
    required this.project,
    super.key,
  });

  final AttendanceApplication attendance;
  final MobileProject project;

  @override
  State<AttendanceSettingsPage> createState() => _AttendanceSettingsPageState();
}

class _AttendanceSettingsPageState extends State<AttendanceSettingsPage> {
  static const _weekdayLabels = <int, String>{
    1: 'Pzt',
    2: 'Sal',
    3: 'Çar',
    4: 'Per',
    5: 'Cum',
    6: 'Cmt',
    7: 'Paz',
  };

  AttendanceReminderSetting? _setting;
  bool _enabled = false;
  TimeOfDay _time = const TimeOfDay(hour: 17, minute: 0);
  Set<int> _weekdays = {1, 2, 3, 4, 5, 6};
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final setting = await widget.attendance.getReminderSetting(
        widget.project.id,
      );
      final parts = setting.localTime.split(':').map(int.parse).toList();
      if (!mounted) return;
      setState(() {
        _setting = setting;
        _enabled = setting.isEnabled;
        _time = TimeOfDay(hour: parts[0], minute: parts[1]);
        _weekdays = {...setting.selectedWeekdays};
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(
        () => _error = error is AgendaValidationFailure
            ? error.message
            : 'Puantaj hatırlatıcı ayarı açılamadı.',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(context: context, initialTime: _time);
    if (selected != null) setState(() => _time = selected);
  }

  Future<void> _save() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final value = await widget.attendance.saveReminderSetting(
        SaveAttendanceReminderSettingCommand(
          projectId: widget.project.id,
          expectedRevision: _setting?.revision ?? 0,
          isEnabled: _enabled,
          localTime:
              '${_time.hour.toString().padLeft(2, '0')}:'
              '${_time.minute.toString().padLeft(2, '0')}',
          selectedWeekdays: _weekdays,
        ),
      );
      if (mounted) Navigator.pop(context, value);
    } on Object catch (error) {
      if (!mounted) return;
      setState(
        () => _error = error is AgendaValidationFailure
            ? error.message
            : 'Puantaj hatırlatıcı ayarı kaydedilemedi.',
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Puantaj hatırlatıcısı')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                key: const Key('attendance-settings'),
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    widget.project.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Hatırlatıcılar Europe/Istanbul saatine göre önümüzdeki '
                    '14 çalışma günü için güvenli biçimde hazırlanır.',
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    key: const Key('attendance-reminder-enabled'),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Puantaj hatırlatıcısı etkin'),
                    value: _enabled,
                    onChanged: (value) => setState(() => _enabled = value),
                  ),
                  ListTile(
                    key: const Key('attendance-reminder-time'),
                    contentPadding: EdgeInsets.zero,
                    minVerticalPadding: 12,
                    title: const Text('Yerel hatırlatma saati'),
                    subtitle: Text(_time.format(context)),
                    trailing: const Icon(Icons.schedule_outlined),
                    onTap: _pickTime,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Çalışma günleri',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _weekdayLabels.entries
                        .map(
                          (entry) => FilterChip(
                            key: Key('attendance-weekday-${entry.key}'),
                            label: Text(entry.value),
                            selected: _weekdays.contains(entry.key),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _weekdays.add(entry.key);
                                } else {
                                  _weekdays.remove(entry.key);
                                }
                              });
                            },
                          ),
                        )
                        .toList(growable: false),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      key: const Key('attendance-settings-error'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    key: const Key('save-attendance-settings'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: _submitting ? null : _save,
                    icon: _submitting
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: const Text('Ayarı kaydet'),
                  ),
                ],
              ),
      ),
    );
  }
}
