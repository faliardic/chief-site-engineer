import 'dart:async';

import 'package:chief_site_engineer/bootstrap/app_bootstrap.dart';
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
    const seed = Color(0xFF1E5D4E);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: productName,
      locale: locale,
      supportedLocales: supportedLocales,
      localizationsDelegates: localizationsDelegates,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        materialTapTargetSize: MaterialTapTargetSize.padded,
        visualDensity: VisualDensity.standard,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        ),
        materialTapTargetSize: MaterialTapTargetSize.padded,
        visualDensity: VisualDensity.standard,
        useMaterial3: true,
      ),
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
  late final ActiveProjectSession _activeProjectSession;

  @override
  void initState() {
    super.initState();
    _activeProjectSession = ActiveProjectSession();
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
    _activeProjectSession.dispose();
    super.dispose();
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

  Future<void> _openPhoneCallResult() async {
    final logId = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => PhoneCallResultPage(
          agenda: widget.bootstrap.agenda,
          contextSuggestions: widget.bootstrap.contextSuggestions,
          projectLocations: widget.bootstrap.projectLocations,
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
                  ),
                ),
              ),
            ),
      onOpenProjectAlbum: catalog == null
          ? null
          : (_) => unawaited(
              Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => ProjectMediaAlbumPage(
                    catalog: catalog,
                    agenda: bootstrap.agenda,
                    concrete: bootstrap.concrete,
                    attachments: bootstrap.concreteAttachments,
                    projectLocations: bootstrap.projectLocations,
                  ),
                ),
              ),
            ),
      onOpenWorkforce: attendance == null
          ? null
          : (_) => unawaited(
              Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: const Text('Sicil')),
                    body: SafeArea(
                      child: WorkforceDirectoryPage(
                        attendance: attendance,
                        agenda: bootstrap.agenda,
                      ),
                    ),
                  ),
                ),
              ),
            ),
      onOpenPhoneCall: (_) => unawaited(_openPhoneCallResult()),
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
      appBar: AppBar(title: Text(title)),
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
            ),
            AgendaPage(
              agenda: widget.bootstrap.agenda,
              projectLocations: widget.bootstrap.projectLocations,
              attachments: widget.bootstrap.concreteAttachments,
              concrete: widget.bootstrap.concrete,
              concreteAttachments: widget.bootstrap.concreteAttachments,
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
              )
            else
              const _PreparingPage(
                icon: Icons.badge_outlined,
                title: 'Puantaj',
              ),
            _MorePage(bootstrap: widget.bootstrap),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        destinations: _destinations,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
      ),
    );
  }
}

class _MorePage extends StatelessWidget {
  const _MorePage({required this.bootstrap});

  final BootstrapSuccess bootstrap;

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
            onTap: concrete != null && attachments != null
                ? () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        appBar: AppBar(title: const Text('Beton Paketi')),
                        body: SafeArea(
                          child: ConcretePage(
                            concrete: concrete,
                            agenda: bootstrap.agenda,
                            attachments: attachments,
                            projectLocations: bootstrap.projectLocations,
                          ),
                        ),
                      ),
                    ),
                  )
                : null,
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
            onTap: attendance != null
                ? () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        appBar: AppBar(title: const Text('Sicil')),
                        body: SafeArea(
                          child: WorkforceDirectoryPage(
                            attendance: attendance,
                            agenda: bootstrap.agenda,
                          ),
                        ),
                      ),
                    ),
                  )
                : null,
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
