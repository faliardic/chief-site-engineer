import 'dart:async';

import 'package:chief_site_engineer/bootstrap/app_bootstrap.dart';
import 'package:chief_site_engineer/features/agenda/agenda_page.dart';
import 'package:chief_site_engineer/features/attendance/attendance_day_page.dart';
import 'package:chief_site_engineer/features/attendance/attendance_page.dart';
import 'package:chief_site_engineer/features/concrete/concrete_page.dart';
import 'package:chief_site_engineer/features/concrete/concrete_pour_detail_page.dart';
import 'package:chief_site_engineer/features/memory/memory_backup_page.dart';
import 'package:chief_site_engineer/features/reminders/reminder_detail_page.dart';
import 'package:chief_site_engineer/features/reminders/reminders_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class CseApp extends StatelessWidget {
  const CseApp({required this.bootstrap, this.fatalErrors, super.key});

  final Future<BootstrapResult> bootstrap;
  final ValueListenable<String?>? fatalErrors;

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
      title: 'Chief Site Engineer',
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
                      : 'Yeni kayıt yazılmadı. Uygulamayı kapatıp yeniden deneyin.',
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
            ),
            AgendaPage(agenda: widget.bootstrap.agenda),
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

class _HomePage extends StatelessWidget {
  const _HomePage({required this.bootstrap});

  final BootstrapSuccess bootstrap;

  @override
  Widget build(BuildContext context) {
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
            title: const Text('Offline temel hazır'),
            subtitle: Text(
              'Cihaz-içi SQLite • ${bootstrap.environmentLabel} ortamı',
            ),
          ),
        ),
        const Card(
          child: ListTile(
            leading: Icon(Icons.lock_outline_rounded),
            title: Text('Veri sınırı'),
            subtitle: Text('Cloud sync ve kullanıcı hesabı bu sürümde yoktur.'),
          ),
        ),
        if (bootstrap.backup case final backup?)
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
