import 'dart:async';

import 'package:chief_site_engineer/app.dart';
import 'package:chief_site_engineer/core/record_id.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/features/projects/project_create_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_agenda_application.dart';

void main() {
  testWidgets('valid name is trimmed, created once, and returned by route', (
    tester,
  ) async {
    final agenda = _ProjectCreateAgenda();
    final result = ValueNotifier<MobileProject?>(null);
    addTearDown(result.dispose);
    await _openPage(tester, agenda, result);

    expect(find.byKey(const Key('project-create-page')), findsOneWidget);
    expect(find.text('Yeni Proje'), findsOneWidget);
    expect(find.text('Proje adı'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('project-name')),
      '  Kuzey Şantiyesi  ',
    );
    await tester.tap(find.byKey(const Key('save-project')));
    await tester.pumpAndSettle();

    expect(agenda.createProjectCalls, 1);
    expect(agenda.lastCommand?.name, 'Kuzey Şantiyesi');
    expect(RecordId.isUuid(agenda.lastCommand!.id), isTrue);
    expect(result.value?.name, 'Kuzey Şantiyesi');
    expect(find.byKey(const Key('project-create-page')), findsNothing);
  });

  testWidgets('blank name stays open and starts no mutation', (tester) async {
    final agenda = _ProjectCreateAgenda();
    final result = ValueNotifier<MobileProject?>(null);
    addTearDown(result.dispose);
    await _openPage(tester, agenda, result);

    await tester.enterText(find.byKey(const Key('project-name')), '   ');
    await tester.tap(find.byKey(const Key('save-project')));
    await tester.pump();

    expect(agenda.createProjectCalls, 0);
    expect(find.byKey(const Key('project-create-page')), findsOneWidget);
    expect(find.byKey(const Key('project-create-error')), findsOneWidget);
    expect(find.text('Proje adı zorunludur.'), findsOneWidget);
    expect(result.value, isNull);
  });

  testWidgets('saving blocks route back until created result is returned', (
    tester,
  ) async {
    final agenda = _ProjectCreateAgenda();
    final pending = Completer<MobileProject>();
    agenda.pendingCreate = pending;
    final result = ValueNotifier<MobileProject?>(null);
    addTearDown(result.dispose);
    await _openPage(tester, agenda, result);

    await tester.enterText(
      find.byKey(const Key('project-name')),
      'Bekleyen Proje',
    );
    final save = find.byKey(const Key('save-project'));
    await tester.tap(save);
    await tester.pump();

    expect(agenda.createProjectCalls, 1);
    expect(
      find.descendant(
        of: save,
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    expect(tester.widget<FilledButton>(save).onPressed, isNull);
    await tester.tap(save, warnIfMissed: false);
    await tester.pump();
    expect(agenda.createProjectCalls, 1);
    expect(find.byKey(const Key('project-create-page')), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pump();
    expect(find.byKey(const Key('project-create-page')), findsOneWidget);
    expect(result.value, isNull);
    expect(agenda.createProjectCalls, 1);

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    await navigator.maybePop();
    await tester.pump();
    expect(find.byKey(const Key('project-create-page')), findsOneWidget);
    expect(result.value, isNull);
    expect(agenda.createProjectCalls, 1);

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byKey(const Key('project-create-page')), findsOneWidget);
    expect(result.value, isNull);
    expect(agenda.createProjectCalls, 1);

    final command = agenda.lastCommand!;
    final created = _project(command.id, command.name);
    pending.complete(created);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('project-create-page')), findsNothing);
    expect(result.value, same(created));
    expect(agenda.createProjectCalls, 1);
  });

  testWidgets('create failure stays open, is user safe, and permits retry', (
    tester,
  ) async {
    final agenda = _ProjectCreateAgenda()
      ..failure = const AgendaValidationFailure(
        'Aynı adlı aktif proje zaten bulunuyor.',
      );
    final result = ValueNotifier<MobileProject?>(null);
    addTearDown(result.dispose);
    await _openPage(tester, agenda, result);

    await tester.enterText(
      find.byKey(const Key('project-name')),
      'Tekrar Projesi',
    );
    final save = find.byKey(const Key('save-project'));
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(agenda.createProjectCalls, 1);
    expect(find.byKey(const Key('project-create-page')), findsOneWidget);
    expect(find.text('Aynı adlı aktif proje zaten bulunuyor.'), findsOneWidget);
    expect(result.value, isNull);

    agenda.failure = StateError('storage details must stay hidden');
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(agenda.createProjectCalls, 2);
    expect(find.text('Proje oluşturulamadı.'), findsOneWidget);
    expect(find.textContaining('storage details'), findsNothing);

    agenda.failure = null;
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(agenda.createProjectCalls, 3);
    expect(result.value?.name, 'Tekrar Projesi');
  });

  testWidgets('back returns without creating anything', (tester) async {
    final agenda = _ProjectCreateAgenda();
    final result = ValueNotifier<MobileProject?>(null);
    addTearDown(result.dispose);
    await _openPage(tester, agenda, result);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(agenda.createProjectCalls, 0);
    expect(result.value, isNull);
    expect(find.byKey(const Key('project-create-page')), findsNothing);
  });

  testWidgets('back remains available after create failure', (tester) async {
    final agenda = _ProjectCreateAgenda()
      ..failure = const AgendaValidationFailure(
        'Aynı adlı aktif proje zaten bulunuyor.',
      );
    final result = ValueNotifier<MobileProject?>(null);
    addTearDown(result.dispose);
    await _openPage(tester, agenda, result);

    await tester.enterText(
      find.byKey(const Key('project-name')),
      'Başarısız Proje',
    );
    await tester.tap(find.byKey(const Key('save-project')));
    await tester.pumpAndSettle();

    expect(agenda.createProjectCalls, 1);
    expect(find.byKey(const Key('project-create-error')), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('project-create-page')), findsNothing);
    expect(result.value, isNull);
    expect(agenda.createProjectCalls, 1);
  });

  testWidgets('320 px and text scale 1.6 keeps submit hit-testable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    tester.binding.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(
      tester.binding.platformDispatcher.clearTextScaleFactorTestValue,
    );
    final agenda = _ProjectCreateAgenda();
    final result = ValueNotifier<MobileProject?>(null);
    addTearDown(result.dispose);
    await _openPage(tester, agenda, result);

    await tester.enterText(
      find.byKey(const Key('project-name')),
      'Dar Ekran Projesi',
    );
    final save = find.byKey(const Key('save-project'));
    await tester.scrollUntilVisible(
      save,
      120,
      scrollable: find.byType(Scrollable).last,
    );
    expect(save.hitTestable(), findsOneWidget);
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(agenda.createProjectCalls, 1);
    expect(result.value?.name, 'Dar Ekran Projesi');
    expect(tester.takeException(), isNull);
  });
}

