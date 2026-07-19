import 'package:chief_site_engineer/application/attendance_application.dart';
import 'package:chief_site_engineer/core/record_id.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/attendance_models.dart';
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
      if (!mounted) return;
      setState(() => _members = members);
    } on Object catch (error) {
      if (!mounted) return;
      setState(
        () => _error = error is AgendaValidationFailure
            ? error.message
            : 'Personel listesi açılamadı.',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
    if (result != null) await _load();
  }

  Future<void> _archive(WorkforceMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Personeli pasifleştir'),
        content: Text(
          '${member.fullName} geçmiş Puantaj kayıtlarında görünmeye devam eder.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Pasifleştir'),
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
        ),
      );
      await _load();
    } on Object catch (error) {
      if (!mounted) return;
      setState(
        () => _error = error is AgendaValidationFailure
            ? error.message
            : 'Personel pasifleştirilemedi.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Personel — ${widget.project.name}')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add-workforce-member'),
        onPressed: _openForm,
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: const Text('Personel ekle'),
      ),
      body: SafeArea(
        child: ListView(
          key: const Key('workforce-list'),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
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
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _error!,
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
              ..._members.map(
                (member) => Card(
                  key: Key('workforce-member-${member.id}'),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    title: Text(
                      member.fullName,
                      softWrap: true,
                      style: TextStyle(
                        decoration: member.isActive
                            ? null
                            : TextDecoration.lineThrough,
                      ),
                    ),
                    subtitle: Text(
                      '${member.teamName}\n${member.roleName}'
                      '${member.personnelCode == null ? '' : ' • ${member.personnelCode}'}'
                      '${member.isActive ? '' : '\nPasif'}',
                    ),
                    isThreeLine: true,
                    trailing: member.isActive
                        ? PopupMenuButton<String>(
                            constraints: const BoxConstraints(minWidth: 160),
                            onSelected: (value) {
                              if (value == 'edit') _openForm(member);
                              if (value == 'archive') _archive(member);
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text('Düzenle'),
                              ),
                              PopupMenuItem(
                                value: 'archive',
                                child: Text('Pasifleştir'),
                              ),
                            ],
                          )
                        : null,
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
  late final String _commandId;
  late final TextEditingController _name;
  late final TextEditingController _team;
  late final TextEditingController _role;
  late final TextEditingController _code;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _commandId = widget.member?.id ?? RecordId.randomUuid();
    _name = TextEditingController(text: widget.member?.fullName);
    _team = TextEditingController(text: widget.member?.teamName);
    _role = TextEditingController(text: widget.member?.roleName);
    _code = TextEditingController(text: widget.member?.personnelCode);
  }

  @override
  void dispose() {
    _name.dispose();
    _team.dispose();
    _role.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final member = widget.member == null
          ? await widget.attendance.createMember(
              CreateWorkforceMemberCommand(
                id: _commandId,
                projectId: widget.project.id,
                fullName: _name.text,
                teamName: _team.text,
                roleName: _role.text,
                personnelCode: _code.text,
              ),
            )
          : await widget.attendance.updateMember(
              UpdateWorkforceMemberCommand(
                id: _commandId,
                expectedRevision: widget.member!.revision,
                fullName: _name.text,
                teamName: _team.text,
                roleName: _role.text,
                personnelCode: _code.text,
              ),
            );
      if (mounted) Navigator.pop(context, member);
    } on Object catch (error) {
      if (!mounted) return;
      setState(
        () => _error = error is AgendaValidationFailure
            ? error.message
            : 'Personel kaydedilemedi.',
      );
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
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _error!,
                  key: const Key('workforce-form-error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            TextField(
              key: const Key('workforce-name'),
              controller: _name,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Tam ad *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('workforce-team'),
              controller: _team,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Ekip/taşeron/işveren *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('workforce-role'),
              controller: _role,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Meslek/pozisyon *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('workforce-code'),
              controller: _code,
              decoration: const InputDecoration(
                labelText: 'Personel kodu (opsiyonel)',
                border: OutlineInputBorder(),
              ),
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
        ),
      ),
    );
  }
}
