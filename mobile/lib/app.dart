import 'package:chief_site_engineer/bootstrap/app_bootstrap.dart';
import 'package:flutter/material.dart';

class CseApp extends StatelessWidget {
  const CseApp({required this.bootstrap, super.key});

  final Future<BootstrapResult> bootstrap;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chief Site Engineer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E5D4E)),
        useMaterial3: true,
      ),
      home: BootstrapGate(bootstrap: bootstrap),
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
          BootstrapFailure() => const BootstrapFailureScreen(),
        };
      },
    );
  }
}

class BootstrapFailureScreen extends StatelessWidget {
  const BootstrapFailureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.storage_rounded, size: 52),
                SizedBox(height: 16),
                Text(
                  'Yerel veri deposu güvenli biçimde açılamadı.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 8),
                Text(
                  'Hiçbir kayıt yazılmadı. Uygulamayı kapatıp yeniden deneyin.',
                  textAlign: TextAlign.center,
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
            const _PreparingPage(
              icon: Icons.notifications_none_rounded,
              title: 'Hatırlatıcı',
            ),
            const _PreparingPage(
              icon: Icons.event_note_outlined,
              title: 'Ajanda',
            ),
            const _PreparingPage(icon: Icons.badge_outlined, title: 'Puantaj'),
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
