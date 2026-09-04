import 'dart:async';

import 'package:chief_site_engineer/bootstrap/app_bootstrap.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/features/agenda/agenda_page.dart';
import 'package:chief_site_engineer/features/agenda/log_detail_page.dart';
import 'package:chief_site_engineer/features/agenda/log_form_page.dart';
import 'package:chief_site_engineer/features/agenda/phone_call_result_page.dart';
import 'package:chief_site_engineer/features/attendance/attendance_day_page.dart';
import 'package:chief_site_engineer/features/attendance/attendance_page.dart';
import 'package:chief_site_engineer/features/attendance/workforce_directory_page.dart';
import 'package:chief_site_engineer/features/attachments/attachment_catalog_page.dart';
import 'package:chief_site_engineer/features/attachments/attachment_health_page.dart';
import 'package:chief_site_engineer/features/attachments/project_media_album_page.dart';
import 'package:chief_site_engineer/features/concrete/concrete_page.dart';
import 'package:chief_site_engineer/features/concrete/concrete_pour_detail_page.dart';
import 'package:chief_site_engineer/features/daily_log/daily_log_page.dart';
import 'package:chief_site_engineer/features/dashboard/project_dashboard_page.dart';
import 'package:chief_site_engineer/features/inventory/inventory_page.dart';
import 'package:chief_site_engineer/features/living_plan/living_plan_page.dart';
import 'package:chief_site_engineer/features/material_requests/material_requests_page.dart';
import 'package:chief_site_engineer/features/memory/memory_backup_page.dart';
import 'package:chief_site_engineer/features/project_context/active_project_control.dart';
import 'package:chief_site_engineer/features/project_context/active_project_session.dart';
import 'package:chief_site_engineer/features/projects/project_create_page.dart';
import 'package:chief_site_engineer/features/reminders/reminder_detail_page.dart';
import 'package:chief_site_engineer/features/reminders/reminder_form_page.dart';
import 'package:chief_site_engineer/features/reminders/reminders_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

export 'package:chief_site_engineer/features/project_context/active_project_control.dart';

const _compactButtonStyle = ButtonStyle(
  minimumSize: WidgetStatePropertyAll(Size(0, 40)),
  padding: WidgetStatePropertyAll(
    EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  ),
  visualDensity: VisualDensity.standard,
  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
);

ThemeData _buildCseTheme(Brightness brightness) {
  const seed = Color(0xFF1E5D4E);
  final base = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: brightness),
    useMaterial3: true,
  );
  final textTheme = base.typography.englishLike
      .merge(base.textTheme)
      .apply(fontSizeFactor: 0.92);
  return base.copyWith(
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    visualDensity: const VisualDensity(horizontal: -1, vertical: -1),
    textTheme: textTheme,
    filledButtonTheme: const FilledButtonThemeData(style: _compactButtonStyle),
    elevatedButtonTheme: const ElevatedButtonThemeData(
      style: _compactButtonStyle,
    ),
    outlinedButtonTheme: const OutlinedButtonThemeData(
      style: _compactButtonStyle,
    ),
    textButtonTheme: const TextButtonThemeData(style: _compactButtonStyle),
    iconButtonTheme: const IconButtonThemeData(
      style: ButtonStyle(
        minimumSize: WidgetStatePropertyAll(Size.square(40)),
        visualDensity: VisualDensity.standard,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),
    inputDecorationTheme: const InputDecorationThemeData(
      isDense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
    appBarTheme: AppBarThemeData(
      toolbarHeight: 52,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 64,
      labelTextStyle: WidgetStatePropertyAll(textTheme.labelSmall),
    ),
  );
}

class CseApp extends StatelessWidget {
  const CseApp({
    required this.bootstrap,
    this.fatalErrors,
    this.environmentLabel,
    super.key,
  });

  static const productName = 'Şefim';
  static const locale = Locale('tr');
  static const supportedLocales = <Locale>[locale];
  static const localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  final Future<BootstrapResult> bootstrap;
  final ValueListenable<String?>? fatalErrors;
  final String? environmentLabel;

  @override
  Widget build(BuildContext context) {
    final listenable = fatalErrors;
    if (listenable != null) {
      return ValueListenableBuilder<String?>(
        valueListenable: listenable,
        builder: (_, code, _) => _buildMaterialApp(code),
      );
    }
    return _buildMaterialApp(null);
  }

  Widget _buildMaterialApp(String? fatalErrorCode) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: productName,
      locale: locale,
      supportedLocales: supportedLocales,
      localizationsDelegates: localizationsDelegates,
      theme: _buildCseTheme(Brightness.light),
      darkTheme: _buildCseTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      builder: (context, child) {
        final label = environmentLabel;
        if (label == null) return child ?? const SizedBox.shrink();
        return Column(
          children: [
            Material(
              color: Theme.of(context).colorScheme.errorContainer,
              child: SafeArea(
                bottom: false,
                child: Semantics(
                  container: true,
                  label: label,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Center(
                      child: Text(
                        label,
                        key: const Key('acceptance-environment-label'),
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(child: child ?? const SizedBox.shrink()),
          ],
        );
      },
      home: fatalErrorCode == null
          ? BootstrapGate(bootstrap: bootstrap)
          : SafeDiagnosticScreen(code: fatalErrorCode),
    );
  }
}

class BootstrapGate extends StatelessWidget {
  const BootstrapGate({required this.bootstrap, super.key});

  final Future<BootstrapResult> bootstrap;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<BootstrapResult>(
      future: bootstrap,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final result = snapshot.requireData;
        return switch (result) {
          BootstrapSuccess() => MobileShell(bootstrap: result),
          BootstrapFailure() => BootstrapFailureScreen(code: result.code),
        };
      },
    );
  }
}

class BootstrapFailureScreen extends StatelessWidget {
  const BootstrapFailureScreen({required this.code, super.key});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: SafeDiagnosticPanel(code: code)),
    );
  }
}