Future<void> _openPage(
  WidgetTester tester,
  _ProjectCreateAgenda agenda,
  ValueNotifier<MobileProject?> result,
) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: CseApp.locale,
      supportedLocales: CseApp.supportedLocales,
      localizationsDelegates: CseApp.localizationsDelegates,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              key: const Key('open-project-create'),
              onPressed: () async {
                result.value = await Navigator.of(context).push<MobileProject>(
                  MaterialPageRoute(
                    builder: (_) => ProjectCreatePage(agenda: agenda),
                  ),
                );
              },
              child: const Text('Aç'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(const Key('open-project-create')));
  await tester.pumpAndSettle();
}

class _ProjectCreateAgenda extends FakeAgendaApplication {
  int createProjectCalls = 0;
  CreateProjectCommand? lastCommand;
  Object? failure;
  Completer<MobileProject>? pendingCreate;

  @override
  Future<MobileProject> createProject(CreateProjectCommand command) async {
    createProjectCalls += 1;
    lastCommand = command;
    if (failure case final current?) throw current;
    if (pendingCreate case final pending?) return pending.future;
    return super.createProject(command);
  }
}

MobileProject _project(String id, String name) => MobileProject(
  id: id,
  name: name,
  createdAt: '2026-09-01T08:00:00Z',
  updatedAt: '2026-09-01T08:00:00Z',
  revision: 1,
);
