import 'dart:async';
import 'dart:ui' show SemanticsAction;

import 'package:chief_site_engineer/app.dart';
import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/application/onboarding_preference.dart';
import 'package:chief_site_engineer/bootstrap/app_bootstrap.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/features/dashboard/project_dashboard_page.dart';
import 'package:chief_site_engineer/features/onboarding/guided_onboarding_page.dart';
import 'package:chief_site_engineer/features/projects/project_create_page.dart';
import 'package:chief_site_engineer/features/reminders/reminder_detail_page.dart';
import 'package:chief_site_engineer/platform/notification_gateway.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_agenda_application.dart';

void main() {
  testWidgets(
    'bootstrap and Dashboard failures stay visible until safe retry',
    (tester) async {
      final bootstrap = Completer<BootstrapResult>();
      final preference = _MemoryPreference();
      await tester.pumpWidget(
        CseApp(bootstrap: bootstrap.future, onboardingPreference: preference),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(GuidedOnboardingPage), findsNothing);
      expect(preference.reads, 0);

      bootstrap.complete(const BootstrapFailure());
      await tester.pumpAndSettle();
      expect(find.byType(BootstrapFailureScreen), findsOneWidget);
      expect(find.byType(GuidedOnboardingPage), findsNothing);

      await tester.pumpWidget(
        CseApp(
          bootstrap: Future.value(
            const BootstrapFailure(code: 'restore_recovery_failed'),
          ),
          onboardingPreference: preference,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Veriler silinmedi'), findsOneWidget);
      expect(find.byType(GuidedOnboardingPage), findsNothing);
      expect(preference.reads, 0);

      final agenda = _OnboardingAgenda()..failProjectReads = true;
      addTearDown(agenda.dispose);
      await _pumpShell(tester, agenda, preference);
      expect(find.byKey(const Key('dashboard-project-error')), findsOneWidget);
      expect(find.byType(GuidedOnboardingPage), findsNothing);
      expect(preference.reads, 0);

      agenda.failProjectReads = false;
      await tester.tap(find.text('Tekrar dene'));
      await tester.pumpAndSettle();
      expect(find.byType(GuidedOnboardingPage), findsOneWidget);
      expect(preference.reads, 1);
    },
  );

  testWidgets('no-project flow reuses create cancel and successful return', (
    tester,
  ) async {
    final agenda = _OnboardingAgenda();
    final preference = _MemoryPreference();
    addTearDown(agenda.dispose);
    await _pumpShell(tester, agenda, preference);

    expect(find.text('CSE nedir?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('guided-onboarding-primary')));
    await tester.pump();
    expect(find.text('İlk proje'), findsOneWidget);
    expect(find.text('Proje oluştur'), findsOneWidget);

    await tester.tap(find.byKey(const Key('guided-onboarding-primary')));
    await tester.pumpAndSettle();
    expect(find.byType(ProjectCreatePage), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(ProjectCreatePage), findsNothing);
    expect(find.text('İlk proje'), findsOneWidget);
    expect(agenda.createProjectCalls, 0);

    await tester.tap(find.byKey(const Key('guided-onboarding-primary')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('project-name')),
      'İlk Saha Projesi',
    );
    await tester.tap(find.byKey(const Key('save-project')));
    await tester.pumpAndSettle();

    expect(agenda.createProjectCalls, 1);
    expect(find.text('Ana günlük akış'), findsOneWidget);
    expect(find.textContaining('Ana Sayfa'), findsOneWidget);
    await tester.tap(find.byKey(const Key('guided-onboarding-primary')));
    await tester.pumpAndSettle();
    expect(find.byType(GuidedOnboardingPage), findsNothing);
    expect(preference.writes, const [guidedOnboardingVersion]);
    expect(find.text('İlk Saha Projesi'), findsWidgets);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    await _pumpShell(tester, agenda, preference);
    expect(find.byType(GuidedOnboardingPage), findsNothing);
  });

  testWidgets('existing project advances without creating a duplicate', (
    tester,
  ) async {
    final agenda = _OnboardingAgenda(projects: const [_projectA]);
    final preference = _MemoryPreference();
    addTearDown(agenda.dispose);
    await _pumpShell(tester, agenda, preference);

    await tester.tap(find.byKey(const Key('guided-onboarding-primary')));
    await tester.pump();
    expect(find.textContaining('Aktif projeniz hazır'), findsOneWidget);
    expect(find.text('Proje oluştur'), findsNothing);
    await tester.tap(find.byKey(const Key('guided-onboarding-primary')));
    await tester.pump();
    expect(find.text('Ana günlük akış'), findsOneWidget);
    expect(find.byType(ProjectCreatePage), findsNothing);
    expect(agenda.createProjectCalls, 0);
  });

  testWidgets('multiple-project selection surface is never covered', (
    tester,
  ) async {
    final agenda = _OnboardingAgenda(projects: const [_projectA, _projectB]);
    final preference = _MemoryPreference();
    addTearDown(agenda.dispose);
    await _pumpShell(tester, agenda, preference);

    expect(
      find.byKey(const Key('dashboard-project-selection-required')),
      findsOneWidget,
    );
    expect(find.byType(GuidedOnboardingPage), findsNothing);
    expect(preference.reads, 0);

    final dashboard = tester.widget<ProjectDashboardPage>(
      find.byType(ProjectDashboardPage),
    );
    expect(dashboard.session.select(_projectA.id, agenda.projects), isTrue);
    await tester.pumpAndSettle();
    expect(find.byType(GuidedOnboardingPage), findsOneWidget);
    expect(preference.reads, 1);
  });

  testWidgets('Back and interruption write nothing and restart at step one', (
    tester,
  ) async {
    final agenda = _OnboardingAgenda();
    final preference = _MemoryPreference();
    addTearDown(agenda.dispose);
    await _pumpShell(tester, agenda, preference);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(GuidedOnboardingPage), findsNothing);
    expect(preference.writes, isEmpty);
    agenda.emitProjectChange();
    await tester.pumpAndSettle();
    expect(find.byType(GuidedOnboardingPage), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    await _pumpShell(tester, agenda, preference);
    expect(find.text('CSE nedir?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('guided-onboarding-primary')));
    await tester.pump();
    expect(find.text('İlk proje'), findsOneWidget);

    tester.view.physicalSize = const Size(600, 320);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pump();
    expect(find.text('İlk proje'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(preference.writes, isEmpty);
    await _pumpShell(tester, agenda, preference);
    expect(find.text('CSE nedir?'), findsOneWidget);
  });

  testWidgets('Skip persists while preference failures remain fail-open', (
    tester,
  ) async {
    final agenda = _OnboardingAgenda();
    final preference = _MemoryPreference();
    addTearDown(agenda.dispose);
    await _pumpShell(tester, agenda, preference);
    await tester.tap(find.byKey(const Key('guided-onboarding-skip')));
    await tester.pumpAndSettle();
    expect(preference.writes, const [guidedOnboardingVersion]);
    expect(find.byType(GuidedOnboardingPage), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    await _pumpShell(tester, agenda, preference);
    expect(find.byType(GuidedOnboardingPage), findsNothing);

    final writeFailure = _MemoryPreference(throwOnWrite: true);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    await _pumpShell(tester, agenda, writeFailure);
    await tester.tap(find.byKey(const Key('guided-onboarding-skip')));
    await tester.pumpAndSettle();
    expect(find.byType(GuidedOnboardingPage), findsNothing);
    expect(writeFailure.writeCalls, 1);

    final readFailure = _MemoryPreference(throwOnRead: true);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    await _pumpShell(tester, agenda, readFailure);
    expect(find.byType(GuidedOnboardingPage), findsNothing);
    expect(find.byKey(const Key('dashboard-no-project')), findsOneWidget);
    expect(readFailure.reads, 1);
  });

  for (final source in ['current intent', 'legacy intent']) {
    testWidgets('$source has whole-launch priority over onboarding', (
      tester,
    ) async {
      final preference = _MemoryPreference();
      final agenda = source == 'current intent'
          ? _IntentOnboardingAgenda(
              projects: const [_projectA],
              reminders: const [_reminder],
              initial: const ReminderNotificationIntent(
                reminderId: _reminderId,
              ),
            )
          : _OnboardingAgenda(
              projects: const [_projectA],
              reminders: const [_reminder],
              initialNotificationReminderId: _reminderId,
            );
      addTearDown(agenda.dispose);
      await _pumpShell(tester, agenda, preference);

      expect(find.byType(ReminderDetailPage), findsOneWidget);
      expect(find.byType(GuidedOnboardingPage), findsNothing);
      Navigator.of(tester.element(find.byType(ReminderDetailPage))).pop();
      await tester.pumpAndSettle();
      expect(find.byType(GuidedOnboardingPage), findsNothing);
      expect(preference.reads, 0);
    });
  }

  testWidgets('semantic actions activate primary, Back chain, and Skip', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final agenda = _OnboardingAgenda(projects: const [_projectA]);
    final preference = _MemoryPreference();
    addTearDown(agenda.dispose);
    await _pumpShell(tester, agenda, preference);

    void performTap(String label) {
      final widgetTarget = find.bySemanticsLabel(label);
      expect(widgetTarget, findsOneWidget);
      expect(
        tester
            .getSemantics(widgetTarget)
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
      );
      final semanticsTarget = find.semantics.byLabel(label);
      expect(semanticsTarget, findsOneWidget);
      tester.semantics.performAction(semanticsTarget, SemanticsAction.tap);
    }

    performTap('Devam');
    await tester.pump();
    expect(find.text('İlk proje'), findsOneWidget);

    performTap('Devam');
    await tester.pump();
    expect(find.text('Ana günlük akış'), findsOneWidget);

    performTap('Önceki adıma dön');
    await tester.pump();
    expect(find.text('İlk proje'), findsOneWidget);

    performTap('Önceki adıma dön');
    await tester.pump();
    expect(find.text('CSE nedir?'), findsOneWidget);

    performTap('Tanıtımı atla');
    await tester.pumpAndSettle();
    expect(find.byType(GuidedOnboardingPage), findsNothing);
    expect(preference.writes, const [guidedOnboardingVersion]);
    semantics.dispose();
  });

  for (final width in [320.0, 390.0, 600.0, 840.0]) {
    for (final scale in [1.0, 1.6]) {
      testWidgets('adaptive accessible flow at $width and text $scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final semantics = tester.ensureSemantics();
        var handled = 0;
        var created = 0;

        Widget subject() => MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(width, 700),
              textScaler: TextScaler.linear(scale),
            ),
            child: GuidedOnboardingPage(
              hasExistingProject: false,
              onCreateProject: () async {
                created += 1;
                return true;
              },
              onHandled: () async => handled += 1,
            ),
          ),
        );

        await tester.pumpWidget(subject());
        await tester.pumpAndSettle();
        await _expectAccessibleControls(
          tester,
          width,
          backLabel: 'Tanıtımdan çık',
          primaryLabel: 'Devam',
        );
        expect(find.bySemanticsLabel('Tanıtımı atla'), findsOneWidget);
        expect(tester.takeException(), isNull);

        final primary = find.byKey(const Key('guided-onboarding-primary'));
        await tester.ensureVisible(primary);
        await tester.pumpAndSettle();
        await tester.tap(primary);
        await tester.pump();
        await _expectAccessibleControls(
          tester,
          width,
          backLabel: 'Önceki adıma dön',
          primaryLabel: 'Proje oluştur',
        );
        expect(find.text('Proje oluştur'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.ensureVisible(primary);
        await tester.pumpAndSettle();
        await tester.tap(primary);
        await tester.pumpAndSettle();
        expect(created, 1);
        expect(find.text('Ana günlük akış'), findsOneWidget);
        await _expectAccessibleControls(
          tester,
          width,
          backLabel: 'Önceki adıma dön',
          primaryLabel: 'Bitir',
        );
        expect(tester.takeException(), isNull);

        final focusOrders = tester
            .widgetList<FocusTraversalOrder>(find.byType(FocusTraversalOrder))
            .map((widget) => (widget.order as NumericFocusOrder).order)
            .toList();
        expect(focusOrders, const [1, 2, 3]);
        expect(handled, 0);
        semantics.dispose();
      });
    }
  }

  testWidgets('onboarding makes no permission-channel call', (tester) async {
    const channel = MethodChannel('flutter.baseflow.com/permissions/methods');
    var permissionCalls = 0;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      _,
    ) async {
      permissionCalls += 1;
      return 0;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    final agenda = _OnboardingAgenda();
    addTearDown(agenda.dispose);
    await _pumpShell(tester, agenda, _MemoryPreference());
    await tester.tap(find.byKey(const Key('guided-onboarding-primary')));
    await tester.pump();
    expect(permissionCalls, 0);
  });
}

Future<void> _pumpShell(
  WidgetTester tester,
  AgendaApplication agenda,
  OnboardingPreference preference,
) async {
  await tester.pumpWidget(
    CseApp(
      bootstrap: Future<BootstrapResult>.value(
        BootstrapSuccess(
          environmentLabel: 'Test',
          smokeRecordId: 'onboarding-test',
          smokeRecordCreatedAt: '2026-09-13T08:00:00Z',
          agenda: agenda,
        ),
      ),
      onboardingPreference: preference,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _expectAccessibleControls(
  WidgetTester tester,
  double width, {
  required String backLabel,
  required String primaryLabel,
}) async {
  for (final key in const [
    Key('guided-onboarding-skip'),
    Key('guided-onboarding-back'),
    Key('guided-onboarding-primary'),
  ]) {
    final finder = find.byKey(key);
    expect(finder, findsOneWidget);
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    final size = tester.getSize(finder);
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
    final rect = tester.getRect(finder);
    expect(rect.left, greaterThanOrEqualTo(0));
    expect(rect.right, lessThanOrEqualTo(width));
  }
  for (final label in ['Tanıtımı atla', backLabel, primaryLabel]) {
    final finder = find.bySemanticsLabel(label);
    expect(finder, findsOneWidget);
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    final node = tester.getSemantics(finder);
    final data = node.getSemanticsData();
    expect(data.flagsCollection.isButton, isTrue);
    expect(data.hasAction(SemanticsAction.tap), isTrue);
    expect(
      node.rect.width,
      greaterThanOrEqualTo(48),
      reason: '$label semantic width',
    );
    expect(
      node.rect.height,
      greaterThanOrEqualTo(48),
      reason: '$label semantic height',
    );
  }
  expect(find.byKey(const Key('guided-onboarding-scroll')), findsOneWidget);
}

class _MemoryPreference implements OnboardingPreference {
  _MemoryPreference({
    this.handledVersion,
    this.throwOnRead = false,
    this.throwOnWrite = false,
  });

  int? handledVersion;
  final bool throwOnRead;
  final bool throwOnWrite;
  int reads = 0;
  int writeCalls = 0;
  final writes = <int>[];

  @override
  Future<int?> readHandledVersion() async {
    reads += 1;
    if (throwOnRead) throw StateError('synthetic preference read failure');
    return handledVersion;
  }

  @override
  Future<void> writeHandledVersion(int version) async {
    writeCalls += 1;
    if (throwOnWrite) throw StateError('synthetic preference write failure');
    writes.add(version);
    handledVersion = version;
  }
}

class _OnboardingAgenda extends FakeAgendaApplication {
  _OnboardingAgenda({
    super.projects = const [],
    super.reminders = const [],
    super.initialNotificationReminderId,
  });

  final _changes = StreamController<void>.broadcast();
  bool failProjectReads = false;
  int createProjectCalls = 0;

  @override
  Stream<void> get projectChanges => _changes.stream;

  @override
  Future<List<MobileProject>> listProjects() async {
    if (failProjectReads) throw StateError('synthetic project read failure');
    return List<MobileProject>.unmodifiable(projects);
  }

  @override
  Future<MobileProject> createProject(CreateProjectCommand command) async {
    createProjectCalls += 1;
    final project = await super.createProject(command);
    _changes.add(null);
    return project;
  }

  void emitProjectChange() => _changes.add(null);

  void dispose() => _changes.close();
}

class _IntentOnboardingAgenda extends _OnboardingAgenda
    implements ReminderNotificationIntentSource {
  _IntentOnboardingAgenda({
    required ReminderNotificationIntent initial,
    super.projects,
    super.reminders,
  }) : _initial = initial;

  ReminderNotificationIntent? _initial;

  @override
  Stream<ReminderNotificationIntent> get notificationIntents =>
      const Stream<ReminderNotificationIntent>.empty();

  @override
  ReminderNotificationIntent? takeInitialNotificationIntent() {
    final result = _initial;
    _initial = null;
    return result;
  }
}

const _projectA = MobileProject(
  id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  name: 'Birinci Proje',
  createdAt: '2026-09-13T07:00:00Z',
  updatedAt: '2026-09-13T07:00:00Z',
  revision: 1,
);

const _projectB = MobileProject(
  id: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
  name: 'İkinci Proje',
  createdAt: '2026-09-13T07:00:00Z',
  updatedAt: '2026-09-13T07:00:00Z',
  revision: 1,
);

const _reminderId = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd';
const _reminder = MobileReminder(
  id: _reminderId,
  projectId: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  projectName: 'Birinci Proje',
  sourceLogId: null,
  title: 'İlk bildirim',
  kind: ReminderKind.action,
  status: ReminderStatus.active,
  nextAttentionAt: '2026-09-13T09:00:00Z',
  createdAt: '2026-09-13T07:00:00Z',
  updatedAt: '2026-09-13T07:00:00Z',
  revision: 1,
);
