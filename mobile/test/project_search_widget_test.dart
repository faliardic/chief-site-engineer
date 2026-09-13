import 'dart:async';
import 'dart:ui' show SemanticsAction;

import 'package:chief_site_engineer/application/project_search_application.dart';
import 'package:chief_site_engineer/features/search/project_search_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _projectA = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const _projectB = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';

void main() {
  testWidgets('loading partial results empty and error states are bounded', (
    tester,
  ) async {
    final session = _Session(_projectA);
    final application = _FakeProjectSearch();
    await _pump(tester, session, application);

    final pending = Completer<ProjectSearchResponse>();
    application.responses['kolon'] = pending.future;
    await _submit(tester, 'kolon');
    expect(find.byKey(const Key('project-search-loading')), findsOneWidget);
    pending.complete(
      ProjectSearchResponse(
        results: [_result(1)],
        failures: const [
          ProjectSearchSourceFailure(
            sourceKind: ProjectSearchSourceKind.concretePour,
            code: 'project_search_concrete_read_failed',
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ajanda kaydı 1'), findsOneWidget);
    expect(
      find.byKey(const Key('project-search-partial-failure')),
      findsOneWidget,
    );

    application.responses['yok'] = Future.value(
      const ProjectSearchResponse(results: [], failures: []),
    );
    await _submit(tester, 'yok');
    expect(find.byKey(const Key('project-search-empty')), findsOneWidget);

    final failed = Completer<ProjectSearchResponse>();
    application.responses['hata'] = failed.future;
    await _submit(tester, 'hata');
    failed.completeError(StateError('read failed'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('project-search-error')), findsOneWidget);
    expect(tester.takeException(), isNull);

    application.responses['iki hata'] = Future.value(
      const ProjectSearchResponse(
        results: [],
        failures: [
          ProjectSearchSourceFailure(
            sourceKind: ProjectSearchSourceKind.agendaObservation,
            code: 'project_search_agenda_read_failed',
          ),
          ProjectSearchSourceFailure(
            sourceKind: ProjectSearchSourceKind.concretePour,
            code: 'project_search_concrete_read_failed',
          ),
        ],
      ),
    );
    await _submit(tester, 'iki hata');
    await tester.pumpAndSettle();
    expect(find.text('Arama kaynakları güvenle okunamadı.'), findsOneWidget);
  });

  testWidgets('project switch cancels stale generation and removes old hits', (
    tester,
  ) async {
    final session = _Session(_projectA);
    final application = _FakeProjectSearch();
    final pending = Completer<ProjectSearchResponse>();
    application.responses['eski'] = pending.future;
    await _pump(tester, session, application);
    await _submit(tester, 'eski');

    session.select(_projectB);
    await tester.pump();
    expect(find.byKey(const Key('project-search-idle')), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('project-search-input')))
          .controller!
          .text,
      isEmpty,
    );
    pending.complete(
      ProjectSearchResponse(results: [_result(1)], failures: const []),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ajanda kaydı 1'), findsNothing);

    application.responses['yeni'] = Future.value(
      ProjectSearchResponse(
        results: [_result(2, projectId: _projectB)],
        failures: const [],
      ),
    );
    await _submit(tester, 'yeni');
    expect(application.queries.last.projectId, _projectB);
    expect(find.text('Ajanda kaydı 2'), findsOneWidget);
  });

  testWidgets('unavailable result does not navigate', (tester) async {
    final session = _Session(_projectA);
    final application = _FakeProjectSearch()
      ..responses['kayıt'] = Future.value(
        ProjectSearchResponse(results: [_result(1)], failures: const []),
      );
    await _pump(tester, session, application, openResult: (_) async => false);
    await _submit(tester, 'kayıt');

    await tester.tap(find.text('Ajanda kaydı 1'));
    await tester.pumpAndSettle();

    expect(find.byType(ProjectSearchPage), findsOneWidget);
    expect(
      find.text('Bu kayıt artık bu projede kullanılamıyor.'),
      findsOneWidget,
    );
  });

  testWidgets('detail Back retains query results and scroll position', (
    tester,
  ) async {
    final session = _Session(_projectA);
    final application = _FakeProjectSearch()
      ..responses['çok'] = Future.value(
        ProjectSearchResponse(
          results: [for (var index = 0; index < 20; index += 1) _result(index)],
          failures: const [],
        ),
      );
    await _pump(
      tester,
      session,
      application,
      openResult: (_) async {
        await Navigator.of(
          tester.element(find.byType(ProjectSearchPage)),
        ).push<void>(
          MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(title: const Text('Kayıt detayı')),
              body: const SizedBox.expand(),
            ),
          ),
        );
        return true;
      },
    );
    await _submit(tester, 'çok');
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -700));
    await tester.pumpAndSettle();
    final before = tester
        .state<ScrollableState>(
          find.descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          ),
        )
        .position
        .pixels;
    expect(before, greaterThan(0));
    await tester.tap(find.text('Ajanda kaydı 8'));
    await tester.pumpAndSettle();
    expect(find.text('Kayıt detayı'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Ajanda kaydı 8'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('project-search-input')))
          .controller!
          .text,
      'çok',
    );
    final after = tester
        .state<ScrollableState>(
          find.descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          ),
        )
        .position
        .pixels;
    expect(after, before);
  });

  for (final width in [320.0, 390.0, 600.0, 840.0]) {
    for (final scale in [1.0, 1.6]) {
      testWidgets(
        'search controls fit ${width.toInt()}px at ${scale}x text scale',
        (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final semantics = tester.ensureSemantics();
          final session = _Session(_projectA);
          final application = _FakeProjectSearch()
            ..responses['kontrol'] = Future.value(
              ProjectSearchResponse(results: [_result(1)], failures: const []),
            );
          await _pump(tester, session, application, textScale: scale);

          await tester.tap(find.byKey(const Key('project-search-input')));
          await tester.pump();
          expect(
            tester
                .widget<EditableText>(find.byType(EditableText))
                .focusNode
                .hasFocus,
            isTrue,
          );
          await tester.enterText(
            find.byKey(const Key('project-search-input')),
            'kontrol',
          );
          await tester.pump();
          final submit = find.byKey(const Key('project-search-submit'));
          expect(tester.getSize(submit).width, greaterThanOrEqualTo(48));
          expect(tester.getSize(submit).height, greaterThanOrEqualTo(48));
          expect(
            tester
                .getSemantics(submit)
                .getSemanticsData()
                .hasAction(SemanticsAction.tap),
            isTrue,
          );
          await tester.tap(submit);
          await tester.pumpAndSettle();
          final tile = find.byKey(
            ValueKey('project-search-result-${_result(1).identity}'),
          );
          expect(tester.getSize(tile).height, greaterThanOrEqualTo(48));
          expect(tester.takeException(), isNull);
          semantics.dispose();
        },
      );
    }
  }
}

