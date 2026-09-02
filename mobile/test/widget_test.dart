import 'dart:async';

import 'package:chief_site_engineer/app.dart';
import 'package:chief_site_engineer/bootstrap/app_bootstrap.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/features/agenda/agenda_page.dart';
import 'package:chief_site_engineer/features/attendance/attendance_page.dart';
import 'package:chief_site_engineer/features/dashboard/project_dashboard_page.dart';
import 'package:chief_site_engineer/features/inventory/inventory_page.dart';
import 'package:chief_site_engineer/features/projects/project_create_page.dart';
import 'package:chief_site_engineer/features/reminders/reminders_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'support/fake_agenda_application.dart';
import 'support/fake_attendance_application.dart';

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
      final semantics = tester.ensureSemantics();
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
      final navigationFinder = find.byType(NavigationBar);
      final navigation = tester.widget<NavigationBar>(navigationFinder);
      expect(navigation.destinations, hasLength(6));
      expect(
        navigation.labelBehavior,
        NavigationDestinationLabelBehavior.alwaysHide,
      );
      expect(
        navigation.destinations
            .cast<NavigationDestination>()
            .map((destination) => destination.label)
            .toList(),
        expectedLabels,
      );
      for (final label in expectedLabels) {
        final labelText = find.descendant(
          of: navigationFinder,
          matching: find.text(label),
        );
        expect(labelText, findsOneWidget);
        final labelFades = tester.widgetList<FadeTransition>(
          find.ancestor(of: labelText, matching: find.byType(FadeTransition)),
        );
        expect(
          labelFades.any((fade) => fade.opacity.value == 0),
          isTrue,
          reason: '$label NavigationBar label must be visually hidden.',
        );
        expect(
          find.descendant(
            of: navigationFinder,
            matching: find.bySemanticsLabel(RegExp('^${RegExp.escape(label)}')),
          ),
          findsOneWidget,
        );
      }

      await tester.tap(
        find.descendant(
          of: navigationFinder,
          matching: find.byIcon(Icons.inventory_2_outlined),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('inventory-project-required')),
        findsOneWidget,
      );

      await tester.tap(
        find.descendant(
          of: navigationFinder,
          matching: find.byIcon(Icons.more_horiz_rounded),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('more-page')), findsOneWidget);
      expect(find.byKey(const Key('more-concrete-package')), findsOneWidget);
      expect(find.byKey(const Key('more-workforce-directory')), findsOneWidget);
      expect(find.text('Beton Paketi'), findsOneWidget);
      expect(find.text('Sicil'), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: navigationFinder,
          matching: find.byIcon(Icons.event_note_outlined),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Bu günde Ajanda kaydı yok.'), findsOneWidget);
      expect(find.byKey(const Key('create-agenda-log')), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets(
    'mobile shell lazily mounts primary tabs once and preserves visited state',
    (tester) async {
      final projectGate = Completer<void>();
      final agenda = FakeAgendaApplication()..listProjectsGate = projectGate;
      final attendance = FakeAttendanceApplication();

      await tester.pumpWidget(
        CseApp(
          bootstrap: Future<BootstrapResult>.value(
            BootstrapSuccess(
              environmentLabel: 'Geliştirme',
              smokeRecordId: 'lazy-primary-tabs',
              smokeRecordCreatedAt: '2026-09-01T08:00:00Z',
              agenda: agenda,
              attendance: attendance,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(ProjectDashboardPage), findsOneWidget);
      expect(find.byType(RemindersPage, skipOffstage: false), findsNothing);
      expect(find.byType(AgendaPage, skipOffstage: false), findsNothing);
      expect(find.byType(InventoryPage, skipOffstage: false), findsNothing);
      expect(find.byType(AttendancePage, skipOffstage: false), findsNothing);
      expect(agenda.listProjectsCalls, 2);
      expect(agenda.todayOverviewCalls, 0);
      expect(agenda.listAgendaCalls, 0);
      expect(agenda.getAgendaLogDetailCalls, 0);

      projectGate.complete();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('dashboard-no-project')), findsOneWidget);

      final navigation = find.byType(NavigationBar);
      Future<void> openTab(IconData icon) async {
        await tester.tap(
          find.descendant(of: navigation, matching: find.byIcon(icon)),
        );
        await tester.pumpAndSettle();
      }

      await openTab(Icons.notifications_none_rounded);
      expect(agenda.todayOverviewCalls, 1);
      expect(find.text('Bugün için açık hatırlatıcı yok.'), findsOneWidget);
      final reminderState = tester.state(
        find.byType(RemindersPage, skipOffstage: false),
      );

      await openTab(Icons.event_note_outlined);
      expect(agenda.listProjectsCalls, 3);
      expect(agenda.listAgendaCalls, 1);
      expect(find.text('Bu günde Ajanda kaydı yok.'), findsOneWidget);
      final agendaState = tester.state(
        find.byType(AgendaPage, skipOffstage: false),
      );

      await openTab(Icons.inventory_2_outlined);
      expect(agenda.listProjectsCalls, 4);
      expect(
        find.byKey(const Key('inventory-project-required')),
        findsOneWidget,
      );

      await openTab(Icons.badge_outlined);
      expect(agenda.listProjectsCalls, 5);
      expect(
        find.text('Puantaj için önce Ajanda bölümünden bir proje oluşturun.'),
        findsOneWidget,
      );

      await openTab(Icons.more_horiz_rounded);
      final projectReadsAfterFirstVisits = agenda.listProjectsCalls;
      await openTab(Icons.notifications_none_rounded);
      expect(
        tester.state(find.byType(RemindersPage, skipOffstage: false)),
        same(reminderState),
      );
      expect(agenda.todayOverviewCalls, 1);
      expect(agenda.listProjectsCalls, projectReadsAfterFirstVisits);

      await openTab(Icons.event_note_outlined);
      expect(
        tester.state(find.byType(AgendaPage, skipOffstage: false)),
        same(agendaState),
      );
      expect(agenda.listAgendaCalls, 1);
      expect(agenda.getAgendaLogDetailCalls, 0);
      expect(agenda.listProjectsCalls, projectReadsAfterFirstVisits);
    },
  );

  testWidgets('Dashboard quick actions open exact existing capture routes', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
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

    final reminderAction = find.byKey(const Key('dashboard-quick-reminder'));
    final agendaAction = find.byKey(const Key('dashboard-quick-agenda'));
    expect(tester.widget<IconButton>(reminderAction).tooltip, 'Unutma ekle');
    expect(
      tester.widget<IconButton>(agendaAction).tooltip,
      'Ajanda kaydı ekle',
    );
    expect(
      find.descendant(
        of: reminderAction,
        matching: find.byIcon(Icons.add_alert_outlined),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: agendaAction,
        matching: find.byIcon(Icons.note_add_outlined),
      ),
      findsOneWidget,
    );
    expect(find.text('+ Unutma'), findsNothing);
    expect(find.text('+ Ajanda kaydı'), findsNothing);
    expect(find.bySemanticsLabel('Unutma ekle'), findsOneWidget);
    expect(find.bySemanticsLabel('Ajanda kaydı ekle'), findsOneWidget);

    await tester.tap(reminderAction);
    await tester.pumpAndSettle();
    final reminderProject = tester.widget<DropdownButtonFormField<String?>>(
      find.byKey(const Key('reminder-project')),
    );
    expect(reminderProject.initialValue, project.id);
    expect(find.byType(BackButton), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await tester.tap(agendaAction);
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
    semantics.dispose();
  });

  testWidgets(
    'zero-project Dashboard creates directly without mounting Agenda',
    (tester) async {
      final agenda = _ShellProjectAgenda();
      await tester.pumpWidget(
        CseApp(
          bootstrap: Future<BootstrapResult>.value(
            BootstrapSuccess(
              environmentLabel: 'Geliştirme',
              smokeRecordId: 'dashboard-create-first-project',
              smokeRecordCreatedAt: '2026-09-01T08:00:00Z',
              agenda: agenda,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final create = find.byKey(const Key('dashboard-create-project'));
      expect(find.text('Yeni proje oluştur'), findsOneWidget);
      await tester.tap(create);
      await tester.pumpAndSettle();

      expect(find.byType(ProjectCreatePage), findsOneWidget);
      expect(find.byType(AgendaPage, skipOffstage: false), findsNothing);
      expect(agenda.listAgendaCalls, 0);
      await tester.enterText(
        find.byKey(const Key('project-name')),
        '  İlk Saha Projesi  ',
      );
      await tester.tap(find.byKey(const Key('save-project')));
      await tester.pumpAndSettle();

      expect(agenda.createProjectCalls, 1);
      expect(agenda.lastProjectCommand?.name, 'İlk Saha Projesi');
      expect(find.byType(ProjectCreatePage), findsNothing);
      expect(find.byType(AgendaPage, skipOffstage: false), findsNothing);
      expect(agenda.listAgendaCalls, 0);
      expect(find.text('İlk Saha Projesi'), findsWidgets);
      final dashboard = tester.widget<ProjectDashboardPage>(
        find.byType(ProjectDashboardPage),
      );
      expect(
        dashboard.session.selectedProjectId,
        agenda.lastProjectCommand?.id,
      );
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        0,
      );
    },
  );

  testWidgets(
    'unselected multiple-project Dashboard opens create and returns unchanged',
    (tester) async {
      const first = MobileProject(
        id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        name: 'Birinci Proje',
        createdAt: '2026-09-01T07:00:00Z',
        updatedAt: '2026-09-01T07:00:00Z',
        revision: 1,
      );
      const second = MobileProject(
        id: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
        name: 'İkinci Proje',
        createdAt: '2026-09-01T07:30:00Z',
        updatedAt: '2026-09-01T07:30:00Z',
        revision: 1,
      );
      final agenda = _ShellProjectAgenda(projects: const [first, second]);
      await tester.pumpWidget(
        CseApp(
          bootstrap: Future<BootstrapResult>.value(
            BootstrapSuccess(
              environmentLabel: 'Geliştirme',
              smokeRecordId: 'dashboard-create-without-selection',
              smokeRecordCreatedAt: '2026-09-01T08:00:00Z',
              agenda: agenda,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('dashboard-project-selection-required')),
        findsOneWidget,
      );
      var dashboard = tester.widget<ProjectDashboardPage>(
        find.byType(ProjectDashboardPage),
      );
      expect(dashboard.session.selectedProjectId, isNull);
      final create = find.byKey(const Key('dashboard-create-project'));
      expect(create, findsOneWidget);

      await tester.tap(create);
      await tester.pumpAndSettle();

      expect(find.byType(ProjectCreatePage), findsOneWidget);
      expect(find.byType(AgendaPage, skipOffstage: false), findsNothing);
      expect(agenda.listAgendaCalls, 0);
      expect(agenda.createProjectCalls, 0);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.byType(ProjectCreatePage), findsNothing);
      expect(
        find.byKey(const Key('dashboard-project-selection-required')),
        findsOneWidget,
      );
      dashboard = tester.widget<ProjectDashboardPage>(
        find.byType(ProjectDashboardPage),
      );
      expect(agenda.createProjectCalls, 0);
      expect(dashboard.session.selectedProjectId, isNull);
      expect(find.byType(AgendaPage, skipOffstage: false), findsNothing);
      expect(agenda.listAgendaCalls, 0);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        0,
      );
      expect(find.byKey(const Key('dashboard-create-project')), findsOneWidget);
    },
  );

  testWidgets(
    'existing-project create cancels safely then makes second project active',
    (tester) async {
      const first = MobileProject(
        id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        name: 'Birinci Proje',
        createdAt: '2026-09-01T07:00:00Z',
        updatedAt: '2026-09-01T07:00:00Z',
        revision: 1,
      );
      final agenda = _ShellProjectAgenda(projects: const [first]);
      await tester.pumpWidget(
        CseApp(
          bootstrap: Future<BootstrapResult>.value(
            BootstrapSuccess(
              environmentLabel: 'Geliştirme',
              smokeRecordId: 'dashboard-create-second-project',
              smokeRecordCreatedAt: '2026-09-01T08:00:00Z',
              agenda: agenda,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      var dashboard = tester.widget<ProjectDashboardPage>(
        find.byType(ProjectDashboardPage),
      );
      expect(dashboard.session.selectedProjectId, first.id);
      expect(find.text('Yeni proje'), findsOneWidget);

      await tester.tap(find.byKey(const Key('dashboard-create-project')));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      dashboard = tester.widget<ProjectDashboardPage>(
        find.byType(ProjectDashboardPage),
      );
      expect(agenda.createProjectCalls, 0);
      expect(dashboard.session.selectedProjectId, first.id);
      expect(agenda.projects, const [first]);

      await tester.tap(find.byKey(const Key('dashboard-create-project')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('project-name')),
        'İkinci Proje',
      );
      await tester.tap(find.byKey(const Key('save-project')));
      await tester.pumpAndSettle();

      dashboard = tester.widget<ProjectDashboardPage>(
        find.byType(ProjectDashboardPage),
      );
      expect(agenda.createProjectCalls, 1);
      expect(agenda.projects, hasLength(2));
      expect(agenda.projects.first, same(first));
      expect(agenda.projects.first.isArchived, isFalse);
      expect(
        dashboard.session.selectedProjectId,
        agenda.lastProjectCommand?.id,
      );
      expect(find.text('İkinci Proje'), findsWidgets);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        0,
      );
    },
  );

  testWidgets('failed shell create preserves selection and retry succeeds', (
    tester,
  ) async {
    const first = MobileProject(
      id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      name: 'Korunan Proje',
      createdAt: '2026-09-01T07:00:00Z',
      updatedAt: '2026-09-01T07:00:00Z',
      revision: 1,
    );
    final agenda = _ShellProjectAgenda(projects: const [first])
      ..projectCreateFailure = StateError('synthetic storage failure');
    await tester.pumpWidget(
      CseApp(
        bootstrap: Future<BootstrapResult>.value(
          BootstrapSuccess(
            environmentLabel: 'Geliştirme',
            smokeRecordId: 'dashboard-create-retry',
            smokeRecordCreatedAt: '2026-09-01T08:00:00Z',
            agenda: agenda,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('dashboard-create-project')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('project-name')),
      'Retry Projesi',
    );
    final save = find.byKey(const Key('save-project'));
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(agenda.createProjectCalls, 1);
    expect(find.byType(ProjectCreatePage), findsOneWidget);
    expect(find.text('Proje oluşturulamadı.'), findsOneWidget);
    var dashboard = tester.widget<ProjectDashboardPage>(
      find.byType(ProjectDashboardPage, skipOffstage: false),
    );
    expect(dashboard.session.selectedProjectId, first.id);
    expect(agenda.projects, const [first]);

    agenda.projectCreateFailure = null;
    await tester.tap(save);
    await tester.pumpAndSettle();
    dashboard = tester.widget<ProjectDashboardPage>(
      find.byType(ProjectDashboardPage),
    );
    expect(agenda.createProjectCalls, 2);
    expect(agenda.projects, hasLength(2));
    expect(dashboard.session.selectedProjectId, agenda.lastProjectCommand?.id);
    expect(find.text('Retry Projesi'), findsWidgets);
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

class _ShellProjectAgenda extends FakeAgendaApplication {
  _ShellProjectAgenda({List<MobileProject> projects = const []})
    : super(projects: projects);

  int createProjectCalls = 0;
  CreateProjectCommand? lastProjectCommand;
  Object? projectCreateFailure;

  @override
  Future<MobileProject> createProject(CreateProjectCommand command) async {
    createProjectCalls += 1;
    lastProjectCommand = command;
    if (projectCreateFailure case final failure?) throw failure;
    return super.createProject(command);
  }
}
