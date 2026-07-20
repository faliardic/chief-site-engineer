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

  testWidgets(
    'legacy null irsaliyeli mikser edit reverse animation boyunca güvenlidir',
    (tester) async {
      final concrete = _FakeConcrete();
      await _pumpDetail(tester, concrete);
      await _openExistingTruck(tester);

      final deliveryNote = tester.widget<TextField>(
        find.byKey(const Key('concrete-truck-delivery-note')),
      );
      expect(deliveryNote.controller!.text, isEmpty);
      await tester.enterText(
        find.byKey(const Key('concrete-truck-plate')),
        '34 CSE 200',
      );
      await tester.enterText(
        find.byKey(const Key('concrete-truck-delivery-note')),
        'IRS-200',
      );
      await tester.enterText(
        find.byKey(const Key('concrete-truck-volume')),
        '15,75',
      );
      await tester.enterText(
        find.byKey(const Key('concrete-truck-note')),
        'Lifecycle güvenli',
      );

      final save = find.byKey(const Key('save-concrete-truck'));
      final saveCallback = tester.widget<FilledButton>(save).onPressed!;
      saveCallback();
      saveCallback();
      await _pumpReverseTransition(tester);

      expect(tester.takeException(), isNull);
      expect(concrete.saveTruckCalls, 1);
      expect(concrete.lastTruckCommand!.deliveryNoteNumber, 'IRS-200');
      expect(concrete.lastTruckCommand!.arrivedAt, '2026-07-19T09:10:00Z');
      expect(
        concrete.lastTruckCommand!.unloadingStartedAt,
        '2026-07-19T09:15:00Z',
      );
      expect(
        concrete.lastTruckCommand!.unloadingEndedAt,
        '2026-07-19T09:30:00Z',
      );
      expect(find.textContaining('#1 34 CSE 200 • 15.75 m³'), findsOneWidget);
      expect(find.textContaining('Lifecycle güvenli'), findsOneWidget);
      expect(find.textContaining('Revizyon 2'), findsOneWidget);
    },
  );

  testWidgets(
    'yeni mikser reason toggle ve double tap tek güvenli mutation üretir',
    (tester) async {
      final concrete = _FakeConcrete();
      await _pumpDetail(tester, concrete);
      await tester.scrollUntilVisible(find.text('Mikser ekle'), 300);
      await tester.tap(find.text('Mikser ekle'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('concrete-truck-plate')),
        '34 NEW 200',
      );
      await tester.enterText(
        find.byKey(const Key('concrete-truck-volume')),
        '7.25',
      );
      await tester.tap(find.byKey(const Key('concrete-truck-result')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bekletildi').last);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('concrete-truck-reason')), findsOneWidget);
      await tester.tap(find.byKey(const Key('concrete-truck-result')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Teslim alındı').last);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('concrete-truck-reason')), findsNothing);
      await tester.tap(find.byKey(const Key('concrete-truck-result')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bekletildi').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('concrete-truck-reason')),
        'Saha kontrolü bekleniyor',
      );

      final save = find.byKey(const Key('save-concrete-truck'));
      final saveCallback = tester.widget<FilledButton>(save).onPressed!;
      saveCallback();
      saveCallback();
      await _pumpReverseTransition(tester);

      expect(tester.takeException(), isNull);
      expect(concrete.saveTruckCalls, 1);
      expect(concrete.lastTruckCommand!.result, ConcreteTruckResult.held);
      expect(concrete.lastTruckCommand!.reason, 'Saha kontrolü bekleniyor');
      expect(concrete.lastTruckCommand!.arrivedAt, isNotNull);
      expect(find.textContaining('34 NEW 200 • 7.25 m³'), findsOneWidget);
    },
  );

  testWidgets(
    'mikser dialog cancel mutation çağırmaz ve lifecycle güvenlidir',
    (tester) async {
      final concrete = _FakeConcrete();
      await _pumpDetail(tester, concrete);
      await _openExistingTruck(tester);

      await tester.tap(find.text('Vazgeç'));
      await _pumpReverseTransition(tester);

      expect(concrete.saveTruckCalls, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'save failure immutable mikser girdisini yeniden açılabilir tutar',
    (tester) async {
      final concrete = _FakeConcrete(failNextTruckSave: true);
      await _pumpDetail(tester, concrete);
      await _openExistingTruck(tester);
      await tester.enterText(
        find.byKey(const Key('concrete-truck-plate')),
        '34 RETRY 200',
      );
      await tester.tap(find.byKey(const Key('save-concrete-truck')));
      await _pumpReverseTransition(tester);

      expect(concrete.saveTruckCalls, 1);
      expect(
        find.byKey(const Key('reopen-concrete-truck-draft')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('reopen-concrete-truck-draft')));
      await tester.pumpAndSettle();
      final plate = tester.widget<TextField>(
        find.byKey(const Key('concrete-truck-plate')),
      );
      expect(plate.controller!.text, '34 RETRY 200');
      await tester.tap(find.text('Vazgeç'));
      await _pumpReverseTransition(tester);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _pumpDetail(WidgetTester tester, _FakeConcrete concrete) async {
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
}

Future<void> _openExistingTruck(WidgetTester tester) async {
  final truck = find.textContaining('#1 34 CSE 196');
  await tester.scrollUntilVisible(truck, 300);
  await tester.tap(truck);
  await tester.pumpAndSettle();
  expect(find.text('Mikseri düzenle'), findsOneWidget);
}

Future<void> _pumpReverseTransition(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pumpAndSettle();
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
  _FakeConcrete({this.delayCreate = false, this.failNextTruckSave = false});
  final bool delayCreate;
  bool failNextTruckSave;
  final _completer = Completer<ConcretePourDetail>();
  int createCalls = 0;
  int saveTruckCalls = 0;
  SaveConcreteTruckCommand? lastTruckCommand;

  ConcretePourDetail get _currentDetail => _detail(lastTruckCommand);

  void completeCreate() {
    if (!_completer.isCompleted) _completer.complete(_currentDetail);
  }

  @override
  Future<ConcretePourDetail> createPour(CreateConcretePourCommand command) {
    createCalls += 1;
    return delayCreate ? _completer.future : Future.value(_currentDetail);
  }

  @override
  Future<ConcretePourDetail> getPourDetail(String pourId) async =>
      _currentDetail;

  @override
  Future<List<ConcretePour>> listPours(ConcretePourQuery query) async => [
    _currentDetail.pour,
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
  Future<ConcretePourDetail> saveTruck(SaveConcreteTruckCommand command) async {
    saveTruckCalls += 1;
    if (failNextTruckSave) {
      failNextTruckSave = false;
      throw const AgendaValidationFailure(
        'Mikser revision değişti; kaydı yeniden kontrol edin.',
      );
    }
    lastTruckCommand = command;
    return _currentDetail;
  }

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

ConcretePourDetail _detail([SaveConcreteTruckCommand? savedTruck]) {
  final pour = ConcretePour(
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
    revision: savedTruck == null ? 1 : 2,
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
  final savedTruckRecord = savedTruck == null
      ? null
      : ConcreteTruck(
          id: savedTruck.id,
          pourId: savedTruck.pourId,
          sequenceNo: savedTruck.sequenceNo,
          vehiclePlate: savedTruck.vehiclePlate,
          deliveryNoteNumber: savedTruck.deliveryNoteNumber,
          plantSnapshot: savedTruck.plantSnapshot,
          batchTime: savedTruck.batchTime,
          arrivedAt: savedTruck.arrivedAt,
          unloadingStartedAt: savedTruck.unloadingStartedAt,
          unloadingEndedAt: savedTruck.unloadingEndedAt,
          volumeM3: savedTruck.volumeM3,
          measuredSlump: savedTruck.measuredSlump,
          concreteTemperature: savedTruck.concreteTemperature,
          result: savedTruck.result,
          reason: savedTruck.reason,
          note: savedTruck.note,
          evidenceExceptionReason: savedTruck.evidenceExceptionReason,
          revision: savedTruck.expectedTruckRevision + 1,
          createdAt: '2026-07-19T09:10:00Z',
          updatedAt: '2026-07-20T13:00:00Z',
        );
  final trucks = savedTruckRecord == null
      ? const [truck]
      : savedTruckRecord.id == truck.id
      ? [savedTruckRecord]
      : [truck, savedTruckRecord];
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
  final delivered = trucks.fold<double>(
    0,
    (total, item) => total + item.volumeM3,
  );
  return ConcretePourDetail(
    pour: pour,
    checks: const [check],
    trucks: trucks,
    sampleSets: const [],
    followUps: const [follow],
    attachments: const [attachment],
    events: const [event],
    linkedReminders: const [],
    metrics: ConcreteMetrics(
      actualDeliveredM3: delivered,
      varianceM3: delivered - 20,
      variancePercent: ((delivered - 20) / 20) * 100,
      receivedTruckCount: trucks
          .where((item) => item.result == ConcreteTruckResult.received)
          .length,
      heldTruckCount: trucks
          .where((item) => item.result == ConcreteTruckResult.held)
          .length,
      returnedTruckCount: trucks
          .where((item) => item.result == ConcreteTruckResult.returned)
          .length,
      partialTruckCount: trucks
          .where((item) => item.result == ConcreteTruckResult.partial)
          .length,
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
