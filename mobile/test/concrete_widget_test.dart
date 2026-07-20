import 'dart:async';

import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/application/concrete_application.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/concrete_models.dart';
import 'package:chief_site_engineer/features/concrete/concrete_page.dart';
import 'package:chief_site_engineer/features/concrete/concrete_pour_detail_page.dart';
import 'package:chief_site_engineer/features/concrete/concrete_pour_form_page.dart';
import 'package:chief_site_engineer/platform/attachment_gateway.dart';
import 'package:chief_site_engineer/platform/capabilities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const projectId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const pourId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
const truckId = 'ffffffff-ffff-4fff-8fff-fffffffffff1';
const attachmentId = 'ffffffff-ffff-4fff-8fff-fffffffffff2';
const project = MobileProject(
  id: projectId,
  name: 'Uzun Proje Adı',
  createdAt: '2026-07-19T07:00:00Z',
  updatedAt: '2026-07-19T07:00:00Z',
  revision: 1,
);

void main() {
  testWidgets(
    'Beton listesi 320 px ekranda filtreleri ve oluşturmayı gösterir',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final concrete = _FakeConcrete();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConcretePage(
              concrete: concrete,
              agenda: _FakeAgenda(),
              attachments: _picker(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Yeni döküm'), findsOneWidget);
      expect(find.textContaining('BT-001'), findsOneWidget);
      expect(find.text('Bugün'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'oluşturma formu validation girdisini korur ve çift dokunma tek komuttur',
    (tester) async {
      final concrete = _FakeConcrete(delayCreate: true);
      await tester.pumpWidget(
        MaterialApp(
          home: ConcretePourFormPage(
            concrete: concrete,
            projects: const [project],
          ),
        ),
      );
      await tester.enterText(
        find.widgetWithText(
          TextFormField,
          'Döküm kodu (boşsa otomatik üretilir)',
        ),
        'BT-187',
      );
      await tester.tap(find.text('Beton paketini oluştur'));
      await tester.pump();
      expect(find.text('BT-187'), findsOneWidget);
      expect(find.text('Mahal / eleman zorunludur.'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Mahal / eleman'),
        'KOLON A1',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Beton sınıfı'),
        'C30/37',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Planlanan metraj (m³)'),
        '20',
      );
      final save = find.text('Beton paketini oluştur');
      tester.testTextInput.hide();
      await tester.pump();
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pump();
      await tester.tap(save);
      await tester.tap(save);
      await tester.pump();
      expect(concrete.createCalls, 1);
      concrete.completeCreate();
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'detay ekranı checklist mikser kanıt numune takip ve timeline sunar',
    (tester) async {
      final concrete = _FakeConcrete();
      await tester.pumpWidget(
        MaterialApp(
          home: ConcretePourDetailPage(
            concrete: concrete,
            agenda: _FakeAgenda(),
            attachments: _picker(),
            pourId: pourId,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Hedef: 20,00 m³'), findsOneWidget);
      expect(find.textContaining('Dökülen: 12,50 m³'), findsOneWidget);
      expect(find.textContaining('Kalan: 7,50 m³'), findsOneWidget);
      for (final text in [
        'Döküm öncesi checklist',
        'Tümünü tamamla',
        'Mikser / irsaliye',
        'Kanıtlar',
        'Numuneler',
        'Takipler / Hatırlatıcılar',
        'Zaman çizelgesi',
        'PDF paylaş',
        'Telefona kaydet',
      ]) {
        final finder = find.textContaining(text);
        await tester.scrollUntilVisible(finder, 300);
        expect(finder, findsOneWidget);
      }
      await tester.scrollUntilVisible(find.text('İrsaliye taraması'), -300);
      await tester.tap(find.text('İrsaliye taraması'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('concrete-full-image')), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

SafeAttachmentPicker _picker() => SafeAttachmentPicker(
  permissions: SafeCapabilityService(_GrantedPermission()),
  picker: _EmptyPicker(),
);

class _GrantedPermission implements PermissionGateway {
  @override
  Future<CapabilityStatus> request(DeviceCapability capability) async =>
      CapabilityStatus.granted;
}

class _EmptyPicker implements AttachmentPickerPort {
  @override
  Future<SelectedAttachment?> pick(AttachmentSource source) async => null;
}

class _FakeConcrete implements ConcreteApplication {
  _FakeConcrete({this.delayCreate = false});
  final bool delayCreate;
  final _completer = Completer<ConcretePourDetail>();
  int createCalls = 0;

  void completeCreate() {
    if (!_completer.isCompleted) _completer.complete(_detail());
  }

  @override
  Future<ConcretePourDetail> createPour(CreateConcretePourCommand command) {
    createCalls += 1;
    return delayCreate ? _completer.future : Future.value(_detail());
  }

  @override
  Future<ConcretePourDetail> getPourDetail(String pourId) async => _detail();

  @override
  Future<List<ConcretePour>> listPours(ConcretePourQuery query) async => [
    _detail().pour,
  ];

  @override
  Future<ConcretePourDetail> attachEvidence(
    AttachConcreteEvidenceCommand command,
  ) => throw UnimplementedError();
  @override
  Future<ConcretePourDetail> bulkComplete(
    BulkCompleteConcreteCommand command,
  ) => throw UnimplementedError();
  @override
  Future<ConcreteExportResult> exportPackage(
    ExportConcretePackageCommand command, {
    bool share = false,
    bool save = false,
  }) => throw UnimplementedError();
  @override
  Future<StoredAttachmentContent> readAttachment(String attachmentId) =>
      Future.value(
        const StoredAttachmentContent(
          fileName: 'irsaliye.jpg',
          mimeType: 'image/jpeg',
          bytes: [0xff, 0xd8, 0xff, 0xd9],
        ),
      );
  @override
  Future<void> openAttachment(String attachmentId) =>
      throw UnimplementedError();
  @override
  Future<ConcretePourDetail> saveSampleSet(
    SaveConcreteSampleSetCommand command,
  ) => throw UnimplementedError();
  @override
  Future<ConcretePourDetail> saveTruck(SaveConcreteTruckCommand command) =>
      throw UnimplementedError();
  @override
  Future<ConcretePourDetail> transitionPour(
    TransitionConcretePourCommand command,
  ) => throw UnimplementedError();
  @override
  Future<ConcretePourDetail> updateCheck(UpdateConcreteCheckCommand command) =>
      throw UnimplementedError();
  @override
  Future<ConcretePourDetail> updateFollowUp(
    UpdateConcreteFollowUpCommand command,
  ) => throw UnimplementedError();
  @override
  Future<ConcretePourDetail> updatePour(UpdateConcretePourCommand command) =>
      throw UnimplementedError();
}

class _FakeAgenda implements AgendaApplication {
  @override
  Stream<void> get projectChanges => const Stream<void>.empty();

  @override
  Future<List<MobileProject>> listProjects() async => const [project];
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ConcretePourDetail _detail() {
  const pour = ConcretePour(
    id: pourId,
    projectId: projectId,
    projectName: 'Uzun Proje Adı',
    pourCode: 'BT-001',
    elementLocation: 'KOLON A1',
    blockName: 'A',
    floorName: '1',
    axisName: 'A/1',
    plannedAt: '2026-07-19T09:00:00Z',
    actualStartedAt: null,
    actualEndedAt: null,
    concreteClass: 'C30/37',
    targetSlump: null,
    plannedVolumeM3: 20,
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
    createdAt: '2026-07-19T07:00:00Z',
    updatedAt: '2026-07-19T07:00:00Z',
    closedAt: null,
    cancelledAt: null,
  );
  const check = ConcreteCheckItem(
    id: 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
    pourId: pourId,
    itemKey: 'location_ready',
    label: 'Döküm mahali hazır',
    sortOrder: 1,
    isRequired: true,
    status: ConcreteCheckStatus.pending,
    note: null,
    reason: null,
    revision: 1,
    updatedAt: '2026-07-19T07:00:00Z',
  );
  const follow = ConcreteFollowUp(
    id: 'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
    pourId: pourId,
    sourceSampleSetId: null,
    itemKey: 'curing_start',
    label: 'Kür başlangıcı',
    dueAt: '2026-07-19T11:00:00Z',
    status: ConcreteFollowUpStatus.pending,
    reminderId: null,
    note: null,
    reason: null,
    revision: 1,
    createdAt: '2026-07-19T07:00:00Z',
    updatedAt: '2026-07-19T07:00:00Z',
    completedAt: null,
  );
  const truck = ConcreteTruck(
    id: truckId,
    pourId: pourId,
    sequenceNo: 1,
    vehiclePlate: '34 CSE 196',
    deliveryNoteNumber: null,
    plantSnapshot: 'Güven Beton',
    batchTime: null,
    arrivedAt: '2026-07-19T09:10:00Z',
    unloadingStartedAt: '2026-07-19T09:15:00Z',
    unloadingEndedAt: '2026-07-19T09:30:00Z',
    volumeM3: 12.5,
    measuredSlump: null,
    concreteTemperature: null,
    result: ConcreteTruckResult.received,
    reason: null,
    note: 'İrsaliye numarası sonra girilecek.',
    evidenceExceptionReason: null,
    revision: 1,
    createdAt: '2026-07-19T09:10:00Z',
    updatedAt: '2026-07-19T09:10:00Z',
  );
  const attachment = ConcreteAttachment(
    id: attachmentId,
    pourId: pourId,
    truckId: truckId,
    sampleSetId: null,
    checkItemId: null,
    evidenceType: ConcreteEvidenceType.deliveryNoteScan,
    originalFileName: 'irsaliye.jpg',
    mimeType: 'image/jpeg',
    byteSize: 4,
    sha256: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
    relativePath: 'concrete/pour/truck/irsaliye.jpg',
    capturedAt: '2026-07-19T09:11:00Z',
    description: 'İrsaliye taraması',
    createdAt: '2026-07-19T09:11:00Z',
    integrity: ConcreteAttachmentIntegrity.ok,
  );
  const event = ConcretePourEvent(
    id: 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
    pourId: pourId,
    sequence: 1,
    eventType: 'pour.created',
    occurredAt: '2026-07-19T07:00:00Z',
    payloadJson: '{}',
  );
  return const ConcretePourDetail(
    pour: pour,
    checks: [check],
    trucks: [truck],
    sampleSets: [],
    followUps: [follow],
    attachments: [attachment],
    events: [event],
    linkedReminders: [],
    metrics: ConcreteMetrics(
      actualDeliveredM3: 12.5,
      varianceM3: -7.5,
      variancePercent: -37.5,
      receivedTruckCount: 1,
      heldTruckCount: 0,
      returnedTruckCount: 0,
      partialTruckCount: 0,
      firstTruckAt: null,
      lastTruckAt: null,
      pourDurationMinutes: null,
      sampleSetCount: 0,
      sampleCount: 0,
      pendingCheckCount: 1,
      missingEvidenceTruckCount: 0,
      openFollowUpCount: 1,
    ),
  );
}
