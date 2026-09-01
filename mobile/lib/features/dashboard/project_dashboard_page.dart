import 'dart:async';

import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/application/construction_living_plan_application.dart';
import 'package:chief_site_engineer/application/daily_log_application.dart';
import 'package:chief_site_engineer/application/material_request_application.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/construction_living_plan_models.dart';
import 'package:chief_site_engineer/domain/daily_log_models.dart';
import 'package:chief_site_engineer/domain/material_request_models.dart';
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

enum _ProjectLoadStatus { loading, ready, error }

enum _SectionStatus { idle, loading, ready, error, disabled }

class _SectionState<T> {
  const _SectionState._(this.status, {this.value});

  const _SectionState.idle() : this._(_SectionStatus.idle);
  const _SectionState.loading() : this._(_SectionStatus.loading);
  const _SectionState.ready(T value)
    : this._(_SectionStatus.ready, value: value);
  const _SectionState.error() : this._(_SectionStatus.error);
  const _SectionState.disabled() : this._(_SectionStatus.disabled);

  final _SectionStatus status;
  final T? value;
}

class _ProjectDashboardPageState extends State<ProjectDashboardPage> {
  StreamSubscription<void>? _projectSubscription;
  List<MobileProject> _projects = const [];
  _ProjectLoadStatus _projectStatus = _ProjectLoadStatus.loading;
  _SectionState<DailyLogDay> _today = const _SectionState.idle();
  _SectionState<List<ConstructionLivingPlanWindowItem>> _plan =
      const _SectionState.idle();
  _SectionState<List<MaterialRequest>> _materials = const _SectionState.idle();
  int _projectGeneration = 0;
  int _todayGeneration = 0;
  int _planGeneration = 0;
  int _materialGeneration = 0;
  int _loadAllGeneration = 0;
  Future<void> _dashboardReadTail = Future<void>.value();

  @override
  void initState() {
    super.initState();
    _projectSubscription = widget.agenda.projectChanges.listen(
      (_) => unawaited(_loadProjects()),
    );
    unawaited(_loadProjects());
  }

