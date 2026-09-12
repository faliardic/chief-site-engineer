import 'dart:ui' show SemanticsAction;

import 'package:chief_site_engineer/features/settings/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows exactly two accessible global settings destinations', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsPage(
          backupPageBuilder: (_) => const _Destination(label: 'Yedek'),
          fileDataHealthPageBuilder: (_) => const _Destination(label: 'Sağlık'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ayarlar'), findsOneWidget);
    expect(find.byType(ListTile), findsNWidgets(2));
    expect(find.byKey(const Key('active-project-indicator')), findsNothing);

    for (final destination in [
      (key: const Key('settings-memory-backup'), label: 'Hafıza ve Yedekleme'),
      (
        key: const Key('settings-file-data-health'),
        label: 'Dosya ve Veri Sağlığı',
      ),
    ]) {
      final finder = find.byKey(destination.key);
      expect(finder, findsOneWidget);
      expect(tester.getSize(finder).height, greaterThanOrEqualTo(48));
      final node = tester.getSemantics(
        find.bySemanticsLabel(destination.label),
      );
      expect(node.getSemanticsData().label, destination.label);
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      expect(node.rect.height, greaterThanOrEqualTo(48));
    }
    semantics.dispose();
  });

  testWidgets('child routes return through Settings to the previous shell', (
    tester,
  ) async {
    await tester.pumpWidget(const _SettingsRouteHost());

    await tester.tap(find.byKey(const Key('open-settings-host')));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsOneWidget);

    await tester.tap(find.byKey(const Key('settings-memory-backup')));
    await tester.pumpAndSettle();
    expect(find.text('Yedek Hedefi'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsOneWidget);

    await tester.tap(find.byKey(const Key('settings-file-data-health')));
    await tester.pumpAndSettle();
    expect(find.text('Sağlık Hedefi'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Önceki Shell'), findsOneWidget);
    expect(find.byType(SettingsPage), findsNothing);
  });
}

class _SettingsRouteHost extends StatelessWidget {
  const _SettingsRouteHost();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              key: const Key('open-settings-host'),
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => SettingsPage(
                    backupPageBuilder: (_) =>
                        const _Destination(label: 'Yedek Hedefi'),
                    fileDataHealthPageBuilder: (_) =>
                        const _Destination(label: 'Sağlık Hedefi'),
                  ),
                ),
              ),
              child: const Text('Önceki Shell'),
            ),
          ),
        ),
      ),
    );
  }
}

class _Destination extends StatelessWidget {
  const _Destination({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text(label)));
  }
}
