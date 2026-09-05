import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/features/agenda/log_form_page.dart';
import 'package:chief_site_engineer/platform/attachment_gateway.dart';
import 'package:chief_site_engineer/platform/capabilities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/fake_agenda_application.dart';

const _project = MobileProject(
  id: 'project-a',
  name: 'Kuzey Şantiyesi',
  createdAt: '2026-07-19T08:00:00Z',
  updatedAt: '2026-07-19T08:00:00Z',
  revision: 1,
);
Finder _key(String value) => find.byKey(Key(value));
Future<void> _show(WidgetTester tester, String value) async {
  await tester.ensureVisible(_key(value));
  await tester.pumpAndSettle();
}

Future<void> _toggle(WidgetTester tester, String value) async {
  await _show(tester, value);
  final label = value == 'log-time-details'
      ? 'Zaman ve tür'
      : 'İsteğe bağlı ayrıntılar';
  await tester.tap(find.text(label));
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
    testWidgets('capture and fixed save remain reachable at $config', (
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
          home: LogFormPage(
            agenda: agenda,
            initialProjectId: _project.id,
            initialIstanbulDay: '2026-07-19',
            attachments: SafeAttachmentPicker(
              permissions: SafeCapabilityService(_Permission()),
              picker: _Picker(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_key('log-description'), findsOneWidget);
      expect(
        tester.state<FormFieldState<String>>(_key('log-project')).value,
        _project.id,
      );
      expect(_key('log-date'), findsNothing);
      expect(_key('log-category'), findsNothing);
      expect(_key('log-notes'), findsNothing);
      expect(find.byType(TextFormField), findsOneWidget);
      expect(
        find.descendant(
          of: _key('log-capture-group'),
          matching: _key('log-add-photo'),
        ),
        findsOneWidget,
      );
      final scroll = tester.getRect(_key('log-form-scroll'));
      final save = tester.getRect(_key('submit-log'));
      expect(scroll.width, lessThanOrEqualTo(640));
      expect(scroll.center.dx, closeTo(config.$1.width / 2, 1));
      expect(save.width, closeTo(scroll.width - 48, 1));
      expect(save.height, greaterThanOrEqualTo(48));
      expect(save.bottom, lessThanOrEqualTo(config.$1.height - config.$3));
      expect(_key('submit-log').hitTestable(), findsOneWidget);
      expect(
        find.ancestor(
          of: _key('submit-log'),
          matching: find.byType(Scrollable),
        ),
        findsNothing,
      );
      await _toggle(tester, 'log-time-details');
      await _show(tester, 'log-date');
      expect(find.text('19.07.2026'), findsOneWidget);
      await _show(tester, 'log-category');
      await _toggle(tester, 'log-optional-details');
      await _show(tester, 'log-notes');
      expect(_key('submit-log').hitTestable(), findsOneWidget);
      await tester.tap(_key('submit-log'));
      await tester.pumpAndSettle();
      expect(agenda.createLogCalls, 0);
      expect(find.text('Kısa açıklama zorunludur.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'collapsed time category location notes retain exact edit command',
    (tester) async {
      const existing = AgendaLog(
        id: 'log-a',
        projectId: 'project-a',
        projectName: 'Kuzey Şantiyesi',
        observedAt: '2026-07-19T09:23:00Z',
        createdAt: '2026-07-19T09:23:00Z',
        updatedAt: '2026-07-19T09:23:00Z',
        category: AgendaCategory.concrete,
        description: 'Eski açıklama',
        location: 'A Blok',
        notes: 'Korunan not',
        revision: 7,
      );
      final agenda = _RecordingAgenda();
      await tester.pumpWidget(
        MaterialApp(
          home: LogFormPage(agenda: agenda, existing: existing),
        ),
      );
      await tester.pumpAndSettle();
      expect(_key('log-date'), findsNothing);
      await _toggle(tester, 'log-time-details');
      expect(find.text('19.07.2026'), findsOneWidget);
      expect(
        tester
            .widget<DropdownButtonFormField<AgendaCategory>>(
              find.descendant(
                of: _key('log-category'),
                matching: find.byType(DropdownButtonFormField<AgendaCategory>),
              ),
            )
            .initialValue,
        AgendaCategory.concrete,
      );
      await _toggle(tester, 'log-optional-details');
      expect(
        tester.widget<TextFormField>(_key('log-location')).controller!.text,
        'A Blok',
      );
      expect(
        tester.widget<TextFormField>(_key('log-notes')).controller!.text,
        'Korunan not',
      );
      await _toggle(tester, 'log-optional-details');
      await _toggle(tester, 'log-time-details');
      await _show(tester, 'log-description');
      await tester.enterText(_key('log-description'), 'Yeni açıklama');
      await tester.tap(_key('submit-log'));
      await tester.pumpAndSettle();
      final command = agenda.updated!;
      expect(command.id, existing.id);
      expect(command.projectId, existing.projectId);
      expect(command.observedAt, existing.observedAt);
      expect(command.category, existing.category);
      expect(command.location, existing.location);
      expect(command.notes, existing.notes);
      expect(command.description, 'Yeni açıklama');
      expect(tester.takeException(), isNull);
    },
  );
}

class _RecordingAgenda extends FakeAgendaApplication {
  _RecordingAgenda() : super(projects: [_project]);
  UpdateAgendaLogCommand? updated;
  @override
  Future<AgendaLog> updateAgendaLog(UpdateAgendaLogCommand command) async {
    updated = command;
    throw const AgendaValidationFailure('Tekrar deneyin.');
  }
}

class _Permission implements PermissionGateway {
  @override
  Future<CapabilityStatus> request(DeviceCapability capability) async =>
      CapabilityStatus.granted;
}

class _Picker implements AttachmentPickerPort {
  @override
  Future<SelectedAttachment?> pick(AttachmentSource source) async => null;
}
