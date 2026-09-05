import 'dart:async';

import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/application/construction_living_plan_application.dart';
import 'package:chief_site_engineer/application/daily_log_application.dart';
import 'package:chief_site_engineer/application/material_request_application.dart';
import 'package:chief_site_engineer/core/record_id.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/features/owned_text_input_dialog.dart';
import 'package:chief_site_engineer/features/project_context/active_project_session.dart';
import 'package:flutter/material.dart';

typedef DashboardCaptureAction =
    Future<bool> Function(String projectId, String localDay);
typedef DashboardProjectAction = void Function(String projectId);

class ProjectDashboardPage extends StatefulWidget {
  const ProjectDashboardPage({
    required this.agenda,
    required this.livingPlan,
    required this.session,
    required this.onCreateProject,
    this.dailyLog,
    this.materialRequests,
    this.onAddReminder,
    this.onAddAgenda,
    this.onOpenToday,
    this.onOpenPlan,
    this.onOpenMaterials,
    this.onOpenConcrete,
    this.onOpenProjectAlbum,
    this.onOpenWorkforce,
    this.onOpenPhoneCall,
    this.onOpenBackup,
    this.onOpenCatalog,
    this.onOpenAttachmentHealth,
    DateTime Function()? clock,
    super.key,
  }) : clock = clock ?? _systemUtcClock;

  final AgendaApplication agenda;
  final DailyLogApplicationPort? dailyLog;
  final ConstructionLivingPlanApplicationPort livingPlan;
  final MaterialRequestApplicationPort? materialRequests;
  final ActiveProjectSession session;
  final VoidCallback onCreateProject;
  final DashboardCaptureAction? onAddReminder;
  final DashboardCaptureAction? onAddAgenda;
  final DashboardProjectAction? onOpenToday;
  final DashboardProjectAction? onOpenPlan;
  final DashboardProjectAction? onOpenMaterials;
  final DashboardProjectAction? onOpenConcrete;
  final DashboardProjectAction? onOpenProjectAlbum;
  final DashboardProjectAction? onOpenWorkforce;
  final DashboardProjectAction? onOpenPhoneCall;
  final VoidCallback? onOpenBackup;
  final DashboardProjectAction? onOpenCatalog;
  final VoidCallback? onOpenAttachmentHealth;
  final DateTime Function() clock;

  @override
  State<ProjectDashboardPage> createState() => _ProjectDashboardPageState();
}

DateTime _systemUtcClock() => DateTime.now().toUtc();

enum _LoadStatus { loading, ready, error }

class _ProjectDashboardPageState extends State<ProjectDashboardPage> {
  StreamSubscription<void>? _projectSubscription;
  List<MobileProject> _projects = const [];
  ProjectProfile? _profile;
  _LoadStatus _projectStatus = _LoadStatus.loading;
  _LoadStatus _profileStatus = _LoadStatus.loading;
  int _projectGeneration = 0;
  int _profileGeneration = 0;
  bool _mutating = false;

  ProjectProfileApplication? get _profileApplication =>
      widget.agenda is ProjectProfileApplication
      ? widget.agenda as ProjectProfileApplication
      : null;

  ProjectLifecycleApplication? get _projectLifecycle =>
      widget.agenda is ProjectLifecycleApplication
      ? widget.agenda as ProjectLifecycleApplication
      : null;

  @override
  void initState() {
    super.initState();
    widget.session.addListener(_handleActiveProjectChanged);
    _projectSubscription = widget.agenda.projectChanges.listen(
      (_) => unawaited(_loadProjects(showLoading: false)),
    );
    unawaited(_loadProjects());
  }

  @override
  void dispose() {
    _projectSubscription?.cancel();
    widget.session.removeListener(_handleActiveProjectChanged);
    super.dispose();
  }