Future<void> _pump(
  WidgetTester tester,
  _Session session,
  _FakeProjectSearch application, {
  Future<bool> Function(ProjectSearchResult)? openResult,
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: ProjectSearchPage(
          application: application,
          activeProjectSession: session,
          readActiveProjectId: () => session.projectId,
          openResult: openResult ?? (_) async => true,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _submit(WidgetTester tester, String query) async {
  await tester.enterText(find.byKey(const Key('project-search-input')), query);
  await tester.pump();
  await tester.tap(find.byKey(const Key('project-search-submit')));
  await tester.pump();
}

ProjectSearchResult _result(int index, {String projectId = _projectA}) =>
    ProjectSearchResult(
      projectId: projectId,
      sourceKind: ProjectSearchSourceKind.agendaObservation,
      sourceId: 'cccccccc-cccc-4ccc-8ccc-${index.toString().padLeft(12, '0')}',
      title: 'Ajanda kaydı $index',
      summary: 'Genel not • A Blok',
      sourceDate: '2026-09-12T08:${index.toString().padLeft(2, '0')}:00Z',
      statusLabel: 'Aktif',
      matchQuality: ProjectSearchMatchQuality.substring,
    );

class _Session extends ChangeNotifier {
  _Session(this.projectId);

  String? projectId;

  void select(String? value) {
    projectId = value;
    notifyListeners();
  }
}

class _FakeProjectSearch implements ProjectSearchApplicationPort {
  final Map<String, Future<ProjectSearchResponse>> responses = {};
  final List<ProjectSearchQuery> queries = [];

  @override
  Future<ProjectSearchResponse> search(ProjectSearchQuery query) {
    queries.add(query);
    return responses[query.query.trim()] ??
        Future.value(const ProjectSearchResponse(results: [], failures: []));
  }
}
