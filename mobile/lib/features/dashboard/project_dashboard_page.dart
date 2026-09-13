import 'dart:async';

import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/application/construction_living_plan_application.dart';
import 'package:chief_site_engineer/application/daily_log_application.dart';
import 'package:chief_site_engineer/application/material_request_application.dart';
import 'package:chief_site_engineer/application/project_information_application.dart';
import 'package:chief_site_engineer/core/record_id.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/project_information_models.dart';
import 'package:chief_site_engineer/features/owned_text_input_dialog.dart';
import 'package:chief_site_engineer/features/project_context/active_project_session.dart';
import 'package:flutter/material.dart';

typedef DashboardCaptureAction =
    Future<bool> Function(String projectId, String localDay);
typedef DashboardProjectAction = void Function(String projectId);
typedef DashboardProjectReadiness = void Function(List<MobileProject> projects);

class ProjectDashboardPage extends StatefulWidget {
  const ProjectDashboardPage({
    required this.agenda,
    required this.livingPlan,
    required this.session,
    required this.onCreateProject,
    this.projectInformation,
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
    this.onOpenCatalog,
    this.onOpenProjectInformation,
    this.onFirstSuccessfulProjectRead,
    DateTime Function()? clock,
    super.key,
  }) : clock = clock ?? _systemUtcClock;

  final AgendaApplication agenda;
  final ProjectInformationApplication? projectInformation;
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
  final DashboardProjectAction? onOpenCatalog;
  final DashboardProjectAction? onOpenProjectInformation;
  final DashboardProjectReadiness? onFirstSuccessfulProjectRead;
  final DateTime Function() clock;

  @override
  State<ProjectDashboardPage> createState() => _ProjectDashboardPageState();
}

DateTime _systemUtcClock() => DateTime.now().toUtc();

enum _LoadStatus { loading, ready, error }

