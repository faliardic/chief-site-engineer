import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/core/record_id.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:flutter/material.dart';

class LogFormPage extends StatefulWidget {
  const LogFormPage({required this.agenda, super.key});

  final AgendaApplication agenda;

  @override
  State<LogFormPage> createState() => _LogFormPageState();
}

class _LogFormPageState extends State<LogFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  final _location = TextEditingController();
  final _notes = TextEditingController();
  late final String _recordId;
  late final String _eventId;
  late DateTime _date;
  late TimeOfDay _time;
  List<MobileProject> _projects = const [];
  String? _projectId;
  AgendaCategory _category = AgendaCategory.generalNote;
  bool _loadingProjects = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _recordId = RecordId.randomUuid();
    _eventId = RecordId.randomUuid();
    final nowLocal = CseTimeCodec.toIstanbul(
      CseTimeCodec.encodeUtc(DateTime.now().toUtc()),
    );
    _date = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);
    _time = TimeOfDay(hour: nowLocal.hour, minute: nowLocal.minute);
    _loadProjects();
  }

  @override
  void dispose() {
    _description.dispose();
    _location.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    try {
      final projects = await widget.agenda.listProjects();
      if (!mounted) return;
      setState(() {
        _projects = projects;
        _projectId ??= projects.isEmpty ? null : projects.first.id;
        _loadingProjects = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _loadingProjects = false;
        _error = 'Projeler okunamadı.';
      });
    }
  }

  Future<void> _createProject() async {
    final controller = TextEditingController();
    final projectId = RecordId.randomUuid();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni proje'),
        content: TextField(
          key: const Key('new-project-name'),
          controller: controller,
          autofocus: true,
          maxLength: 160,
          decoration: const InputDecoration(labelText: 'Proje adı'),
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
    controller.dispose();
    if (name == null || !mounted) return;
    try {
      final project = await widget.agenda.createProject(
        CreateProjectCommand(id: projectId, name: name),
      );
      await _loadProjects();
      if (mounted) setState(() => _projectId = project.id);
    } on AgendaValidationFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    if (_projectId == null) {
      setState(() => _error = 'Önce bir proje oluşturup seçin.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final observedAt = CseTimeCodec.canonicalFromIstanbulComponents(
        year: _date.year,
        month: _date.month,
        day: _date.day,
        hour: _time.hour,
        minute: _time.minute,
      );
      final created = await widget.agenda.createAgendaLog(
        CreateAgendaLogCommand(
          id: _recordId,
          eventId: _eventId,
          projectId: _projectId!,
          observedAt: observedAt,
          category: _category,
          description: _description.text,
          location: _location.text,
          notes: _notes.text,
        ),
      );
      if (!mounted) return;
      Navigator.pop(context, CseTimeCodec.istanbulDayKey(created.observedAt));
    } on AgendaValidationFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on TimeContractViolation {
      if (mounted) setState(() => _error = 'Olay tarih/saat değeri geçersiz.');
    } on Object {
      if (mounted) {
        setState(() => _error = 'Log güvenli biçimde kaydedilemedi.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yeni Ajanda logu')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_error != null)
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_error!, key: const Key('log-form-error')),
                ),
              ),
            if (_loadingProjects)
              const LinearProgressIndicator()
            else ...[
              DropdownButtonFormField<String>(
                key: const Key('log-project'),
                initialValue: _projectId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Proje',
                  border: OutlineInputBorder(),
                ),
                items: _projects
                    .map(
                      (project) => DropdownMenuItem(
                        value: project.id,
                        child: Text(
                          project.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _projectId = value),
                validator: (value) =>
                    value == null ? 'Proje zorunludur.' : null,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  key: const Key('create-project'),
                  onPressed: _createProject,
                  icon: const Icon(Icons.add_business_outlined),
                  label: const Text('Yeni proje oluştur'),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  key: const Key('log-date'),
                  onPressed: () async {
                    final value = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (value != null) {
                      setState(() => _date = value);
                    }
                  },
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(
                    '${_date.day.toString().padLeft(2, '0')}.'
                    '${_date.month.toString().padLeft(2, '0')}.${_date.year}',
                  ),
                ),
                OutlinedButton.icon(
                  key: const Key('log-time'),
                  onPressed: () async {
                    final value = await showTimePicker(
                      context: context,
                      initialTime: _time,
                    );
                    if (value != null) setState(() => _time = value);
                  },
                  icon: const Icon(Icons.schedule),
                  label: Text(_time.format(context)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<AgendaCategory>(
              key: const Key('log-category'),
              initialValue: _category,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Kayıt türü',
                border: OutlineInputBorder(),
              ),
              items: AgendaCategory.values
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(category.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _category = value!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('log-description'),
              controller: _description,
              maxLength: 500,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Kısa açıklama',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Kısa açıklama zorunludur.'
                  : null,
            ),
            TextFormField(
              key: const Key('log-location'),
              controller: _location,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: 'Mahal (opsiyonel)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: const Key('log-notes'),
              controller: _notes,
              maxLength: 4000,
              minLines: 3,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Ayrıntılı not (opsiyonel)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                key: const Key('submit-log'),
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_submitting ? 'Kaydediliyor…' : 'Logu kaydet'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