class SafeDiagnosticScreen extends StatelessWidget {
  const SafeDiagnosticScreen({required this.code, super.key});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: SafeDiagnosticPanel(code: code)),
    );
  }
}

class SafeDiagnosticPanel extends StatelessWidget {
  const SafeDiagnosticPanel({required this.code, super.key});

  final String code;

  @override
  Widget build(BuildContext context) {
    final recoveryFailure = code == 'restore_recovery_failed';
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.storage_rounded, size: 52),
                const SizedBox(height: 16),
                Text(
                  recoveryFailure
                      ? 'Yerel hafıza kurtarma işlemi güvenle tamamlanamadı.'
                      : 'Uygulama güvenli biçimde başlatılamadı.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  recoveryFailure
                      ? 'Veriler silinmedi; kurtarma alanı korundu. Uygulamayı kapatın ve teknik destek için tanı kodunu not edin.'
                      : 'İşlem sonucu doğrulanamadı. Uygulamayı kapatıp yeniden açın, ilgili kaydı kontrol edin ve aynı işlemi kontrol etmeden tekrarlamayın.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Semantics(
                  label: 'Güvenli tanı kodu',
                  child: Text(
                    'Tanı kodu: $code',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MobileShell extends StatefulWidget {
  const MobileShell({required this.bootstrap, super.key});

  final BootstrapSuccess bootstrap;

  @override
  State<MobileShell> createState() => _MobileShellState();
}

class _MobileShellState extends State<MobileShell> {
  int _selectedIndex = 0;
  final Set<int> _visitedPrimaryTabs = {0};
  final _inventoryKey = GlobalKey<InventoryPageState>();
  StreamSubscription<String>? _notificationTapSubscription;
  StreamSubscription<void>? _projectContextSubscription;
  late final ActiveProjectSession _activeProjectSession;
  List<MobileProject> _activeProjectOptions = const [];
  Map<String, String> _activeProjectNames = const {};
  int _projectContextGeneration = 0;
  int _routeProjectValidationGeneration = 0;
  int _dashboardContextEpoch = 0;

  @override
  void initState() {
    super.initState();
    _activeProjectSession = ActiveProjectSession();
    _activeProjectSession.addListener(_handleActiveProjectChanged);
    _projectContextSubscription = widget.bootstrap.agenda.projectChanges.listen(
      (_) => unawaited(_refreshActiveProjectOptions()),
    );
    unawaited(_refreshActiveProjectOptions());
    _notificationTapSubscription = widget.bootstrap.agenda.notificationTaps
        .listen(_openReminderFromNotification);
    final initial = widget.bootstrap.agenda.initialNotificationReminderId;
    if (initial != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _openReminderFromNotification(initial),
      );
    }
  }

  @override
  void dispose() {
    _notificationTapSubscription?.cancel();
    _projectContextSubscription?.cancel();
    _activeProjectSession.removeListener(_handleActiveProjectChanged);
    _activeProjectSession.dispose();
    super.dispose();
  }

  void _handleActiveProjectChanged() {
    if (!mounted) return;
    setState(() {});
    final selectedProjectId = _activeProjectSession.selectedProjectId;
    if (selectedProjectId != null &&
        !_activeProjectNames.containsKey(selectedProjectId)) {
      unawaited(_refreshActiveProjectOptions());
    }
  }

  Future<void> _refreshActiveProjectOptions() async {
    final generation = ++_projectContextGeneration;
    try {
      final projects = await widget.bootstrap.agenda.listProjects();
      if (!mounted || generation != _projectContextGeneration) return;
      final activeProjects = projects
          .where((project) => !project.isArchived)
          .toList(growable: false);
      if (activeProjects.map((project) => project.id).toSet().length !=
          activeProjects.length) {
        throw StateError('Duplicate active project IDs');
      }
      setState(() {
        _activeProjectOptions = activeProjects;
        _activeProjectNames = {
          for (final project in activeProjects) project.id: project.name,
        };
      });
    } on Object {
      if (!mounted || generation != _projectContextGeneration) return;
      // A transient refresh must not make the visible context contradict the
      // still-operational ActiveProjectSession selection. Keep the last
      // successfully validated display cache until a later refresh succeeds.
    }
  }

  String get _activeProjectLabel {
    final selectedProjectId = _activeProjectSession.selectedProjectId;
    if (selectedProjectId == null) return 'Proje seçilmedi';
    return _activeProjectNames[selectedProjectId] ?? 'Proje seçilmedi';
  }

  Future<void> _adoptRouteProjectSelection(
    String projectId, {
    bool refreshDashboard = true,
  }) async {
    final generation = ++_routeProjectValidationGeneration;
    final cachedProjects = _activeProjectOptions;
    if (cachedProjects.any((project) => project.id == projectId)) {
      if (!mounted || generation != _routeProjectValidationGeneration) return;
      if (!_activeProjectSession.select(projectId, cachedProjects)) return;
      if (refreshDashboard) setState(() => _dashboardContextEpoch += 1);
      return;
    }
    try {
      final projects = await widget.bootstrap.agenda.listProjects();
      if (!mounted || generation != _routeProjectValidationGeneration) return;
      if (!_activeProjectSession.select(projectId, projects)) return;
      if (refreshDashboard) setState(() => _dashboardContextEpoch += 1);
    } on Object {
      // Route-local selection remains local when fresh shell validation fails.
    }
  }

  void _reportRouteProjectSelection(String projectId) {
    unawaited(_adoptRouteProjectSelection(projectId));
  }

  void _reportPrimaryProjectSelection(String projectId) {
    unawaited(_adoptRouteProjectSelection(projectId, refreshDashboard: false));
  }

  void _selectAppBarProject(String projectId) {
    if (!_activeProjectOptions.any((project) => project.id == projectId)) {
      return;
    }
    if (_selectedIndex == 3) {
      // Inventory reports back only after fresh project validation and its
      // exact scoped load succeed. Failed/stale loads never retarget the shell.
      unawaited(_inventoryKey.currentState?.selectProject(projectId));
    } else {
      _reportPrimaryProjectSelection(projectId);
    }
  }

  void _reportAlbumProjectSelection(String projectId) {
    unawaited(_adoptRouteProjectSelection(projectId, refreshDashboard: false));
  }

  Future<void> _openProjectAlbum(String projectId) async {
    final catalog = widget.bootstrap.attachmentCatalog;
    if (catalog == null) return;
    final initialSessionProjectId = _activeProjectSession.selectedProjectId;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ProjectMediaAlbumPage(
          catalog: catalog,
          agenda: widget.bootstrap.agenda,
          concrete: widget.bootstrap.concrete,
          attachments: widget.bootstrap.concreteAttachments,
          projectLocations: widget.bootstrap.projectLocations,
          initialProjectId: projectId,
          onProjectSelected: _reportAlbumProjectSelection,
          appBarProjectControlBuilder: _buildRouteProjectControl,
        ),
      ),
    );
    if (!mounted ||
        _activeProjectSession.selectedProjectId == initialSessionProjectId) {
      return;
    }
    setState(() => _dashboardContextEpoch += 1);
  }