  @override
  void dispose() {
    _projectSubscription?.cancel();
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

  Future<void> _loadProjects() async {
    final generation = ++_projectGeneration;
    if (mounted) setState(() => _projectStatus = _ProjectLoadStatus.loading);
    try {
      final projects = (await widget.agenda.listProjects())
          .where((project) => !project.isArchived)
          .toList(growable: false);
      if (!mounted || generation != _projectGeneration) return;
      widget.session.reconcile(projects);
      setState(() {
        _projects = projects;
        _projectStatus = _ProjectLoadStatus.ready;
      });
      if (widget.session.selectedProject(projects) case final project?) {
        _loadAll(project.id);
      } else {
        _clearSections();
      }
    } on Object {
      if (!mounted || generation != _projectGeneration) return;
      widget.session.clear();
      setState(() {
        _projects = const [];
        _projectStatus = _ProjectLoadStatus.error;
      });
      _clearSections();
    }
  }

  void _clearSections() {
    _loadAllGeneration += 1;
    _todayGeneration += 1;
    _planGeneration += 1;
    _materialGeneration += 1;
    if (!mounted) return;
    setState(() {
      _today = widget.dailyLog == null
          ? const _SectionState.disabled()
          : const _SectionState.idle();
      _plan = const _SectionState.idle();
      _materials = widget.materialRequests == null
          ? const _SectionState.disabled()
          : const _SectionState.idle();
    });
  }

  void _loadAll(String projectId) {
    final generation = ++_loadAllGeneration;
    _todayGeneration += 1;
    _planGeneration += 1;
    _materialGeneration += 1;
    if (!mounted) return;
    setState(() {
      _today = widget.dailyLog == null
          ? const _SectionState.disabled()
          : const _SectionState.loading();
      _plan = const _SectionState.loading();
      _materials = widget.materialRequests == null
          ? const _SectionState.disabled()
          : const _SectionState.loading();
    });
    unawaited(_loadAllInOrder(projectId, generation));
  }

  Future<void> _loadAllInOrder(String projectId, int generation) async {
    await _loadPipelineSection(
      projectId,
      generation,
      () => _loadToday(projectId),
    );
    if (!_acceptLoadAll(projectId, generation)) return;
    await _loadPipelineSection(
      projectId,
      generation,
      () => _loadPlan(projectId),
    );
    if (!_acceptLoadAll(projectId, generation)) return;
    await _loadPipelineSection(
      projectId,
      generation,
      () => _loadMaterials(projectId),
    );
  }

  Future<void> _loadPipelineSection(
    String projectId,
    int generation,
    Future<void> Function() operation,
  ) => _enqueueDashboardRead(() async {
    if (!_acceptLoadAll(projectId, generation)) return;
    await operation();
  });

  Future<void> _enqueueDashboardRead(Future<void> Function() operation) {
    final completer = Completer<void>();
    _dashboardReadTail = _dashboardReadTail.then((_) async {
      try {
        await operation();
        completer.complete();
      } on Object catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  Future<void> _loadToday(String projectId) async {
    final application = widget.dailyLog;
    if (application == null) {
      if (mounted) setState(() => _today = const _SectionState.disabled());
      return;
    }
    final generation = ++_todayGeneration;
    setState(() => _today = const _SectionState.loading());
    try {
      final value = await application.loadDay(
        projectId: projectId,
        localDay: _localDay,
      );
      if (!_acceptSectionResult(projectId, generation, _todayGeneration)) {
        return;
      }
      setState(() => _today = _SectionState.ready(value));
    } on Object {
      if (!_acceptSectionResult(projectId, generation, _todayGeneration)) {
        return;
      }
      setState(() => _today = const _SectionState.error());
    }
  }

  Future<void> _loadPlan(String projectId) async {
    final generation = ++_planGeneration;
    setState(() => _plan = const _SectionState.loading());
    final day = DateTime.parse(_localDay);
    try {
      final value = await widget.livingPlan.loadSevenDayPlan(
        projectId: projectId,
        windowStart: DateTime(day.year, day.month, day.day),
      );
      if (!_acceptSectionResult(projectId, generation, _planGeneration)) {
        return;
      }
      setState(() => _plan = _SectionState.ready(value));
    } on Object {
      if (!_acceptSectionResult(projectId, generation, _planGeneration)) {
        return;
      }
      setState(() => _plan = const _SectionState.error());
    }
  }

  Future<void> _loadMaterials(String projectId) async {
    final application = widget.materialRequests;
    if (application == null) {
      if (mounted) {
        setState(() => _materials = const _SectionState.disabled());
      }
      return;
    }
    final generation = ++_materialGeneration;
    setState(() => _materials = const _SectionState.loading());
    try {
      final value = await application.listMaterialRequests(
        projectId: projectId,
        kind: MaterialRequestListKind.open,
      );
      if (!_acceptSectionResult(projectId, generation, _materialGeneration)) {
        return;
      }
      setState(() => _materials = _SectionState.ready(value));
    } on Object {
      if (!_acceptSectionResult(projectId, generation, _materialGeneration)) {
        return;
      }
      setState(() => _materials = const _SectionState.error());
    }
  }

  bool _acceptSectionResult(
    String projectId,
    int generation,
    int currentGeneration,
  ) =>
      mounted &&
      generation == currentGeneration &&
      widget.session.selectedProjectId == projectId;

  bool _acceptLoadAll(String projectId, int generation) =>
      mounted &&
      generation == _loadAllGeneration &&
      widget.session.selectedProjectId == projectId;

  void _reloadSection(String projectId, Future<void> Function() operation) {
    unawaited(
      _enqueueDashboardRead(() async {
        if (!mounted || widget.session.selectedProjectId != projectId) return;
        await operation();
      }),
    );
  }

  void _selectProject(String projectId) {
    if (!widget.session.select(projectId, _projects)) return;
    setState(() {});
    _loadAll(projectId);
  }

  Future<void> _showProjectSelector() async {
    final projectId = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 12),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(
                'Aktif proje seç',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            for (final project in _projects)
              ListTile(
                key: ValueKey('dashboard-project-${project.id}'),
                leading: const Icon(Icons.apartment_rounded),
                title: Text(project.name),
                trailing: widget.session.selectedProjectId == project.id
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () => Navigator.pop(context, project.id),
              ),
          ],
        ),
      ),
    );
    if (projectId != null && mounted) _selectProject(projectId);
  }

