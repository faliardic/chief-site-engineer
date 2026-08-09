import 'package:chief_site_engineer/application/attendance_application.dart';
import 'package:chief_site_engineer/core/record_id.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/attendance_models.dart';
import 'package:chief_site_engineer/features/attendance/workforce_person_detail_page.dart';
import 'package:chief_site_engineer/features/attendance/workforce_registry_page.dart';
import 'package:flutter/material.dart';

class WorkforcePage extends StatefulWidget {
  const WorkforcePage({
    required this.attendance,
    required this.project,
    super.key,
  });

  final AttendanceApplication attendance;
  final MobileProject project;

  @override
  State<WorkforcePage> createState() => _WorkforcePageState();
}

class _WorkforcePageState extends State<WorkforcePage> {
  bool _includeInactive = false;
  bool _loading = true;
  String? _error;
  List<WorkforceMember> _members = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final members = await widget.attendance.listMembers(
        widget.project.id,
        includeInactive: _includeInactive,
      );
      if (mounted) setState(() => _members = members);
    } on Object catch (error) {
      if (mounted) {
        setState(() => _error = _message(error, 'Personel listesi açılamadı.'));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openRegistry() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => WorkforceRegistryPage(
          attendance: widget.attendance,
          project: widget.project,
        ),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _openForm([WorkforceMember? member]) async {
    final result = await Navigator.of(context).push<WorkforceMember>(
      MaterialPageRoute(
        builder: (_) => WorkforceMemberFormPage(
          attendance: widget.attendance,
          project: widget.project,
          member: member,
        ),
      ),
    );
    if (result != null && mounted) await _load();
  }

  Future<void> _openDetail(WorkforceMember member) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => WorkforcePersonDetailPage(
          attendance: widget.attendance,
          memberId: member.id,
        ),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _transition(WorkforceMember member) async {
    final archive = member.isActive;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(archive ? 'Personeli pasifleştir' : 'Personeli yeniden aç'),
        content: Text(
          archive
              ? '${member.fullName} geçmiş Puantaj kayıtlarında görünmeye devam eder.'
              : '${member.fullName} yeniden aktif personel listesine alınır.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(archive ? 'Pasifleştir' : 'Yeniden aç'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.attendance.archiveMember(
        ArchiveWorkforceMemberCommand(
          id: member.id,
          expectedRevision: member.revision,
          eventId: RecordId.randomUuid(),
          archive: archive,
        ),
      );
      await _load();
    } on Object catch (error) {
      if (mounted) {
        setState(
          () => _error = _message(error, 'Personel durumu değiştirilemedi.'),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('İş gücü — ${widget.project.name}')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add-workforce-member'),
        onPressed: _openForm,
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: const Text('Personel ekle'),
      ),
      body: SafeArea(
        child: ListView(
          key: const Key('workforce-list'),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
          children: [
            OutlinedButton.icon(
              key: const Key('manage-workforce-registry'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: _openRegistry,
              icon: const Icon(Icons.account_tree_outlined),
              label: const Text('Taşeronlar ve ekipler'),
            ),
            SwitchListTile(
              key: const Key('show-inactive-workforce'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Pasif personeli göster'),
              value: _includeInactive,
              onChanged: (value) {
                setState(() => _includeInactive = value);
                _load();
              },
            ),
            if (_error case final error?)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  error,
                  key: const Key('workforce-error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_members.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Bu proje için personel kaydı bulunmuyor.'),
                ),
              )
            else
              for (final member in _members)
                Card(
                  key: Key('workforce-member-${member.id}'),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    onTap: () => _openDetail(member),
                    title: Text(
                      member.fullName,
                      style: TextStyle(
                        decoration: member.isActive
                            ? null
                            : TextDecoration.lineThrough,
                      ),
                    ),
                    subtitle: Text(
                      '${member.subcontractorName ?? 'Tanımsız taşeron'} • ${member.teamName}\n'
                      '${member.roleName}${member.personnelCode == null ? '' : ' • ${member.personnelCode}'}'
                      '${member.isActive ? '' : '\nPasif'}',
                    ),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') _openForm(member);
                        if (value == 'transition') _transition(member);
                      },
                      itemBuilder: (_) => [
                        if (member.isActive)
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Düzenle'),
                          ),
                        PopupMenuItem(
                          value: 'transition',
                          child: Text(
                            member.isActive ? 'Pasifleştir' : 'Yeniden aç',
                          ),
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
}

class WorkforceMemberFormPage extends StatefulWidget {
  const WorkforceMemberFormPage({
    required this.attendance,
    required this.project,
    this.member,
    super.key,
  });

  final AttendanceApplication attendance;
  final MobileProject project;
  final WorkforceMember? member;

  @override
  State<WorkforceMemberFormPage> createState() =>
      _WorkforceMemberFormPageState();
}

class _WorkforceMemberFormPageState extends State<WorkforceMemberFormPage> {
  static const _newSubcontractor = '__new_subcontractor__';
  static const _newTeam = '__new_team__';
  late final String _commandId;
  late final TextEditingController _name;
  late final TextEditingController _role;
  late final TextEditingController _code;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final TextEditingController _startedOn;
  late final TextEditingController _note;
  List<Subcontractor> _subcontractors = const [];
  List<WorkforceTeam> _teams = const [];
  String? _subcontractorId;
  String? _teamId;
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _commandId = widget.member?.id ?? RecordId.randomUuid();
    _name = TextEditingController(text: widget.member?.fullName);
    _role = TextEditingController(text: widget.member?.roleName);
    _code = TextEditingController(text: widget.member?.personnelCode);
    _phone = TextEditingController(text: widget.member?.phone);
    _address = TextEditingController(text: widget.member?.address);
    _startedOn = TextEditingController(text: widget.member?.startedOn);
    _note = TextEditingController(text: widget.member?.note);
    _subcontractorId = widget.member?.subcontractorId;
    _teamId = widget.member?.teamId;
    _loadRegistry();
  }

  @override
  void dispose() {
    _name.dispose();
    _role.dispose();
    _code.dispose();
    _phone.dispose();
    _address.dispose();
    _startedOn.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _loadRegistry() async {
    try {
      final subcontractors = await widget.attendance.listSubcontractors(
        widget.project.id,
      );
      final teams = _subcontractorId == null
          ? const <WorkforceTeam>[]
          : await widget.attendance.listTeams(
              widget.project.id,
              subcontractorId: _subcontractorId,
            );
      if (!mounted) return;
      setState(() {
        _subcontractors = subcontractors;
        _teams = teams;
        _loading = false;
      });
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = _message(error, 'Taşeron ve ekip listesi açılamadı.');
        });
      }
    }
  }

  Future<String?> _askName(String title, String label) async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Oluştur'),
          ),
        ],
      ),
    );
    await Future<void>.delayed(kThemeAnimationDuration);
    controller.dispose();
    return value;
  }

  Future<void> _createSubcontractor() async {
    final name = await _askName('Yeni taşeron', 'Taşeron/unvan adı');
    if (name == null) return;
    try {
      final value = await widget.attendance.createSubcontractor(
        CreateSubcontractorCommand(
          id: RecordId.randomUuid(),
          eventId: RecordId.randomUuid(),
          projectId: widget.project.id,
          name: name,
        ),
      );
      _subcontractorId = value.id;
      _teamId = null;
      await _loadRegistry();
    } on Object catch (error) {
      if (mounted) {
        setState(() => _error = _message(error, 'Taşeron oluşturulamadı.'));
      }
    }
  }

  Future<void> _createTeam() async {
    final subcontractorId = _subcontractorId;
    if (subcontractorId == null) return;
    final name = await _askName('Yeni ekip', 'Ekip/iş kalemi adı');
    if (name == null) return;
    try {
      final value = await widget.attendance.createTeam(
        CreateWorkforceTeamCommand(
          id: RecordId.randomUuid(),
          eventId: RecordId.randomUuid(),
          projectId: widget.project.id,
          subcontractorId: subcontractorId,
          name: name,
        ),
      );
      _teamId = value.id;
      await _loadRegistry();
    } on Object catch (error) {
      if (mounted) {
        setState(() => _error = _message(error, 'Ekip oluşturulamadı.'));
      }
    }
  }

  Future<void> _selectSubcontractor(String? value) async {
    if (value == _newSubcontractor) {
      await _createSubcontractor();
      return;
    }
    setState(() {
      _subcontractorId = value;
      _teamId = null;
      _teams = const [];
    });
    if (value != null) {
      final teams = await widget.attendance.listTeams(
        widget.project.id,
        subcontractorId: value,
      );
      if (mounted) setState(() => _teams = teams);
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final subcontractorId = _subcontractorId;
    final teamId = _teamId;
    final team = _teams.where((item) => item.id == teamId).firstOrNull;
    if (subcontractorId == null || team == null) {
      setState(() => _error = 'Taşeron ve ekip seçilmelidir.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final member = widget.member == null
          ? await widget.attendance.createMember(
              CreateWorkforceMemberCommand(
                id: _commandId,
                eventId: RecordId.randomUuid(),
                projectId: widget.project.id,
                subcontractorId: subcontractorId,
                teamId: team.id,
                fullName: _name.text,
                teamName: team.name,
                roleName: _role.text,
                personnelCode: _code.text,
                phone: _phone.text,
                address: _address.text,
                startedOn: _startedOn.text,
                note: _note.text,
              ),
            )
          : await widget.attendance.updateMember(
              UpdateWorkforceMemberCommand(
                id: _commandId,
                eventId: RecordId.randomUuid(),
                expectedRevision: widget.member!.revision,
                subcontractorId: subcontractorId,
                teamId: team.id,
                fullName: _name.text,
                teamName: team.name,
                roleName: _role.text,
                personnelCode: _code.text,
                phone: _phone.text,
                address: _address.text,
                startedOn: _startedOn.text,
                replaceAddress: true,
                replaceStartedOn: true,
                note: _note.text,
              ),
            );
      if (mounted) Navigator.pop(context, member);
    } on Object catch (error) {
      if (mounted) {
        setState(() => _error = _message(error, 'Personel kaydedilemedi.'));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.member == null ? 'Personel ekle' : 'Personeli düzenle',
        ),
      ),
      body: SafeArea(
        child: ListView(
          key: const Key('workforce-member-form'),
          padding: const EdgeInsets.all(16),
          children: [
            if (_error case final error?)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  error,
                  key: const Key('workforce-form-error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else ...[
              DropdownButtonFormField<String>(
                key: const Key('workforce-subcontractor'),
                initialValue: _subcontractorId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Taşeron seç *',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(
                    value: _newSubcontractor,
                    child: Text('+ Yeni taşeron ekle'),
                  ),
                  ..._subcontractors.map(
                    (item) => DropdownMenuItem(
                      value: item.id,
                      child: Text(item.name),
                    ),
                  ),
                ],
                onChanged: _submitting ? null : _selectSubcontractor,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: const Key('workforce-team'),
                initialValue: _teamId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Ekip seç *',
                  border: OutlineInputBorder(),
                ),
                items: [
                  if (_subcontractorId != null)
                    const DropdownMenuItem(
                      value: _newTeam,
                      child: Text('+ Yeni ekip ekle'),
                    ),
                  ..._teams.map(
                    (item) => DropdownMenuItem(
                      value: item.id,
                      child: Text(item.name),
                    ),
                  ),
                ],
                onChanged: _subcontractorId == null || _submitting
                    ? null
                    : (value) {
                        if (value == _newTeam) {
                          _createTeam();
                        } else {
                          setState(() => _teamId = value);
                        }
                      },
              ),
              const SizedBox(height: 12),
              _field(const Key('workforce-name'), _name, 'Tam ad *'),
              const SizedBox(height: 12),
              _field(const Key('workforce-role'), _role, 'Meslek/pozisyon *'),
              const SizedBox(height: 12),
              _field(
                const Key('workforce-code'),
                _code,
                'Personel kodu (opsiyonel)',
              ),
              const SizedBox(height: 12),
              _field(
                const Key('workforce-phone'),
                _phone,
                'Telefon (opsiyonel)',
              ),
              const SizedBox(height: 12),
              _field(
                const Key('workforce-address'),
                _address,
                'Adres (opsiyonel)',
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              _field(
                const Key('workforce-started-on'),
                _startedOn,
                'İşe başlama tarihi (YYYY-AA-GG)',
              ),
              const SizedBox(height: 12),
              _field(
                const Key('workforce-note'),
                _note,
                'Not (opsiyonel)',
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                key: const Key('save-workforce-member'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('Kaydet'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  TextField _field(
    Key key,
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) => TextField(
    key: key,
    controller: controller,
    maxLines: maxLines,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
  );
}

String _message(Object error, String fallback) =>
    error is AgendaValidationFailure ? error.message : fallback;
