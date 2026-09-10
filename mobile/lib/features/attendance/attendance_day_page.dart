import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/application/attendance_application.dart';
import 'package:chief_site_engineer/core/record_id.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/attendance_models.dart';
import 'package:chief_site_engineer/features/attendance/workforce_directory_page.dart';
import 'package:chief_site_engineer/features/attendance/workforce_page.dart';
import 'package:chief_site_engineer/features/reminders/reminder_detail_page.dart';
import 'package:chief_site_engineer/platform/attendance_export_gateway.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AttendanceDayPage extends StatefulWidget {
  const AttendanceDayPage({
    required this.attendance,
    required this.agenda,
    required this.dayId,
    this.project,
    super.key,
  });

  final AttendanceApplication attendance;
  final AgendaApplication agenda;
  final String dayId;
  final MobileProject? project;

  @override
  State<AttendanceDayPage> createState() => _AttendanceDayPageState();
}

class _AttendanceDayPageState extends State<AttendanceDayPage> {
  AttendanceDayDetail? _detail;
  List<WorkforceMember> _allMembers = const [];
  List<WorkforceMember> _members = const [];
  List<Subcontractor> _subcontractors = const [];
  final Map<String, AttendanceResult?> _results = {};
  final Map<String, String> _entryIds = {};
  final Map<String, TextEditingController> _overtime = {};
  final Map<String, TextEditingController> _notes = {};
  final TextEditingController _generalNote = TextEditingController();
  bool _loading = true;
  bool _submitting = false;
  bool _showNewMemberWarning = false;
  String? _error;
  String _saveEventId = RecordId.randomUuid();
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
      if (!mounted) return;
      _disposeDraftControllers();
      _results.clear();
      _entryIds.clear();
      final entryByMember = {
        for (final entry in detail.entries) entry.memberId: entry,
      };
      final visibleMembers =
          members
              .where(
                (member) =>
                    member.isActive || entryByMember.containsKey(member.id),
              )
              .toList(growable: false)
            ..sort(_compareMembers);
      _allMembers = List.of(members)..sort(_compareMembers);
      _members = visibleMembers;
      _subcontractors = subcontractors;
      for (final member in members.where(
        (item) => item.isActive || entryByMember.containsKey(item.id),
      )) {
        _entryIds[member.id] =
            entryByMember[member.id]?.id ?? RecordId.randomUuid();
      }
      for (final member in visibleMembers) {
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
      await _saveCurrentDraft(detail);
      await _load();
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _error = _message(error, 'Puantaj kaydedilemedi.'));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<AttendanceDayDetail> _saveCurrentDraft(
    AttendanceDayDetail detail,
  ) async {
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
    final saved = await widget.attendance.saveRoster(
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
    return saved;
  }

  void _markDraftFull([String? teamId]) {
    if (_submitting) return;
    setState(() {
      for (final member in _members) {
        if (!member.isActive) continue;
        if (teamId != null && member.teamId != teamId) continue;
        _results[member.id] = AttendanceResult.fullDay;
      }
    });
  }

  Future<void> _pickTeam() async {
    final byId = <String, WorkforceMember>{};
    for (final member in _allMembers.where((item) => item.isActive)) {
      if (_usesTechnicalTeam(member)) continue;
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
    if (selected != null) _markDraftFull(selected);
  }

  Future<MobileProject> _currentProject(String projectId) async {
    final supplied = widget.project;
    if (supplied != null && supplied.id == projectId) return supplied;
    final projects = await widget.agenda.listProjects();
    final project = projects
        .where(
          (candidate) => candidate.id == projectId && !candidate.isArchived,
        )
        .firstOrNull;
    if (project == null) {
      throw const AgendaValidationFailure('Aktif proje artık kullanılamıyor.');
    }
    return project;
  }

  Future<void> _openEmptyWorkforceAction() async {
    final detail = _detail;
    if (detail == null || _submitting) return;
    try {
      final project = await _currentProject(detail.day.projectId);
      if (!mounted) return;
      var createdMember = false;
      if (_subcontractors.isEmpty) {
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(title: const Text('Sicil')),
              body: WorkforceDirectoryPage(
                attendance: widget.attendance,
                agenda: widget.agenda,
                initialProjectId: project.id,
              ),
            ),
          ),
        );
      } else {
        createdMember =
            await Navigator.of(context).push<WorkforceMember>(
              MaterialPageRoute(
                builder: (_) => WorkforceMemberFormPage(
                  attendance: widget.attendance,
                  project: project,
                  initialSubcontractorId: _subcontractors.length == 1
                      ? _subcontractors.single.id
                      : null,
                ),
              ),
            ) !=
            null;
      }
      if (mounted) {
        if (createdMember) _showNewMemberWarning = true;
        await _load();
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() => _error = _message(error, 'Sicil formu açılamadı.'));
      }
    }
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
      var currentDetail = detail;
      if (transition == AttendanceTransition.complete) {
        try {
          currentDetail = await _saveCurrentDraft(detail);
        } on Object catch (error) {
          if (!mounted) return;
          setState(() => _error = _message(error, 'Puantaj kaydedilemedi.'));
          return;
        }
        if (!mounted) return;
        setState(() => _detail = currentDetail);
      }
      await widget.attendance.transitionDay(
        TransitionAttendanceDayCommand(
          dayId: currentDetail.day.id,
          dayEventId: _dayEventId,
          reminderEventId: _reminderEventId,
          expectedRevision: currentDetail.day.revision,
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

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
    return Scaffold(
      appBar: AppBar(title: const Text('Günlük Puantaj')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : detail == null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _error ?? 'Puantaj günü bulunamadı.',
                        key: const Key('attendance-day-load-error'),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        key: const Key('attendance-day-retry'),
                        onPressed: _load,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Tekrar dene'),
                      ),
                    ],
                  ),
                ),
              )
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
                          const SizedBox(height: 8),
                          _SummaryCard(
                            detail: detail,
                            members: _members,
                            results: _results,
                            overtime: _overtime,
                          ),
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
                            if (_members.isEmpty)
                              Card(
                                key: const Key('attendance-workforce-empty'),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        _subcontractors.isEmpty
                                            ? 'Bu projede henüz firma ve personel yok.'
                                            : 'Bu firmalarda henüz aktif personel yok.',
                                      ),
                                      const SizedBox(height: 12),
                                      FilledButton.icon(
                                        key: Key(
                                          _subcontractors.isEmpty
                                              ? 'attendance-add-company'
                                              : 'attendance-add-person',
                                        ),
                                        onPressed: _submitting
                                            ? null
                                            : _openEmptyWorkforceAction,
                                        icon: Icon(
                                          _subcontractors.isEmpty
                                              ? Icons.add_business_outlined
                                              : Icons.person_add_alt_1_outlined,
                                        ),
                                        label: Text(
                                          _subcontractors.isEmpty
                                              ? 'Taşeron / İşveren ekle'
                                              : 'Personel ekle',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              ..._buildFlatRoster(),
                            if (_members.isNotEmpty &&
                                _subcontractors.isNotEmpty)
                              OutlinedButton.icon(
                                key: const Key('attendance-add-person'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                ),
                                onPressed: _submitting
                                    ? null
                                    : _openEmptyWorkforceAction,
                                icon: const Icon(
                                  Icons.person_add_alt_1_outlined,
                                ),
                                label: const Text('Personel ekle'),
                              ),
                            Card(
                              child: ExpansionTile(
                                key: const Key('attendance-bulk-tools'),
                                maintainState: true,
                                title: const Text('Toplu işlemler'),
                                subtitle: const Text(
                                  'Seçimler yalnız mevcut taslağa uygulanır.',
                                ),
                                childrenPadding: const EdgeInsets.fromLTRB(
                                  12,
                                  0,
                                  12,
                                  12,
                                ),
                                children: [
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      OutlinedButton.icon(
                                        key: const Key('mark-all-full'),
                                        style: OutlinedButton.styleFrom(
                                          minimumSize: const Size(48, 48),
                                        ),
                                        onPressed: _submitting
                                            ? null
                                            : _markDraftFull,
                                        icon: const Icon(
                                          Icons.done_all_outlined,
                                        ),
                                        label: const Text('Aktifleri tam gün'),
                                      ),
                                      OutlinedButton.icon(
                                        key: const Key('mark-team-full'),
                                        style: OutlinedButton.styleFrom(
                                          minimumSize: const Size(48, 48),
                                        ),
                                        onPressed:
                                            _submitting ||
                                                !_allMembers.any(
                                                  (member) =>
                                                      member.isActive &&
                                                      !_usesTechnicalTeam(
                                                        member,
                                                      ),
                                                )
                                            ? null
                                            : _pickTeam,
                                        icon: const Icon(Icons.groups_outlined),
                                        label: const Text('Ekibi tam gün'),
                                      ),
                                    ],
                                  ),
                                ],
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
                                    title: Text(
                                      _historyEventLabel(event.eventType),
                                    ),
                                    subtitle: Text(
                                      CseTimeCodec.formatIstanbul(
                                        event.occurredAt,
                                      ),
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

  String _historyEventLabel(String eventType) => switch (eventType) {
    'attendance_day.created' => 'Puantaj günü oluşturuldu',
    'attendance_entry.upserted' => 'Personel puantajı güncellendi',
    'attendance_entry.removed' => 'Personel kaydı kaldırıldı',
    'attendance_day.note_updated' => 'Günlük not güncellendi',
    'attendance_day.completed' => 'Gün tamamlandı',
    'attendance_day.no_work' => 'Çalışma yok olarak işaretlendi',
    'attendance_day.reopened' => 'Gün yeniden açıldı',
    'attendance_day.csv_exported' => 'CSV dışa aktarıldı',
    'attendance_day.reminder_linked' => 'Puantaj hatırlatıcısı bağlandı',
    _ => 'Puantaj kaydı güncellendi',
  };

  List<Widget> _buildFlatRoster() {
    return [
      if (_results.values.every((result) => result == null))
        const Padding(
          padding: EdgeInsets.fromLTRB(4, 4, 4, 8),
          child: Text(
            'Bugün için henüz Puantaj işaretlenmedi.',
            key: Key('attendance-unmarked-guidance'),
          ),
        ),
      KeyedSubtree(
        key: const Key('attendance-flat-list'),
        child: Column(
          children: _members
              .map(
                (member) => _MemberAttendanceCard(
                  member: member,
                  result: _results[member.id],
                  overtime: _overtime[member.id]!,
                  note: _notes[member.id]!,
                  onDraftChanged: () => setState(() {}),
                  onResultChanged: (value) {
                    setState(() {
                      _results[member.id] = value;
                      if (value == AttendanceResult.absent ||
                          value == AttendanceResult.leave) {
                        _overtime[member.id]!.text = '0';
                      }
                    });
                  },
                ),
              )
              .toList(growable: false),
        ),
      ),
    ];
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
    required this.onDraftChanged,
    required this.onResultChanged,
  });

  final WorkforceMember member;
  final AttendanceResult? result;
  final TextEditingController overtime;
  final TextEditingController note;
  final VoidCallback onDraftChanged;
  final ValueChanged<AttendanceResult?> onResultChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: Key('attendance-member-${member.id}'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${member.fullName}${member.isActive ? '' : ' (pasif)'}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(
              '${member.subcontractorName ?? 'Firma belirtilmedi'} • '
              '${member.roleName}',
            ),
            const SizedBox(height: 8),
            Column(
              key: Key('attendance-result-${member.id}'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Çalışma sonucu'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final value in AttendanceResult.values)
                      OutlinedButton(
                        key: Key(
                          'attendance-result-${member.id}-${value.name}',
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          visualDensity: VisualDensity.standard,
                          backgroundColor: result == value
                              ? Theme.of(context).colorScheme.primaryContainer
                              : null,
                          foregroundColor: result == value
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : null,
                          side: result == value
                              ? BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2,
                                )
                              : null,
                        ),
                        onPressed: () => onResultChanged(value),
                        child: Semantics(
                          selected: result == value,
                          inMutuallyExclusiveGroup: true,
                          child: Text(value.label),
                        ),
                      ),
                  ],
                ),
                if (result == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('Kayıt yok'),
                  ),
                TextButton(
                  key: Key('attendance-clear-result-${member.id}'),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    visualDensity: VisualDensity.standard,
                  ),
                  onPressed: result == null
                      ? null
                      : () => onResultChanged(null),
                  child: const Text('Seçimi temizle'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ExpansionTile(
              key: Key('attendance-member-details-${member.id}'),
              maintainState: true,
              tilePadding: EdgeInsets.zero,
              title: const Text('FM ve not'),
              childrenPadding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                if (!_usesTechnicalTeam(member)) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Ekip: ${member.teamName}'),
                  ),
                  const SizedBox(height: 8),
                ],
                TextField(
                  key: Key('attendance-overtime-${member.id}'),
                  controller: overtime,
                  enabled:
                      result != AttendanceResult.absent &&
                      result != AttendanceResult.leave,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => onDraftChanged(),
                  decoration: const InputDecoration(
                    labelText: 'FM dk',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: Key('attendance-note-${member.id}'),
                  controller: note,
                  onChanged: (_) => onDraftChanged(),
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
  const _SummaryCard({
    required this.detail,
    required this.members,
    required this.results,
    required this.overtime,
  });

  final AttendanceDayDetail detail;
  final List<WorkforceMember> members;
  final Map<String, AttendanceResult?> results;
  final Map<String, TextEditingController> overtime;

  @override
  Widget build(BuildContext context) {
    var fullDay = 0;
    var halfDay = 0;
    var absent = 0;
    var leave = 0;
    var unmarked = 0;
    var overtimeMinutes = 0;
    if (detail.day.status == AttendanceDayStatus.draft) {
      for (final member in members) {
        switch (results[member.id]) {
          case AttendanceResult.fullDay:
            fullDay += 1;
          case AttendanceResult.halfDay:
            halfDay += 1;
          case AttendanceResult.absent:
            absent += 1;
          case AttendanceResult.leave:
            leave += 1;
          case null:
            unmarked += 1;
        }
        overtimeMinutes += int.tryParse(overtime[member.id]?.text ?? '') ?? 0;
      }
    } else {
      final totals = detail.totals;
      fullDay = totals.fullDayCount;
      halfDay = totals.halfDayCount;
      absent = totals.absentCount;
      leave = totals.leaveCount;
      overtimeMinutes = totals.overtimeMinutes;
    }
    final present = fullDay + halfDay;
    final personDays = fullDay + (halfDay * 0.5);
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
              'Tam gün $fullDay • Yarım gün $halfDay • '
              'Gelmedi $absent • İzinli $leave',
            ),
            Text(
              'İşaretlenmedi $unmarked',
              key: const Key('attendance-unmarked-count'),
            ),
            Text('Sahada $present • ${personDays.toStringAsFixed(1)} kişi-gün'),
            Text(
              'Fazla mesai $overtimeMinutes dk '
              '(${(overtimeMinutes / 60).toStringAsFixed(2)} saat)',
            ),
            if (detail.day.status != AttendanceDayStatus.draft &&
                detail.teamSummaries.isNotEmpty) ...[
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

bool _usesTechnicalTeam(WorkforceMember member) => isWorkforceTechnicalTeamLink(
  projectId: member.projectId,
  subcontractorId: member.subcontractorId,
  teamId: member.teamId,
);

int _compareMembers(WorkforceMember left, WorkforceMember right) {
  final company = (left.subcontractorName ?? '').toLowerCase().compareTo(
    (right.subcontractorName ?? '').toLowerCase(),
  );
  if (company != 0) return company;
  final name = left.fullName.toLowerCase().compareTo(
    right.fullName.toLowerCase(),
  );
  if (name != 0) return name;
  return left.id.compareTo(right.id);
}
