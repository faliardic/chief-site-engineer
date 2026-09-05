import 'dart:async';

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
  bool _allowPop = false;
  bool _exitDialogOpen = false;
  String? _error;

  bool get _isDirty => _nameController.text.isNotEmpty;

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
      await _popWithGuardBypass(project);
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

  Future<void> _handlePopAttempt(Object? result) async {
    if (_saving || !_isDirty || _exitDialogOpen) return;
    _exitDialogOpen = true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('unsaved-changes-dialog'),
        title: const Text('Kaydedilmemiş değişiklikler'),
        content: const Text(
          'Yaptığınız değişiklikler kaydedilmedi. Formdan çıkmak istiyor musunuz?',
        ),
        actions: [
          TextButton(
            key: const Key('stay-on-form'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Formda kal'),
          ),
          TextButton(
            key: const Key('discard-form'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Kaydetmeden çık'),
          ),
        ],
      ),
    );
    _exitDialogOpen = false;
    if (!mounted || discard != true) return;
    await _popWithGuardBypass(result);
  }

  Future<void> _popWithGuardBypass(Object? result) async {
    if (!mounted) return;
    setState(() => _allowPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: _allowPop || (!_saving && !_isDirty),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_handlePopAttempt(result));
      },
      child: Scaffold(
        key: const Key('project-create-page'),
        appBar: AppBar(title: const Text('Yeni Proje')),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final padding = constraints.maxWidth < 600 ? 24.0 : 40.0;
              return SingleChildScrollView(
                key: const Key('project-create-scroll'),
                padding: EdgeInsets.all(padding),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 560,
                      minHeight: (constraints.maxHeight - padding * 2).clamp(
                        0,
                        double.infinity,
                      ),
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        key: const Key('project-create-content'),
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Projenizi adlandırın',
                            key: const Key('project-create-heading'),
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Projenize bir ad vererek başlayın. Diğer bilgileri daha sonra Proje Profili’nde tamamlayabilirsiniz.',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 32),
                          Container(
                            key: const Key('project-name-group'),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                  onChanged: (_) => setState(() {}),
                                  onSubmitted: _saving ? null : (_) => _save(),
                                ),
                                if (_error case final error?) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    error,
                                    key: const Key('project-create-error'),
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          const Spacer(),
                          Semantics(
                            label: _saving ? 'Kaydediliyor…' : 'Kaydet',
                            button: true,
                            enabled: !_saving,
                            excludeSemantics: true,
                            onTap: _saving ? null : _save,
                            child: FilledButton(
                              key: const Key('save-project'),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(0, 48),
                              ),
                              onPressed: _saving ? null : _save,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_saving) ...[
                                    const SizedBox.square(
                                      dimension: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Flexible(
                                    child: Text(
                                      _saving ? 'Kaydediliyor…' : 'Kaydet',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
