import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/application/attendance_application.dart';
import 'package:chief_site_engineer/core/record_id.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/attendance_models.dart';
import 'package:chief_site_engineer/features/reminders/reminder_detail_page.dart';
import 'package:chief_site_engineer/platform/attendance_export_gateway.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AttendanceDayPage extends StatefulWidget {
  const AttendanceDayPage({
    required this.attendance,
    required this.agenda,
    required this.dayId,
    super.key,
  });

  final AttendanceApplication attendance;
  final AgendaApplication agenda;
  final String dayId;

  @override
  State<AttendanceDayPage> createState() => _AttendanceDayPageState();
}

class _AttendanceDayPageState extends State<AttendanceDayPage> {
  AttendanceDayDetail? _detail;
  List<WorkforceMember> _members = const [];
  final Map<String, AttendanceResult?> _results = {};
  final Map<String, String> _entryIds = {};
  final Map<String, TextEditingController> _overtime = {};
  final Map<String, TextEditingController> _notes = {};
  final TextEditingController _generalNote = TextEditingController();
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  String _saveEventId = RecordId.randomUuid();
  String _bulkEventId = RecordId.randomUuid();
  String _dayEventId = RecordId.randomUuid();
  String _reminderEventId = RecordId.randomUuid();
  String _exportEventId = RecordId.randomUuid();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _disposeDraftControllers();
    _generalNote.dispose();
    super.dispose();
  }

  void _disposeDraftControllers() {
    for (final controller in _overtime.values) {
      controller.dispose();
    }
    for (final controller in _notes.values) {
      controller.dispose();
    }
    _overtime.clear();
    _notes.clear();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await widget.attendance.getDayDetail(widget.dayId);
      final members = await widget.attendance.listMembers(
        detail.day.projectId,
        includeInactive: true,
      );
      if (!mounted) return;
      _disposeDraftControllers();
      _results.clear();
      _entryIds.clear();
      final entryByMember = {
        for (final entry in detail.entries) entry.memberId: entry,
      };
      _members = members
          .where(
            (member) => member.isActive || entryByMember.containsKey(member.id),
          )
          .toList(growable: false);
      for (final member in _members) {
        final entry = entryByMember[member.id];
        _entryIds[member.id] = entry?.id ?? RecordId.randomUuid();
        _results[member.id] = entry?.result;
        _overtime[member.id] = TextEditingController(
          text: entry == null ? '0' : '${entry.overtimeMinutes}',
        );
        _notes[member.id] = TextEditingController(text: entry?.shortNote);
      }
      _generalNote.text = detail.day.generalNote ?? '';
      setState(() => _detail = detail);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _error = _message(error, 'Puantaj günü açılamadı.'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final detail = _detail;
    if (detail == null || _submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final values = <AttendanceRosterValue>[];
      for (final member in _members) {
        final result = _results[member.id];
        if (result == null) continue;
        final overtime = int.tryParse(_overtime[member.id]!.text.trim());
        if (overtime == null) {
          throw const AgendaValidationFailure(
            'Fazla mesai tam dakika olarak girilmelidir.',
          );
        }
        values.add(
          AttendanceRosterValue(
            entryId: _entryIds[member.id]!,
            memberId: member.id,
            result: result,
            overtimeMinutes: overtime,
            shortNote: _notes[member.id]!.text,
          ),
        );
      }
      await widget.attendance.saveRoster(
        SaveAttendanceRosterCommand(
          dayId: detail.day.id,
          eventId: _saveEventId,
          expectedRevision: detail.day.revision,
          values: values,
          replaceGeneralNote: true,
          generalNote: _generalNote.text,
        ),
      );
      _saveEventId = RecordId.randomUuid();
      await _load();
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _error = _message(error, 'Taslak kaydedilemedi.'));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _markFull([String? team]) async {
    final detail = _detail;
    if (detail == null || _submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.attendance.markFullDay(
        MarkAttendanceFullCommand(
          dayId: detail.day.id,
          eventId: _bulkEventId,
          expectedRevision: detail.day.revision,
          entryIdsByMember: _entryIds,
          teamName: team,
        ),
      );
      _bulkEventId = RecordId.randomUuid();
      await _load();
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _error = _message(error, 'Hızlı işlem uygulanamadı.'));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _pickTeam() async {
    final teams =
        _members
            .where((member) => member.isActive)
            .map((member) => member.teamName)
            .toSet()
            .toList()
          ..sort(
            (left, right) => left.toLowerCase().compareTo(right.toLowerCase()),
          );
    if (teams.isEmpty) return;
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(12),
          children: [
            const ListTile(
              title: Text(
                'Tam gün işaretlenecek ekip',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            ...teams.map(
              (team) => ListTile(
                key: Key('mark-team-full-$team'),
                title: Text(team),
                minVerticalPadding: 12,
                onTap: () => Navigator.pop(context, team),
              ),
            ),
          ],
        ),
      ),
    );
    if (selected != null) await _markFull(selected);
  }

  Future<void> _transition(AttendanceTransition transition) async {
    final detail = _detail;
    if (detail == null || _submitting) return;
    final label = switch (transition) {
      AttendanceTransition.complete => 'Günü tamamla',
      AttendanceTransition.noWork => 'Bugün çalışma yok',
      AttendanceTransition.reopen => 'Günü yeniden aç',
    };
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(label),
        content: Text(
          transition == AttendanceTransition.reopen
              ? 'Önceki sonuç event geçmişinde kalacak ve gün yeniden düzenlenebilecek.'
              : 'Bu durumdan sonra değişiklik için açıkça yeniden açma gerekir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            key: const Key('confirm-attendance-transition'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Onayla'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.attendance.transitionDay(
        TransitionAttendanceDayCommand(
          dayId: detail.day.id,
          dayEventId: _dayEventId,
          reminderEventId: _reminderEventId,
          expectedRevision: detail.day.revision,
          transition: transition,
        ),
      );
      _dayEventId = RecordId.randomUuid();
      _reminderEventId = RecordId.randomUuid();
      await _load();
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _error = _message(error, '$label işlemi başarısız.'));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _export({required bool share}) async {
    final detail = _detail;
    if (detail == null || _submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final result = await widget.attendance.exportDay(
        ExportAttendanceDayCommand(
          dayId: detail.day.id,
          eventId: _exportEventId,
          expectedRevision: detail.day.revision,
        ),
        share: share,
      );
      _exportEventId = RecordId.randomUuid();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${result.fileName} güvenli biçimde oluşturuldu.'),
        ),
      );
      await _load();
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _error = _message(error, 'CSV oluşturulamadı.'));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _copySummary() async {
    final detail = _detail;
    if (detail == null) return;
    await Clipboard.setData(
      ClipboardData(text: AttendanceCsvFormatter.humanSummary(detail)),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Günlük özet panoya kopyalandı.')),
    );
  }

  Future<void> _remove(AttendanceEntry entry) async {
    final detail = _detail;
    if (detail == null || _submitting) return;
    setState(() => _submitting = true);
    try {
      await widget.attendance.removeEntry(
        RemoveAttendanceEntryCommand(
          dayId: detail.day.id,
          entryId: entry.id,
          eventId: RecordId.randomUuid(),
          expectedRevision: detail.day.revision,
        ),
      );
      await _load();
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _error = _message(error, 'Entry kaldırılamadı.'));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
    return Scaffold(
      appBar: AppBar(title: const Text('Günlük Puantaj')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : detail == null
            ? Center(child: Text(_error ?? 'Puantaj günü bulunamadı.'))
            : ListView(
                key: const Key('attendance-day-detail'),
                padding: const EdgeInsets.all(12),
                children: [
                  _DayHeader(detail: detail),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        _error!,
                        key: const Key('attendance-day-error'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  if (detail.linkedReminder case final reminder?)
                    Card(
                      child: ListTile(
                        key: const Key('attendance-linked-reminder'),
                        minVerticalPadding: 12,
                        leading: const Icon(Icons.notifications_outlined),
                        title: Text(reminder.title),
                        subtitle: Text(reminder.status.label),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push<void>(
                          MaterialPageRoute(
                            builder: (_) => ReminderDetailPage(
                              agenda: widget.agenda,
                              attendance: widget.attendance,
                              reminderId: reminder.id,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (detail.day.status == AttendanceDayStatus.draft) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          key: const Key('mark-all-full'),
                          onPressed: _submitting ? null : _markFull,
                          icon: const Icon(Icons.done_all_outlined),
                          label: const Text('Tümünü tam gün'),
                        ),
                        OutlinedButton.icon(
                          key: const Key('mark-team-full'),
                          onPressed: _submitting ? null : _pickTeam,
                          icon: const Icon(Icons.groups_outlined),
                          label: const Text('Ekibi tam gün'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_members.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Aktif personel yok. Önce proje personeli ekleyin.',
                          ),
                        ),
                      )
                    else
                      ..._buildTeamSections(detail),
                    TextField(
                      key: const Key('attendance-general-note'),
                      controller: _generalNote,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Günlük genel not',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      key: const Key('save-attendance-draft'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      onPressed: _submitting ? null : _save,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Taslak kaydet'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            key: const Key('attendance-no-work'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                            ),
                            onPressed: _submitting
                                ? null
                                : () =>
                                      _transition(AttendanceTransition.noWork),
                            child: const Text('Çalışma yok'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton(
                            key: const Key('complete-attendance-day'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                            ),
                            onPressed: _submitting
                                ? null
                                : () => _transition(
                                    AttendanceTransition.complete,
                                  ),
                            child: const Text('Günü tamamla'),
                          ),
                        ),
                      ],
                    ),
                  ] else
                    FilledButton.icon(
                      key: const Key('reopen-attendance-day'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      onPressed: _submitting
                          ? null
                          : () => _transition(AttendanceTransition.reopen),
                      icon: const Icon(Icons.lock_open_outlined),
                      label: const Text('Günü yeniden aç'),
                    ),
                  const SizedBox(height: 16),
                  _SummaryCard(detail: detail),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        key: const Key('save-attendance-csv'),
                        onPressed: _submitting
                            ? null
                            : () => _export(share: false),
                        icon: const Icon(Icons.download_outlined),
                        label: const Text('CSV kaydet'),
                      ),
                      OutlinedButton.icon(
                        key: const Key('share-attendance-csv'),
                        onPressed: _submitting
                            ? null
                            : () => _export(share: true),
                        icon: const Icon(Icons.share_outlined),
                        label: const Text('CSV paylaş'),
                      ),
                      OutlinedButton.icon(
                        key: const Key('copy-attendance-summary'),
                        onPressed: _copySummary,
                        icon: const Icon(Icons.content_copy_outlined),
                        label: const Text('Özeti kopyala'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ExpansionTile(
                    key: const Key('attendance-event-history'),
                    title: Text('Değişiklik geçmişi (${detail.events.length})'),
                    children: detail.events
                        .map(
                          (event) => ListTile(
                            title: Text(event.eventType),
                            subtitle: Text(
                              '#${event.sequence} • '
                              '${CseTimeCodec.formatIstanbul(event.occurredAt)}',
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ],
              ),
      ),
    );
  }

  List<Widget> _buildTeamSections(AttendanceDayDetail detail) {
    final entryByMember = {
      for (final entry in detail.entries) entry.memberId: entry,
    };
    final groups = <String, List<WorkforceMember>>{};
    for (final member in _members) {
      groups.putIfAbsent(member.teamName, () => []).add(member);
    }
    return groups.entries
        .expand((group) {
          return <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
              child: Text(
                group.key,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ...group.value.map(
              (member) => _MemberAttendanceCard(
                member: member,
                result: _results[member.id],
                overtime: _overtime[member.id]!,
                note: _notes[member.id]!,
                hasPersistedEntry: entryByMember.containsKey(member.id),
                onResultChanged: (value) {
                  setState(() {
                    _results[member.id] = value;
                    if (value == AttendanceResult.absent ||
                        value == AttendanceResult.leave) {
                      _overtime[member.id]!.text = '0';
                    }
                  });
                },
                onRemove: entryByMember[member.id] == null
                    ? null
                    : () => _remove(entryByMember[member.id]!),
              ),
            ),
          ];
        })
        .toList(growable: false);
  }

  String _message(Object error, String fallback) =>
      error is AgendaValidationFailure ? error.message : fallback;
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.detail});

  final AttendanceDayDetail detail;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              detail.day.projectName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text('${detail.day.localDate} • ${detail.day.status.label}'),
            Text('Revision ${detail.day.revision}'),
            if (detail.day.generalNote != null) ...[
              const SizedBox(height: 4),
              Text(detail.day.generalNote!),
            ],
          ],
        ),
      ),
    );
  }
}

class _MemberAttendanceCard extends StatelessWidget {
  const _MemberAttendanceCard({
    required this.member,
    required this.result,
    required this.overtime,
    required this.note,
    required this.hasPersistedEntry,
    required this.onResultChanged,
    required this.onRemove,
  });

  final WorkforceMember member;
  final AttendanceResult? result;
  final TextEditingController overtime;
  final TextEditingController note;
  final bool hasPersistedEntry;
  final ValueChanged<AttendanceResult?> onResultChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: Key('attendance-member-${member.id}'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${member.fullName}${member.isActive ? '' : ' (pasif)'}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                if (hasPersistedEntry)
                  IconButton(
                    key: Key('remove-attendance-${member.id}'),
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    tooltip: 'Kaydı kaldır',
                    onPressed: onRemove,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
              ],
            ),
            Text(member.roleName),
            const SizedBox(height: 8),
            DropdownButtonFormField<AttendanceResult?>(
              key: Key('attendance-result-${member.id}'),
              initialValue: result,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Çalışma sonucu',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<AttendanceResult?>(
                  value: null,
                  child: Text('Kayıt yok'),
                ),
                ...AttendanceResult.values.map(
                  (value) => DropdownMenuItem<AttendanceResult?>(
                    value: value,
                    child: Text(value.label),
                  ),
                ),
              ],
              onChanged: onResultChanged,
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 104,
                  child: TextField(
                    key: Key('attendance-overtime-${member.id}'),
                    controller: overtime,
                    enabled:
                        result != AttendanceResult.absent &&
                        result != AttendanceResult.leave,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'FM dk',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    key: Key('attendance-note-${member.id}'),
                    controller: note,
                    decoration: const InputDecoration(
                      labelText: 'Kısa not',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.detail});

  final AttendanceDayDetail detail;

  @override
  Widget build(BuildContext context) {
    final totals = detail.totals;
    return Card(
      key: const Key('attendance-summary'),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Günlük özet', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              'Tam gün ${totals.fullDayCount} • '
              'Yarım gün ${totals.halfDayCount} • '
              'Gelmedi ${totals.absentCount} • İzinli ${totals.leaveCount}',
            ),
            Text(
              'Sahada ${totals.presentCount} • '
              '${totals.personDayEquivalent.toStringAsFixed(1)} kişi-gün',
            ),
            Text(
              'Fazla mesai ${totals.overtimeMinutes} dk '
              '(${(totals.overtimeMinutes / 60).toStringAsFixed(2)} saat)',
            ),
            if (detail.teamSummaries.isNotEmpty) ...[
              const Divider(),
              ...detail.teamSummaries.map(
                (team) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${team.teamName}: '
                    '${team.totals.personDayEquivalent.toStringAsFixed(1)} kişi-gün, '
                    '${team.totals.overtimeMinutes} dk FM',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
