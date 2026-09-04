import 'dart:async';

import 'package:chief_site_engineer/app.dart';
import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/application/construction_living_plan_application.dart';
import 'package:chief_site_engineer/application/daily_log_application.dart';
import 'package:chief_site_engineer/application/material_request_application.dart';
import 'package:chief_site_engineer/core/mobile_operation_coordinator.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/construction_living_plan_models.dart';
import 'package:chief_site_engineer/domain/daily_log_models.dart';
import 'package:chief_site_engineer/domain/material_request_models.dart';
import 'package:chief_site_engineer/features/dashboard/project_dashboard_page.dart';
import 'package:chief_site_engineer/features/project_context/active_project_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_agenda_application.dart';

void main() {
  testWidgets('zero projects shows setup and runs no project-bound read', (
    tester,
  ) async {
    final fixture = _Fixture(projects: const []);
    addTearDown(fixture.dispose);
    var setupCalls = 0;

    await tester.pumpWidget(
      fixture.app(onCreateProject: () => setupCalls += 1),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dashboard-no-project')), findsOneWidget);
    expect(fixture.daily.calls, isEmpty);
    expect(fixture.plan.calls, isEmpty);
    expect(fixture.materials.calls, isEmpty);

    final setupAction = find.byKey(const Key('dashboard-create-project'));
    expect(setupAction, findsOneWidget);
    expect(
      find.descendant(
        of: setupAction,
        matching: find.byIcon(Icons.add_business_rounded),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: setupAction,
        matching: find.text('Yeni proje oluştur'),
      ),
      findsOneWidget,
    );
    await tester.tap(setupAction);
    expect(setupCalls, 1);
  });

  testWidgets('multiple projects fail closed until exact explicit selection', (
    tester,
  ) async {
    final projects = [_project('a', 'Kuzey'), _project('b', 'Güney')];
    final fixture = _Fixture(projects: projects);
    addTearDown(fixture.dispose);

    await tester.pumpWidget(fixture.app());
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('dashboard-project-selection-required')),
      findsOneWidget,
    );
    expect(fixture.daily.calls, isEmpty);
    expect(fixture.plan.calls, isEmpty);
    expect(fixture.materials.calls, isEmpty);

    expect(find.byKey(const Key('dashboard-select-project')), findsNothing);
    expect(find.byKey(const Key('dashboard-change-project')), findsNothing);
    expect(find.byKey(const Key('dashboard-create-project')), findsOneWidget);
    expect(fixture.session.select('b', projects), isTrue);
    await tester.pumpAndSettle();

    expect(fixture.session.selectedProjectId, 'b');
    expect(fixture.daily.calls.single, ('b', '2026-08-30'));
    expect(fixture.plan.calls.single.$1, 'b');
    expect(fixture.plan.calls.single.$2, DateTime(2026, 8, 30));
    expect(fixture.materials.calls.single, 'b');
    expect(find.text('Güney'), findsOneWidget);
  });

  testWidgets(
    'unselected multiple projects keeps only new-project action at narrow scale',
    (tester) async {
      tester.view.physicalSize = const Size(320, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.binding.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(
        tester.binding.platformDispatcher.clearTextScaleFactorTestValue,
      );
      final fixture = _Fixture(
        projects: [_project('a', 'Kuzey'), _project('b', 'Güney')],
      );
      addTearDown(fixture.dispose);
      var createCalls = 0;

      await tester.pumpWidget(
        fixture.app(onCreateProject: () => createCalls += 1),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('dashboard-project-selection-required')),
        findsOneWidget,
      );
      final create = find.byKey(const Key('dashboard-create-project'));
      expect(find.byKey(const Key('dashboard-select-project')), findsNothing);
      expect(find.byKey(const Key('dashboard-change-project')), findsNothing);
      expect(
        find.descendant(of: create, matching: find.text('Yeni proje')),
        findsOneWidget,
      );
      expect(create.hitTestable(), findsOneWidget);

      await tester.tap(create);
      await tester.pump();

      expect(createCalls, 1);
      expect(fixture.session.selectedProjectId, isNull);
      expect(fixture.daily.calls, isEmpty);
      expect(fixture.plan.calls, isEmpty);
      expect(fixture.materials.calls, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'projectChanges invalidates stale selection without read leakage',
    (tester) async {
      final fixture = _Fixture(projects: [_project('a', 'Kuzey')]);
      addTearDown(fixture.dispose);
      await tester.pumpWidget(fixture.app());
      await tester.pumpAndSettle();
      expect(fixture.session.selectedProjectId, 'a');
      expect(fixture.daily.calls, hasLength(1));

      fixture.agenda.projects = [_project('b', 'Güney'), _project('c', 'Doğu')];
      fixture.agenda.emitProjectChange();
      await tester.pumpAndSettle();

      expect(fixture.session.selectedProjectId, isNull);
      expect(
        find.byKey(const Key('dashboard-project-selection-required')),
        findsOneWidget,
      );
      expect(fixture.daily.calls, hasLength(1));
      expect(fixture.plan.calls, hasLength(1));
      expect(fixture.materials.calls, hasLength(1));
    },
  );

  testWidgets(
    'section failure is isolated and retry rereads only that source',
    (tester) async {
      final fixture = _Fixture(projects: [_project('a', 'Kuzey')]);
      addTearDown(fixture.dispose);
      fixture.daily.fail = true;

      await tester.pumpWidget(fixture.app());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('dashboard-today-retry')), findsOneWidget);
      final retry = find.byKey(const Key('dashboard-today-retry'));
      expect(tester.widget<IconButton>(retry).tooltip, 'Tekrar dene');
      expect(
        find.descendant(
          of: retry,
          matching: find.byIcon(Icons.refresh_rounded),
        ),
        findsOneWidget,
      );
      expect(find.text('Tekrar dene'), findsNothing);
      expect(find.text('Plan penceresinde kayıt yok.'), findsOneWidget);
      expect(fixture.plan.calls, hasLength(1));
      expect(fixture.materials.calls, hasLength(1));

      fixture.daily.fail = false;
      await tester.tap(retry);
      await tester.pumpAndSettle();

      expect(fixture.daily.calls, hasLength(2));
      expect(fixture.plan.calls, hasLength(1));
      expect(fixture.materials.calls, hasLength(1));
      expect(find.textContaining('Puantaj: kullanılamıyor'), findsOneWidget);
      expect(find.textContaining('Ajanda: 1'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const Key('dashboard-materials-card')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Açık malzeme ihtiyacı yok.'), findsOneWidget);
    },
  );

  testWidgets(
    'quick actions receive exact session project/day and cancel writes nothing',
    (tester) async {
      final fixture = _Fixture(projects: [_project('a', 'Kuzey')]);
      addTearDown(fixture.dispose);
      final captures = <(String, String, String)>[];

      await tester.pumpWidget(
        fixture.app(
          onReminder: (projectId, day) async {
            captures.add(('reminder', projectId, day));
            return false;
          },
          onAgenda: (projectId, day) async {
            captures.add(('agenda', projectId, day));
            return false;
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('dashboard-quick-reminder')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('dashboard-quick-agenda')));
      await tester.pump();

      expect(captures, [
        ('reminder', 'a', '2026-08-30'),
        ('agenda', 'a', '2026-08-30'),
      ]);
      expect(fixture.agenda.createReminderCalls, 0);
      expect(fixture.agenda.createLogCalls, 0);
    },
  );

  testWidgets('normal phone Dashboard uses compact field layout', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final fixture = _Fixture(projects: [_project('a', 'Kuzey')]);
    addTearDown(fixture.dispose);
    final opened = <(String, String)>[];

    await tester.pumpWidget(
      fixture.app(
        onReminder: (_, _) async => false,
        onAgenda: (_, _) async => false,
        onOpenToday: (projectId) => opened.add(('today', projectId)),
        onOpenPlan: (projectId) => opened.add(('plan', projectId)),
        onOpenMaterials: (projectId) => opened.add(('materials', projectId)),
        onOpenConcrete: (projectId) => opened.add(('concrete', projectId)),
        onOpenProjectAlbum: (projectId) => opened.add(('album', projectId)),
        onOpenWorkforce: (projectId) => opened.add(('workforce', projectId)),
      ),
    );
    await tester.pumpAndSettle();

    final reminder = find.byKey(const Key('dashboard-quick-reminder'));
    final agenda = find.byKey(const Key('dashboard-quick-agenda'));
    final reminderRect = tester.getRect(reminder);
    final agendaRect = tester.getRect(agenda);
    expect(reminderRect.top, closeTo(agendaRect.top, 0.01));
    expect(reminderRect.right, lessThan(agendaRect.left));
    expect(reminderRect.height, inInclusiveRange(40, 42));
    expect(agendaRect.height, inInclusiveRange(40, 42));
    expect(tester.widget<IconButton>(reminder).tooltip, 'Unutma ekle');
    expect(tester.widget<IconButton>(agenda).tooltip, 'Ajanda kaydı ekle');
    expect(
      find.descendant(
        of: reminder,
        matching: find.byIcon(Icons.add_alert_outlined),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: agenda,
        matching: find.byIcon(Icons.note_add_outlined),
      ),
      findsOneWidget,
    );
    expect(find.text('+ Unutma'), findsNothing);
    expect(find.text('+ Ajanda kaydı'), findsNothing);
    expect(find.bySemanticsLabel('Unutma ekle'), findsOneWidget);
    expect(find.bySemanticsLabel('Ajanda kaydı ekle'), findsOneWidget);

    final header = find.byKey(const Key('dashboard-project-header'));
    final createProject = find.byKey(const Key('dashboard-create-project'));
    expect(
      find.descendant(of: createProject, matching: find.text('Yeni proje')),
      findsOneWidget,
    );
    final headerPaddings = tester.widgetList<Padding>(
      find.descendant(of: header, matching: find.byType(Padding)),
    );
    expect(
      headerPaddings.map((widget) => widget.padding),
      contains(const EdgeInsets.all(12)),
    );
    expect(
      tester
          .widget<Icon>(
            find.descendant(of: header, matching: find.byType(Icon)).first,
          )
          .size,
      28,
    );

    final planCard = find.byKey(const Key('dashboard-plan-card'));
    final summaryPaddings = tester.widgetList<Padding>(
      find.descendant(of: planCard, matching: find.byType(Padding)),
    );
    expect(
      summaryPaddings.map((widget) => widget.padding),
      contains(const EdgeInsets.all(12)),
    );
    expect(
      tester
          .widget<Icon>(
            find.descendant(of: planCard, matching: find.byType(Icon)).first,
          )
          .size,
      22,
    );

    final summaryActions = <(Finder, String)>[
      (find.byKey(const Key('dashboard-open-today')), 'Günlük Log’u aç'),
      (find.byKey(const Key('dashboard-open-plan')), '7 Günlük Planı aç'),
      (find.byKey(const Key('dashboard-open-materials')), 'Malzemeleri aç'),
    ];
    for (final (action, label) in summaryActions) {
      expect(tester.widget<IconButton>(action).tooltip, label);
      expect(
        find.descendant(
          of: action,
          matching: find.byIcon(Icons.open_in_new_rounded),
        ),
        findsOneWidget,
      );
      final actionSemantics = tester.widgetList<Semantics>(
        find.ancestor(of: action, matching: find.byType(Semantics)),
      );
      expect(
        actionSemantics.map((widget) => widget.properties.label),
        contains(label),
      );
      expect(find.text(label), findsNothing);
      await tester.tap(action);
    }
    expect(opened, [('today', 'a'), ('plan', 'a'), ('materials', 'a')]);
    expect(find.text('Bugün'), findsWidgets);
    expect(find.text('7 Günlük Plan'), findsOneWidget);
    expect(find.text('İstenecek Malzemeler'), findsOneWidget);

    const toolKeys = [
      Key('dashboard-concrete-package'),
      Key('dashboard-project-album'),
      Key('dashboard-workforce-directory'),
    ];
    final workforce = find.byKey(toolKeys.last);
    await tester.scrollUntilVisible(
      workforce,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    final toolOffsets = [
      for (final key in toolKeys) tester.getTopLeft(find.byKey(key)).dy,
    ];
    expect(toolOffsets, orderedEquals(toolOffsets.toList()..sort()));

    for (final key in toolKeys) {
      final tool = find.byKey(key);
      await tester.ensureVisible(tool);
      await tester.tap(tool);
      await tester.pump();
    }
    expect(opened, [
      ('today', 'a'),
      ('plan', 'a'),
      ('materials', 'a'),
      ('concrete', 'a'),
      ('album', 'a'),
      ('workforce', 'a'),
    ]);

    final album = find.byKey(const Key('dashboard-project-album'));
    final tile = tester.widget<ListTile>(
      find.descendant(of: album, matching: find.byType(ListTile)),
    );
    expect(tile.dense, isTrue);
    expect(
      tile.visualDensity,
      const VisualDensity(horizontal: -1, vertical: -2),
    );
    expect(tile.contentPadding, const EdgeInsets.symmetric(horizontal: 12));
    expect(tile.minVerticalPadding, 4);
    expect(tile.horizontalTitleGap, 8);
    expect(
      find.descendant(of: album, matching: find.text('Proje Albümü')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: album,
        matching: find.text('Fotoğraf ve videoları kaynaklarıyla görüntüle.'),
      ),
      findsOneWidget,
    );
    semantics.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'large-text Dashboard uses safe action fallback without overflow',
    (tester) async {
      final semantics = tester.ensureSemantics();
      tester.view.physicalSize = const Size(320, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.binding.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(
        tester.binding.platformDispatcher.clearTextScaleFactorTestValue,
      );
      final fixture = _Fixture(
        projects: [_project('a', 'Çok Uzun Kuzey Projesi')],
      );
      addTearDown(fixture.dispose);

      await tester.pumpWidget(
        fixture.app(
          onReminder: (_, _) async => false,
          onAgenda: (_, _) async => false,
          brightness: Brightness.dark,
        ),
      );
      await tester.pumpAndSettle();

      final reminder = find.byKey(const Key('dashboard-quick-reminder'));
      final agenda = find.byKey(const Key('dashboard-quick-agenda'));
      final reminderRect = tester.getRect(reminder);
      final agendaRect = tester.getRect(agenda);
      expect(reminderRect.top, closeTo(agendaRect.top, 0.01));
      expect(reminderRect.right, lessThan(agendaRect.left));
      expect(reminderRect.height, inInclusiveRange(40, 42));
      expect(agendaRect.height, inInclusiveRange(40, 42));
      expect(find.bySemanticsLabel('Unutma ekle'), findsOneWidget);
      expect(find.bySemanticsLabel('Ajanda kaydı ekle'), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('Aktif proje Çok Uzun Kuzey Projesi')),
        findsOneWidget,
      );
      final createProject = find.byKey(const Key('dashboard-create-project'));
      expect(
        find.descendant(of: createProject, matching: find.text('Yeni proje')),
        findsOneWidget,
      );
      expect(createProject.hitTestable(), findsOneWidget);
      await tester.tap(createProject);
      await tester.pump();
      expect(find.byType(ListView), findsWidgets);
      semantics.dispose();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('core reads run Today then Plan then Materials without overlap', (
    tester,
  ) async {
    _useTallSurface(tester);
    final reads = _ControlledDashboardReads();
    final fixture = _Fixture(
      projects: [_project('a', 'Kuzey')],
      controlledReads: reads,
    );
    addTearDown(fixture.dispose);

    await tester.pumpWidget(fixture.app());
    await _pumpUntil(
      tester,
      () => reads.starts.length == 1,
      'Today read did not start.',
    );

    expect(reads.starts, ['today:a']);
    expect(reads.inFlight, 1);
    expect(reads.maxInFlight, 1);
    expect(find.byType(LinearProgressIndicator), findsNWidgets(3));

    reads.complete('today:a', _dailyLogDay('a', summaryText: 'A gün özeti'));
    await _pumpUntil(
      tester,
      () => reads.starts.length == 2,
      'Living Plan read did not follow Today.',
    );

    expect(reads.starts, ['today:a', 'plan:a']);
    expect(reads.inFlight, 1);
    expect(find.textContaining('A gün özeti'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNWidgets(2));

    reads.complete('plan:a', const <ConstructionLivingPlanWindowItem>[]);
    await _pumpUntil(
      tester,
      () => reads.starts.length == 3,
      'Materials read did not follow Living Plan.',
    );

    expect(reads.starts, ['today:a', 'plan:a', 'materials:a']);
    expect(reads.inFlight, 1);
    expect(find.text('Plan penceresinde kayıt yok.'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    reads.complete('materials:a', const <MaterialRequest>[]);
    await tester.pumpAndSettle();

    expect(reads.inFlight, 0);
    expect(reads.maxInFlight, 1);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.text('Açık malzeme ihtiyacı yok.'), findsOneWidget);
  });

  testWidgets(
    'post-create Dashboard shares the reload queue through failure and retry',
    (tester) async {
      _useTallSurface(tester);
      final coordinator = MobileOperationCoordinator();
      final reads = _ControlledDashboardReads();
      final fixture = _Fixture(
        projects: const [],
        controlledReads: reads,
        coordinator: coordinator,
      );
      addTearDown(fixture.dispose);
      await tester.pumpWidget(fixture.app());
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('dashboard-no-project')), findsOneWidget);

      // A projectChanges fan-out must wait for the current application read.
      final reloadGate = Completer<void>();
      final reload = coordinator.run(() => reloadGate.future);
      fixture.agenda.projects = [_project('a', 'Yeni proje')];
      fixture.agenda.emitProjectChange();
      await tester.pump();
      expect(reads.starts, isEmpty);
      reloadGate.complete();
      await reload;
      await _pumpUntil(
        tester,
        () => reads.starts.contains('today:a'),
        'First-project Today did not start after the reload.',
      );
      expect(fixture.session.selectedProjectId, 'a');

      // A different primary screen must not open SQLite while Today owns it.
      var reminderReadStarted = false;
      final reminderGate = Completer<void>();
      final reminderRead = coordinator.run(() async {
        reminderReadStarted = true;
        await reminderGate.future;
      });
      await tester.pump();
      expect(reminderReadStarted, isFalse);
      reads.complete('today:a', _dailyLogDay('a'));
      await _pumpUntil(
        tester,
        () => reminderReadStarted,
        'Queued reminder reload did not follow Today.',
      );
      expect(reads.starts, ['today:a']);
      reminderGate.complete();
      await reminderRead;
      await _pumpUntil(
        tester,
        () => reads.starts.contains('plan:a'),
        'Plan did not wait for the queued reminder reload.',
      );

      var agendaReadStarted = false;
      final agendaRead = coordinator.run(() async {
        agendaReadStarted = true;
      });
      await tester.pump();
      expect(agendaReadStarted, isFalse);
      reads.fail('plan:a', StateError('controlled_plan_failure'));
      await _pumpUntil(
        tester,
        () => reads.starts.contains('materials:a'),
        'Already-coordinated Materials must not deadlock on a nested queue.',
      );
      await agendaRead;
      expect(agendaReadStarted, isTrue);
      reads.complete('materials:a', const <MaterialRequest>[]);
      await tester.pumpAndSettle();
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byKey(const Key('dashboard-plan-retry')), findsOneWidget);
      expect(fixture.session.selectedProjectId, 'a');

      await tester.tap(find.byKey(const Key('dashboard-plan-retry')));
      await _pumpUntil(
        tester,
        () => reads.starts.where((value) => value == 'plan:a').length == 2,
        'Plan retry did not start.',
      );
      var afterRetryStarted = false;
      final afterRetry = coordinator.run(() async {
        afterRetryStarted = true;
      });
      await tester.pump();
      expect(afterRetryStarted, isFalse);
      reads.complete('plan:a', const <ConstructionLivingPlanWindowItem>[]);
      await tester.pumpAndSettle();
      await afterRetry;
      expect(afterRetryStarted, isTrue);
      expect(reads.starts, ['today:a', 'plan:a', 'materials:a', 'plan:a']);
      expect(reads.inFlight, 0);
      expect(reads.maxInFlight, 1);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Plan penceresinde kayıt yok.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('section failure settles and does not stop later reads', (
    tester,
  ) async {
    _useTallSurface(tester);
    final reads = _ControlledDashboardReads();
    final fixture = _Fixture(
      projects: [_project('a', 'Kuzey')],
      controlledReads: reads,
    );
    addTearDown(fixture.dispose);

    await tester.pumpWidget(fixture.app());
    await _pumpUntil(
      tester,
      () => reads.starts.length == 1,
      'Today read did not start.',
    );
    reads.fail('today:a', const DailyLogFailure('controlled_daily_failure'));
    await _pumpUntil(
      tester,
      () => reads.starts.length == 2,
      'Living Plan did not start after Today failure.',
    );

    expect(reads.starts, ['today:a', 'plan:a']);
    expect(find.byKey(const Key('dashboard-today-retry')), findsOneWidget);
    expect(reads.inFlight, 1);

    reads.complete('plan:a', const <ConstructionLivingPlanWindowItem>[]);
    await _pumpUntil(
      tester,
      () => reads.starts.length == 3,
      'Materials did not start after Living Plan.',
    );
    reads.complete('materials:a', const <MaterialRequest>[]);
    await tester.pumpAndSettle();

    expect(reads.starts, ['today:a', 'plan:a', 'materials:a']);
    expect(reads.inFlight, 0);
    expect(reads.maxInFlight, 1);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.byKey(const Key('dashboard-today-retry')), findsOneWidget);
    expect(find.text('Plan penceresinde kayıt yok.'), findsOneWidget);
    expect(find.text('Açık malzeme ihtiyacı yok.'), findsOneWidget);
  });

  testWidgets(
    'project switch rejects stale result and runs only the new pipeline',
    (tester) async {
      _useTallSurface(tester);
      final reads = _ControlledDashboardReads();
      final projects = [_project('a', 'Kuzey'), _project('b', 'Güney')];
      final fixture = _Fixture(projects: projects, controlledReads: reads);
      addTearDown(fixture.dispose);
      expect(fixture.session.select('a', projects), isTrue);

      await tester.pumpWidget(fixture.app());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const Key('dashboard-select-project')), findsNothing);
      expect(find.byKey(const Key('dashboard-change-project')), findsNothing);
      await _pumpUntil(
        tester,
        () => reads.starts.contains('today:a'),
        'Project A Today read did not start.',
      );

      expect(find.byKey(const Key('dashboard-change-project')), findsNothing);
      expect(fixture.session.select('b', projects), isTrue);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(fixture.session.selectedProjectId, 'b');
      expect(reads.starts, ['today:a']);
      expect(reads.inFlight, 1);
      expect(find.byType(LinearProgressIndicator), findsNWidgets(3));

      reads.complete(
        'today:a',
        _dailyLogDay('a', summaryText: 'ESKİ A SONUCU'),
      );
      await _pumpUntil(
        tester,
        () => reads.starts.contains('today:b'),
        'Project B Today read did not follow stale Project A.',
      );

      expect(reads.starts, ['today:a', 'today:b']);
      expect(find.textContaining('ESKİ A SONUCU'), findsNothing);
      expect(reads.inFlight, 1);

      reads.complete(
        'today:b',
        _dailyLogDay('b', summaryText: 'GÜNCEL B SONUCU'),
      );
      await _pumpUntil(
        tester,
        () => reads.starts.contains('plan:b'),
        'Project B Living Plan read did not start.',
      );
      reads.complete('plan:b', const <ConstructionLivingPlanWindowItem>[]);
      await _pumpUntil(
        tester,
        () => reads.starts.contains('materials:b'),
        'Project B Materials read did not start.',
      );
      reads.complete('materials:b', const <MaterialRequest>[]);
      await tester.pumpAndSettle();

      expect(reads.starts, ['today:a', 'today:b', 'plan:b', 'materials:b']);
      expect(reads.maxInFlight, 1);
      expect(fixture.session.selectedProjectId, 'b');
      expect(find.textContaining('ESKİ A SONUCU'), findsNothing);
      expect(find.textContaining('GÜNCEL B SONUCU'), findsOneWidget);
      expect(find.text('Güney'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    },
  );
}

class _Fixture {
  _Fixture({
    required List<MobileProject> projects,
    _ControlledDashboardReads? controlledReads,
    MobileOperationCoordinator? coordinator,
  }) : agenda = coordinator == null
           ? _AgendaFake(projects: projects)
           : _CoordinatedAgendaFake(
               projects: projects,
               coordinator: coordinator,
             ),
       daily = _DailyFake(controlledReads),
       plan = _PlanFake(controlledReads),
       materials = _MaterialFake(controlledReads, coordinator: coordinator);

  final _AgendaFake agenda;
  final _DailyFake daily;
  final _PlanFake plan;
  final _MaterialFake materials;
  final ActiveProjectSession session = ActiveProjectSession();

  Widget app({
    VoidCallback? onCreateProject,
    DashboardCaptureAction? onReminder,
    DashboardCaptureAction? onAgenda,
    DashboardProjectAction? onOpenToday,
    DashboardProjectAction? onOpenPlan,
    DashboardProjectAction? onOpenMaterials,
    DashboardProjectAction? onOpenConcrete,
    DashboardProjectAction? onOpenProjectAlbum,
    DashboardProjectAction? onOpenWorkforce,
    Brightness brightness = Brightness.light,
  }) => MaterialApp(
    locale: CseApp.locale,
    supportedLocales: CseApp.supportedLocales,
    localizationsDelegates: CseApp.localizationsDelegates,
    theme: ThemeData(brightness: brightness),
    home: Scaffold(
      body: ProjectDashboardPage(
        agenda: agenda,
        dailyLog: daily,
        livingPlan: plan,
        materialRequests: materials,
        session: session,
        onCreateProject: onCreateProject ?? () {},
        onAddReminder: onReminder,
        onAddAgenda: onAgenda,
        onOpenToday: onOpenToday,
        onOpenPlan: onOpenPlan,
        onOpenMaterials: onOpenMaterials,
        onOpenConcrete: onOpenConcrete,
        onOpenProjectAlbum: onOpenProjectAlbum,
        onOpenWorkforce: onOpenWorkforce,
        clock: () => DateTime.utc(2026, 8, 30, 9),
      ),
    ),
  );

  void dispose() {
    agenda.disposeDashboardFake();
    session.dispose();
  }
}

class _AgendaFake extends FakeAgendaApplication {
  _AgendaFake({required super.projects});

  final StreamController<void> _dashboardProjectChanges =
      StreamController<void>.broadcast();

  @override
  Stream<void> get projectChanges => _dashboardProjectChanges.stream;

  void emitProjectChange() => _dashboardProjectChanges.add(null);

  void disposeDashboardFake() => _dashboardProjectChanges.close();
}

class _CoordinatedAgendaFake extends _AgendaFake
    implements CoordinatedAgendaApplication {
  _CoordinatedAgendaFake({required super.projects, required this.coordinator});

  @override
  final MobileOperationCoordinator coordinator;

  @override
  Future<List<MobileProject>> listProjects() =>
      coordinator.run(() => super.listProjects());
}

class _DailyFake implements DailyLogApplicationPort {
  _DailyFake(this.controlledReads);

  final _ControlledDashboardReads? controlledReads;
  final List<(String, String)> calls = [];
  bool fail = false;

  @override
  Future<List<DailyLogProject>> listProjects() async => const [];

  @override
  Future<DailyLogDay> loadDay({
    required String projectId,
    required String localDay,
  }) async {
    calls.add((projectId, localDay));
    if (fail) throw const DailyLogFailure('synthetic_daily_failure');
    final controlled = controlledReads;
    if (controlled != null) {
      return controlled.wait<DailyLogDay>('today:$projectId');
    }
    return _dailyLogDay(projectId, localDay: localDay);
  }
}

class _PlanFake extends UnavailableConstructionLivingPlanApplication {
  _PlanFake(this.controlledReads);

  final _ControlledDashboardReads? controlledReads;
  final List<(String, DateTime)> calls = [];

  @override
  Future<List<ConstructionLivingPlanWindowItem>> loadSevenDayPlan({
    required String projectId,
    required DateTime windowStart,
  }) async {
    calls.add((projectId, windowStart));
    final controlled = controlledReads;
    if (controlled != null) {
      return controlled.wait<List<ConstructionLivingPlanWindowItem>>(
        'plan:$projectId',
      );
    }
    return const [];
  }
}

class _MaterialFake implements MaterialRequestApplicationPort {
  _MaterialFake(this.controlledReads, {this.coordinator});

  final MobileOperationCoordinator? coordinator;
  final _ControlledDashboardReads? controlledReads;
  final List<String> calls = [];

  @override
  Future<List<MaterialRequest>> listMaterialRequests({
    required String projectId,
    required MaterialRequestListKind kind,
  }) {
    final queue = coordinator;
    return queue == null
        ? _readRequests(projectId, kind)
        : queue.run(() => _readRequests(projectId, kind));
  }

  Future<List<MaterialRequest>> _readRequests(
    String projectId,
    MaterialRequestListKind kind,
  ) async {
    calls.add(projectId);
    expectSync(kind, MaterialRequestListKind.open);
    final controlled = controlledReads;
    if (controlled != null) {
      return controlled.wait<List<MaterialRequest>>('materials:$projectId');
    }
    return const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ControlledDashboardReads {
  final List<String> starts = [];
  final Map<String, Completer<Object?>> _pending = {};
  int inFlight = 0;
  int maxInFlight = 0;

  Future<T> wait<T>(String label) async {
    expectSync(
      _pending.containsKey(label),
      isFalse,
      reason: 'duplicate $label',
    );
    starts.add(label);
    inFlight += 1;
    if (inFlight > maxInFlight) maxInFlight = inFlight;
    final completer = Completer<Object?>();
    _pending[label] = completer;
    try {
      return (await completer.future) as T;
    } finally {
      inFlight -= 1;
    }
  }

  void complete(String label, Object? value) {
    final completer = _pending.remove(label);
    expect(completer, isNotNull, reason: '$label is not pending');
    completer!.complete(value);
  }

  void fail(String label, Object error) {
    final completer = _pending.remove(label);
    expect(completer, isNotNull, reason: '$label is not pending');
    completer!.completeError(error);
  }
}

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() condition,
  String failureMessage,
) async {
  for (var attempt = 0; attempt < 20; attempt += 1) {
    await tester.pump();
    if (condition()) return;
  }
  fail(failureMessage);
}

void _useTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

DailyLogDay _dailyLogDay(
  String projectId, {
  String localDay = '2026-08-30',
  String summaryText = '1 kaynak kaydı',
}) => DailyLogDay(
  projectId: projectId,
  projectName: projectId == 'b' ? 'Güney' : 'Kuzey',
  localDay: localDay,
  sections: [
    DailyLogSection.summary(text: summaryText),
    DailyLogSection.unavailable(
      kind: DailyLogSectionKind.attendance,
      failure: const DailyLogSectionFailure(
        code: 'attendance_unavailable',
        message: 'Puantaj okunamadı.',
      ),
    ),
    DailyLogSection.available(
      kind: DailyLogSectionKind.livingPlan,
      entries: const [],
    ),
    DailyLogSection.available(
      kind: DailyLogSectionKind.concrete,
      entries: const [],
    ),
    DailyLogSection.available(
      kind: DailyLogSectionKind.agenda,
      entries: [
        DailyLogEntry(
          id: 'agenda-1',
          text: 'Saha turu',
          sourceRefs: [
            DailyLogSourceRef(
              kind: DailyLogSourceKind.agendaLog,
              sourceId: 'agenda-1',
            ),
          ],
        ),
      ],
    ),
    DailyLogSection.available(
      kind: DailyLogSectionKind.openFollowUps,
      entries: const [],
    ),
  ],
);

MobileProject _project(String id, String name) => MobileProject(
  id: id,
  name: name,
  createdAt: '2026-08-30T06:00:00Z',
  updatedAt: '2026-08-30T06:00:00Z',
  revision: 1,
);