  Future<void> _openProjectCreate() async {
    final project = await Navigator.of(context).push<MobileProject>(
      MaterialPageRoute(
        builder: (_) => ProjectCreatePage(agenda: widget.bootstrap.agenda),
      ),
    );
    if (!mounted || project == null) return;

    final activeProjects = [
      for (final current in _activeProjectOptions)
        if (current.id != project.id) current,
      project,
    ];
    setState(() {
      _activeProjectOptions = activeProjects;
      _activeProjectNames = {
        for (final current in activeProjects) current.id: current.name,
      };
      _selectedIndex = 0;
      _visitedPrimaryTabs.add(0);
      _dashboardContextEpoch += 1;
    });
    _activeProjectSession.select(project.id, activeProjects);
  }

  void _selectPrimaryTab(int index) {
    if (!mounted ||
        (_selectedIndex == index && _visitedPrimaryTabs.contains(index))) {
      return;
    }
    setState(() {
      _selectedIndex = index;
      _visitedPrimaryTabs.add(index);
    });
  }

  Widget _buildVisitedPrimaryTab(int index, Widget Function() builder) {
    return _visitedPrimaryTabs.contains(index)
        ? builder()
        : const SizedBox.shrink();
  }

  Widget _buildRouteProjectControl(ValueChanged<String> onSelected) {
    return ListenableBuilder(
      listenable: _activeProjectSession,
      builder: (context, child) => ActiveProjectControl(
        label: _activeProjectLabel,
        projects: _activeProjectOptions,
        onSelected: onSelected,
      ),
    );
  }

