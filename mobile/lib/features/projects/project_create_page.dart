import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/core/record_id.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:flutter/material.dart';

class ProjectCreatePage extends StatefulWidget {
  const ProjectCreatePage({required this.agenda, super.key});

  final AgendaApplication agenda;

  @override
  State<ProjectCreatePage> createState() => _ProjectCreatePageState();
}

class _ProjectCreatePageState extends State<ProjectCreatePage> {
  final TextEditingController _nameController = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Proje adı zorunludur.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final project = await widget.agenda.createProject(
        CreateProjectCommand(id: RecordId.randomUuid(), name: name),
      );
      if (!mounted) return;
      Navigator.of(context).pop(project);
    } on AgendaValidationFailure catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.message;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Proje oluşturulamadı.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('project-create-page'),
      appBar: AppBar(title: const Text('Yeni Proje')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              key: const Key('project-name'),
              controller: _nameController,
              enabled: !_saving,
              maxLength: 160,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Proje adı',
                border: OutlineInputBorder(),
              ),
              onSubmitted: _saving ? null : (_) => _save(),
            ),
            if (_error case final error?) ...[
              const SizedBox(height: 8),
              Text(
                error,
                key: const Key('project-create-error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('save-project'),
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}