  String get _localDay {
    final local = CseTimeCodec.toIstanbul(
      CseTimeCodec.encodeUtc(widget.clock().toUtc()),
    );
    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadProjects({bool showLoading = true}) async {
    final generation = ++_projectGeneration;
    if (mounted && showLoading) {
      setState(() => _projectStatus = _LoadStatus.loading);
    }
    try {
      final projects = (await widget.agenda.listProjects())
          .where((project) => !project.isArchived)
          .toList(growable: false);
      if (!mounted || generation != _projectGeneration) return;
      widget.session.reconcile(projects);
      setState(() {
        _projects = projects;
        _projectStatus = _LoadStatus.ready;
      });
      final selected = widget.session.selectedProject(projects);
      if (selected == null) {
        _clearProfile();
      } else {
        unawaited(_loadProfile(selected.id, showLoading: showLoading));
      }
    } on Object {
      if (!mounted || generation != _projectGeneration) return;
      widget.session.clear();
      setState(() {
        _projects = const [];
        _projectStatus = _LoadStatus.error;
      });
      _clearProfile();
    }
  }

  void _handleActiveProjectChanged() {
    if (!mounted || _projectStatus != _LoadStatus.ready) return;
    final selected = widget.session.selectedProject(_projects);
    if (selected == null) {
      _clearProfile();
      return;
    }
    unawaited(_loadProfile(selected.id));
  }

  void _clearProfile() {
    _profileGeneration += 1;
    if (!mounted) return;
    setState(() {
      _profile = null;
      _profileStatus = _LoadStatus.loading;
    });
  }

  Future<void> _loadProfile(String projectId, {bool showLoading = true}) async {
    final generation = ++_profileGeneration;
    if (mounted && showLoading) {
      setState(() {
        _profile = null;
        _profileStatus = _LoadStatus.loading;
      });
    }
    final application = _profileApplication;
    if (application == null) {
      if (mounted && generation == _profileGeneration) {
        setState(() => _profileStatus = _LoadStatus.error);
      }
      return;
    }
    try {
      final profile = await application.getProjectProfile(projectId);
      if (!mounted ||
          generation != _profileGeneration ||
          widget.session.selectedProjectId != projectId) {
        return;
      }
      setState(() {
        _profile = profile;
        _profileStatus = _LoadStatus.ready;
      });
    } on Object {
      if (!mounted ||
          generation != _profileGeneration ||
          widget.session.selectedProjectId != projectId) {
        return;
      }
      setState(() => _profileStatus = _LoadStatus.error);
    }
  }

  Future<void> _runMutation(Future<void> Function() operation) async {
    if (_mutating) return;
    setState(() => _mutating = true);
    try {
      await operation();
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_messageFor(error))));
      final projectId = widget.session.selectedProjectId;
      if (projectId != null) unawaited(_loadProfile(projectId));
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  String _messageFor(Object error) => switch (error) {
    AgendaValidationFailure() => error.message,
    _ => 'Proje profili güncellenemedi. Kayıtlar korunuyor.',
  };

  Future<void> _editProjectName(MobileProject project) async {
    final application = _projectLifecycle;
    if (_mutating || application == null) return;
    final name = await showDialog<String>(
      context: context,
      builder: (context) => OwnedTextInputDialog(
        title: 'Proje adını düzenle',
        label: 'Proje adı',
        confirmLabel: 'Kaydet',
        initialValue: project.name,
        inputKey: const Key('project-profile-edit-name'),
        confirmKey: const Key('project-profile-save-name'),
        maxLength: 160,
        trimResult: true,
        validator: (value) =>
            value.trim().isEmpty ? 'Proje adı boş bırakılamaz.' : null,
      ),
    );
    if (name == null ||
        !mounted ||
        widget.session.selectedProjectId != project.id) {
      return;
    }
    await _runMutation(() async {
      final renamed = await application.renameProject(
        RenameProjectCommand(
          projectId: project.id,
          eventId: RecordId.randomUuid(),
          expectedRevision: project.revision,
          name: name,
        ),
      );
      if (!mounted) return;
      setState(() {
        _projects = [
          for (final item in _projects)
            if (item.id == renamed.id) renamed else item,
        ];
        final profile = _profile;
        if (profile != null && profile.project.id == renamed.id) {
          _profile = ProjectProfile(project: renamed, fields: profile.fields);
        }
      });
    });
  }

