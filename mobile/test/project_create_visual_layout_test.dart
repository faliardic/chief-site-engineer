import 'package:chief_site_engineer/features/projects/project_create_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_agenda_application.dart';

Finder _key(String key) => find.byKey(Key(key));
Finder get _scroll => find
    .descendant(
      of: _key('project-create-scroll'),
      matching: find.byType(Scrollable),
    )
    .first;

void main() {
  for (final size in [
    const Size(320, 760),
    const Size(390, 844),
    const Size(800, 900),
    const Size(1280, 900),
  ]) {
    testWidgets(
      'form uses available height and bounded centered width at $size',
      (tester) async {
        await _pump(tester, size);
        expect(find.byType(TextField), findsOneWidget);
        expect(_key('project-name'), findsOneWidget);
        expect(_key('save-project').hitTestable(), findsOneWidget);
        expect(find.text('Kaydet'), findsOneWidget);
        expect(find.byType(FilledButton), findsOneWidget);
        expect(_key('project-create-heading').hitTestable(), findsOneWidget);
        expect(find.textContaining('Proje Profili'), findsOneWidget);
        expect(
          find.descendant(
            of: _key('project-name-group'),
            matching: _key('project-name'),
          ),
          findsOneWidget,
        );
        final content = tester.getRect(_key('project-create-content'));
        final save = tester.getRect(_key('save-project'));
        final heading = tester.getRect(_key('project-create-heading'));
        final group = tester.getRect(_key('project-name-group'));
        expect(content.width, lessThanOrEqualTo(560));
        expect(content.center.dx, closeTo(size.width / 2, 1));
        expect(save.width, closeTo(content.width, 1));
        expect(save.height, greaterThanOrEqualTo(48));
        expect(save.top, greaterThan(size.height * .7));
        expect(size.height - save.bottom, inInclusiveRange(24, 40));
        expect(heading.bottom, lessThan(group.top));
        expect(group.bottom, lessThan(save.top));
        final field = tester.widget<TextField>(_key('project-name'));
        expect(field.maxLength, 160);
        expect(field.textInputAction, TextInputAction.done);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final scenario in [
    (const Size(320, 760), 0.0),
    (const Size(390, 844), 0.0),
    (const Size(320, 320), 0.0),
    (const Size(390, 300), 0.0),
    (const Size(320, 640), 300.0),
    (const Size(390, 760), 340.0),
    (const Size(800, 600), 300.0),
  ]) {
    testWidgets('2x text and keyboard remain scroll safe at $scenario', (
      tester,
    ) async {
      await _pump(tester, scenario.$1, scale: 2, keyboard: scenario.$2);
      expect(tester.takeException(), isNull);
      expect(find.byType(TextField), findsOneWidget);
      await tester.ensureVisible(_key('project-name'));
      await tester.enterText(_key('project-name'), '   ');
      await tester.scrollUntilVisible(
        _key('save-project'),
        120,
        scrollable: _scroll,
      );
      await tester.pumpAndSettle();
      expect(_key('save-project').hitTestable(), findsOneWidget);
      expect(
        tester.getRect(_key('save-project')).bottom,
        lessThanOrEqualTo(scenario.$1.height - scenario.$2),
      );
      expect(
        tester.getSize(_key('save-project')).height,
        greaterThanOrEqualTo(48),
      );
      await tester.tap(_key('save-project'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(_key('project-create-error'));
      await tester.pumpAndSettle();
      expect(find.text('Proje adı zorunludur.'), findsOneWidget);
      expect(
        tester.widget<TextField>(_key('project-name')).controller!.text,
        '   ',
      );
      await tester.scrollUntilVisible(
        _key('save-project'),
        120,
        scrollable: _scroll,
      );
      expect(_key('save-project').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

Future<void> _pump(
  WidgetTester tester,
  Size size, {
  double scale = 1,
  double keyboard = 0,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: ProjectCreatePage(agenda: FakeAgendaApplication()),
    ),
  );
  await tester.pumpAndSettle();
}
