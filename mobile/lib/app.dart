import 'dart:async';

import 'package:chief_site_engineer/bootstrap/app_bootstrap.dart';
import 'package:chief_site_engineer/features/agenda/agenda_page.dart';
import 'package:chief_site_engineer/features/attendance/attendance_day_page.dart';
import 'package:chief_site_engineer/features/attendance/attendance_page.dart';
import 'package:chief_site_engineer/features/attendance/workforce_directory_page.dart';
import 'package:chief_site_engineer/features/attachments/attachment_catalog_page.dart';
import 'package:chief_site_engineer/features/attachments/attachment_health_page.dart';
import 'package:chief_site_engineer/features/concrete/concrete_page.dart';
import 'package:chief_site_engineer/features/concrete/concrete_pour_detail_page.dart';
import 'package:chief_site_engineer/features/daily_log/daily_log_page.dart';
import 'package:chief_site_engineer/features/living_plan/living_plan_page.dart';
import 'package:chief_site_engineer/features/memory/memory_backup_page.dart';
import 'package:chief_site_engineer/features/reminders/reminder_detail_page.dart';
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

  @override
  void initState() {
    super.initState();
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
        setState(() => _selectedIndex = 3);
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
        setState(() => _selectedIndex = 4);
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
    NavigationDestination(icon: Icon(Icons.badge_outlined), label: 'Puantaj'),
    NavigationDestination(
      icon: Icon(Icons.foundation_outlined),
      label: 'Beton Paketi',
    ),
    NavigationDestination(icon: Icon(Icons.contacts_outlined), label: 'Sicil'),
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
            _HomePage(bootstrap: widget.bootstrap),
            RemindersPage(
              agenda: widget.bootstrap.agenda,
              attendance: widget.bootstrap.attendance,
              projectLocations: widget.bootstrap.projectLocations,
            ),
            AgendaPage(
              agenda: widget.bootstrap.agenda,
              projectLocations: widget.bootstrap.projectLocations,
              attachments: widget.bootstrap.concreteAttachments,
              concrete: widget.bootstrap.concrete,
              concreteAttachments: widget.bootstrap.concreteAttachments,
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
            if (widget.bootstrap.concrete case final concrete?)
              if (widget.bootstrap.concreteAttachments case final attachments?)
                ConcretePage(
                  concrete: concrete,
                  agenda: widget.bootstrap.agenda,
                  attachments: attachments,
                  projectLocations: widget.bootstrap.projectLocations,
                )
              else
                const _PreparingPage(
                  icon: Icons.foundation_outlined,
                  title: 'Beton Paketi',
                )
            else
              const _PreparingPage(
                icon: Icons.foundation_outlined,
                title: 'Beton Paketi',
              ),
            if (widget.bootstrap.attendance case final attendance?)
              WorkforceDirectoryPage(
                attendance: attendance,
                agenda: widget.bootstrap.agenda,
              )
            else
              const _PreparingPage(
                icon: Icons.contacts_outlined,
                title: 'Sicil',
              ),
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

class _HomePage extends StatefulWidget {
  const _HomePage({required this.bootstrap});

  final BootstrapSuccess bootstrap;

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  static const _fieldTips = <String>[
    'Sahada görülen veya söylenenler, mümkün olduğunca anında kayda geçtiğinde unutulmaz.',
    'Fotoğraf; neyi, nerede ve neden gösterdiğiyle birlikte anlam kazanır.',
    'Gün sonu, önemli gelişmelerin rapor ve kayıtlara yansıdığını kontrol etme zamanıdır.',
    'Açık işler zihinde değil, sistemde görünür kaldığında daha kolay takip edilir.',
  ];

  var _fieldTipIndex = 0;

  void _showPreviousFieldTip() {
    setState(() {
      _fieldTipIndex =
          (_fieldTipIndex - 1 + _fieldTips.length) % _fieldTips.length;
    });
  }

  void _showNextFieldTip() {
    setState(() {
      _fieldTipIndex = (_fieldTipIndex + 1) % _fieldTips.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final fieldTip = _fieldTips[_fieldTipIndex];
    final fieldTipPosition = '${_fieldTipIndex + 1} / ${_fieldTips.length}';
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Saha hafızanız cihazınızda.',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text(
          'Günlük kullanım internet, bilgisayar veya yerel ağ bağlantısı gerektirmez.',
        ),
        const SizedBox(height: 20),
        Card(
          child: ListTile(
            leading: const Icon(Icons.offline_bolt_outlined),
            title: const Text('Çevrim dışı temel hazır'),
            subtitle: Text(
              'Cihaz-içi SQLite • ${widget.bootstrap.environmentLabel} ortamı',
            ),
          ),
        ),
        const Card(
          child: ListTile(
            leading: Icon(Icons.lock_outline_rounded),
            title: Text('Veri sınırı'),
            subtitle: Text(
              'Bulut eşitleme ve kullanıcı hesabı bu sürümde yoktur.',
            ),
          ),
        ),
        Card(
          child: ListTile(
            key: const Key('open-living-plan'),
            leading: const Icon(Icons.calendar_view_week_outlined),
            title: const Text('7 Günlük Plan'),
            subtitle: const Text('Geciken işleri ve önündeki yedi günü yönet.'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => LivingPlanPage(
                  agenda: widget.bootstrap.agenda,
                  livingPlan: widget.bootstrap.livingPlan,
                  intelligence: widget.bootstrap.livingPlanIntelligence,
                ),
              ),
            ),
          ),
        ),
        if (widget.bootstrap.dailyLog case final dailyLog?)
          Card(
            child: ListTile(
              key: const Key('open-daily-log'),
              leading: const Icon(Icons.summarize_outlined),
              title: const Text('Günlük Log'),
              subtitle: const Text(
                'Seçilen günün kaynak kayıtlarından salt-okunur taslak hazırla.',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => DailyLogPage(dailyLog: dailyLog),
                ),
              ),
            ),
          ),
        Card(
          key: const Key('home-field-tip-card'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.tips_and_updates_outlined),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Saha İpucu',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Semantics(
                  key: const Key('field-tip-live-region'),
                  label: 'Saha İpucu $fieldTipPosition: $fieldTip',
                  liveRegion: true,
                  child: Text(fieldTip, key: const Key('field-tip-text')),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    IconButton(
                      key: const Key('previous-field-tip'),
                      tooltip: 'Önceki saha ipucu',
                      onPressed: _showPreviousFieldTip,
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    Expanded(
                      child: Text(
                        fieldTipPosition,
                        key: const Key('field-tip-position'),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      key: const Key('next-field-tip'),
                      tooltip: 'Sonraki saha ipucu',
                      onPressed: _showNextFieldTip,
                      icon: const Icon(Icons.arrow_forward_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (widget.bootstrap.backup case final backup?)
          Card(
            child: ListTile(
              key: const Key('open-memory-backup'),
              minVerticalPadding: 12,
              leading: const Icon(Icons.settings_backup_restore_rounded),
              title: const Text('Hafıza ve Yedekleme'),
              subtitle: const Text(
                'Parola korumalı tam mobil yedek oluştur veya geri yükle.',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => MemoryBackupPage(backup: backup),
                ),
              ),
            ),
          ),
        if (widget.bootstrap.attachmentCatalog case final catalog?)
          Card(
            child: ListTile(
              key: const Key('open-attachment-catalog'),
              minVerticalPadding: 12,
              leading: const Icon(Icons.folder_copy_outlined),
              title: const Text('Dosya Kataloğu'),
              subtitle: const Text(
                'Projedeki dosyaları ve bağlı CSE kayıtlarını görüntüle.',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => AttachmentCatalogPage(catalog: catalog),
                ),
              ),
            ),
          ),
        if (widget.bootstrap.attachmentReconciliation
            case final reconciliation?)
          Card(
            child: ListTile(
              key: const Key('open-attachment-health'),
              minVerticalPadding: 12,
              leading: const Icon(Icons.health_and_safety_outlined),
              title: const Text('Dosya sağlığı'),
              subtitle: const Text(
                'Eksik, bozuk veya kırık bağlantıları salt-okunur denetle.',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) =>
                      AttachmentHealthPage(reconciliation: reconciliation),
                ),
              ),
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