  Future<void> _editField(ProjectProfileField field) async {
    var label = field.label;
    var value = field.value;
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(field.isBuiltIn ? field.label : 'Alanı düzenle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!field.isBuiltIn)
              TextFormField(
                key: const Key('project-profile-edit-label'),
                initialValue: label,
                onChanged: (next) => label = next,
                autofocus: true,
                maxLength: 120,
                decoration: const InputDecoration(labelText: 'Alan adı'),
              ),
            TextFormField(
              key: const Key('project-profile-edit-value'),
              initialValue: value,
              onChanged: (next) => value = next,
              autofocus: field.isBuiltIn,
              maxLength: 4000,
              decoration: const InputDecoration(labelText: 'Değer'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            key: const Key('project-profile-save-field'),
            onPressed: () {
              final normalizedLabel = label.trim();
              if (normalizedLabel.isEmpty) return;
              Navigator.pop(context, (normalizedLabel, value));
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    if (result == null || !mounted) return;
    final application = _profileApplication;
    if (application == null) return;
    await _runMutation(() async {
      await application.updateProjectProfileField(
        UpdateProjectProfileFieldCommand(
          fieldId: field.id,
          eventId: RecordId.randomUuid(),
          projectId: field.projectId,
          expectedRevision: field.revision,
          label: result.$1,
          value: result.$2,
        ),
      );
    });
  }

  Future<void> _addField(MobileProject project) async {
    var label = '';
    var value = '';
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Özel alan ekle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              key: const Key('project-profile-new-label'),
              onChanged: (next) => label = next,
              autofocus: true,
              maxLength: 120,
              decoration: const InputDecoration(labelText: 'Alan adı'),
            ),
            TextFormField(
              key: const Key('project-profile-new-value'),
              onChanged: (next) => value = next,
              maxLength: 4000,
              decoration: const InputDecoration(labelText: 'Değer'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            key: const Key('project-profile-create-field'),
            onPressed: () {
              final normalizedLabel = label.trim();
              if (normalizedLabel.isEmpty) return;
              Navigator.pop(context, (normalizedLabel, value));
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
    if (result == null || !mounted) return;
    final application = _profileApplication;
    if (application == null) return;
    await _runMutation(() async {
      await application.createProjectProfileField(
        CreateProjectProfileFieldCommand(
          id: RecordId.randomUuid(),
          eventId: RecordId.randomUuid(),
          projectId: project.id,
          label: result.$1,
          value: result.$2,
        ),
      );
    });
  }

  Future<void> _archiveField(ProjectProfileField field) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Özel alanı arşivle'),
        content: Text('${field.label} profil görünümünden kaldırılacak.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            key: const Key('project-profile-confirm-archive'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Arşivle'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final application = _profileApplication;
    if (application == null) return;
    await _runMutation(() async {
      await application.mutateProjectProfileFieldArchive(
        MutateProjectProfileFieldArchiveCommand(
          fieldId: field.id,
          eventId: RecordId.randomUuid(),
          projectId: field.projectId,
          expectedRevision: field.revision,
          archive: true,
        ),
      );
    });
  }

  Future<void> _reorderFields(int oldIndex, int newIndex) async {
    final profile = _profile;
    final application = _profileApplication;
    if (profile == null || application == null || _mutating) return;
    final fields = [...profile.fields];
    final moved = fields.removeAt(oldIndex);
    fields.insert(newIndex, moved);
    setState(
      () => _profile = ProjectProfile(project: profile.project, fields: fields),
    );
    await _runMutation(() async {
      await application.reorderProjectProfileFields(
        ReorderProjectProfileFieldsCommand(
          eventId: RecordId.randomUuid(),
          projectId: profile.project.id,
          fields: [
            for (final field in fields)
              ProjectProfileFieldOrder(
                fieldId: field.id,
                expectedRevision: field.revision,
              ),
          ],
        ),
      );
    });
  }

  Future<void> _runCapture(DashboardCaptureAction? action) async {
    final projectId = widget.session.selectedProjectId;
    if (action == null || projectId == null) return;
    await action(projectId, _localDay);
  }

  void _openProjectAction(DashboardProjectAction? action, String projectId) {
    if (action != null) action(projectId);
  }

  Future<void> _openTools(MobileProject project) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          key: const Key('project-profile-tools-sheet'),
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 12),
          children: [
            ListTile(
              title: const Text('Araçlar'),
              subtitle: Text(project.name),
            ),
            _toolTile(
              sheetContext,
              key: const Key('dashboard-create-project'),
              icon: Icons.add_business_rounded,
              title: 'Yeni proje',
              action: widget.onCreateProject,
            ),
            _toolTile(
              sheetContext,
              key: const Key('dashboard-quick-reminder'),
              icon: Icons.notifications_active_outlined,
              title: 'Hatırlatıcı ekle',
              action: widget.onAddReminder == null
                  ? null
                  : () => _runCapture(widget.onAddReminder),
            ),
            _toolTile(
              sheetContext,
              key: const Key('dashboard-quick-agenda'),
              icon: Icons.edit_note_outlined,
              title: 'Ajanda kaydı ekle',
              action: widget.onAddAgenda == null
                  ? null
                  : () => _runCapture(widget.onAddAgenda),
            ),
            _toolTile(
              sheetContext,
              key: const Key('dashboard-open-today'),
              icon: Icons.today_outlined,
              title: 'Günlük Log',
              action: widget.onOpenToday == null
                  ? null
                  : () => _openProjectAction(widget.onOpenToday, project.id),
            ),
            _toolTile(
              sheetContext,
              key: const Key('dashboard-open-plan'),
              icon: Icons.calendar_view_week_outlined,
              title: '7 Günlük Plan',
              action: widget.onOpenPlan == null
                  ? null
                  : () => _openProjectAction(widget.onOpenPlan, project.id),
            ),
            _toolTile(
              sheetContext,
              key: const Key('dashboard-open-materials'),
              icon: Icons.inventory_2_outlined,
              title: 'İstenecek Malzemeler',
              action: widget.onOpenMaterials == null
                  ? null
                  : () =>
                        _openProjectAction(widget.onOpenMaterials, project.id),
            ),
            _toolTile(
              sheetContext,
              key: const Key('dashboard-concrete-package'),
              icon: Icons.foundation_outlined,
              title: 'Beton Paketi',
              action: widget.onOpenConcrete == null
                  ? null
                  : () => _openProjectAction(widget.onOpenConcrete, project.id),
            ),
            _toolTile(
              sheetContext,
              key: const Key('dashboard-project-album'),
              icon: Icons.photo_library_outlined,
              title: 'Proje Albümü',
              action: widget.onOpenProjectAlbum == null
                  ? null
                  : () => _openProjectAction(
                      widget.onOpenProjectAlbum,
                      project.id,
                    ),
            ),
            _toolTile(
              sheetContext,
              key: const Key('dashboard-workforce-directory'),
              icon: Icons.contacts_outlined,
              title: 'Saha Rehberi',
              action: widget.onOpenWorkforce == null
                  ? null
                  : () =>
                        _openProjectAction(widget.onOpenWorkforce, project.id),
            ),
            _toolTile(
              sheetContext,
              key: const Key('dashboard-phone-call-result'),
              icon: Icons.phone_in_talk_outlined,
              title: 'Görüşme sonucu',
              action: widget.onOpenPhoneCall == null
                  ? null
                  : () =>
                        _openProjectAction(widget.onOpenPhoneCall, project.id),
            ),
            _toolTile(
              sheetContext,
              key: const Key('dashboard-memory-backup'),
              icon: Icons.settings_backup_restore_rounded,
              title: 'Hafıza ve Yedekleme',
              action: widget.onOpenBackup,
            ),
            _toolTile(
              sheetContext,
              key: const Key('dashboard-attachment-catalog'),
              icon: Icons.folder_copy_outlined,
              title: 'Dosya Kataloğu',
              action: widget.onOpenCatalog == null
                  ? null
                  : () => _openProjectAction(widget.onOpenCatalog, project.id),
            ),
            _toolTile(
              sheetContext,
              key: const Key('dashboard-attachment-health'),
              icon: Icons.health_and_safety_outlined,
              title: 'Dosya sağlığı',
              action: widget.onOpenAttachmentHealth,
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolTile(
    BuildContext sheetContext, {
    required Key key,
    required IconData icon,
    required String title,
    required FutureOr<void> Function()? action,
  }) => ListTile(
    key: key,
    leading: Icon(icon),
    title: Text(title),
    enabled: action != null,
    onTap: action == null
        ? null
        : () {
            Navigator.pop(sheetContext);
            Future<void>.sync(action);
          },
  );

  @override
  Widget build(BuildContext context) => switch (_projectStatus) {
    _LoadStatus.loading => const Center(
      key: Key('dashboard-loading-projects'),
      child: CircularProgressIndicator(),
    ),
    _LoadStatus.error => _ProjectStateSurface(
      key: const Key('dashboard-project-error'),
      icon: Icons.warning_amber_rounded,
      title: 'Projeler güvenli biçimde okunamadı.',
      body: 'Hiçbir proje kaydı değiştirilmedi.',
      actionIcon: Icons.refresh_rounded,
      actionLabel: 'Tekrar dene',
      onAction: _loadProjects,
    ),
    _LoadStatus.ready => _buildReady(),
  };

  Widget _buildReady() {
    if (_projects.isEmpty) {
      return _ProjectStateSurface(
        key: const Key('dashboard-no-project'),
        icon: Icons.apartment_rounded,
        title: 'İlk projenizi oluşturun',
        body: 'Proje profili, saha bilgileriniz için tek başlangıç noktasıdır.',
        actionIcon: Icons.add_business_rounded,
        actionLabel: 'Yeni proje oluştur',
        actionKey: const Key('dashboard-create-project'),
        onAction: widget.onCreateProject,
      );
    }
    final selected = widget.session.selectedProject(_projects);
    if (selected == null) {
      return _ProjectStateSurface(
        key: const Key('dashboard-project-selection-required'),
        icon: Icons.rule_folder_outlined,
        title: 'Çalışacağınız projeyi seçin',
        body: 'Birden fazla aktif proje var. Aktif projeyi üst çubuktan seçin.',
        actionIcon: Icons.add_business_rounded,
        actionLabel: 'Yeni proje',
        actionKey: const Key('dashboard-create-project'),
        onAction: widget.onCreateProject,
      );
    }
    return _buildProfile(selected);
  }

  Widget _buildProfile(MobileProject project) {
    final profile = _profile;
    return ListView(
      key: const Key('project-profile-home'),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
      children: [
        Card(
          key: const Key('project-profile-header'),
          child: InkWell(
            onTap: _mutating || _projectLifecycle == null
                ? null
                : () => unawaited(_editProjectName(project)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Proje Profili',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    project.name,
                    key: const Key('project-profile-name'),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (_profileStatus == _LoadStatus.loading ||
            profile == null && _profileStatus == _LoadStatus.ready)
          const Center(
            key: Key('project-profile-loading'),
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_profileStatus == _LoadStatus.error)
          _ProjectStateSurface(
            key: const Key('project-profile-error'),
            icon: Icons.warning_amber_rounded,
            title: 'Proje profili okunamadı.',
            body: 'Kayıtlar değiştirilmedi.',
            actionIcon: Icons.refresh_rounded,
            actionLabel: 'Tekrar dene',
            onAction: () => _loadProfile(project.id),
          )
        else if (profile != null && profile.project.id == project.id) ...[
          ReorderableListView.builder(
            key: const Key('project-profile-fields'),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: profile.fields.length,
            onReorderItem: _reorderFields,
            itemBuilder: (context, index) {
              final field = profile.fields[index];
              return Card(
                key: ValueKey('project-profile-field-${field.id}'),
                child: ListTile(
                  onTap: _mutating ? null : () => _editField(field),
                  title: Text(field.label),
                  subtitle: Text(
                    field.value.isEmpty ? 'Henüz girilmedi' : field.value,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!field.isBuiltIn)
                        IconButton(
                          key: ValueKey('project-profile-archive-${field.id}'),
                          tooltip: 'Alanı arşivle',
                          onPressed: _mutating
                              ? null
                              : () => _archiveField(field),
                          icon: const Icon(Icons.archive_outlined),
                        ),
                      ReorderableDragStartListener(
                        key: ValueKey('project-profile-drag-${field.id}'),
                        index: index,
                        enabled: !_mutating,
                        child: const Padding(
                          padding: EdgeInsets.all(12),
                          child: Icon(Icons.drag_handle_rounded),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const Key('project-profile-add-field'),
              onPressed: _mutating ? null : () => _addField(project),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Özel alan ekle'),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            key: const Key('project-profile-tools'),
            leading: const Icon(Icons.widgets_outlined),
            title: const Text('Araçlar'),
            subtitle: const Text('Saha akışları ve güvenli yardımcı işlemler'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _openTools(project),
          ),
        ),
      ],
    );
  }
}

class _ProjectStateSurface extends StatelessWidget {
  const _ProjectStateSurface({
    required this.icon,
    required this.title,
    required this.body,
    required this.actionIcon,
    required this.actionLabel,
    required this.onAction,
    this.actionKey,
    super.key,
  });

  final IconData icon;
  final String title;
  final String body;
  final IconData actionIcon;
  final String actionLabel;
  final VoidCallback onAction;
  final Key? actionKey;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(body, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            key: actionKey,
            onPressed: onAction,
            icon: Icon(actionIcon),
            label: Text(actionLabel),
          ),
        ],
      ),
    ),
  );
}
