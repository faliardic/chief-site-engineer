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
  List<WorkforceMember> _allMembers = const [];
  List<WorkforceMember> _members = const [];
  List<Subcontractor> _subcontractors = const [];
  List<WorkforceTeam> _teams = const [];
  final Map<String, AttendanceResult?> _results = {};
  final Map<String, String> _entryIds = {};
  final Map<String, TextEditingController> _overtime = {};
  final Map<String, TextEditingController> _notes = {};
  final TextEditingController _generalNote = TextEditingController();
  bool _loading = true;
  bool _registryLoading = false;
  bool _submitting = false;
  bool _showNewMemberWarning = false;
  String? _selectedSubcontractorId;
  String? _selectedTeamId;
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
      final subcontractors = await widget.attendance.listSubcontractors(
        detail.day.projectId,
      );
      final selectedSubcontractorId =
          subcontractors.any((item) => item.id == _selectedSubcontractorId)
          ? _selectedSubcontractorId
          : null;
      final teams = selectedSubcontractorId == null
          ? const <WorkforceTeam>[]
          : await widget.attendance.listTeams(
              detail.day.projectId,
              subcontractorId: selectedSubcontractorId,
            );
      final selectedTeamId = teams.any((item) => item.id == _selectedTeamId)
          ? _selectedTeamId
          : null;
      if (!mounted) return;
      _disposeDraftControllers();
      _results.clear();
      _entryIds.clear();
      final entryByMember = {
        for (final entry in detail.entries) entry.memberId: entry,
      };
      _allMembers = members;
      _members = members
          .where((member) => entryByMember.containsKey(member.id))
          .toList(growable: false);
      _subcontractors = subcontractors;
      _teams = teams;
      _selectedSubcontractorId = selectedSubcontractorId;
      _selectedTeamId = selectedTeamId;
      for (final member in members.where(
        (item) => item.isActive || entryByMember.containsKey(item.id),
      )) {
        _entryIds[member.id] =
            entryByMember[member.id]?.id ?? RecordId.randomUuid();
      }
      for (final member in _members) {
        final entry = entryByMember[member.id];
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
      setState(() => _error = _message(error, 'Puantaj kaydedilemedi.'));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _markFull([String? teamId]) async {
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
          teamId: teamId,
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
    final byId = <String, WorkforceMember>{};
    for (final member in _allMembers.where((item) => item.isActive)) {
      byId.putIfAbsent(member.teamId ?? member.teamName, () => member);
    }
    final teams = byId.entries.toList()
      ..sort((left, right) {
        final subcontractor = (left.value.subcontractorName ?? '')
            .toLowerCase()
            .compareTo((right.value.subcontractorName ?? '').toLowerCase());
        if (subcontractor != 0) return subcontractor;
        return left.value.teamName.toLowerCase().compareTo(
          right.value.teamName.toLowerCase(),
        );
      });
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
                key: Key('mark-team-full-${team.key}'),
                title: Text(team.value.teamName),
                subtitle: Text(
                  team.value.subcontractorName ?? 'Tanımsız taşeron',
                ),
                minVerticalPadding: 12,
                onTap: () => Navigator.pop(context, team.key),
              ),
            ),
          ],
        ),
      ),
    );
    if (selected != null) await _markFull(selected);
  }

  List<WorkforceMember> get _candidateMembers {
    final subcontractorId = _selectedSubcontractorId;
    if (subcontractorId == null || _registryLoading) return const [];
    final activeTeamIds = _teams.map((item) => item.id).toSet();
    final selectedIds = _members.map((item) => item.id).toSet();
    return _allMembers
        .where(
          (member) =>
              member.isActive &&
              member.subcontractorId == subcontractorId &&
              member.teamId != null &&
              activeTeamIds.contains(member.teamId) &&
              (_selectedTeamId == null || member.teamId == _selectedTeamId) &&
              !selectedIds.contains(member.id),
        )
        .toList(growable: false);
  }

  Future<void> _selectSubcontractor(String? value) async {
    final detail = _detail;
    if (detail == null || value == _selectedSubcontractorId) return;
    setState(() {
      _selectedSubcontractorId = value;
      _selectedTeamId = null;
      _teams = const [];
      _registryLoading = value != null;
      _error = null;
    });
    if (value == null) return;
    try {
      final teams = await widget.attendance.listTeams(
        detail.day.projectId,
        subcontractorId: value,
      );
      if (!mounted || _selectedSubcontractorId != value) return;
      setState(() {
        _teams = teams;
        _registryLoading = false;
      });
    } on Object catch (error) {
      if (!mounted || _selectedSubcontractorId != value) return;
      setState(() {
        _registryLoading = false;
        _error = _message(error, 'Aktif ekipler açılamadı.');
      });
    }
  }

  void _addDraftMember(WorkforceMember member) {
    if (_members.any((item) => item.id == member.id)) return;
    setState(() {
      _members = [..._members, member];
      _entryIds.putIfAbsent(member.id, RecordId.randomUuid);
      _results[member.id] = AttendanceResult.fullDay;
      _overtime[member.id] = TextEditingController(text: '0');
      _notes[member.id] = TextEditingController();
    });
  }

  void _discardDraftMember(WorkforceMember member) {
    final hasPersistedEntry =
        _detail?.entries.any((entry) => entry.memberId == member.id) ?? false;
    if (hasPersistedEntry) return;
    setState(() {
      _members = _members
          .where((item) => item.id != member.id)
          .toList(growable: false);
      _results.remove(member.id);
      _overtime.remove(member.id)?.dispose();
      _notes.remove(member.id)?.dispose();
    });
  }

  Future<void> _createInlineMember() async {
    final detail = _detail;
    final subcontractorId = _selectedSubcontractorId;
    final subcontractor = _subcontractors
        .where((item) => item.id == subcontractorId)
        .firstOrNull;
    if (detail == null || subcontractor == null || _submitting) return;
    if (_teams.isEmpty) {
      setState(
        () => _error =
            'Bu taşeronun aktif ekibi yok. Önce Sicil’den aktif ekip oluşturun.',
      );
      return;
    }
    final member = await showModalBottomSheet<WorkforceMember>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _InlineWorkforceMemberSheet(
        attendance: widget.attendance,
        projectId: detail.day.projectId,
        subcontractor: subcontractor,
        teams: _teams,
      ),
    );
    if (!mounted || member == null) return;
    setState(() {
      _allMembers = [
        ..._allMembers.where((item) => item.id != member.id),
        member,
      ];
      _showNewMemberWarning = true;
      _error = null;
    });
    _addDraftMember(member);
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
      setState(() => _error = _message(error, 'Puantaj kaydı kaldırılamadı.'));
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
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 840),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                leading: const Icon(
                                  Icons.notifications_outlined,
                                ),
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
                          if (detail.day.status ==
                              AttendanceDayStatus.draft) ...[
                            if (_showNewMemberWarning)
                              Card(
                                key: const Key('attendance-new-member-warning'),
                                color: Theme.of(
                                  context,
                                ).colorScheme.secondaryContainer,
                                child: const ListTile(
                                  leading: Icon(Icons.info_outline),
                                  title: Text(
                                    'Yeni personel Sicil’e kaydedildi',
                                  ),
                                  subtitle: Text(
                                    'SGK işe giriş ve İSG/OSGB kayıtlarını Sicil’den '
                                    'kontrol edin. CSE resmi uygunluk kararı vermez; '
                                    'yalnız saha kaydı ve görünürlük sağlar.',
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  key: const Key('mark-all-full'),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(48, 48),
                                  ),
                                  onPressed: _submitting ? null : _markFull,
                                  icon: const Icon(Icons.done_all_outlined),
                                  label: const Text('Tümünü tam gün'),
                                ),
                                OutlinedButton.icon(
                                  key: const Key('mark-team-full'),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(48, 48),
                                  ),
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
                                    'Bu gün için seçilmiş personel yok. Personel ekle '
                                    'alanından İşveren ve personel seçin.',
                                  ),
                                ),
                              )
                            else
                              ..._buildTeamSections(detail),
                            Card(
                              child: ExpansionTile(
                                key: const Key('attendance-add-people'),
                                initiallyExpanded: _members.isEmpty,
                                maintainState: true,
                                title: const Text('Personel ekle'),
                                children: [_buildRosterSelector()],
                              ),
                            ),
                            const SizedBox(height: 12),
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
                              label: const Text('Kaydet'),
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
                                        : () => _transition(
                                            AttendanceTransition.noWork,
                                          ),
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
                                  : () => _transition(
                                      AttendanceTransition.reopen,
                                    ),
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
                            title: Text(
                              'Değişiklik geçmişi (${detail.events.length})',
                            ),
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
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildRosterSelector() {
    const allTeams = '__all-active-teams__';
    final subcontractorId = _selectedSubcontractorId;
    final candidates = _candidateMembers;
    return Card(
      key: const Key('attendance-roster-selector'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personel seçimi',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            const Text(
              'Önce İşveren seçin; yalnız o işverenin aktif personelleri '
              'aday olarak gösterilir.',
            ),
            const SizedBox(height: 12),
            KeyedSubtree(
              key: const Key('attendance-subcontractor-selector'),
              child: DropdownButtonFormField<String>(
                key: ValueKey('attendance-subcontractor-$subcontractorId'),
                initialValue: subcontractorId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'İşveren seç *',
                  border: OutlineInputBorder(),
                ),
                items: _subcontractors
                    .map(
                      (item) => DropdownMenuItem(
                        value: item.id,
                        child: Text(item.name),
                      ),
                    )
                    .toList(growable: false),
                onChanged: _submitting ? null : _selectSubcontractor,
              ),
            ),
            if (_subcontractors.isEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Aktif işveren yok. Önce Sicil’den işveren ve ekip oluşturun.',
              ),
            ],
            if (subcontractorId != null) ...[
              const SizedBox(height: 12),
              if (_registryLoading)
                const LinearProgressIndicator(
                  key: Key('attendance-registry-loading'),
                )
              else ...[
                KeyedSubtree(
                  key: const Key('attendance-team-filter'),
                  child: DropdownButtonFormField<String>(
                    key: ValueKey(
                      'attendance-team-$subcontractorId-${_selectedTeamId ?? allTeams}',
                    ),
                    initialValue: _selectedTeamId ?? allTeams,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Ekip filtresi',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: allTeams,
                        child: Text('Tüm aktif ekipler'),
                      ),
                      ..._teams.map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(item.name),
                        ),
                      ),
                    ],
                    onChanged: _submitting
                        ? null
                        : (value) => setState(
                            () => _selectedTeamId = value == allTeams
                                ? null
                                : value,
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                if (_teams.isEmpty)
                  const Text(
                    'Bu işverenin aktif ekibi yok. Yeni personel için önce '
                    'Sicil’den aktif ekip oluşturun.',
                    key: Key('attendance-no-active-team'),
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    key: const Key('attendance-new-member'),
                    onPressed: _submitting || _teams.isEmpty
                        ? null
                        : _createInlineMember,
                    icon: const Icon(Icons.person_add_alt_1_outlined),
                    label: const Text('+ Yeni eleman'),
                  ),
                ),
                if (_teams.isNotEmpty) ...[
                  const Divider(),
                  Text(
                    'Aday personeller (${candidates.length})',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  if (candidates.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Bu filtrede rostere eklenebilecek aktif personel yok.',
                      ),
                    )
                  else
                    ...candidates.map(
                      (member) => ListTile(
                        key: Key('attendance-candidate-${member.id}'),
                        contentPadding: EdgeInsets.zero,
                        title: Text(member.fullName),
                        subtitle: Text(
                          '${member.teamName} • ${member.roleName}'
                          '${member.phone == null ? '' : ' • ${member.phone}'}',
                        ),
                        trailing: IconButton(
                          key: Key('add-attendance-member-${member.id}'),
                          tooltip: 'Rostere ekle',
                          onPressed: _submitting
                              ? null
                              : () => _addDraftMember(member),
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ),
                    ),
                ],
              ],
            ],
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
      groups
          .putIfAbsent(member.teamId ?? member.teamName, () => [])
          .add(member);
    }
    return groups.entries
        .expand((group) {
          return <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
              child: Text(
                '${group.value.first.teamName} — '
                '${group.value.first.subcontractorName ?? 'Tanımsız taşeron'}',
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
                    ? () => _discardDraftMember(member)
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

class _InlineWorkforceMemberSheet extends StatefulWidget {
  const _InlineWorkforceMemberSheet({
    required this.attendance,
    required this.projectId,
    required this.subcontractor,
    required this.teams,
  });

  final AttendanceApplication attendance;
  final String projectId;
  final Subcontractor subcontractor;
  final List<WorkforceTeam> teams;

  @override
  State<_InlineWorkforceMemberSheet> createState() =>
      _InlineWorkforceMemberSheetState();
}

class _InlineWorkforceMemberSheetState
    extends State<_InlineWorkforceMemberSheet> {
  late final String _memberId;
  late final String _eventId;
  final TextEditingController _name = TextEditingController();
  final TextEditingController _role = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _personnelCode = TextEditingController();
  String? _teamId;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _memberId = RecordId.randomUuid();
    _eventId = RecordId.randomUuid();
    if (widget.teams.length == 1) _teamId = widget.teams.single.id;
  }

  @override
  void dispose() {
    _name.dispose();
    _role.dispose();
    _phone.dispose();
    _personnelCode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final team = widget.teams.where((item) => item.id == _teamId).firstOrNull;
    if (team == null) {
      setState(() => _error = 'Aktif ekip seçilmelidir.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final member = await widget.attendance.createMember(
        CreateWorkforceMemberCommand(
          id: _memberId,
          eventId: _eventId,
          projectId: widget.projectId,
          subcontractorId: widget.subcontractor.id,
          teamId: team.id,
          fullName: _name.text,
          teamName: team.name,
          roleName: _role.text,
          phone: _phone.text,
          personnelCode: _personnelCode.text,
        ),
      );
      if (mounted) Navigator.pop(context, member);
    } on Object catch (error) {
      if (!mounted) return;
      setState(
        () => _error = error is AgendaValidationFailure
            ? error.message
            : 'Personel oluşturulamadı.',
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        top: 16,
        right: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: SingleChildScrollView(
        key: const Key('attendance-inline-member-form'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '+ Yeni eleman',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text('İşveren: ${widget.subcontractor.name}'),
            const SizedBox(height: 12),
            if (_error case final error?) ...[
              Text(
                error,
                key: const Key('attendance-inline-member-error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 12),
            ],
            DropdownButtonFormField<String>(
              key: const Key('attendance-inline-member-team'),
              initialValue: _teamId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Ekip *',
                border: OutlineInputBorder(),
              ),
              items: widget.teams
                  .map(
                    (item) => DropdownMenuItem(
                      value: item.id,
                      child: Text(item.name),
                    ),
                  )
                  .toList(growable: false),
              onChanged: _submitting
                  ? null
                  : (value) => setState(() => _teamId = value),
            ),
            const SizedBox(height: 12),
            _inlineField(
              key: const Key('attendance-inline-member-name'),
              controller: _name,
              label: 'Ad soyad *',
            ),
            const SizedBox(height: 12),
            _inlineField(
              key: const Key('attendance-inline-member-role'),
              controller: _role,
              label: 'Görev/meslek *',
            ),
            const SizedBox(height: 12),
            _inlineField(
              key: const Key('attendance-inline-member-phone'),
              controller: _phone,
              label: 'Telefon (opsiyonel)',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            _inlineField(
              key: const Key('attendance-inline-member-code'),
              controller: _personnelCode,
              label: 'Personel kodu (opsiyonel)',
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _submitting
                        ? null
                        : () => Navigator.pop(context),
                    child: const Text('Vazgeç'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    key: const Key('save-attendance-inline-member'),
                    onPressed: _submitting ? null : _submit,
                    icon: _submitting
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.person_add_alt_1_outlined),
                    label: const Text('Oluştur'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  TextField _inlineField({
    required Key key,
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
  }) => TextField(
    key: key,
    controller: controller,
    keyboardType: keyboardType,
    textInputAction: TextInputAction.next,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
  );
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
            Text('Revizyon ${detail.day.revision}'),
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
                if (onRemove != null)
                  IconButton(
                    key: Key('remove-attendance-${member.id}'),
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    tooltip: hasPersistedEntry
                        ? 'Kaydı kaldır'
                        : 'Taslak seçimden çıkar',
                    onPressed: onRemove,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
              ],
            ),
            Text(
              '${member.subcontractorName ?? 'Tanımsız taşeron'} • '
              '${member.teamName}',
            ),
            Text(
              '${member.roleName}'
              '${member.phone == null ? '' : ' • ${member.phone}'}',
            ),
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
            ExpansionTile(
              key: Key('attendance-member-details-${member.id}'),
              maintainState: true,
              tilePadding: EdgeInsets.zero,
              title: const Text('FM ve not'),
              childrenPadding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                TextField(
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
                const SizedBox(height: 12),
                TextField(
                  key: Key('attendance-note-${member.id}'),
                  controller: note,
                  decoration: const InputDecoration(
                    labelText: 'Kısa not',
                    border: OutlineInputBorder(),
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
