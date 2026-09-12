import 'dart:async';

import 'package:chief_site_engineer/application/material_request_application.dart';
import 'package:chief_site_engineer/domain/material_request_models.dart';
import 'package:chief_site_engineer/features/material_requests/material_requests_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _projectA = MaterialRequestProject(id: 'project-a', name: 'Kuzey');
const _projectB = MaterialRequestProject(id: 'project-b', name: 'Güney');
const _request = MaterialRequest(
  id: 'request-1',
  projectId: 'project-b',
  materialName: 'C30 beton',
  locationId: 'location-1',
  locationName: 'A Blok',
  livingPlanItemId: 'plan-1',
  livingPlanActivityName: 'Temel betonu',
  quantity: 12,
  unit: 'm³',
  neededOn: '2026-09-15',
  priority: MaterialRequestPriority.high,
  status: MaterialRequestStatus.needed,
  revision: 1,
  createdAtUtc: '2026-09-11T08:00:00Z',
  updatedAtUtc: '2026-09-11T08:00:00Z',
  statusChangedAtUtc: '2026-09-11T08:00:00Z',
);

void main() {
  testWidgets(
    'binds only the exact Dashboard project without a local chooser',
    (tester) async {
      final application = _MaterialFake(projects: const [_projectA, _projectB]);

      await _pumpPage(tester, application, initialProjectId: _projectB.id);

      expect(application.events, [
        'listProjects',
        'listMaterialRequests:${_projectB.id}:open',
      ]);
      expect(
        find.byKey(const Key('material-request-project-context')),
        findsOneWidget,
      );
      expect(find.text(_projectB.name), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsNothing);
      expect(find.byKey(const Key('material-request-create')), findsOneWidget);

      await tester.tap(find.text('Geçmiş'));
      await tester.pumpAndSettle();
      expect(application.kindCalls.last, MaterialRequestListKind.history);
      expect(
        find.byKey(const Key('material-request-history-empty')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('material-request-create')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vazgeç'));
      await tester.pumpAndSettle();
      expect(application.kindCalls.last, MaterialRequestListKind.history);
      expect(
        find.byKey(const Key('material-request-history-empty')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'missing or stale shared context fails closed without discovery',
    (tester) async {
      final application = _MaterialFake(projects: const [_projectA, _projectB]);

      await _pumpPage(tester, application);

      expect(application.events, isEmpty);
      expect(
        find.byKey(const Key('material-request-project-context-unavailable')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('material-request-create')), findsNothing);

      await _pumpPage(tester, application, initialProjectId: 'missing-project');

      expect(application.events, ['listProjects']);
      expect(application.requestReads, 0);
      expect(application.locationReads, 0);
      expect(application.planReads, 0);
      expect(application.creates, isEmpty);
      expect(find.byKey(const Key('material-request-create')), findsNothing);
      expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    },
  );

  testWidgets('failed create keeps the draft and prevents duplicate submits', (
    tester,
  ) async {
    final application = _MaterialFake(projects: const [_projectB]);
    final createGate = Completer<MaterialRequest>();
    application.createGate = createGate;

    await _pumpPage(tester, application, initialProjectId: _projectB.id);
    await tester.tap(find.byKey(const Key('material-request-create')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('material-request-name')),
      '  C30 beton  ',
    );

    await tester.tap(find.byKey(const Key('material-request-save')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('material-request-save')));
    await tester.pump();
    expect(application.creates, hasLength(1));

    createGate.completeError(
      const MaterialRequestFailure('material_request_operation_failed'),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('material-request-create-error')),
      findsOneWidget,
    );
    expect(find.text('  C30 beton  '), findsOneWidget);

    application.createGate = null;
    await tester.tap(find.byKey(const Key('material-request-save')));
    await tester.pumpAndSettle();

    expect(application.creates, hasLength(2));
    expect(application.creates.last.projectId, _projectB.id);
    expect(application.creates.last.materialName, 'C30 beton');
    expect(
      find.byKey(const Key('material-request-create-dialog')),
      findsNothing,
    );
  });

  testWidgets('cards stay usable at compact width and high text scale', (
    tester,
  ) async {
    final application = _MaterialFake(
      projects: const [_projectB],
      openRequests: const [_request],
    );

    await _pumpPage(
      tester,
      application,
      initialProjectId: _projectB.id,
      size: const Size(320, 640),
      textScale: 2,
    );

    expect(find.text('C30 beton'), findsOneWidget);
    expect(find.text('Miktar: 12 m³'), findsOneWidget);
    expect(find.text('Mahal: A Blok'), findsOneWidget);
    expect(find.text('Plan işi: Temel betonu'), findsOneWidget);
    expect(find.text('Detayı aç'), findsOneWidget);
    expect(find.text('İstendi yap'), findsOneWidget);
    final detailButton = find.ancestor(
      of: find.text('Detayı aç'),
      matching: find.byType(TextButton),
    );
    expect(tester.getSize(detailButton).height, greaterThanOrEqualTo(48));
    expect(tester.takeException(), isNull);
  });

  testWidgets('refresh failure preserves prior content and disables writes', (
    tester,
  ) async {
    final application = _MaterialFake(
      projects: const [_projectB],
      openRequests: const [_request],
    );

    await _pumpPage(tester, application, initialProjectId: _projectB.id);
    application.failList = true;
    await tester.tap(find.byKey(const Key('material-request-refresh')));
    await tester.pumpAndSettle();

    expect(find.text('C30 beton'), findsOneWidget);
    expect(
      find.byKey(const Key('material-request-list-retry')),
      findsOneWidget,
    );
    expect(
      find.text('Son güvenli içerik yalnızca görüntüleniyor.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FloatingActionButton>(
            find.byKey(const Key('material-request-create')),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('transition action is disabled while its write is in flight', (
    tester,
  ) async {
    final application = _MaterialFake(
      projects: const [_projectB],
      openRequests: const [_request],
    );
    final transitionGate = Completer<MaterialRequest>();
    application.transitionGate = transitionGate;

    await _pumpPage(tester, application, initialProjectId: _projectB.id);
    final transitionButton = find.ancestor(
      of: find.text('İstendi yap'),
      matching: find.byType(FilledButton),
    );
    await tester.tap(transitionButton);
    await tester.pump();

    expect(application.transitions, hasLength(1));
    expect(tester.widget<FilledButton>(transitionButton).onPressed, isNull);
    expect(find.text('Durum güncelleniyor…'), findsOneWidget);

    transitionGate.complete(_request);
    await tester.pumpAndSettle();
    expect(application.transitions, hasLength(1));
  });
}

Future<void> _pumpPage(
  WidgetTester tester,
  _MaterialFake application, {
  String? initialProjectId,
  Size size = const Size(800, 900),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: MaterialRequestsPage(
        application: application,
        initialProjectId: initialProjectId,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _MaterialFake implements MaterialRequestApplicationPort {
  _MaterialFake({
    required this.projects,
    this.openRequests = const [],
    this.historyRequests = const [],
  });

  List<MaterialRequestProject> projects;
  List<MaterialRequest> openRequests;
  List<MaterialRequest> historyRequests;
  final events = <String>[];
  final kindCalls = <MaterialRequestListKind>[];
  final creates = <CreateMaterialRequestCommand>[];
  final transitions = <TransitionMaterialRequestCommand>[];
  var requestReads = 0;
  var locationReads = 0;
  var planReads = 0;
  var failList = false;
  Completer<MaterialRequest>? createGate;
  Completer<MaterialRequest>? transitionGate;

  @override
  Future<List<MaterialRequestProject>> listProjects() async {
    events.add('listProjects');
    return projects;
  }

  @override
  Future<List<MaterialRequest>> listMaterialRequests({
    required String projectId,
    required MaterialRequestListKind kind,
  }) async {
    requestReads += 1;
    kindCalls.add(kind);
    events.add('listMaterialRequests:$projectId:${kind.name}');
    if (failList) {
      throw const MaterialRequestFailure('material_request_operation_failed');
    }
    return kind == MaterialRequestListKind.open
        ? openRequests
        : historyRequests;
  }

  @override
  Future<List<MaterialRequestLocationOption>> listLocations(
    String projectId,
  ) async {
    locationReads += 1;
    events.add('listLocations:$projectId');
    return const [];
  }

  @override
  Future<List<MaterialRequestLivingPlanOption>> listLivingPlanItems(
    String projectId,
  ) async {
    planReads += 1;
    events.add('listLivingPlanItems:$projectId');
    return const [];
  }

  @override
  Future<MaterialRequest> createMaterialRequest(
    CreateMaterialRequestCommand command,
  ) async {
    creates.add(command);
    final gate = createGate;
    if (gate != null) return gate.future;
    return _request;
  }

  @override
  Future<MaterialRequestDetail> getMaterialRequestDetail(
    String requestId,
  ) async => const MaterialRequestDetail(request: _request, events: []);

  @override
  Future<MaterialRequest> transitionMaterialRequest(
    TransitionMaterialRequestCommand command,
  ) async {
    transitions.add(command);
    final gate = transitionGate;
    if (gate != null) return gate.future;
    return _request;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
