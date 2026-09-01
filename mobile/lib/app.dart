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
import 'package:chief_site_engineer/features/project_context/active_project_session.dart';
import 'package:chief_site_engineer/features/reminders/reminder_detail_page.dart';
import 'package:chief_site_engineer/features/reminders/reminder_form_page.dart';
import 'package:chief_site_engineer/features/reminders/reminders_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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

  bool get _showsActiveProjectIndicator =>
      _selectedIndex == 1 ||
      _selectedIndex == 2 ||
      _selectedIndex == 4 ||
      _selectedIndex == 5;

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
        ),
      ),
    );
    if (!mounted ||
        _activeProjectSession.selectedProjectId == initialSessionProjectId) {
      return;
    }
    setState(() => _dashboardContextEpoch += 1);
  }

  void _showDashboardProjectSelection() {
    if (mounted) setState(() => _selectedIndex = 0);
  }

  Future<void> _openConcreteFromMore() async {
    final concrete = widget.bootstrap.concrete;
    final attachments = widget.bootstrap.concreteAttachments;
    if (concrete == null || attachments == null) return;
    final projectId = _activeProjectSession.selectedProjectId;
    if (projectId == null) {
      _showDashboardProjectSelection();
      return;
    }
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Beton Paketi')),
          body: SafeArea(
            child: ConcretePage(
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

  Future<void> _openWorkforceFromMore() async {
    final attendance = widget.bootstrap.attendance;
    if (attendance == null) return;
    final projectId = _activeProjectSession.selectedProjectId;
    if (projectId == null) {
      _showDashboardProjectSelection();
      return;
    }
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Sicil')),
          body: SafeArea(
            child: WorkforceDirectoryPage(
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
        setState(() => _selectedIndex = 4);
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
        setState(() => _selectedIndex = 5);
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
    setState(() => _selectedIndex = 1);
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
      onCreateProject: () => setState(() => _selectedIndex = 2),
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
      onOpenProjectAlbum: catalog == null
          ? null
          : (projectId) => unawaited(_openProjectAlbum(projectId)),
      onOpenWorkforce: attendance == null
          ? null
          : (projectId) => unawaited(
              Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: const Text('Sicil')),
                    body: SafeArea(
                      child: WorkforceDirectoryPage(
                        attendance: attendance,
                        agenda: bootstrap.agenda,
                        initialProjectId: projectId,
                        onProjectSelected: _reportRouteProjectSelection,
                      ),
                    ),
                  ),
                ),
              ),
            ),
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
    NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Başlangıç'),
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
    NavigationDestination(icon: Icon(Icons.more_horiz_rounded), label: 'Daha'),
  ];

  @override
  Widget build(BuildContext context) {
    final title = _destinations[_selectedIndex].label;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: _showsActiveProjectIndicator
            ? [_ActiveProjectIndicator(label: _activeProjectLabel)]
            : null,
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildDashboard(),
            RemindersPage(
              agenda: widget.bootstrap.agenda,
              attendance: widget.bootstrap.attendance,
              contextSuggestions: widget.bootstrap.contextSuggestions,
              projectLocations: widget.bootstrap.projectLocations,
              preferredProjectId: _activeProjectSession.selectedProjectId,
            ),
            AgendaPage(
              agenda: widget.bootstrap.agenda,
              projectLocations: widget.bootstrap.projectLocations,
              attachments: widget.bootstrap.concreteAttachments,
              concrete: widget.bootstrap.concrete,
              concreteAttachments: widget.bootstrap.concreteAttachments,
              activeProjectId: _activeProjectSession.selectedProjectId,
            ),
            InventoryPage(
              application: widget.bootstrap.inventory,
              listProjects: widget.bootstrap.agenda.listProjects,
              projectChanges: widget.bootstrap.agenda.projectChanges,
            ),
            if (widget.bootstrap.attendance case final attendance?)
              AttendancePage(
                attendance: attendance,
                agenda: widget.bootstrap.agenda,
                activeProjectId: _activeProjectSession.selectedProjectId,
                isActive: _selectedIndex == 4,
                onProjectSelected: _reportRouteProjectSelection,
              )
            else
              const _PreparingPage(
                icon: Icons.badge_outlined,
                title: 'Puantaj',
              ),
            _MorePage(
              bootstrap: widget.bootstrap,
              onOpenConcrete:
                  widget.bootstrap.concrete != null &&
                      widget.bootstrap.concreteAttachments != null
                  ? () => unawaited(_openConcreteFromMore())
                  : null,
              onOpenWorkforce: widget.bootstrap.attendance == null
                  ? null
                  : () => unawaited(_openWorkforceFromMore()),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        destinations: _destinations,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
      ),
    );
  }
}

class _ActiveProjectIndicator extends StatelessWidget {
  const _ActiveProjectIndicator({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Center(
        child: Tooltip(
          message: 'Aktif proje: $label',
          child: Semantics(
            container: true,
            label: 'Aktif proje: $label',
            child: Chip(
              key: const Key('active-project-indicator'),
              avatar: const Icon(Icons.apartment_rounded, size: 18),
              label: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 132),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
      ),
    );
  }
}

class _MorePage extends StatelessWidget {
  const _MorePage({
    required this.bootstrap,
    required this.onOpenConcrete,
    required this.onOpenWorkforce,
  });

  final BootstrapSuccess bootstrap;
  final VoidCallback? onOpenConcrete;
  final VoidCallback? onOpenWorkforce;

  @override
  Widget build(BuildContext context) {
    final concrete = bootstrap.concrete;
    final attachments = bootstrap.concreteAttachments;
    final attendance = bootstrap.attendance;
    return ListView(
      key: const Key('more-page'),
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            key: const Key('more-concrete-package'),
            leading: const Icon(Icons.foundation_outlined),
            title: const Text('Beton Paketi'),
            subtitle: Text(
              concrete != null && attachments != null
                  ? 'Beton dökümü kayıtlarını aç.'
                  : 'Hazırlanıyor',
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: onOpenConcrete,
          ),
        ),
        Card(
          child: ListTile(
            key: const Key('more-workforce-directory'),
            leading: const Icon(Icons.contacts_outlined),
            title: const Text('Sicil'),
            subtitle: Text(
              attendance != null
                  ? 'Saha Rehberi ve sicili aç.'
                  : 'Hazırlanıyor',
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: onOpenWorkforce,
          ),
        ),
      ],
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
