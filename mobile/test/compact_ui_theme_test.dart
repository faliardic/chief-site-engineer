import 'package:chief_site_engineer/app.dart';
import 'package:chief_site_engineer/bootstrap/app_bootstrap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_agenda_application.dart';

void main() {
  testWidgets(
    'root themes share compact sizing and preserve accessibility scaling',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.binding.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(
        tester.binding.platformDispatcher.clearTextScaleFactorTestValue,
      );

      await tester.pumpWidget(
        CseApp(bootstrap: Future<BootstrapResult>.value(BootstrapFailure())),
      );
      await tester.pumpAndSettle();
      final diagnosticContext = tester.element(
        find.text('Uygulama güvenli biçimde başlatılamadı.'),
      );
      expect(
        MediaQuery.textScalerOf(diagnosticContext).scale(10),
        closeTo(16, 0.001),
      );
      expect(tester.takeException(), isNull);

      tester.binding.platformDispatcher.textScaleFactorTestValue = 1;
      await tester.pumpWidget(
        CseApp(
          bootstrap: Future<BootstrapResult>.value(
            BootstrapSuccess(
              environmentLabel: 'Test',
              smokeRecordId: 'issue-567-compact-theme',
              smokeRecordCreatedAt: '2026-09-01T08:00:00Z',
              agenda: FakeAgendaApplication(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      final light = app.theme!;
      final dark = app.darkTheme!;
      _expectCompactTheme(light, dark);

      expect(find.byKey(const Key('dashboard-no-project')), findsOneWidget);
      expect(tester.getSize(find.byType(AppBar)).height, 52);
      expect(tester.getSize(find.byType(NavigationBar)).height, 64);
      expect(tester.takeException(), isNull);
    },
  );
}

void _expectCompactTheme(ThemeData light, ThemeData dark) {
  const density = VisualDensity(horizontal: -1, vertical: -1);
  const buttonMinimum = Size(0, 40);
  const buttonPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 8);
  const states = <WidgetState>{};

  expect(light.brightness, Brightness.light);
  expect(dark.brightness, Brightness.dark);
  expect(light.useMaterial3, isTrue);
  expect(dark.useMaterial3, isTrue);
  expect(light.materialTapTargetSize, MaterialTapTargetSize.shrinkWrap);
  expect(dark.materialTapTargetSize, MaterialTapTargetSize.shrinkWrap);
  expect(light.visualDensity, density);
  expect(dark.visualDensity, density);

  final lightButtons = <ButtonStyle?>[
    light.filledButtonTheme.style,
    light.elevatedButtonTheme.style,
    light.outlinedButtonTheme.style,
    light.textButtonTheme.style,
  ];
  final darkButtons = <ButtonStyle?>[
    dark.filledButtonTheme.style,
    dark.elevatedButtonTheme.style,
    dark.outlinedButtonTheme.style,
    dark.textButtonTheme.style,
  ];
  for (var index = 0; index < lightButtons.length; index += 1) {
    final lightStyle = lightButtons[index]!;
    final darkStyle = darkButtons[index]!;
    expect(lightStyle.minimumSize!.resolve(states), buttonMinimum);
    expect(darkStyle.minimumSize!.resolve(states), buttonMinimum);
    expect(lightStyle.padding!.resolve(states), buttonPadding);
    expect(darkStyle.padding!.resolve(states), buttonPadding);
    expect(lightStyle.visualDensity, VisualDensity.standard);
    expect(darkStyle.visualDensity, VisualDensity.standard);
    expect(lightStyle.tapTargetSize, MaterialTapTargetSize.shrinkWrap);
    expect(darkStyle.tapTargetSize, MaterialTapTargetSize.shrinkWrap);
  }

  expect(
    light.iconButtonTheme.style!.minimumSize!.resolve(states),
    const Size.square(40),
  );
  expect(
    dark.iconButtonTheme.style!.minimumSize!.resolve(states),
    const Size.square(40),
  );
  expect(light.iconButtonTheme.style!.visualDensity, VisualDensity.standard);
  expect(dark.iconButtonTheme.style!.visualDensity, VisualDensity.standard);

  expect(light.inputDecorationTheme.isDense, isTrue);
  expect(dark.inputDecorationTheme.isDense, isTrue);
  expect(
    light.inputDecorationTheme.contentPadding,
    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  );
  expect(
    dark.inputDecorationTheme.contentPadding,
    light.inputDecorationTheme.contentPadding,
  );
  expect(light.appBarTheme.toolbarHeight, 52);
  expect(dark.appBarTheme.toolbarHeight, 52);
  expect(light.navigationBarTheme.height, 64);
  expect(dark.navigationBarTheme.height, 64);
  expect(light.appBarTheme.titleTextStyle!.fontSize, lessThan(22));
  expect(
    dark.appBarTheme.titleTextStyle!.fontSize,
    light.appBarTheme.titleTextStyle!.fontSize,
  );
  expect(
    light.navigationBarTheme.labelTextStyle!.resolve(states)!.fontSize,
    light.textTheme.labelSmall!.fontSize,
  );
  expect(
    dark.navigationBarTheme.labelTextStyle!.resolve(states)!.fontSize,
    light.navigationBarTheme.labelTextStyle!.resolve(states)!.fontSize,
  );

  final defaultTheme = ThemeData(useMaterial3: true);
  final defaultTextTheme = defaultTheme.typography.englishLike.merge(
    defaultTheme.textTheme,
  );
  final defaultStyles = _textStyles(defaultTextTheme);
  final lightStyles = _textStyles(light.textTheme);
  final darkStyles = _textStyles(dark.textTheme);
  expect(lightStyles, hasLength(defaultStyles.length));
  for (var index = 0; index < defaultStyles.length; index += 1) {
    final defaultStyle = defaultStyles[index]!;
    final lightStyle = lightStyles[index]!;
    final darkStyle = darkStyles[index]!;
    expect(lightStyle.fontSize, closeTo(defaultStyle.fontSize! * 0.92, 0.001));
    expect(darkStyle.fontSize, lightStyle.fontSize);
    expect(lightStyle.fontWeight, defaultStyle.fontWeight);
    expect(darkStyle.fontWeight, lightStyle.fontWeight);
  }
  expect(
    light.textTheme.displayLarge!.fontSize,
    greaterThan(light.textTheme.headlineLarge!.fontSize!),
  );
  expect(
    light.textTheme.headlineLarge!.fontSize,
    greaterThan(light.textTheme.titleLarge!.fontSize!),
  );
  expect(
    light.textTheme.titleLarge!.fontSize,
    greaterThan(light.textTheme.bodyLarge!.fontSize!),
  );
  expect(
    light.textTheme.bodyLarge!.fontSize,
    greaterThan(light.textTheme.labelSmall!.fontSize!),
  );
}

List<TextStyle?> _textStyles(TextTheme theme) => [
  theme.displayLarge,
  theme.displayMedium,
  theme.displaySmall,
  theme.headlineLarge,
  theme.headlineMedium,
  theme.headlineSmall,
  theme.titleLarge,
  theme.titleMedium,
  theme.titleSmall,
  theme.bodyLarge,
  theme.bodyMedium,
  theme.bodySmall,
  theme.labelLarge,
  theme.labelMedium,
  theme.labelSmall,
];
