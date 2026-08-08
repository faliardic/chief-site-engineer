import 'package:chief_site_engineer/app.dart';
import 'package:chief_site_engineer/bootstrap/app_bootstrap.dart';
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
      expect(find.text('Çevrim dışı temel hazır'), findsOneWidget);
      expect(
        find.textContaining('Bulut eşitleme ve kullanıcı hesabı'),
        findsOneWidget,
      );
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

  testWidgets('mobile shell exposes all release 0.1 navigation entries', (
    tester,
  ) async {
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

    expect(find.text('Saha hafızanız cihazınızda.'), findsOneWidget);
    for (final label in [
      'Başlangıç',
      'Hatırlatıcı',
      'Ajanda',
      'Puantaj',
      'Beton Paketi',
    ]) {
      expect(find.text(label), findsWidgets);
    }

    await tester.tap(find.text('Ajanda').last);
    await tester.pumpAndSettle();
    expect(find.text('Bu günde Ajanda kaydı yok.'), findsOneWidget);
    expect(find.byKey(const Key('create-agenda-log')), findsOneWidget);
  });

  testWidgets('home field tips stay single cycle manually and remain accessible', (
    tester,
  ) async {
    final semanticsHandle = tester.ensureSemantics();
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.binding.platformDispatcher.textScaleFactorTestValue = 1.6;
    tester.binding.platformDispatcher.platformBrightnessTestValue =
        Brightness.dark;
    addTearDown(
      tester.binding.platformDispatcher.clearTextScaleFactorTestValue,
    );
    addTearDown(
      tester.binding.platformDispatcher.clearPlatformBrightnessTestValue,
    );

    const tips = <String>[
      'Sahada görülen veya söylenenler, mümkün olduğunca anında kayda geçtiğinde unutulmaz.',
      'Fotoğraf; neyi, nerede ve neden gösterdiğiyle birlikte anlam kazanır.',
      'Gün sonu, önemli gelişmelerin rapor ve kayıtlara yansıdığını kontrol etme zamanıdır.',
      'Açık işler zihinde değil, sistemde görünür kaldığında daha kolay takip edilir.',
    ];

    await tester.pumpWidget(
      CseApp(
        bootstrap: Future<BootstrapResult>.value(
          BootstrapSuccess(
            environmentLabel: 'Geliştirme',
            smokeRecordId: 'home-field-tips',
            smokeRecordCreatedAt: '2026-08-08T08:00:00Z',
            agenda: FakeAgendaApplication(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('home-field-tip-card')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    void expectOnlyTip(int index) {
      for (var tipIndex = 0; tipIndex < tips.length; tipIndex += 1) {
        expect(
          find.text(tips[tipIndex]),
          tipIndex == index ? findsOneWidget : findsNothing,
        );
      }
    }

    Future<void> tapTipControl(Key key) async {
      final control = find.byKey(key);
      await tester.ensureVisible(control);
      await tester.tap(control);
      await tester.pump();
    }

    expect(find.byKey(const Key('home-field-tip-card')), findsOneWidget);
    expect(find.text('Saha İpucu'), findsOneWidget);
    expect(find.byKey(const Key('field-tip-text')), findsOneWidget);
    expectOnlyTip(0);
    expect(find.text('1 / 4'), findsOneWidget);

    final previous = tester.widget<IconButton>(
      find.byKey(const Key('previous-field-tip')),
    );
    final next = tester.widget<IconButton>(
      find.byKey(const Key('next-field-tip')),
    );
    expect(previous.tooltip, 'Önceki saha ipucu');
    expect(next.tooltip, 'Sonraki saha ipucu');

    var liveRegion = tester.widget<Semantics>(
      find.byKey(const Key('field-tip-live-region')),
    );
    expect(liveRegion.properties.liveRegion, isTrue);
    expect(liveRegion.properties.label, 'Saha İpucu 1 / 4: ${tips.first}');

    await tapTipControl(const Key('next-field-tip'));
    expectOnlyTip(1);
    expect(find.text('2 / 4'), findsOneWidget);

    await tapTipControl(const Key('next-field-tip'));
    await tapTipControl(const Key('next-field-tip'));
    expectOnlyTip(3);
    expect(find.text('4 / 4'), findsOneWidget);

    await tapTipControl(const Key('next-field-tip'));
    expectOnlyTip(0);
    expect(find.text('1 / 4'), findsOneWidget);

    await tapTipControl(const Key('previous-field-tip'));
    expectOnlyTip(3);
    expect(find.text('4 / 4'), findsOneWidget);
    liveRegion = tester.widget<Semantics>(
      find.byKey(const Key('field-tip-live-region')),
    );
    expect(liveRegion.properties.liveRegion, isTrue);
    expect(liveRegion.properties.label, 'Saha İpucu 4 / 4: ${tips.last}');

    final cardContext = tester.element(
      find.byKey(const Key('home-field-tip-card')),
    );
    expect(Theme.of(cardContext).brightness, Brightness.dark);
    expect(MediaQuery.textScalerOf(cardContext).scale(10), 16);
    final exception = tester.takeException();
    semanticsHandle.dispose();
    expect(exception, isNull);
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
