import 'package:chief_site_engineer/application/attachment_catalog_application.dart';
import 'package:chief_site_engineer/application/concrete_application.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/attachment_models.dart';
import 'package:chief_site_engineer/domain/concrete_models.dart';
import 'package:chief_site_engineer/features/attachments/attachment_catalog_page.dart';
import 'package:chief_site_engineer/features/attachments/attachment_health_page.dart';
import 'package:chief_site_engineer/features/concrete/concrete_pour_detail_page.dart';
import 'package:chief_site_engineer/platform/attachment_gateway.dart';
import 'package:chief_site_engineer/platform/capabilities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_agenda_application.dart';

const _projectA = '11111111-1111-4111-8111-111111111111';
const _projectB = '22222222-2222-4222-8222-222222222222';
const _physicalImage = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const _physicalPdf = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
const _physicalBroken = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';

void main() {
  setUpAll(() {
    CseTimeCodec.initialize();
  });

  testWidgets('catalog renders project-scoped links and selection guards', (
    tester,
  ) async {
    final catalog = _WidgetCatalog();
    await tester.pumpWidget(
      MaterialApp(home: AttachmentCatalogPage(catalog: catalog)),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('attachment-catalog-project-selector')),
      findsOneWidget,
    );
    expect(find.text('Ajanda • Kaynak kayıt • site_photo'), findsNWidgets(3));
    expect(find.text('1 bağ'), findsWidgets);
    final selector = tester.widget<DropdownButtonFormField<String>>(
      find.byKey(const Key('attachment-catalog-project-selector')),
    );
    selector.onChanged!(_projectB);
    await tester.pumpAndSettle();
    expect(catalog.requestedProjects, [_projectA, _projectB]);
    expect(find.text('Proje B belgesi.pdf'), findsOneWidget);

    ProjectAttachmentCatalogItem? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () async {
                selected = await Navigator.of(context)
                    .push<ProjectAttachmentCatalogItem>(
                      MaterialPageRoute(
                        builder: (_) => AttachmentCatalogPage(
                          catalog: catalog,
                          initialProjectId: _projectA,
                          selectionSourceType:
                              AttachmentCatalogSourceType.agendaObservation,
                          selectionSourceId:
                              'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
                          allowedMimeTypes: const {
                            'image/jpeg',
                            'image/png',
                            'image/heic',
                          },
                        ),
                      ),
                    );
              },
              child: const Text('Aç'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Aç'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<ListTile>(
            find.byKey(const Key('attachment-catalog-item-$_physicalPdf')),
          )
          .onTap,
      isNull,
    );
    expect(
      tester
          .widget<ListTile>(
            find.byKey(const Key('attachment-catalog-item-$_physicalBroken')),
          )
          .onTap,
      isNull,
    );
    await tester.tap(
      find.byKey(const Key('attachment-catalog-item-$_physicalImage')),
    );
    await tester.pumpAndSettle();
    expect(selected?.physicalAttachmentId, _physicalImage);
  });

  testWidgets('health page exposes every read-only finding on explicit open', (
    tester,
  ) async {
    var inspectCalls = 0;
    final report = AttachmentReconciliationReport([
      const AttachmentReconciliationFinding(
        type: AttachmentReconciliationFindingType.healthy,
        attachmentId: 'healthy',
      ),
      for (final type in AttachmentReconciliationFindingType.values.where(
        (value) => value != AttachmentReconciliationFindingType.healthy,
      ))
        AttachmentReconciliationFinding(
          type: type,
          attachmentId: 'attachment-${type.code}',
          linkId: type == AttachmentReconciliationFindingType.brokenTarget
              ? 'broken-link'
              : null,
          relativePath: type.code,
        ),
    ]);
    await tester.pumpWidget(
      MaterialApp(
        home: AttachmentHealthPage(
          inspector: () async {
            inspectCalls += 1;
            return report;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(inspectCalls, 1);
    expect(find.text('1 sağlıklı • 10 sorun'), findsOneWidget);
    for (final label in const [
      'Dosya eksik',
      'Boyut uyuşmuyor',
      'Hash uyuşmuyor',
      'Dosya türü uyuşmuyor',
      'Güvensiz dosya yolu',
      'Kırık kayıt bağlantısı',
      'Proje bağlantısı uyuşmuyor',
      'Bağsız yönetilen dosya',
      'Tamamlanmamış geçici dosya',
      'Benzer eski dosya adayı',
    ]) {
      await tester.scrollUntilVisible(
        find.text(label),
        250,
        scrollable: find.descendant(
          of: find.byKey(const Key('attachment-health-list')),
          matching: find.byType(Scrollable),
        ),
      );
      expect(find.text(label), findsOneWidget);
    }
    await tester.tap(find.byKey(const Key('refresh-attachment-health')));
    await tester.pumpAndSettle();
    expect(inspectCalls, 2);
  });

  testWidgets(
    'Concrete links catalog physical without creating managed bytes',
    (tester) async {
      tester.view.physicalSize = const Size(430, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final target = _pourDetail();
      final concrete = _CatalogConcreteFake(target);
      final agenda = FakeAgendaApplication(
        projects: const [
          MobileProject(
            id: _projectA,
            name: 'Proje A',
            createdAt: '2026-08-09T12:00:00Z',
            updatedAt: '2026-08-09T12:00:00Z',
            revision: 1,
          ),
        ],
      );
      final picker = SafeAttachmentPicker(
        permissions: const SafeCapabilityService(_DeniedPermission()),
        picker: const _UnexpectedPicker(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ConcretePourDetailPage(
            concrete: concrete,
            agenda: agenda,
            attachments: picker,
            pourId: target.pour.id,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final linkButton = find.byKey(
        const Key('link-existing-concrete-attachment'),
      );
      await tester.scrollUntilVisible(
        linkButton,
        400,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(linkButton);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('attachment-catalog-item-$_physicalPdf')),
      );
      await tester.pumpAndSettle();

      final detail = await concrete.getPourDetail(target.pour.id);
      expect(
        detail.attachments.single.relativePath,
        'managed/$_physicalPdf.pdf',
      );
      expect(
        detail.attachments.single.evidenceType,
        ConcreteEvidenceType.other,
      );
      expect(concrete.physicalRowCount, 1);
      expect(concrete.byteOperationCount, 0);
      expect(concrete.linkCalls, 1);
      expect(tester.takeException(), isNull);
    },
  );
}

ConcretePourDetail _pourDetail() => const ConcretePourDetail(
  pour: ConcretePour(
    id: 'ffffffff-ffff-4fff-8fff-fffffffffff4',
    projectId: _projectA,
    projectName: 'Proje A',
    pourCode: 'BT-002',
    elementLocation: 'A Blok',
    blockName: null,
    floorName: null,
    axisName: null,
    plannedAt: '2026-08-09T12:00:00Z',
    actualStartedAt: null,
    actualEndedAt: null,
    concreteClass: 'C30/37',
    targetSlump: null,
    plannedVolumeM3: 12,
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
    createdAt: '2026-08-09T12:00:00Z',
    updatedAt: '2026-08-09T12:00:00Z',
    closedAt: null,
    cancelledAt: null,
  ),
  concreteClassId: 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
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
    varianceM3: -12,
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

class _CatalogConcreteFake
    implements
        ConcreteApplication,
        ConcreteExistingAttachmentApplication,
        AttachmentCatalogHost {
  _CatalogConcreteFake(this._detail);

  ConcretePourDetail _detail;
  int physicalRowCount = 1;
  int byteOperationCount = 0;
  int linkCalls = 0;

  @override
  AttachmentCatalogApplication get attachmentCatalog => _WidgetCatalog();

  @override
  Future<ConcretePourDetail> getPourDetail(String pourId) async {
    expect(pourId, _detail.pour.id);
    return _detail;
  }

  @override
  Future<ConcretePourDetail> linkExistingAttachment(
    LinkExistingConcreteAttachmentCommand command,
  ) async {
    expect(command.pourId, _detail.pour.id);
    expect(command.physicalAttachmentId, _physicalPdf);
    expect(command.expectedPourRevision, _detail.pour.revision);
    linkCalls += 1;
    final pour = _detail.pour;
    final now = '2026-08-09T12:01:00Z';
    _detail = ConcretePourDetail(
      pour: ConcretePour(
        id: pour.id,
        projectId: pour.projectId,
        projectName: pour.projectName,
        pourCode: pour.pourCode,
        elementLocation: pour.elementLocation,
        locationId: pour.locationId,
        stableLocationName: pour.stableLocationName,
        stableLocationArchivedAt: pour.stableLocationArchivedAt,
        blockName: pour.blockName,
        floorName: pour.floorName,
        axisName: pour.axisName,
        plannedAt: pour.plannedAt,
        actualStartedAt: pour.actualStartedAt,
        actualEndedAt: pour.actualEndedAt,
        concreteClass: pour.concreteClass,
        targetSlump: pour.targetSlump,
        plannedVolumeM3: pour.plannedVolumeM3,
        orderedVolumeM3: pour.orderedVolumeM3,
        plantName: pour.plantName,
        plantBranch: pour.plantBranch,
        plantContact: pour.plantContact,
        plantAppointmentReference: pour.plantAppointmentReference,
        pumpEquipment: pour.pumpEquipment,
        laboratoryName: pour.laboratoryName,
        laboratoryContact: pour.laboratoryContact,
        laboratoryAppointment: pour.laboratoryAppointment,
        inspectionNotifiedAt: pour.inspectionNotifiedAt,
        inspectionNotifiedPerson: pour.inspectionNotifiedPerson,
        status: pour.status,
        generalNote: pour.generalNote,
        sampleExceptionReason: pour.sampleExceptionReason,
        varianceNote: pour.varianceNote,
        revision: pour.revision + 1,
        createdAt: pour.createdAt,
        updatedAt: now,
        closedAt: pour.closedAt,
        cancelledAt: pour.cancelledAt,
        pendingCheckCount: pour.pendingCheckCount,
        missingEvidenceTruckCount: pour.missingEvidenceTruckCount,
        openFollowUpCount: pour.openFollowUpCount,
      ),
      concreteClassId: _detail.concreteClassId,
      agendaLogId: _detail.agendaLogId,
      checks: _detail.checks,
      trucks: _detail.trucks,
      sampleSets: _detail.sampleSets,
      followUps: _detail.followUps,
      attachments: [
        ..._detail.attachments,
        ConcreteAttachment(
          id: command.linkId,
          pourId: command.pourId,
          truckId: null,
          sampleSetId: null,
          checkItemId: null,
          evidenceType: ConcreteEvidenceType.other,
          originalFileName: 'Rapor.pdf',
          mimeType: 'application/pdf',
          byteSize: 10,
          sha256: List.filled(64, 'a').join(),
          relativePath: 'managed/$_physicalPdf.pdf',
          capturedAt: now,
          description: null,
          createdAt: now,
          integrity: ConcreteAttachmentIntegrity.ok,
        ),
      ],
      events: _detail.events,
      linkedReminders: _detail.linkedReminders,
      metrics: _detail.metrics,
    );
    return _detail;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _WidgetCatalog implements AttachmentCatalogApplication {
  final List<String> requestedProjects = [];

  @override
  Future<List<AttachmentCatalogProject>> listProjects() async => const [
    AttachmentCatalogProject(id: _projectA, name: 'Proje A'),
    AttachmentCatalogProject(id: _projectB, name: 'Proje B'),
  ];

  @override
  Future<List<ProjectAttachmentCatalogItem>> listProjectAttachments(
    String projectId,
  ) async {
    requestedProjects.add(projectId);
    if (projectId == _projectB) {
      return [_item(_physicalPdf, 'Proje B belgesi.pdf', 'application/pdf')];
    }
    return [
      _item(_physicalImage, 'Saha fotoğrafı.jpg', 'image/jpeg'),
      _item(_physicalPdf, 'Rapor.pdf', 'application/pdf'),
      _item(
        _physicalBroken,
        'Eksik fotoğraf.jpg',
        'image/jpeg',
        integrity: ManagedAttachmentIntegrity.missingFile,
      ),
    ];
  }
}

ProjectAttachmentCatalogItem _item(
  String id,
  String name,
  String mimeType, {
  ManagedAttachmentIntegrity integrity = ManagedAttachmentIntegrity.healthy,
}) => ProjectAttachmentCatalogItem(
  physicalAttachmentId: id,
  relativePath: 'managed/$id.bin',
  mimeType: mimeType,
  byteSize: 10,
  sha256Value: List.filled(64, 'a').join(),
  createdAt: '2026-08-09T12:00:00Z',
  integrity: integrity,
  links: [
    AttachmentCatalogLink(
      id: '99999999-9999-4999-8999-${id.substring(id.length - 12)}',
      sourceType: AttachmentCatalogSourceType.agendaObservation,
      sourceId: '88888888-8888-4888-8888-888888888888',
      sourceLabel: 'Ajanda • Kaynak kayıt',
      role: 'site_photo',
      originalFileName: name,
      createdAt: '2026-08-09T12:00:00Z',
      archivedAt: null,
    ),
  ],
);

class _DeniedPermission implements PermissionGateway {
  const _DeniedPermission();

  @override
  Future<CapabilityStatus> request(DeviceCapability capability) async =>
      CapabilityStatus.denied;
}

class _UnexpectedPicker implements AttachmentPickerPort {
  const _UnexpectedPicker();

  @override
  Future<SelectedAttachment?> pick(AttachmentSource source) =>
      throw StateError('picker must not run');
}
