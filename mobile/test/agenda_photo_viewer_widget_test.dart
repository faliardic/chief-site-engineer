import 'dart:async';

import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/features/agenda/agenda_photo_viewer_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_agenda_application.dart';

const _photoId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa2';
const _logId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1';
const _projectId = '11111111-1111-4111-8111-111111111111';

void main() {
  AgendaLogPhoto photo() => const AgendaLogPhoto(
    id: _photoId,
    logId: _logId,
    projectId: _projectId,
    originalFileName: 'saha.jpg',
    mimeType: 'image/jpeg',
    byteSize: 4,
    sha256: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
    relativePath: 'managed/aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa2.jpg',
    description: null,
    capturedAt: '2026-08-10T10:00:00Z',
    integrity: AgendaAttachmentIntegrity.ok,
    createdAt: '2026-08-10T10:00:00Z',
    updatedAt: '2026-08-10T10:00:00Z',
    archivedAt: null,
    revision: 1,
  );

  _ExportAgendaApplication healthyAgenda() => _ExportAgendaApplication(
    agendaPhotoContents: const {
      _photoId: StoredAttachmentContent(
        fileName: 'saha.jpg',
        mimeType: 'image/jpeg',
        bytes: [0xff, 0xd8, 0xff, 1],
      ),
    },
  );

  Future<void> pumpViewer(WidgetTester tester, AgendaApplication agenda) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AgendaPhotoViewerPage(agenda: agenda, photo: photo()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('healthy viewer exposes save and share with busy feedback', (
    tester,
  ) async {
    final agenda = healthyAgenda();
    final saveCompleter = Completer<bool>();
    agenda.saveCompleter = saveCompleter;
    await pumpViewer(tester, agenda);

    expect(find.byKey(const Key('agenda-full-photo')), findsOneWidget);
    expect(find.byKey(const Key('agenda-photo-save')), findsOneWidget);
    expect(find.byKey(const Key('agenda-photo-share')), findsOneWidget);

    await tester.tap(find.byKey(const Key('agenda-photo-save')));
    await tester.pump();
    expect(
      find.byKey(const Key('agenda-photo-export-progress')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(const Key('agenda-photo-save')))
          .onPressed,
      isNull,
    );
    expect(agenda.savedPhotoIds, [_photoId]);

    saveCompleter.complete(true);
    await tester.pumpAndSettle();
    expect(find.text('Fotoğraf cihaza kaydedildi.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('agenda-photo-share')));
    await tester.pumpAndSettle();
    expect(agenda.sharedPhotoIds, [_photoId]);
    expect(find.text('Paylaşım ekranı açıldı.'), findsOneWidget);
  });

  testWidgets('photo actions fit a narrow screen with large Turkish text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final agenda = healthyAgenda();

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
          child: AgendaPhotoViewerPage(agenda: agenda, photo: photo()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('agenda-photo-save')), findsOneWidget);
    expect(find.byKey(const Key('agenda-photo-share')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('save cancellation is neutral and keeps viewer usable', (
    tester,
  ) async {
    final agenda = healthyAgenda()..saveResult = false;
    await pumpViewer(tester, agenda);

    await tester.tap(find.byKey(const Key('agenda-photo-save')));
    await tester.pumpAndSettle();

    expect(find.text('Kaydetme iptal edildi.'), findsOneWidget);
    expect(find.textContaining('Kayıt değişmedi'), findsNothing);
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(const Key('agenda-photo-save')))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('export errors use safe visible language', (tester) async {
    final agenda = healthyAgenda()
      ..saveFailure = StateError('sensitive platform path');
    await pumpViewer(tester, agenda);

    await tester.tap(find.byKey(const Key('agenda-photo-save')));
    await tester.pumpAndSettle();

    expect(
      find.text('Fotoğraf güvenli biçimde kaydedilemedi. Kayıt değişmedi.'),
      findsOneWidget,
    );
    expect(find.textContaining('sensitive platform path'), findsNothing);
  });

  testWidgets('unreadable photo shows diagnostic without export actions', (
    tester,
  ) async {
    final agenda = _ExportAgendaApplication();
    await pumpViewer(tester, agenda);

    expect(
      find.text('Fotoğraf güvenli biçimde açılamadı. Kayıt silinmedi.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('agenda-photo-save')), findsNothing);
    expect(find.byKey(const Key('agenda-photo-share')), findsNothing);
    expect(agenda.savedPhotoIds, isEmpty);
    expect(agenda.sharedPhotoIds, isEmpty);
  });
}

class _ExportAgendaApplication extends FakeAgendaApplication
    implements AgendaPhotoExportApplication {
  _ExportAgendaApplication({super.agendaPhotoContents});

  final List<String> savedPhotoIds = [];
  final List<String> sharedPhotoIds = [];
  bool saveResult = true;
  Completer<bool>? saveCompleter;
  Object? saveFailure;
  Object? shareFailure;

  @override
  Future<bool> saveAgendaPhoto(String photoId) async {
    savedPhotoIds.add(photoId);
    if (saveFailure case final error?) throw error;
    if (saveCompleter case final completer?) return completer.future;
    return saveResult;
  }

  @override
  Future<void> shareAgendaPhoto(String photoId) async {
    sharedPhotoIds.add(photoId);
    if (shareFailure case final error?) throw error;
  }
}