  Future<void> _openConcrete(String projectId) async {
    final concrete = widget.bootstrap.concrete;
    final attachments = widget.bootstrap.concreteAttachments;
    if (concrete == null || attachments == null) return;
    if (!mounted) return;
    final pageKey = GlobalKey<ConcretePageState>();
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: const Text('Beton Paketi'),
            actions: [
              _buildRouteProjectControl((selectedProjectId) {
                final pageState = pageKey.currentState;
                if (pageState != null) {
                  unawaited(pageState.selectProject(selectedProjectId));
                }
              }),
            ],
          ),
          body: SafeArea(
            child: ConcretePage(
              key: pageKey,
              concrete: concrete,
              agenda: widget.bootstrap.agenda,
              attachments: attachments,
              projectLocations: widget.bootstrap.projectLocations,
              initialProjectId: projectId,
              onProjectSelected: _reportRouteProjectSelection,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openWorkforce(String projectId) async {
    final attendance = widget.bootstrap.attendance;
    if (attendance == null || !mounted) return;
    final pageKey = GlobalKey<WorkforceDirectoryPageState>();
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: const Text('Sicil'),
            actions: [
              _buildRouteProjectControl((selectedProjectId) {
                final pageState = pageKey.currentState;
                if (pageState != null) {
                  unawaited(pageState.selectProject(selectedProjectId));
                }
              }),
            ],
          ),
          body: SafeArea(
            child: WorkforceDirectoryPage(
              key: pageKey,
              attendance: attendance,
              agenda: widget.bootstrap.agenda,
              initialProjectId: projectId,
              onProjectSelected: _reportRouteProjectSelection,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openReminderFromNotification(String reminderId) async {
    if (!mounted) return;
    try {
      final reminder = await widget.bootstrap.agenda.getReminderDetail(
        reminderId,
      );
      final attendance = widget.bootstrap.attendance;
      if (reminder.attendanceDayId != null && attendance != null) {
        if (!mounted) return;
        _selectPrimaryTab(4);
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => AttendanceDayPage(
              attendance: attendance,
              agenda: widget.bootstrap.agenda,
              dayId: reminder.attendanceDayId!,
            ),
          ),
        );
        return;
      }
      final concrete = widget.bootstrap.concrete;
      final attachments = widget.bootstrap.concreteAttachments;
      if (reminder.concretePourId != null &&
          concrete != null &&
          attachments != null) {
        if (!mounted) return;
        _selectPrimaryTab(0);
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => ConcretePourDetailPage(
              concrete: concrete,
              agenda: widget.bootstrap.agenda,
              attachments: attachments,
              projectLocations: widget.bootstrap.projectLocations,
              pourId: reminder.concretePourId!,
            ),
          ),
        );
        return;
      }
    } on Object {
      // Invalid/stale notification payload falls back to reminder detail.
    }
    if (!mounted) return;
    _selectPrimaryTab(1);
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ReminderDetailPage(
          agenda: widget.bootstrap.agenda,
          projectLocations: widget.bootstrap.projectLocations,
          attendance: widget.bootstrap.attendance,
          concrete: widget.bootstrap.concrete,
          concreteAttachments: widget.bootstrap.concreteAttachments,
          reminderId: reminderId,
        ),
      ),
    );
  }

  Future<void> _openPhoneCallResult(String initialProjectId) async {
    final logId = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => PhoneCallResultPage(
          agenda: widget.bootstrap.agenda,
          contextSuggestions: widget.bootstrap.contextSuggestions,
          projectLocations: widget.bootstrap.projectLocations,
          initialProjectId: initialProjectId,
          onProjectSelected: _reportRouteProjectSelection,
        ),
      ),
    );
    if (!mounted || logId == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => LogDetailPage(
          agenda: widget.bootstrap.agenda,
          projectLocations: widget.bootstrap.projectLocations,
          attachments: widget.bootstrap.concreteAttachments,
          concrete: widget.bootstrap.concrete,
          concreteAttachments: widget.bootstrap.concreteAttachments,
          logId: logId,
        ),
      ),
    );
  }

  ProjectDashboardPage _buildDashboard() {
    final bootstrap = widget.bootstrap;
    final dailyLog = bootstrap.dailyLog;
    final materials = bootstrap.materialRequests;
    final catalog = bootstrap.attachmentCatalog;
    final attendance = bootstrap.attendance;
    final backup = bootstrap.backup;
    final reconciliation = bootstrap.attachmentReconciliation;
    return ProjectDashboardPage(
      key: ValueKey('project-dashboard-context-$_dashboardContextEpoch'),
      agenda: bootstrap.agenda,
      dailyLog: dailyLog,
      livingPlan: bootstrap.livingPlan,
      materialRequests: materials,
      session: _activeProjectSession,
      onCreateProject: () => unawaited(_openProjectCreate()),
      onAddReminder: (projectId, localDay) async {
        final value = await Navigator.of(context).push<Object?>(
          MaterialPageRoute(
            builder: (_) => ReminderFormPage(
              agenda: bootstrap.agenda,
              contextSuggestions: bootstrap.contextSuggestions,
              projectLocations: bootstrap.projectLocations,
              preferredProjectId: projectId,
            ),
          ),
        );
        return value != null;
      },
      onAddAgenda: (projectId, localDay) async {
        final value = await Navigator.of(context).push<Object?>(
          MaterialPageRoute(
            builder: (_) => LogFormPage(
              agenda: bootstrap.agenda,
              projectLocations: bootstrap.projectLocations,
              attachments: bootstrap.concreteAttachments,
              concrete: bootstrap.concrete,
              concreteAttachments: bootstrap.concreteAttachments,
              initialProjectId: projectId,
              initialIstanbulDay: localDay,
            ),
          ),
        );
        return value != null;
      },
      onOpenToday: dailyLog == null
          ? null
          : (projectId) => unawaited(
              Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => DailyLogPage(
                    dailyLog: dailyLog,
                    workChain: bootstrap.workChain,
                    initialProjectId: projectId,
                    onProjectSelected: _reportRouteProjectSelection,
                  ),
                ),
              ),
            ),
      onOpenPlan: (projectId) => unawaited(
        Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => LivingPlanPage(
              agenda: bootstrap.agenda,
              livingPlan: bootstrap.livingPlan,
              intelligence: bootstrap.livingPlanIntelligence,
              initialProjectId: projectId,
              onProjectSelected: _reportRouteProjectSelection,
            ),
          ),
        ),
      ),
      onOpenMaterials: materials == null
          ? null
          : (projectId) => unawaited(
              Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => MaterialRequestsPage(
                    application: materials,
                    initialProjectId: projectId,
                    onProjectSelected: _reportRouteProjectSelection,
                  ),
                ),
              ),
            ),
      onOpenConcrete:
          bootstrap.concrete == null || bootstrap.concreteAttachments == null
          ? null
          : (projectId) => unawaited(_openConcrete(projectId)),
      onOpenProjectAlbum: catalog == null
          ? null
          : (projectId) => unawaited(_openProjectAlbum(projectId)),
      onOpenWorkforce: attendance == null
          ? null
          : (projectId) => unawaited(_openWorkforce(projectId)),
      onOpenPhoneCall: (projectId) =>
          unawaited(_openPhoneCallResult(projectId)),
      onOpenBackup: backup == null
          ? null
          : () => unawaited(
              Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => MemoryBackupPage(backup: backup),
                ),
              ),
            ),
      onOpenCatalog: catalog == null
          ? null
          : (projectId) => unawaited(
              Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => AttachmentCatalogPage(
                    catalog: catalog,
                    initialProjectId: projectId,
                  ),
                ),
              ),
            ),
      onOpenAttachmentHealth: reconciliation == null
          ? null
          : () => unawaited(
              Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) =>
                      AttachmentHealthPage(reconciliation: reconciliation),
                ),
              ),
            ),
    );
  }

  static const _destinations = <NavigationDestination>[
    NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Ana Sayfa'),
    NavigationDestination(
      icon: Icon(Icons.notifications_none_rounded),
      label: 'Hatırlatıcı',
    ),
    NavigationDestination(
      icon: Icon(Icons.event_note_outlined),
      label: 'Ajanda',
    ),
    NavigationDestination(
      icon: Icon(Icons.inventory_2_outlined),
      label: 'Envanter',
    ),
    NavigationDestination(icon: Icon(Icons.badge_outlined), label: 'Puantaj'),
  ];

  @override
  Widget build(BuildContext context) {
    final title = _destinations[_selectedIndex].label;
    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= 600;
        final useExtendedRail = constraints.maxWidth >= 840;
        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            actions: [
              ActiveProjectControl(
                label: _activeProjectLabel,
                projects: _activeProjectOptions,
                onSelected: _selectAppBarProject,
              ),
            ],
          ),
          body: SafeArea(
            child: Row(
              children: [
                if (useRail)
                  NavigationRail(
                    selectedIndex: _selectedIndex,
                    extended: useExtendedRail,
                    labelType: useExtendedRail
                        ? null
                        : NavigationRailLabelType.all,
                    scrollable: true,
                    destinations: [
                      for (final destination in _destinations)
                        NavigationRailDestination(
                          icon: destination.icon,
                          selectedIcon: destination.selectedIcon,
                          label: Text(destination.label),
                        ),
                    ],
                    onDestinationSelected: _selectPrimaryTab,
                  ),
                Expanded(
                  key: const ValueKey('primary-shell-content'),
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: [
                      _buildDashboard(),
                      _buildVisitedPrimaryTab(
                        1,
                        () => RemindersPage(
                          agenda: widget.bootstrap.agenda,
                          attendance: widget.bootstrap.attendance,
                          contextSuggestions:
                              widget.bootstrap.contextSuggestions,
                          projectLocations: widget.bootstrap.projectLocations,
                          preferredProjectId:
                              _activeProjectSession.selectedProjectId,
                        ),
                      ),
                      _buildVisitedPrimaryTab(
                        2,
                        () => AgendaPage(
                          agenda: widget.bootstrap.agenda,
                          projectLocations: widget.bootstrap.projectLocations,
                          attachments: widget.bootstrap.concreteAttachments,
                          concrete: widget.bootstrap.concrete,
                          concreteAttachments:
                              widget.bootstrap.concreteAttachments,
                          activeProjectId:
                              _activeProjectSession.selectedProjectId,
                        ),
                      ),
                      _buildVisitedPrimaryTab(
                        3,
                        () => InventoryPage(
                          key: _inventoryKey,
                          application: widget.bootstrap.inventory,
                          listProjects: widget.bootstrap.agenda.listProjects,
                          projectChanges:
                              widget.bootstrap.agenda.projectChanges,
                          activeProjectId:
                              _activeProjectSession.selectedProjectId,
                          isActive: _selectedIndex == 3,
                          onProjectSelected: _reportPrimaryProjectSelection,
                        ),
                      ),
                      _buildVisitedPrimaryTab(
                        4,
                        () => switch (widget.bootstrap.attendance) {
                          final attendance? => AttendancePage(
                            attendance: attendance,
                            agenda: widget.bootstrap.agenda,
                            activeProjectId:
                                _activeProjectSession.selectedProjectId,
                            isActive: _selectedIndex == 4,
                            onProjectSelected: _reportPrimaryProjectSelection,
                          ),
                          null => const _PreparingPage(
                            icon: Icons.badge_outlined,
                            title: 'Puantaj',
                          ),
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: useRail
              ? null
              : NavigationBar(
                  selectedIndex: _selectedIndex,
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  destinations: _destinations,
                  onDestinationSelected: _selectPrimaryTab,
                ),
        );
      },
    );
  }
}

class _PreparingPage extends StatelessWidget {
  const _PreparingPage({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text(
              'Hazırlanıyor',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Text(
              'Bu alan sonraki dar mobil özellik diliminde açılacak.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