  Future<void> _runCapture(DashboardCaptureAction? action) async {
    final projectId = widget.session.selectedProjectId;
    if (action == null || projectId == null) return;
    final changed = await action(projectId, _localDay);
    if (changed && mounted && widget.session.selectedProjectId == projectId) {
      _reloadSection(projectId, () => _loadToday(projectId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return switch (_projectStatus) {
      _ProjectLoadStatus.loading => const Center(
        key: Key('dashboard-loading-projects'),
        child: CircularProgressIndicator(),
      ),
      _ProjectLoadStatus.error => _ProjectStateSurface(
        key: const Key('dashboard-project-error'),
        icon: Icons.warning_amber_rounded,
        title: 'Projeler güvenli biçimde okunamadı.',
        body: 'Hiçbir proje kaydı değiştirilmedi.',
        actionIcon: Icons.refresh_rounded,
        actionLabel: 'Tekrar dene',
        onAction: _loadProjects,
      ),
      _ProjectLoadStatus.ready => _buildReady(),
    };
  }

  Widget _buildReady() {
    if (_projects.isEmpty) {
      return _ProjectStateSurface(
        key: const Key('dashboard-no-project'),
        icon: Icons.apartment_rounded,
        title: 'İlk projenizi oluşturun',
        body:
            'Dashboard günlük saha kayıtlarını bir proje bağlamında gösterir.',
        actionIcon: Icons.add_business_rounded,
        actionLabel: 'Proje kurulumuna git',
        onAction: widget.onCreateProject,
      );
    }
    final selected = widget.session.selectedProject(_projects);
    if (selected == null) {
      return _ProjectStateSurface(
        key: const Key('dashboard-project-selection-required'),
        icon: Icons.rule_folder_outlined,
        title: 'Çalışacağınız projeyi seçin',
        body:
            'Birden fazla aktif proje var. Seçim yapılmadan proje kayıtları okunmaz.',
        actionIcon: Icons.swap_horiz_rounded,
        actionLabel: 'Proje seç',
        onAction: _showProjectSelector,
      );
    }
    return _buildDashboard(selected);
  }

  Widget _buildDashboard(MobileProject project) {
    final day = DateTime.parse(_localDay);
    final dateLabel = MaterialLocalizations.of(context).formatFullDate(day);
    return ListView(
      key: const Key('project-dashboard-list'),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      children: [
        Card(
          key: const Key('dashboard-project-header'),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.apartment_rounded, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Semantics(
                    container: true,
                    label: 'Aktif proje ${project.name}, bugün $dateLabel',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Aktif proje',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          project.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 2),
                        Text(dateLabel, key: const Key('dashboard-date')),
                      ],
                    ),
                  ),
                ),
                if (_projects.length > 1)
                  _DashboardIconAction(
                    actionKey: const Key('dashboard-change-project'),
                    icon: Icons.swap_horiz_rounded,
                    label: 'Aktif projeyi değiştir',
                    onPressed: _showProjectSelector,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        _QuickActions(
          onReminder: widget.onAddReminder == null
              ? null
              : () => _runCapture(widget.onAddReminder),
          onAgenda: widget.onAddAgenda == null
              ? null
              : () => _runCapture(widget.onAddAgenda),
        ),
        const SizedBox(height: 12),
        Text('Bugün', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        _DashboardSummaryCard(
          key: const Key('dashboard-today-card'),
          icon: Icons.today_outlined,
          status: _today.status,
          readyText: _today.value == null ? null : _todaySummary(_today.value!),
          emptyText: null,
          errorText: 'Bugünün özeti okunamadı. Diğer bölümler korunuyor.',
          disabledText: 'Bugün özeti bu kurulumda hazır değil.',
          retryKey: const Key('dashboard-today-retry'),
          onRetry: () =>
              _reloadSection(project.id, () => _loadToday(project.id)),
          actionKey: const Key('dashboard-open-today'),
          actionLabel: 'Günlük Log’u aç',
          onAction: widget.onOpenToday == null
              ? null
              : () => widget.onOpenToday!(project.id),
        ),
        _DashboardSummaryCard(
          key: const Key('dashboard-plan-card'),
          icon: Icons.calendar_view_week_outlined,
          title: '7 Günlük Plan',
          status: _plan.status,
          readyText: _plan.value == null || _plan.value!.isEmpty
              ? null
              : _planSummary(_plan.value!),
          emptyText: 'Plan penceresinde kayıt yok.',
          errorText: '7 günlük plan okunamadı. Diğer bölümler korunuyor.',
          disabledText: '7 günlük plan bu kurulumda hazır değil.',
          retryKey: const Key('dashboard-plan-retry'),
          onRetry: () =>
              _reloadSection(project.id, () => _loadPlan(project.id)),
          actionKey: const Key('dashboard-open-plan'),
          actionLabel: '7 Günlük Planı aç',
          onAction: widget.onOpenPlan == null
              ? null
              : () => widget.onOpenPlan!(project.id),
        ),
        _DashboardSummaryCard(
          key: const Key('dashboard-materials-card'),
          icon: Icons.inventory_2_outlined,
          title: 'İstenecek Malzemeler',
          status: _materials.status,
          readyText: _materials.value == null || _materials.value!.isEmpty
              ? null
              : '${_materials.value!.length} açık malzeme ihtiyacı var.',
          emptyText: 'Açık malzeme ihtiyacı yok.',
          errorText: 'Malzeme ihtiyaçları okunamadı. Diğer bölümler korunuyor.',
          disabledText: 'Malzeme takibi bu kurulumda hazır değil.',
          retryKey: const Key('dashboard-materials-retry'),
          onRetry: () =>
              _reloadSection(project.id, () => _loadMaterials(project.id)),
          actionKey: const Key('dashboard-open-materials'),
          actionLabel: 'Malzemeleri aç',
          onAction: widget.onOpenMaterials == null
              ? null
              : () => widget.onOpenMaterials!(project.id),
        ),
        const SizedBox(height: 8),
        Text('Proje araçları', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        _DashboardActionTile(
          key: const Key('dashboard-project-album'),
          icon: Icons.photo_library_outlined,
          title: 'Proje Albümü',
          enabledSubtitle: 'Fotoğraf ve videoları kaynaklarıyla görüntüle.',
          onTap: widget.onOpenProjectAlbum == null
              ? null
              : () => widget.onOpenProjectAlbum!(project.id),
        ),
        _DashboardActionTile(
          key: const Key('dashboard-workforce-directory'),
          icon: Icons.contacts_outlined,
          title: 'Saha Rehberi',
          enabledSubtitle: 'Projenin kişi ve firma kayıtlarını aç.',
          onTap: widget.onOpenWorkforce == null
              ? null
              : () => widget.onOpenWorkforce!(project.id),
        ),
        const SizedBox(height: 8),
        Text(
          'Tüm araçlar ve güvenlik',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        _DashboardActionTile(
          key: const Key('dashboard-phone-call-result'),
          icon: Icons.phone_in_talk_outlined,
          title: 'Görüşme sonucu',
          enabledSubtitle: 'Telefon görüşmesinin sonucunu Ajanda’ya kaydet.',
          onTap: widget.onOpenPhoneCall == null
              ? null
              : () => widget.onOpenPhoneCall!(project.id),
        ),
        _DashboardActionTile(
          key: const Key('dashboard-memory-backup'),
          icon: Icons.settings_backup_restore_rounded,
          title: 'Hafıza ve Yedekleme',
          enabledSubtitle: 'Mobil hafızayı yedekle veya geri yükle.',
          onTap: widget.onOpenBackup,
        ),
        _DashboardActionTile(
          key: const Key('dashboard-attachment-catalog'),
          icon: Icons.folder_copy_outlined,
          title: 'Dosya Kataloğu',
          enabledSubtitle: 'Projenin dosya kayıtlarını görüntüle.',
          onTap: widget.onOpenCatalog == null
              ? null
              : () => widget.onOpenCatalog!(project.id),
        ),
        _DashboardActionTile(
          key: const Key('dashboard-attachment-health'),
          icon: Icons.health_and_safety_outlined,
          title: 'Dosya sağlığı',
          enabledSubtitle: 'Dosya bütünlüğünü salt-okunur denetle.',
          onTap: widget.onOpenAttachmentHealth,
        ),
      ],
    );
  }
}

String _todaySummary(DailyLogDay day) {
  final parts = <String>[];
  final summary = day.section(DailyLogSectionKind.summary).summaryText;
  if (summary != null) parts.add(summary);
  for (final kind in DailyLogSectionKind.values.skip(1)) {
    final section = day.section(kind);
    if (!section.isAvailable) {
      parts.add('${kind.title}: kullanılamıyor');
    } else if (section.entries.isEmpty) {
      parts.add('${kind.title}: kayıt yok');
    } else {
      parts.add('${kind.title}: ${section.entries.length}');
    }
  }
  return parts.join('\n');
}

String _planSummary(List<ConstructionLivingPlanWindowItem> items) {
  final overdue = items.where((item) => item.isOverdue).length;
  return overdue == 0
      ? '${items.length} plan işi var; geciken iş yok.'
      : '${items.length} plan işi • $overdue geciken';
}

enum _DashboardIconActionKind { standard, filled, tonal, outlined }

class _DashboardIconAction extends StatelessWidget {
  const _DashboardIconAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.actionKey,
    this.kind = _DashboardIconActionKind.standard,
  });

  final Key? actionKey;
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final _DashboardIconActionKind kind;

  @override
  Widget build(BuildContext context) {
    final style = IconButton.styleFrom(
      minimumSize: const Size.square(40),
      fixedSize: const Size.square(40),
      maximumSize: const Size.square(40),
      iconSize: 20,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.standard,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
    final button = switch (kind) {
      _DashboardIconActionKind.standard => IconButton(
        key: actionKey,
        tooltip: label,
        style: style,
        onPressed: onPressed,
        icon: Icon(icon),
      ),
      _DashboardIconActionKind.filled => IconButton.filled(
        key: actionKey,
        tooltip: label,
        style: style,
        onPressed: onPressed,
        icon: Icon(icon),
      ),
      _DashboardIconActionKind.tonal => IconButton.filledTonal(
        key: actionKey,
        tooltip: label,
        style: style,
        onPressed: onPressed,
        icon: Icon(icon),
      ),
      _DashboardIconActionKind.outlined => IconButton.outlined(
        key: actionKey,
        tooltip: label,
        style: style,
        onPressed: onPressed,
        icon: Icon(icon),
      ),
    };
    return Semantics(
      label: label,
      button: true,
      enabled: onPressed != null,
      excludeSemantics: true,
      child: button,
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onReminder, required this.onAgenda});

  final VoidCallback? onReminder;
  final VoidCallback? onAgenda;

  @override
  Widget build(BuildContext context) {
    final reminder = _DashboardIconAction(
      actionKey: const Key('dashboard-quick-reminder'),
      icon: Icons.add_alert_outlined,
      label: 'Unutma ekle',
      kind: _DashboardIconActionKind.filled,
      onPressed: onReminder,
    );
    final agenda = _DashboardIconAction(
      actionKey: const Key('dashboard-quick-agenda'),
      icon: Icons.note_add_outlined,
      label: 'Ajanda kaydı ekle',
      kind: _DashboardIconActionKind.tonal,
      onPressed: onAgenda,
    );
    return Wrap(spacing: 8, runSpacing: 8, children: [reminder, agenda]);
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
    super.key,
  });

  final IconData icon;
  final String title;
  final String body;
  final IconData actionIcon;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(body, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              _DashboardIconAction(
                icon: actionIcon,
                label: actionLabel,
                kind: _DashboardIconActionKind.filled,
                onPressed: onAction,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardSummaryCard extends StatelessWidget {
  const _DashboardSummaryCard({
    required this.icon,
    required this.status,
    required this.readyText,
    required this.emptyText,
    required this.errorText,
    required this.disabledText,
    required this.retryKey,
    required this.onRetry,
    required this.actionKey,
    required this.actionLabel,
    required this.onAction,
    this.title,
    super.key,
  });

  final IconData icon;
  final String? title;
  final _SectionStatus status;
  final String? readyText;
  final String? emptyText;
  final String errorText;
  final String disabledText;
  final Key retryKey;
  final VoidCallback onRetry;
  final Key actionKey;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final resolvedTitle = title ?? 'Bugün';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    resolvedTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                _DashboardIconAction(
                  actionKey: actionKey,
                  icon: Icons.open_in_new_rounded,
                  label: actionLabel,
                  onPressed: onAction,
                ),
              ],
            ),
            const SizedBox(height: 8),
            switch (status) {
              _SectionStatus.loading => const LinearProgressIndicator(),
              _SectionStatus.error => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(errorText),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _DashboardIconAction(
                      actionKey: retryKey,
                      icon: Icons.refresh_rounded,
                      label: 'Tekrar dene',
                      kind: _DashboardIconActionKind.outlined,
                      onPressed: onRetry,
                    ),
                  ),
                ],
              ),
              _SectionStatus.disabled => Text(disabledText),
              _SectionStatus.ready => Text(
                readyText ?? emptyText ?? 'Bu bölümde kayıt yok.',
              ),
              _SectionStatus.idle => const Text('Proje seçimi bekleniyor.'),
            },
          ],
        ),
      ),
    );
  }
}

class _DashboardActionTile extends StatelessWidget {
  const _DashboardActionTile({
    required this.icon,
    required this.title,
    required this.enabledSubtitle,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String enabledSubtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        dense: true,
        visualDensity: const VisualDensity(horizontal: -1, vertical: -2),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        minVerticalPadding: 4,
        horizontalTitleGap: 8,
        leading: Icon(icon, size: 22),
        title: Text(title),
        subtitle: Text(
          onTap == null ? 'Bu kurulumda hazır değil.' : enabledSubtitle,
        ),
        trailing: onTap == null
            ? const Icon(Icons.block_outlined, size: 20)
            : const Icon(Icons.chevron_right_rounded, size: 20),
        onTap: onTap,
      ),
    );
  }
}
