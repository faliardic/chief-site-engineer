import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/features/agenda/log_form_page.dart';
import 'package:chief_site_engineer/platform/attachment_gateway.dart';
import 'package:chief_site_engineer/platform/capabilities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_agenda_application.dart';

const _project = MobileProject(
  id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  name: 'Kuzey Şantiyesi',
  createdAt: '2026-09-05T06:00:00Z',
  updatedAt: '2026-09-05T06:00:00Z',
  revision: 1,
);

Finder _key(String value) => find.byKey(Key(value));

void main() {
  setUpAll(CseTimeCodec.initialize);

  testWidgets('new capture follows locked active-project hierarchy', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(700, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final agenda = FakeAgendaApplication(projects: const [_project]);
    await tester.pumpWidget(
      MaterialApp(
        home: LogFormPage(
          agenda: agenda,
          initialProjectId: _project.id,
          initialIstanbulDay: '2026-09-09',
          attachments: _attachmentPicker(_QueuedPicker()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aktif proje: ${_project.name}'), findsOneWidget);
    expect(_key('log-project'), findsNothing);
    expect(_key('create-project'), findsNothing);
    expect(_key('log-time-details'), findsNothing);
    expect(_key('log-optional-details'), findsNothing);
    expect(_key('log-notes'), findsNothing);
    expect(_key('open-location-catalog-from-log'), findsNothing);

    final ordered = [
      _key('log-project-context'),
      _key('log-date-time-controls'),
      _key('log-description'),
      _key('log-location'),
      _key('log-photo-panel'),
      _key('log-category'),
    ];
    for (final target in ordered) {
      expect(target, findsOneWidget);
    }
    for (var index = 1; index < ordered.length; index++) {
      expect(
        tester.getTopLeft(ordered[index - 1]).dy,
        lessThan(tester.getTopLeft(ordered[index]).dy),
      );
    }
    expect(tester.getSize(_key('log-date')).height, greaterThanOrEqualTo(48));
    expect(tester.getSize(_key('log-time')).height, greaterThanOrEqualTo(48));
    expect(
      tester.getSize(_key('log-add-photo')).height,
      greaterThanOrEqualTo(96),
    );
    expect(tester.getSize(_key('submit-log')).height, greaterThanOrEqualTo(48));
    expect(tester.takeException(), isNull);
  });

  testWidgets('new capture keeps selected day, category and active project', (
    tester,
  ) async {
    final agenda = FakeAgendaApplication(projects: const [_project]);
    await _pumpForm(
      tester,
      LogFormPage(
        agenda: agenda,
        initialProjectId: _project.id,
        initialIstanbulDay: '2026-09-09',
      ),
    );
    await tester.enterText(_key('log-description'), 'Beton kontrol kaydı');
    await _selectDropdown<AgendaCategory>(
      tester,
      _key('log-category'),
      AgendaCategory.concrete.label,
    );
    await _submit(tester);

    expect(agenda.createLogCalls, 1);
    expect(agenda.lastLogCommand?.projectId, _project.id);
    expect(agenda.lastLogCommand?.category, AgendaCategory.concrete);
    expect(
      CseTimeCodec.istanbulDayKey(agenda.lastLogCommand!.observedAt),
      '2026-09-09',
    );
    expect(agenda.lastLogCommand?.notes?.trim(), isEmpty);
  });

  testWidgets('photo preview, cancel and remove preserve the draft', (
    tester,
  ) async {
    final picker = _QueuedPicker()
      ..responses.add(
        const SelectedAttachment(
          name: 'saha.jpg',
          bytes: [1, 2, 3],
          source: AttachmentSource.photoLibrary,
        ),
      )
      ..responses.add(null);
    final agenda = FakeAgendaApplication(projects: const [_project]);
    await _pumpForm(
      tester,
      LogFormPage(
        agenda: agenda,
        initialProjectId: _project.id,
        attachments: _attachmentPicker(picker),
      ),
    );
    await tester.enterText(_key('log-description'), 'Korunan fotoğraf taslağı');

    await _pickFromLibrary(tester);
    expect(_key('pending-log-photo-0'), findsOneWidget);
    expect(_key('remove-pending-log-photo-0'), findsOneWidget);
    expect(
      tester.getSize(_key('remove-pending-log-photo-0')).height,
      greaterThanOrEqualTo(48),
    );
    await _pickFromLibrary(tester);
    expect(_key('pending-log-photo-0'), findsOneWidget);
    expect(
      tester.widget<TextFormField>(_key('log-description')).controller?.text,
      'Korunan fotoğraf taslağı',
    );
    await tester.ensureVisible(_key('remove-pending-log-photo-0'));
    await tester.tap(_key('remove-pending-log-photo-0'));
    await tester.pumpAndSettle();
    expect(_key('pending-log-photo-0'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('edit preserves project, legacy notes, category and revision', (
    tester,
  ) async {
    final existing = AgendaLog(
      id: 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
      projectId: _project.id,
      projectName: _project.name,
      observedAt: '2026-09-09T06:00:00Z',
      createdAt: '2026-09-09T06:00:00Z',
      updatedAt: '2026-09-09T06:00:00Z',
      revision: 7,
      category: AgendaCategory.inspection,
      description: 'Eski açıklama',
      location: 'A Blok',
      notes: 'Korunacak ayrıntılı not',
    );
    final agenda = FakeAgendaApplication(
      projects: const [_project],
      logs: [existing],
    );
    await _pumpForm(tester, LogFormPage(agenda: agenda, existing: existing));
    expect(_key('log-notes'), findsOneWidget);
    expect(
      tester.widget<TextFormField>(_key('log-notes')).controller?.text,
      'Korunacak ayrıntılı not',
    );
    await tester.enterText(_key('log-description'), 'Yeni açıklama');
    await _submit(tester);

    final updated = agenda.logs.single;
    expect(updated.projectId, _project.id);
    expect(updated.notes, 'Korunacak ayrıntılı not');
    expect(updated.category, AgendaCategory.inspection);
    expect(updated.revision, 8);
  });

  testWidgets('new capture without active project cannot save globally', (
    tester,
  ) async {
    final agenda = FakeAgendaApplication(projects: const [_project]);
    await _pumpForm(tester, LogFormPage(agenda: agenda));
    expect(
      find.text('Ajanda kaydı için önce aktif proje seçin.'),
      findsOneWidget,
    );
    expect(tester.widget<FilledButton>(_key('submit-log')).onPressed, isNull);
    expect(agenda.createLogCalls, 0);
  });
}

Future<void> _pumpForm(WidgetTester tester, LogFormPage form) async {
  tester.view.physicalSize = const Size(500, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(home: form));
  await tester.pumpAndSettle();
}

Future<void> _submit(WidgetTester tester) async {
  await tester.ensureVisible(_key('submit-log'));
  await tester.tap(_key('submit-log'));
  await tester.pumpAndSettle();
}

Future<void> _selectDropdown<T>(
  WidgetTester tester,
  Finder field,
  String label,
) async {
  await tester.ensureVisible(field);
  await tester.tap(field);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Future<void> _pickFromLibrary(WidgetTester tester) async {
  await tester.ensureVisible(_key('log-add-photo'));
  await tester.tap(_key('log-add-photo'));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(ListTile, 'Sistem fotoğraf seçici'));
  await tester.pumpAndSettle();
}

SafeAttachmentPicker _attachmentPicker(AttachmentPickerPort picker) =>
    SafeAttachmentPicker(
      permissions: SafeCapabilityService(_GrantedPermissions()),
      picker: picker,
    );

class _GrantedPermissions implements PermissionGateway {
  @override
  Future<CapabilityStatus> request(DeviceCapability capability) async =>
      CapabilityStatus.granted;
}

class _QueuedPicker
    implements AttachmentPickerPort, MultipleAttachmentPickerPort {
  final List<SelectedAttachment?> responses = [];

  @override
  Future<SelectedAttachment?> pick(AttachmentSource source) async =>
      responses.removeAt(0);

  @override
  Future<List<SelectedAttachment>?> pickMany(AttachmentSource source) async {
    final response = responses.removeAt(0);
    return response == null ? null : [response];
  }
}
