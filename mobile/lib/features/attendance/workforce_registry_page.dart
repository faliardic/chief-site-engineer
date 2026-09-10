import 'package:chief_site_engineer/application/attendance_application.dart';
import 'package:chief_site_engineer/core/record_id.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/attendance_models.dart';
import 'package:flutter/material.dart';

class WorkforceRegistryPage extends StatefulWidget {
  const WorkforceRegistryPage({
    required this.attendance,
    required this.project,
    this.startWithCompanyForm = false,
    super.key,
  });

  final AttendanceApplication attendance;
  final MobileProject project;
  final bool startWithCompanyForm;

  @override
  State<WorkforceRegistryPage> createState() => _WorkforceRegistryPageState();
}

class _WorkforceRegistryPageState extends State<WorkforceRegistryPage> {
  bool _includeArchived = false;
  bool _loading = true;
  String? _error;
  List<Subcontractor> _subcontractors = const [];
  List<WorkforceTeam> _teams = const [];

  @override
  void initState() {
    super.initState();
    _load();
    if (widget.startWithCompanyForm) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _saveSubcontractor();
      });
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final subcontractors = await widget.attendance.listSubcontractors(
        widget.project.id,
        includeArchived: _includeArchived,
      );
      final teams = await widget.attendance.listTeams(
        widget.project.id,
        includeArchived: _includeArchived,
      );
      if (mounted) {
        setState(() {
          _subcontractors = subcontractors;
          _teams = teams;
        });
      }
    } on Object catch (error) {
      if (mounted) setState(() => _error = _message(error, 'Sicil açılamadı.'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<_SubcontractorInput?> _subcontractorInput([
    Subcontractor? value,
  ]) async {
    final name = TextEditingController(text: value?.name);
    final contact = TextEditingController(text: value?.contactName);
    final phone = TextEditingController(text: value?.phone);
    final address = TextEditingController(text: value?.address);
    final specialty = TextEditingController(text: value?.specialty);
    final startedOn = TextEditingController(text: value?.startedOn);
    final endedOn = TextEditingController(text: value?.endedOn);
    final note = TextEditingController(text: value?.note);
    final result = await showDialog<_SubcontractorInput>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(value == null ? 'Firma ekle' : 'Firmayı düzenle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(name, 'Firma adı *', key: const Key('subcontractor-name')),
              _gap,
              _field(
                contact,
                'Yetkili adı',
                key: const Key('subcontractor-contact'),
              ),
              _gap,
              _field(phone, 'Telefon', key: const Key('subcontractor-phone')),
              const SizedBox(height: 4),
              ExpansionTile(
                key: const Key('subcontractor-other-information'),
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 4),
                title: const Text('Diğer bilgiler'),
                children: [
                  _field(
                    address,
                    'Adres',
                    key: const Key('subcontractor-address'),
                    maxLines: 3,
                  ),
                  _gap,
                  _field(
                    specialty,
                    'İş kalemi / uzmanlık',
                    key: const Key('subcontractor-specialty'),
                  ),
                  _gap,
                  _field(
                    startedOn,
                    'Başlangıç tarihi (YYYY-AA-GG)',
                    key: const Key('subcontractor-started-on'),
                  ),
                  _gap,
                  _field(
                    endedOn,
                    'Bitiş tarihi (YYYY-AA-GG)',
                    key: const Key('subcontractor-ended-on'),
                  ),
                  _gap,
                  _field(
                    note,
                    'Not',
                    key: const Key('subcontractor-note'),
                    maxLines: 3,
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              _SubcontractorInput(
                name.text,
                contact.text,
                phone.text,
                address.text,
                specialty.text,
                startedOn.text,
                endedOn.text,
                note.text,
              ),
            ),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    await Future<void>.delayed(kThemeAnimationDuration);
    name.dispose();
    contact.dispose();
    phone.dispose();
    address.dispose();
    specialty.dispose();
    startedOn.dispose();
    endedOn.dispose();
    note.dispose();
    return result;
  }

  Future<Subcontractor?> _saveSubcontractor([Subcontractor? current]) async {
    final input = await _subcontractorInput(current);
    if (input == null) {
      if (mounted && widget.startWithCompanyForm && current == null) {
        Navigator.pop(context);
      }
      return null;
    }
    try {
      late final Subcontractor saved;
      if (current == null) {
        saved = await widget.attendance.createSubcontractor(
          CreateSubcontractorCommand(
            id: RecordId.randomUuid(),
            eventId: RecordId.randomUuid(),
            projectId: widget.project.id,
            name: input.name,
            contactName: input.contact,
            phone: input.phone,
            address: input.address,
            specialty: input.specialty,
            startedOn: input.startedOn,
            endedOn: input.endedOn,
            note: input.note,
          ),
        );
      } else {
        saved = await widget.attendance.updateSubcontractor(
          UpdateSubcontractorCommand(
            id: current.id,
            eventId: RecordId.randomUuid(),
            expectedRevision: current.revision,
            name: input.name,
            contactName: input.contact,
            phone: input.phone,
            address: input.address,
            specialty: input.specialty,
            startedOn: input.startedOn,
            endedOn: input.endedOn,
            replaceAddress: true,
            replaceSpecialty: true,
            replaceStartedOn: true,
            replaceEndedOn: true,
            note: input.note,
          ),
        );
      }
      await _load();
      if (mounted && widget.startWithCompanyForm && current == null) {
        Navigator.pop(context, saved);
      }
      return saved;
    } on Object catch (error) {
      if (mounted) {
        setState(() => _error = _message(error, 'Firma kaydedilemedi.'));
      }
      return null;
    }
  }

  Future<void> _saveTeam(
    Subcontractor subcontractor, [
    WorkforceTeam? current,
  ]) async {
    final name = TextEditingController(text: current?.name);
    final lead = TextEditingController(text: current?.leadName);
    final note = TextEditingController(text: current?.note);
    final result = await showDialog<_TeamInput>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(current == null ? 'Yeni ekip' : 'Ekibi düzenle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                subcontractor.name,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              _gap,
              _field(name, 'Ekip/iş kalemi adı *'),
              _gap,
              _field(lead, 'Ekip sorumlusu'),
              _gap,
              _field(note, 'Not', maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              _TeamInput(name.text, lead.text, note.text),
            ),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    await Future<void>.delayed(kThemeAnimationDuration);
    name.dispose();
    lead.dispose();
    note.dispose();
    if (result == null) return;
    try {
      if (current == null) {
        await widget.attendance.createTeam(
          CreateWorkforceTeamCommand(
            id: RecordId.randomUuid(),
            eventId: RecordId.randomUuid(),
            projectId: widget.project.id,
            subcontractorId: subcontractor.id,
            name: result.name,
            leadName: result.lead,
            note: result.note,
          ),
        );
      } else {
        await widget.attendance.updateTeam(
          UpdateWorkforceTeamCommand(
            id: current.id,
            eventId: RecordId.randomUuid(),
            expectedRevision: current.revision,
            name: result.name,
            leadName: result.lead,
            note: result.note,
          ),
        );
      }
      await _load();
    } on Object catch (error) {
      if (mounted) {
        setState(() => _error = _message(error, 'Ekip kaydedilemedi.'));
      }
    }
  }

  Future<void> _transitionSubcontractor(Subcontractor value) async {
    try {
      await widget.attendance.transitionSubcontractor(
        TransitionSubcontractorCommand(
          id: value.id,
          eventId: RecordId.randomUuid(),
          expectedRevision: value.revision,
          archive: value.isActive,
        ),
      );
      await _load();
    } on Object catch (error) {
      if (mounted) {
        setState(
          () => _error = _message(error, 'Firma durumu değiştirilemedi.'),
        );
      }
    }
  }

  Future<void> _transitionTeam(WorkforceTeam value) async {
    try {
      await widget.attendance.transitionTeam(
        TransitionWorkforceTeamCommand(
          id: value.id,
          eventId: RecordId.randomUuid(),
          expectedRevision: value.revision,
          archive: value.isActive,
        ),
      );
      await _load();
    } on Object catch (error) {
      if (mounted) {
        setState(
          () => _error = _message(error, 'Ekip durumu değiştirilemedi.'),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firmalar ve ekipler')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add-subcontractor'),
        onPressed: _saveSubcontractor,
        icon: const Icon(Icons.add_business_outlined),
        label: const Text('Firma ekle'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Pasif kayıtları göster'),
              value: _includeArchived,
              onChanged: (value) {
                setState(() => _includeArchived = value);
                _load();
              },
            ),
            if (_error case final error?)
              Text(
                error,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_subcontractors.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Henüz firma veya ekip kaydı yok.'),
                ),
              )
            else
              for (final subcontractor in _subcontractors)
                Card(
                  key: Key('subcontractor-${subcontractor.id}'),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                subcontractor.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (action) {
                                if (action == 'edit') {
                                  _saveSubcontractor(subcontractor);
                                }
                                if (action == 'transition') {
                                  _transitionSubcontractor(subcontractor);
                                }
                              },
                              itemBuilder: (_) => [
                                if (subcontractor.isActive)
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Düzenle'),
                                  ),
                                PopupMenuItem(
                                  value: 'transition',
                                  child: Text(
                                    subcontractor.isActive
                                        ? 'Pasifleştir'
                                        : 'Yeniden aç',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Text(
                          '${subcontractor.activeTeamCount} aktif ekip • '
                          '${subcontractor.activePersonCount} aktif personel'
                          '${subcontractor.isActive ? '' : ' • Pasif'}',
                        ),
                        const Divider(),
                        for (final team in _teams.where(
                          (item) => item.subcontractorId == subcontractor.id,
                        ))
                          ListTile(
                            key: Key('workforce-team-${team.id}'),
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.groups_2_outlined),
                            title: Text(team.name),
                            subtitle: Text(
                              '${team.activePersonCount} aktif personel'
                              '${team.isActive ? '' : ' • Pasif'}',
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (action) {
                                if (action == 'edit') {
                                  _saveTeam(subcontractor, team);
                                }
                                if (action == 'transition') {
                                  _transitionTeam(team);
                                }
                              },
                              itemBuilder: (_) => [
                                if (team.isActive)
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Düzenle'),
                                  ),
                                PopupMenuItem(
                                  value: 'transition',
                                  child: Text(
                                    team.isActive
                                        ? 'Pasifleştir'
                                        : 'Yeniden aç',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (subcontractor.isActive)
                          OutlinedButton.icon(
                            key: Key('add-team-${subcontractor.id}'),
                            onPressed: () => _saveTeam(subcontractor),
                            icon: const Icon(Icons.group_add_outlined),
                            label: const Text('Ekip ekle'),
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

const _gap = SizedBox(height: 10);

TextField _field(
  TextEditingController controller,
  String label, {
  Key? key,
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

class _SubcontractorInput {
  const _SubcontractorInput(
    this.name,
    this.contact,
    this.phone,
    this.address,
    this.specialty,
    this.startedOn,
    this.endedOn,
    this.note,
  );
  final String name;
  final String contact;
  final String phone;
  final String address;
  final String specialty;
  final String startedOn;
  final String endedOn;
  final String note;
}

class _TeamInput {
  const _TeamInput(this.name, this.lead, this.note);
  final String name;
  final String lead;
  final String note;
}

String _message(Object error, String fallback) =>
    error is AgendaValidationFailure ? error.message : fallback;
