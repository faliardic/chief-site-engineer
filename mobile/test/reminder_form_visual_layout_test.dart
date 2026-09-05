import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/features/reminders/reminder_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/fake_agenda_application.dart';

const _project = MobileProject(
  id: 'project-a',
  name: 'Kuzey Şantiyesi',
  createdAt: '2026-09-01T08:00:00Z',
  updatedAt: '2026-09-01T08:00:00Z',
  revision: 1,
);
Finder _key(String key) => find.byKey(Key(key));
Future<void> _show(WidgetTester tester, String key) async {
  await tester.ensureVisible(_key(key));
  await tester.pumpAndSettle();
}

void main() {
  for (final config in [
    (const Size(320, 760), 1.0, 0.0),
    (const Size(390, 844), 1.0, 0.0),
    (const Size(320, 760), 2.0, 0.0),
    (const Size(390, 844), 2.0, 0.0),
    (const Size(320, 300), 2.0, 0.0),
    (const Size(390, 300), 2.0, 0.0),
    (const Size(320, 640), 2.0, 300.0),
    (const Size(390, 760), 2.0, 340.0),
    (const Size(800, 900), 2.0, 0.0),
    (const Size(1280, 900), 2.0, 0.0),
  ]) {
    testWidgets('required-first groups and pinned save fit $config', (
      tester,
    ) async {
      tester.view.physicalSize = config.$1;
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = FakeViewPadding(bottom: config.$3);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      final agenda = FakeAgendaApplication(projects: [_project]);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(config.$2)),
            child: child!,
          ),
          home: ReminderFormPage(
            agenda: agenda,
            preferredProjectId: _project.id,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_key('reminder-title'), findsOneWidget);
      expect(_key('reminder-kind'), findsNothing);
      expect(find.byType(TextFormField), findsOneWidget);
      expect(
        tester.state<FormFieldState<String?>>(_key('reminder-project')).value,
        _project.id,
      );
      final scroll = tester.getRect(_key('reminder-form-scroll'));
      expect(scroll.width, lessThanOrEqualTo(640));
      expect(scroll.center.dx, closeTo(config.$1.width / 2, 1));
      final save = tester.getRect(_key('submit-reminder'));
      expect(save.width, closeTo(scroll.width - 48, 1));
      expect(save.height, greaterThanOrEqualTo(48));
      expect(save.bottom, lessThanOrEqualTo(config.$1.height - config.$3));
      expect(_key('submit-reminder').hitTestable(), findsOneWidget);
      expect(find.text('Kaydet'), findsOneWidget);
      expect(
        find.ancestor(
          of: _key('submit-reminder'),
          matching: find.byType(Scrollable),
        ),
        findsNothing,
      );
      await _show(tester, 'reminder-time-group');
      expect(find.text('Zaman'), findsOneWidget);
      await _show(tester, 'reminder-optional-details');
      await tester.tap(_key('reminder-optional-details'));
      await tester.pumpAndSettle();
      await _show(tester, 'reminder-kind');
      expect(
        tester.state<FormFieldState<ReminderKind>>(_key('reminder-kind')).value,
        ReminderKind.action,
      );
      expect(
        find.descendant(
          of: _key('reminder-optional-details'),
          matching: _key('reminder-kind'),
        ),
        findsOneWidget,
      );
      await _show(tester, 'reminder-has-deadline');
      await tester.tap(_key('reminder-has-deadline'));
      await tester.pumpAndSettle();
      await _show(tester, 'reminder-deadline-time');
      expect(_key('submit-reminder').hitTestable(), findsOneWidget);
      await tester.tap(_key('submit-reminder'));
      await tester.pumpAndSettle();
      expect(agenda.createReminderCalls, 0);
      expect(find.text('Hatırlatıcı metni zorunludur.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'collapsed optional values persist and simple capture retains default kind',
    (tester) async {
      final agenda = FakeAgendaApplication()
        ..createReminderFailure = const AgendaValidationFailure(
          'Tekrar deneyin.',
        );
      await tester.pumpWidget(
        MaterialApp(home: ReminderFormPage(agenda: agenda)),
      );
      await tester.pumpAndSettle();
      await tester.enterText(_key('reminder-title'), 'Kontrol et');
      await tester.tap(_key('submit-reminder'));
      await tester.pumpAndSettle();
      expect(agenda.lastReminderCommand!.kind, ReminderKind.action);
      expect(agenda.lastReminderCommand!.projectId, isNull);
      expect(
        agenda.lastReminderCommand!.schedule,
        ReminderScheduleKind.in15Minutes,
      );
      final id = agenda.lastReminderCommand!.id;
      final eventId = agenda.lastReminderCommand!.eventId;
      await _show(tester, 'reminder-optional-details');
      await tester.tap(_key('reminder-optional-details'));
      await tester.pumpAndSettle();
      for (final entry in [
        ('reminder-description', 'Açıklama'),
        ('reminder-location', 'Kat 2'),
        ('reminder-related-person', 'Ali'),
        ('reminder-condition', 'Kontrolden sonra'),
      ]) {
        await _show(tester, entry.$1);
        await tester.enterText(_key(entry.$1), entry.$2);
      }
      await _show(tester, 'reminder-important');
      await tester.tap(_key('reminder-important'));
      await _show(tester, 'reminder-optional-details');
      await tester.tap(find.text('İsteğe bağlı ayrıntılar'));
      await tester.pumpAndSettle();
      await tester.tap(_key('submit-reminder'));
      await tester.pumpAndSettle();
      final command = agenda.lastReminderCommand!;
      expect(command.id, id);
      expect(command.eventId, eventId);
      expect(command.title, 'Kontrol et');
      expect(command.description, 'Açıklama');
      expect(command.location, 'Kat 2');
      expect(command.relatedPerson, 'Ali');
      expect(command.conditionText, 'Kontrolden sonra');
      expect(command.isImportant, isTrue);
      expect(agenda.createReminderCalls, 2);
      expect(find.text('Tekrar deneyin.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