class _ProjectDashboardPageState extends State<ProjectDashboardPage> {
  StreamSubscription<void>? _projectSubscription;
  ProjectInformationSession? _informationSession;
  List<MobileProject> _projects = const [];
  ProjectInformationSnapshot? _information;
  ProjectInformationSourceStatus? _informationFailure;
  _LoadStatus _projectStatus = _LoadStatus.loading;
  _LoadStatus _informationStatus = _LoadStatus.loading;
  int _projectGeneration = 0;
  int _informationGeneration = 0;
  bool _mutating = false;
  bool _reportedFirstSuccessfulProjectRead = false;
  EdgeDraggingAutoScroller? _fieldAutoScroller;

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
    _informationSession = widget.projectInformation?.createSession();
    widget.session.addListener(_handleActiveProjectChanged);
    _projectSubscription = widget.agenda.projectChanges.listen(
      (_) => unawaited(_loadProjects(showLoading: false)),
    );
    unawaited(_loadProjects());
  }

  @override
  void dispose() {
    _fieldAutoScroller?.stopAutoScroll();
    _informationSession?.clearProject();
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
      _reportFirstSuccessfulProjectRead(projects);
      final selected = widget.session.selectedProject(projects);
      if (selected == null) {
        _clearInformation();
      } else {
        unawaited(_loadInformation(selected.id, showLoading: showLoading));
      }
    } on Object {
      if (!mounted || generation != _projectGeneration) return;
      widget.session.clear();
      setState(() {
        _projects = const [];
        _projectStatus = _LoadStatus.error;
      });
      _clearInformation();
    }
  }

  void _reportFirstSuccessfulProjectRead(List<MobileProject> projects) {
    if (_reportedFirstSuccessfulProjectRead) return;
    _reportedFirstSuccessfulProjectRead = true;
    final callback = widget.onFirstSuccessfulProjectRead;
    if (callback == null) return;
    final snapshot = List<MobileProject>.unmodifiable(projects);
    callback(snapshot);
  }

  void _handleActiveProjectChanged() {
    if (!mounted || _projectStatus != _LoadStatus.ready) return;
    final selected = widget.session.selectedProject(_projects);
    if (selected == null) {
      _clearInformation();
      return;
    }
    _clearInformation();
    unawaited(_loadInformation(selected.id));
  }

  void _clearInformation() {
    _informationGeneration += 1;
    _informationSession?.clearProject();
    if (!mounted) return;
    setState(() {
      _information = null;
      _informationFailure = null;
      _informationStatus = _LoadStatus.loading;
    });
  }

  Future<void> _loadInformation(
    String projectId, {
    bool showLoading = true,
  }) async {
    final generation = ++_informationGeneration;
    if (mounted && showLoading) {
      setState(() {
        _information = null;
        _informationFailure = null;
        _informationStatus = _LoadStatus.loading;
      });
    }
    final session = _informationSession;
    if (session == null) {
      if (mounted && generation == _informationGeneration) {
        setState(() => _informationStatus = _LoadStatus.error);
      }
      return;
    }
    final result = await session.loadProject(projectId);
    if (!mounted ||
        generation != _informationGeneration ||
        widget.session.selectedProjectId != projectId) {
      return;
    }
    switch (result) {
      case ProjectInformationReady():
        if (result.snapshot.projectId != projectId) return;
        setState(() {
          _information = result.snapshot;
          _informationFailure = null;
          _informationStatus = _LoadStatus.ready;
        });
      case ProjectInformationLoadFailure():
        setState(() {
          _information = null;
          _informationFailure = result.failure;
          _informationStatus = _LoadStatus.error;
        });
      case ProjectInformationSuperseded():
        break;
    }
  }

  Future<void> _reloadInformationIfStillSelected(String projectId) async {
    if (!mounted || widget.session.selectedProjectId != projectId) return;
    await _loadInformation(projectId, showLoading: false);
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
      if (projectId != null) unawaited(_loadInformation(projectId));
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  String _messageFor(Object error) => switch (error) {
    AgendaValidationFailure() => error.message,
    _ => 'Proje bilgileri güncellenemedi. Kayıtlar korunuyor.',
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
      });
      if (widget.session.selectedProjectId == project.id) {
        await _loadInformation(project.id, showLoading: false);
      }
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
          if (!field.isBuiltIn)
            TextButton.icon(
              key: ValueKey('project-profile-archive-${field.id}'),
              onPressed: () {
                Navigator.pop(context);
                unawaited(_archiveField(field));
              },
              icon: const Icon(Icons.archive_outlined),
              label: const Text('Arşivle'),
            ),
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
      await _reloadInformationIfStillSelected(field.projectId);
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
      await _reloadInformationIfStillSelected(project.id);
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
      await _reloadInformationIfStillSelected(field.projectId);
    });
  }

  Future<void> _reorderFields(
    MobileProject project,
    List<ProjectProfileField> visibleFields,
    int oldIndex,
    int newIndex,
  ) async {
    final application = _profileApplication;
    final snapshot = _information;
    if (application == null ||
        snapshot == null ||
        snapshot.projectId != project.id ||
        widget.session.selectedProjectId != project.id ||
        _mutating) {
      return;
    }
    final currentFields = snapshot.profileFields
        .where((field) => !field.isArchived)
        .toList(growable: false);
    if (currentFields.length != visibleFields.length ||
        oldIndex < 0 ||
        oldIndex >= currentFields.length ||
        newIndex < 0 ||
        newIndex >= currentFields.length ||
        currentFields.indexed.any(
          (entry) =>
              entry.$2.id != visibleFields[entry.$1].id ||
              entry.$2.revision != visibleFields[entry.$1].revision,
        )) {
      return;
    }
    final reordered = [...currentFields];
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);
    await _runMutation(() async {
      await application.reorderProjectProfileFields(
        ReorderProjectProfileFieldsCommand(
          eventId: RecordId.randomUuid(),
          projectId: project.id,
          fields: [
            for (final field in reordered)
              ProjectProfileFieldOrder(
                fieldId: field.id,
                expectedRevision: field.revision,
              ),
          ],
        ),
      );
      await _reloadInformationIfStillSelected(project.id);
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
            Semantics(
              key: const Key('dashboard-project-files-section'),
              header: true,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Text(
                  'Proje dosyaları',
                  style: Theme.of(sheetContext).textTheme.titleSmall,
                ),
              ),
            ),
            _toolTile(
              sheetContext,
              key: const Key('dashboard-project-album'),
              icon: Icons.photo_library_outlined,
              title: 'Proje Albümü',
              subtitle: 'Proje medyası ve kaynak kayıtları',
              action: widget.onOpenProjectAlbum == null
                  ? null
                  : () => _openProjectAction(
                      widget.onOpenProjectAlbum,
                      project.id,
                    ),
            ),
            _toolTile(
              sheetContext,
              key: const Key('dashboard-attachment-catalog'),
              icon: Icons.folder_copy_outlined,
              title: 'Dosya Kataloğu',
              subtitle: 'Ek metadata, bağlantı ve bütünlük bilgileri',
              action: widget.onOpenCatalog == null
                  ? null
                  : () => _openProjectAction(widget.onOpenCatalog, project.id),
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
    String? subtitle,
    required FutureOr<void> Function()? action,
  }) => ListTile(
    key: key,
    leading: Icon(icon),
    title: Text(title),
    subtitle: subtitle == null ? null : Text(subtitle),
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
    return _buildProject(selected);
  }

  Widget _buildProject(MobileProject project) {
    return ListView(
      key: const Key('project-profile-home'),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
      children: [
        Card(
          key: const Key('project-profile-header'),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _mutating || _projectLifecycle == null
                        ? null
                        : () => unawaited(_editProjectName(project)),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Aktif Proje',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            project.name,
                            key: const Key('project-profile-name'),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('project-profile-create-project'),
                  tooltip: 'Yeni Proje',
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  onPressed: widget.onCreateProject,
                  icon: const Icon(Icons.add_business_rounded),
                ),
                IconButton(
                  key: const Key('project-profile-tools'),
                  tooltip: 'Araçlar',
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  onPressed: () => _openTools(project),
                  icon: const Icon(Icons.widgets_outlined),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Semantics(
          header: true,
          child: Text(
            'Hızlı Bilgiler',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 8),
        _buildQuickInformation(project),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const Key('dashboard-open-project-information'),
          onPressed:
              widget.onOpenProjectInformation == null ||
                  _informationStatus != _LoadStatus.ready
              ? null
              : () => _openProjectAction(
                  widget.onOpenProjectInformation,
                  project.id,
                ),
          icon: const Icon(Icons.list_alt_rounded),
          label: const Text('Tüm proje bilgileri'),
        ),
        if (_profileApplication != null &&
            _informationStatus == _LoadStatus.ready &&
            _information?.projectId == project.id &&
            _information!.statusFor(ProjectInformationSource.profile).state !=
                ProjectInformationReadState.failed) ...[
          const SizedBox(height: 8),
          _buildProfileEditor(project, _information!),
        ],
      ],
    );
  }

  Widget _buildProfileEditor(
    MobileProject project,
    ProjectInformationSnapshot snapshot,
  ) {
    final fields = snapshot.profileFields
        .where((field) => !field.isArchived)
        .toList(growable: false);
    return Card(
      key: const Key('project-profile-editor'),
      child: ExpansionTile(
        leading: const Icon(Icons.edit_note_rounded),
        title: const Text('Profil alanlarını düzenle'),
        subtitle: const Text('Mevcut alanları düzenle, ekle veya sırala'),
        childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 520 ? 3 : 2;
              final width =
                  (constraints.maxWidth - (columns - 1) * 8) / columns;
              final height = 64 + MediaQuery.textScalerOf(context).scale(52);
              return Wrap(
                key: const Key('project-profile-fields'),
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var index = 0; index < fields.length; index++)
                    SizedBox(
                      key: ValueKey(
                        'project-profile-field-${fields[index].id}',
                      ),
                      width: width,
                      height: height,
                      child: _buildFieldCell(
                        project,
                        fields,
                        index,
                        width,
                        height,
                      ),
                    ),
                  SizedBox(
                    width: width,
                    height: height,
                    child: Tooltip(
                      message: 'Özel alan ekle',
                      child: OutlinedButton(
                        key: const Key('project-profile-add-field'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(8),
                        ),
                        onPressed: _mutating ? null : () => _addField(project),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_rounded),
                            SizedBox(height: 4),
                            Text(
                              'Özel alan ekle',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFieldCell(
    MobileProject project,
    List<ProjectProfileField> fields,
    int index,
    double width,
    double height,
  ) {
    final field = fields[index];
    return DragTarget<ProjectProfileField>(
      onWillAcceptWithDetails: (details) =>
          !_mutating &&
          details.data.projectId == project.id &&
          details.data.id != field.id &&
          fields.any(
            (item) =>
                item.id == details.data.id &&
                item.revision == details.data.revision,
          ),
      onAcceptWithDetails: (details) {
        final oldIndex = fields.indexWhere(
          (item) => item.id == details.data.id,
        );
        if (oldIndex >= 0) {
          unawaited(_reorderFields(project, fields, oldIndex, index));
        }
      },
      builder: (context, candidates, rejected) => Card(
        margin: EdgeInsets.zero,
        color: candidates.isEmpty
            ? null
            : Theme.of(context).colorScheme.secondaryContainer,
        child: InkWell(
          onTap: _mutating ? null : () => _editField(field),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  field.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Text(
                    field.value.isEmpty ? 'Henüz girilmedi' : field.value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Draggable<ProjectProfileField>(
                      key: ValueKey('project-profile-drag-${field.id}'),
                      data: field,
                      maxSimultaneousDrags: _mutating ? 0 : 1,
                      onDragStarted: () {
                        _fieldAutoScroller?.stopAutoScroll();
                        _fieldAutoScroller = EdgeDraggingAutoScroller(
                          Scrollable.of(context),
                          velocityScalar: 30,
                        );
                      },
                      onDragUpdate: (details) {
                        _fieldAutoScroller?.startAutoScrollIfNecessary(
                          Rect.fromCenter(
                            center: details.globalPosition,
                            width: 40,
                            height: 40,
                          ),
                        );
                      },
                      onDragEnd: (_) => _fieldAutoScroller?.stopAutoScroll(),
                      feedback: Material(
                        elevation: 6,
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: width,
                          height: height,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              field.label,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                      child: const Tooltip(
                        message: 'Sıralamak için sürükleyin',
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: Icon(Icons.drag_handle_rounded, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickInformation(MobileProject project) {
    if (_informationStatus == _LoadStatus.loading) {
      return const Card(
        key: Key('dashboard-project-information-loading'),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    final snapshot = _information;
    if (_informationStatus == _LoadStatus.error ||
        snapshot == null ||
        snapshot.projectId != project.id) {
      return _ProjectStateSurface(
        key: const Key('dashboard-project-information-error'),
        icon: Icons.warning_amber_rounded,
        title: 'Proje bilgileri okunamadı.',
        body:
            _informationFailure?.errorCode ==
                'project_information_project_changed_during_read'
            ? 'Proje okuma sırasında değişti. Güncel bilgileri yeniden yükleyin.'
            : 'Kayıtlar değiştirilmedi.',
        actionIcon: Icons.refresh_rounded,
        actionLabel: 'Tekrar dene',
        onAction: () => _loadInformation(project.id),
      );
    }
    final items = _quickItems(snapshot);
    final hasFailure = snapshot.sourceStatuses.any(
      (status) => status.state == ProjectInformationReadState.failed,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasFailure)
          Card(
            key: const Key('dashboard-project-information-partial-error'),
            color: Theme.of(context).colorScheme.errorContainer,
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Bazı bilgiler okunamadı; boş alanlardan ayrı olarak işaretlendi.',
              ),
            ),
          ),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 520 ? 3 : 2;
            final width = (constraints.maxWidth - (columns - 1) * 8) / columns;
            return Wrap(
              key: const Key('dashboard-quick-information'),
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in items)
                  SizedBox(
                    width: width,
                    child: Card(
                      key: ValueKey('dashboard-quick-${item.key}'),
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.value,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _QuickItem {
  const _QuickItem(this.key, this.label, this.value);

  final String key;
  final String label;
  final String value;
}

List<_QuickItem> _quickItems(ProjectInformationSnapshot snapshot) {
  final metadataStatus = snapshot.statusFor(ProjectInformationSource.metadata);
  final profileStatus = snapshot.statusFor(ProjectInformationSource.profile);
  final inventoryStatus = snapshot.statusFor(
    ProjectInformationSource.inventory,
  );
  final fields = snapshot.profileFields.where((field) => !field.isArchived);
  String? profileValue(ProjectProfileBuiltinField builtin) {
    for (final field in fields) {
      if (field.builtinField == builtin && field.value.trim().isNotEmpty) {
        return field.value.trim();
      }
    }
    return null;
  }

  final manualArea = profileValue(ProjectProfileBuiltinField.totalArea);
  final derived = snapshot.derivedInventoryTotals;
  final derivedArea =
      derived.areaState == ProjectInformationDerivedAreaState.available
      ? '${_formatQuickNumber(derived.totalArea!)} '
            '${derived.totalAreaUnit!} (türetilmiş)'
      : null;
  final manualFloors = profileValue(ProjectProfileBuiltinField.totalFloors);
  return <_QuickItem>[
    _QuickItem(
      'address',
      'Adres',
      metadataStatus.state == ProjectInformationReadState.failed
          ? 'Okunamadı'
          : _quickValue(snapshot.metadata?.address),
    ),
    _QuickItem(
      'total-area',
      'Toplam alan',
      profileStatus.state == ProjectInformationReadState.failed
          ? 'Okunamadı'
          : manualArea ??
                (inventoryStatus.state == ProjectInformationReadState.failed
                    ? 'Okunamadı'
                    : derivedArea ?? 'Henüz girilmedi'),
    ),
    _QuickItem(
      'block-count',
      'Aktif blok',
      inventoryStatus.state == ProjectInformationReadState.failed
          ? 'Okunamadı'
          : '${derived.activeBlockCount} (türetilmiş)',
    ),
    _QuickItem(
      'total-floors',
      'Toplam kat',
      profileStatus.state == ProjectInformationReadState.failed
          ? 'Okunamadı'
          : manualFloors ??
                (inventoryStatus.state == ProjectInformationReadState.failed
                    ? 'Okunamadı'
                    : '${derived.activeFloorCount} (türetilmiş)'),
    ),
    _QuickItem(
      'yibf',
      'YİBF No',
      profileStatus.state == ProjectInformationReadState.failed
          ? 'Okunamadı'
          : profileValue(ProjectProfileBuiltinField.yibfNumber) ??
                'Henüz girilmedi',
    ),
  ];
}

String _quickValue(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty
      ? 'Henüz girilmedi'
      : normalized;
}

String _formatQuickNumber(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');

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
