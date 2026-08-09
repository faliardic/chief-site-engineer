import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/application/concrete_application.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/concrete_models.dart';
import 'package:chief_site_engineer/features/concrete/concrete_attachment_viewer_page.dart';
import 'package:chief_site_engineer/features/concrete/concrete_pour_detail_page.dart';
import 'package:chief_site_engineer/platform/attachment_gateway.dart';
import 'package:chief_site_engineer/platform/capabilities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('JPEG and PNG stay in the in-app InteractiveViewer', (
    tester,
  ) async {
    for (final mimeType in ['image/jpeg', 'image/png']) {
      final concrete = _ViewerConcrete();
      await tester.pumpWidget(
        MaterialApp(
          home: ConcreteAttachmentViewerPage(
            concrete: concrete,
            attachment: _attachment(mimeType),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.byKey(const Key('concrete-full-image')), findsOneWidget);
      expect(find.byKey(const Key('open-concrete-media')), findsNothing);
      expect(concrete.readCalls, 1);
      expect(concrete.openCalls, 0);
    }
  });

  testWidgets(
    'HEIC PDF video and audio route to integrity-gated external open',
    (tester) async {
      for (final mimeType in [
        'image/heic',
        'application/pdf',
        'video/mp4',
        'audio/mpeg',
        'audio/mp4',
        'audio/wav',
      ]) {
        final concrete = _ViewerConcrete();
        await tester.pumpWidget(
          MaterialApp(
            home: ConcreteAttachmentViewerPage(
              concrete: concrete,
              attachment: _attachment(mimeType),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final buttonKey = mimeType == 'application/pdf'
            ? const Key('open-concrete-pdf')
            : const Key('open-concrete-media');
        expect(find.byKey(buttonKey), findsOneWidget);
        expect(find.byType(InteractiveViewer), findsNothing);
        await tester.tap(find.byKey(buttonKey));
        await tester.pumpAndSettle();
        expect(concrete.openCalls, 1);
        expect(concrete.readCalls, 0);
      }
    },
  );

  testWidgets('failed integrity never exposes or invokes external open', (
    tester,
  ) async {
    final concrete = _ViewerConcrete();
    await tester.pumpWidget(
      MaterialApp(
        home: ConcreteAttachmentViewerPage(
          concrete: concrete,
          attachment: _attachment(
            'video/mp4',
            integrity: ConcreteAttachmentIntegrity.tampered,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('MIME/hash doğrulaması'), findsOneWidget);
    expect(find.byKey(const Key('open-concrete-media')), findsNothing);
    expect(concrete.openCalls, 0);
  });

  testWidgets('general Concrete evidence sends one ordered multi-file batch', (
    tester,
  ) async {
    final concrete = _BatchConcrete(_pourDetail());
    final picker = SafeAttachmentPicker(
      permissions: const SafeCapabilityService(_GrantedPermission()),
      picker: _MediaManyPicker(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ConcretePourDetailPage(
          concrete: concrete,
          agenda: _AgendaStub(),
          attachments: picker,
          pourId: concrete.detail.pour.id,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final addButton = find.widgetWithText(OutlinedButton, 'Saha kanıtı ekle');
    await tester.scrollUntilVisible(
      addButton,
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await Scrollable.ensureVisible(
      tester.element(addButton),
      alignment: 0.5,
      duration: Duration.zero,
    );
    await tester.pumpAndSettle();
    expect(addButton.hitTestable(), findsOneWidget);
    await tester.tap(addButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dosya seç'));
    await tester.pumpAndSettle();

    expect(concrete.batchCalls, 1);
    expect(concrete.lastBatch?.classifyGeneralByMime, isTrue);
    expect(
      concrete.lastBatch?.attachments.map((item) => item.originalFileName),
      ['saha.jpg', 'rapor.pdf', 'voice.mp3', 'voice.m4a', 'voice.wav'],
    );
  });

  testWidgets(
    'selected audio stage failure stays non-destructive and explains the reason',
    (tester) async {
      final concrete = _BatchConcrete(
        _pourDetail(),
        failure: const AgendaValidationFailure(
          'Seçilen dosyanın içeriği desteklenen fotoğraf, PDF, video veya ses '
          'biçimi olarak doğrulanamadı; Beton kaydı değişmedi.',
        ),
      );
      final picker = SafeAttachmentPicker(
        permissions: const SafeCapabilityService(_GrantedPermission()),
        picker: _UnsupportedAudioPicker(),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: ConcretePourDetailPage(
            concrete: concrete,
            agenda: _AgendaStub(),
            attachments: picker,
            pourId: concrete.detail.pour.id,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final addButton = find.widgetWithText(OutlinedButton, 'Saha kanıtı ekle');
      await tester.scrollUntilVisible(
        addButton,
        300,
        scrollable: find.byType(Scrollable).last,
      );
      await Scrollable.ensureVisible(
        tester.element(addButton),
        alignment: 0.5,
        duration: Duration.zero,
      );
      await tester.pumpAndSettle();
      expect(addButton.hitTestable(), findsOneWidget);
      await tester.tap(addButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dosya seç'));
      await tester.pumpAndSettle();

      expect(concrete.batchCalls, 1);
      expect(
        find.textContaining('ses biçimi olarak doğrulanamadı'),
        findsOneWidget,
      );
      expect(concrete.detail.attachments, isEmpty);
    },
  );
}

ConcreteAttachment _attachment(
  String mimeType, {
  ConcreteAttachmentIntegrity integrity = ConcreteAttachmentIntegrity.ok,
}) => ConcreteAttachment(
  id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  pourId: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
  truckId: null,
  sampleSetId: null,
  checkItemId: null,
  evidenceType: ConcreteEvidenceType.other,
  originalFileName: 'kanıt.${_extension(mimeType)}',
  mimeType: mimeType,
  byteSize: 4,
  sha256: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
  relativePath:
      'managed/aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa.${_extension(mimeType)}',
  capturedAt: '2026-08-09T10:00:00Z',
  description: null,
  createdAt: '2026-08-09T10:00:00Z',
  integrity: integrity,
);

String _extension(String mimeType) => switch (mimeType) {
  'image/jpeg' => 'jpg',
  'image/png' => 'png',
  'image/heic' => 'heic',
  'application/pdf' => 'pdf',
  'video/mp4' => 'mp4',
  'audio/mpeg' => 'mp3',
  'audio/mp4' => 'm4a',
  'audio/wav' => 'wav',
  _ => 'bin',
};

class _ViewerConcrete implements ConcreteApplication {
  int readCalls = 0;
  int openCalls = 0;

  @override
  Future<StoredAttachmentContent> readAttachment(String attachmentId) async {
    readCalls += 1;
    return const StoredAttachmentContent(
      fileName: 'kanıt.jpg',
      mimeType: 'image/jpeg',
      bytes: [0xff, 0xd8, 0xff, 0xd9],
    );
  }

  @override
  Future<void> openAttachment(String attachmentId) async {
    openCalls += 1;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _BatchConcrete
    implements ConcreteApplication, ConcreteEvidenceBatchApplication {
  _BatchConcrete(this.detail, {this.failure});

  final ConcretePourDetail detail;
  final Object? failure;
  int batchCalls = 0;
  AttachConcreteEvidenceBatchCommand? lastBatch;

  @override
  Future<ConcretePourDetail> getPourDetail(String pourId) async => detail;

  @override
  Future<ConcretePourDetail> attachEvidenceBatch(
    AttachConcreteEvidenceBatchCommand command,
  ) async {
    batchCalls += 1;
    lastBatch = command;
    if (failure case final error?) throw error;
    return detail;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _AgendaStub implements AgendaApplication {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _GrantedPermission implements PermissionGateway {
  const _GrantedPermission();

  @override
  Future<CapabilityStatus> request(DeviceCapability capability) async =>
      CapabilityStatus.granted;
}

class _MediaManyPicker
    implements AttachmentPickerPort, MultipleAttachmentPickerPort {
  @override
  Future<SelectedAttachment?> pick(AttachmentSource source) async =>
      (await pickMany(source))!.first;

  @override
  Future<List<SelectedAttachment>?> pickMany(AttachmentSource source) async => [
    SelectedAttachment(
      name: 'saha.jpg',
      bytes: const [0xff, 0xd8, 0xff, 1],
      source: source,
    ),
    SelectedAttachment(
      name: 'rapor.pdf',
      bytes: const [0x25, 0x50, 0x44, 0x46, 0x2d, 0x31],
      source: source,
    ),
    SelectedAttachment(
      name: 'voice.mp3',
      bytes: const [0x49, 0x44, 0x33, 0x04, 0xff, 0xfb, 0x90, 0x64],
      source: source,
    ),
    SelectedAttachment(
      name: 'voice.m4a',
      bytes: _m4aAudioFixture(),
      source: source,
    ),
    SelectedAttachment(
      name: 'voice.wav',
      bytes: const [
        0x52,
        0x49,
        0x46,
        0x46,
        0x04,
        0x00,
        0x00,
        0x00,
        0x57,
        0x41,
        0x56,
        0x45,
      ],
      source: source,
    ),
  ];
}

class _UnsupportedAudioPicker
    implements AttachmentPickerPort, MultipleAttachmentPickerPort {
  @override
  Future<SelectedAttachment?> pick(AttachmentSource source) async =>
      (await pickMany(source))!.single;

  @override
  Future<List<SelectedAttachment>?> pickMany(AttachmentSource source) async => [
    SelectedAttachment(
      name: 'spoofed.m4a',
      bytes: const [0x4f, 0x67, 0x67, 0x53, 0x00],
      source: source,
    ),
  ];
}

List<int> _m4aAudioFixture() => [
  ..._isoBox('ftyp', [...'mp42'.codeUnits, 0, 0, 0, 0, ...'isom'.codeUnits]),
  ..._isoBox('moov', [
    ..._isoBox('trak', [
      ..._isoBox('mdia', [
        ..._isoBox('hdlr', [
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          ...'soun'.codeUnits,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
        ]),
      ]),
    ]),
  ]),
  ..._isoBox('mdat', const [1, 2, 3, 4]),
];

List<int> _isoBox(String type, List<int> payload) => [
  ..._uint32(payload.length + 8),
  ...type.codeUnits,
  ...payload,
];

List<int> _uint32(int value) => [
  (value >> 24) & 0xff,
  (value >> 16) & 0xff,
  (value >> 8) & 0xff,
  value & 0xff,
];

ConcretePourDetail _pourDetail() {
  const pourId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
  return const ConcretePourDetail(
    pour: ConcretePour(
      id: pourId,
      projectId: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      projectName: 'Şantiye',
      pourCode: 'D-001',
      elementLocation: 'Temel',
      blockName: null,
      floorName: null,
      axisName: null,
      plannedAt: '2026-08-09T10:00:00Z',
      actualStartedAt: null,
      actualEndedAt: null,
      concreteClass: 'C30/37',
      targetSlump: 'S3',
      plannedVolumeM3: 10,
      orderedVolumeM3: null,
      plantName: null,
      plantBranch: null,
      plantContact: null,
      plantAppointmentReference: null,
      pumpEquipment: null,
      laboratoryName: null,
      laboratoryContact: null,
      laboratoryAppointment: null,
      inspectionNotifiedAt: null,
      inspectionNotifiedPerson: null,
      status: ConcretePourStatus.draft,
      generalNote: null,
      sampleExceptionReason: null,
      varianceNote: null,
      revision: 1,
      createdAt: '2026-08-09T09:00:00Z',
      updatedAt: '2026-08-09T09:00:00Z',
      closedAt: null,
      cancelledAt: null,
    ),
    concreteClassId: 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
    agendaLogId: null,
    checks: [],
    trucks: [],
    sampleSets: [],
    followUps: [],
    attachments: [],
    events: [],
    linkedReminders: [],
    metrics: ConcreteMetrics(
      actualDeliveredM3: 0,
      varianceM3: -10,
      variancePercent: -100,
      receivedTruckCount: 0,
      heldTruckCount: 0,
      returnedTruckCount: 0,
      partialTruckCount: 0,
      firstTruckAt: null,
      lastTruckAt: null,
      pourDurationMinutes: null,
      sampleSetCount: 0,
      sampleCount: 0,
      pendingCheckCount: 0,
      missingEvidenceTruckCount: 0,
      openFollowUpCount: 0,
    ),
  );
}
