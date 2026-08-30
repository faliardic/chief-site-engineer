import 'package:chief_site_engineer/app.dart';
import 'package:chief_site_engineer/bootstrap/app_bootstrap.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'support/fake_agenda_application.dart';

void main() {
  testWidgets(
    'CseApp forces Turkish Material Widgets and Cupertino localizations',
    (tester) async {
      tester.binding.platformDispatcher.localeTestValue = const Locale(
        'en',
        'US',
      );
      addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);
      await tester.pumpWidget(
        CseApp(
          bootstrap: Future<BootstrapResult>.value(
            BootstrapSuccess(
              environmentLabel: 'Geliştirme',
              smokeRecordId: 'localization-baseline',
              smokeRecordCreatedAt: '2026-07-28T08:00:00Z',
              agenda: FakeAgendaApplication(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.locale, CseApp.locale);
      expect(app.supportedLocales, CseApp.supportedLocales);
      expect(app.localizationsDelegates, CseApp.localizationsDelegates);
      expect(
        app.localizationsDelegates,
        contains(GlobalMaterialLocalizations.delegate),
      );
      expect(
        app.localizationsDelegates,
        contains(GlobalWidgetsLocalizations.delegate),
      );
      expect(
        app.localizationsDelegates,
        contains(GlobalCupertinoLocalizations.delegate),
      );

      final context = tester.element(find.byType(BootstrapGate));
      final material = MaterialLocalizations.of(context);
      expect(Localizations.localeOf(context), const Locale('tr'));
      expect(material.copyButtonLabel, 'Kopyala');
      expect(material.pasteButtonLabel, 'Yapıştır');
      expect(material.cutButtonLabel, 'Kes');
      expect(material.selectAllButtonLabel, 'Tümünü seç');
      expect(WidgetsLocalizations.of(context).textDirection, TextDirection.ltr);
      final cupertino = CupertinoLocalizations.of(context);
      expect(cupertino.copyButtonLabel, 'Kopyala');
      expect(cupertino.pasteButtonLabel, 'Yapıştır');
      expect(cupertino.cutButtonLabel, 'Kes');
      expect(cupertino.selectAllButtonLabel, 'Tümünü Seç');
      expect(find.byKey(const Key('dashboard-no-project')), findsOneWidget);
      expect(find.text('İlk projenizi oluşturun'), findsOneWidget);
      expect(find.textContaining('Offline temel hazır'), findsNothing);
      expect(find.textContaining('Cloud sync'), findsNothing);
    },
  );

  testWidgets('editable TextField selection toolbar actions are Turkish', (
    tester,
  ) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => switch (call.method) {
        'Clipboard.hasStrings' => <String, Object>{'value': true},
        'Clipboard.getData' => <String, Object>{'text': 'CSE266 SENTETİK PANO'},
        _ => null,
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final controller = TextEditingController(
      text: 'CSE266 sentetik seçim metni',
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _localizedTestApp(
        Scaffold(
          body: Center(
            child: SizedBox(
              width: 600,
              child: TextField(
                key: const Key('editable-localization-fixture'),
                controller: controller,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.longPress(
      find.byKey(const Key('editable-localization-fixture')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Kopyala'), findsOneWidget);
    expect(find.text('Yapıştır'), findsOneWidget);
    expect(find.text('Kes'), findsOneWidget);
    expect(find.text('Tümünü seç'), findsOneWidget);
    expect(debugDefaultTargetPlatformOverride, isNull);
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('read-only TextField hides cut and paste actions', (
    tester,
  ) async {
    final controller = TextEditingController(
      text: 'CSE266 salt okunur sentetik metin',
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _localizedTestApp(
        Scaffold(
          body: Center(
            child: SizedBox(
              width: 600,
              child: TextField(
                key: const Key('readonly-localization-fixture'),
                controller: controller,
                readOnly: true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.longPress(
      find.byKey(const Key('readonly-localization-fixture')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Kopyala'), findsOneWidget);
    expect(find.text('Tümünü seç'), findsOneWidget);
    expect(find.text('Kes'), findsNothing);
    expect(find.text('Yapıştır'), findsNothing);
    expect(debugDefaultTargetPlatformOverride, isNull);
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('date and time pickers expose Turkish actions', (tester) async {
    await tester.pumpWidget(
      _localizedTestApp(
        Builder(
          builder: (context) => Scaffold(
            body: Column(
              children: [
                TextButton(
                  key: const Key('open-localized-date-picker'),
                  onPressed: () => showDatePicker(
                    context: context,
                    initialDate: DateTime(2026, 7, 28),
                    firstDate: DateTime(2026),
                    lastDate: DateTime(2027),
                  ),
                  child: const Text('Tarih fixture'),
                ),
                TextButton(
                  key: const Key('open-localized-time-picker'),
                  onPressed: () => showTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 8, minute: 30),
                  ),
                  child: const Text('Saat fixture'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('open-localized-date-picker')));
    await tester.pumpAndSettle();
    expect(find.text('Tarih seçin'), findsOneWidget);
    expect(find.text('İptal'), findsOneWidget);
    expect(find.text('Tamam'), findsOneWidget);
    await tester.tap(find.text('İptal'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('open-localized-time-picker')));
    await tester.pumpAndSettle();
    expect(find.text('Saat seçin'), findsOneWidget);
    expect(find.text('İptal'), findsOneWidget);
    expect(find.text('Tamam'), findsOneWidget);
    expect(find.textContaining('08'), findsWidgets);
    await tester.tap(find.text('İptal'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'mobile shell exposes exact six Slice 4 destinations and Daha hub',
    (tester) async {
      await tester.pumpWidget(
        CseApp(
          bootstrap: Future<BootstrapResult>.value(
            BootstrapSuccess(
              environmentLabel: 'Geliştirme',
              smokeRecordId: 'mobile-foundation-v1',
              smokeRecordCreatedAt: '2026-07-19T08:00:00Z',
              agenda: FakeAgendaApplication(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('dashboard-no-project')), findsOneWidget);
      const expectedLabels = [
        'Başlangıç',
        'Hatırlatıcı',
        'Ajanda',
        'Envanter',
        'Puantaj',
        'Daha',
      ];
      final navigation = tester.widget<NavigationBar>(
        find.byType(NavigationBar),
      );
      expect(navigation.destinations, hasLength(6));
      expect(
        navigation.destinations
            .cast<NavigationDestination>()
            .map((destination) => destination.label)
            .toList(),
        expectedLabels,
      );
      for (final label in expectedLabels) {
        expect(find.text(label), findsWidgets);
      }

      await tester.tap(find.text('Envanter').last);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('inventory-project-required')),
        findsOneWidget,
      );

      await tester.tap(find.text('Daha').last);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('more-page')), findsOneWidget);
      expect(find.byKey(const Key('more-concrete-package')), findsOneWidget);
      expect(find.byKey(const Key('more-workforce-directory')), findsOneWidget);
      expect(find.text('Beton Paketi'), findsOneWidget);
      expect(find.text('Sicil'), findsOneWidget);

      await tester.tap(find.text('Ajanda').last);
      await tester.pumpAndSettle();
      expect(find.text('Bu günde Ajanda kaydı yok.'), findsOneWidget);
      expect(find.byKey(const Key('create-agenda-log')), findsOneWidget);
    },
  );

  testWidgets('Dashboard quick actions open exact existing capture routes', (
    tester,
  ) async {
    const project = MobileProject(
      id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      name: 'Şantiye A',
      createdAt: '2026-08-30T06:00:00Z',
      updatedAt: '2026-08-30T06:00:00Z',
      revision: 1,
    );
    final agenda = FakeAgendaApplication(projects: const [project]);
    await tester.pumpWidget(
      CseApp(
        bootstrap: Future<BootstrapResult>.value(
          BootstrapSuccess(
            environmentLabel: 'Geliştirme',
            smokeRecordId: 'dashboard-routes',
            smokeRecordCreatedAt: '2026-08-30T08:00:00Z',
            agenda: agenda,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dashboard-project-header')), findsOneWidget);
    expect(find.byKey(const Key('home-field-tip-card')), findsNothing);

    await tester.tap(find.byKey(const Key('dashboard-quick-reminder')));
    await tester.pumpAndSettle();
    final reminderProject = tester.widget<DropdownButtonFormField<String?>>(
      find.byKey(const Key('reminder-project')),
    );
    expect(reminderProject.initialValue, project.id);
    expect(find.byType(BackButton), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('dashboard-quick-agenda')));
    await tester.pumpAndSettle();
    final logProject = tester.widget<DropdownButtonFormField<String>>(
      find.byKey(const Key('log-project')),
    );
    expect(logProject.initialValue, project.id);
    expect(find.byType(BackButton), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(agenda.createReminderCalls, 0);
    expect(agenda.createLogCalls, 0);
  });

  testWidgets('database bootstrap failure is fail closed and user safe', (
    tester,
  ) async {
    await tester.pumpWidget(
      CseApp(bootstrap: Future<BootstrapResult>.value(BootstrapFailure())),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Uygulama güvenli biçimde başlatılamadı.'),
      findsOneWidget,
    );
    expect(find.textContaining('İşlem sonucu doğrulanamadı.'), findsOneWidget);
    expect(find.textContaining('ilgili kaydı kontrol edin'), findsOneWidget);
    expect(find.textContaining('Yeni kayıt yazılmadı.'), findsNothing);
    expect(find.text('Tanı kodu: startup_failed'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('fatal errors replace raw exceptions with a safe diagnostic', (
    tester,
  ) async {
    final fatalErrors = ValueNotifier<String?>(null);
    await tester.pumpWidget(
      CseApp(
        bootstrap: Future<BootstrapResult>.value(BootstrapFailure()),
        fatalErrors: fatalErrors,
      ),
    );
    fatalErrors.value = 'uncaught_async_error';
    await tester.pumpAndSettle();

    expect(find.text('Tanı kodu: uncaught_async_error'), findsOneWidget);
    expect(find.textContaining('Exception'), findsNothing);
    expect(find.textContaining('StackTrace'), findsNothing);
  });

  for (final brightness in Brightness.values) {
    testWidgets('CseApp fatal screen opens in ${brightness.name} theme', (
      tester,
    ) async {
      tester.binding.platformDispatcher.platformBrightnessTestValue =
          brightness;
      addTearDown(
        tester.binding.platformDispatcher.clearPlatformBrightnessTestValue,
      );
      await tester.pumpWidget(
        CseApp(
          bootstrap: Future<BootstrapResult>.value(BootstrapFailure()),
          fatalErrors: ValueNotifier<String?>('synthetic_fatal'),
        ),
      );
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(SafeDiagnosticPanel));
      expect(Theme.of(context).brightness, brightness);
      expect(find.text('Tanı kodu: synthetic_fatal'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  for (final width in [320.0, 430.0]) {
    testWidgets(
      'safe diagnostic fits ${width.toInt()} px with large Turkish text',
      (tester) async {
        tester.view.physicalSize = Size(width, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(brightness: Brightness.dark),
            home: const MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(1.6)),
              child: SafeDiagnosticScreen(code: 'restore_recovery_failed'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.textContaining('Veriler silinmedi'), findsOneWidget);
        expect(find.text('Tanı kodu: restore_recovery_failed'), findsOneWidget);
      },
    );
  }
}

Widget _localizedTestApp(Widget home) => MaterialApp(
  locale: CseApp.locale,
  supportedLocales: CseApp.supportedLocales,
  localizationsDelegates: CseApp.localizationsDelegates,
  theme: ThemeData(platform: TargetPlatform.android),
  home: home,
);
