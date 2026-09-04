import 'dart:convert';

import 'package:chief_site_engineer/application/attachment_catalog_application.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/domain/attachment_models.dart';
import 'package:chief_site_engineer/features/agenda/log_detail_page.dart';
import 'package:chief_site_engineer/features/attachments/project_media_album_page.dart';
import 'package:chief_site_engineer/features/project_context/active_project_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_agenda_application.dart';

const _projectA = MobileProject(
  id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  name: 'Kuzey',
  createdAt: '2026-09-01T08:00:00Z',
  updatedAt: '2026-09-01T08:00:00Z',
  revision: 1,
);
const _projectB = MobileProject(
  id: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
  name: 'Güney',
  createdAt: '2026-09-01T08:00:00Z',
  updatedAt: '2026-09-01T08:00:00Z',
  revision: 1,
);
const _log = AgendaLog(
  id: '11111111-1111-4111-8111-111111111111',
  projectId: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  projectName: 'Kuzey',
  observedAt: '2026-09-02T08:00:00Z',
  createdAt: '2026-09-02T08:00:00Z',
  updatedAt: '2026-09-02T08:00:00Z',
  category: AgendaCategory.generalNote,
  description: 'Albüm kaynak kaydı',
  location: null,
  notes: null,
  revision: 1,
);

void main() {
  testWidgets(
    'valid shared switch preserves Album state, resets filters, and keeps media/source behavior',
    (tester) async {
      final photo = _item(
        id: 'photo',
        mimeType: 'image/png',
        link: _link(
          id: 'photo-link',
          sourceType: AttachmentCatalogSourceType.agendaObservation,
          sourceId: _log.id,
          sourceLabel: 'Ajanda • Albüm kaynak kaydı',
          fileName: 'saha.png',
        ),
      );
      final video = _item(
        id: 'video',
        mimeType: 'video/mp4',
        link: _link(
          id: 'video-link',
          sourceType: AttachmentCatalogSourceType.concretePour,
          sourceId: '22222222-2222-4222-8222-222222222222',
          sourceLabel: 'Beton • Döküm 1',
          fileName: 'dokum.mp4',
          sourceAvailable: false,
        ),
      );
      final unhealthy = _item(
        id: 'unhealthy',
        mimeType: 'image/jpeg',
        integrity: ManagedAttachmentIntegrity.hashMismatch,
        link: _link(
          id: 'unhealthy-link',
          sourceType: AttachmentCatalogSourceType.agendaObservation,
          sourceId: _log.id,
          sourceLabel: 'Ajanda • Eski medya',
          fileName: 'bozuk.jpg',
        ),
      );
      final catalog = _MediaCatalog(
        itemsByProject: {
          _projectA.id: [photo, video, unhealthy],
          _projectB.id: const [],
        },
      );
      final agenda = FakeAgendaApplication(
        projects: const [_projectA, _projectB],
        logDetail: const AgendaLogDetail(log: _log, reminders: []),
      );
      var activeProjectId = _projectA.id;
      final reportedProjects = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setHostState) => ProjectMediaAlbumPage(
              key: const Key('project-media-album-page'),
              catalog: catalog,
              agenda: agenda,
              initialProjectId: activeProjectId,
              onProjectSelected: (projectId) {
                reportedProjects.add(projectId);
                setHostState(() => activeProjectId = projectId);
              },
              appBarProjectControlBuilder: (onSelected) => ActiveProjectControl(
                label: activeProjectId == _projectA.id
                    ? _projectA.name
                    : _projectB.name,
                projects: const [_projectA, _projectB],
                onSelected: onSelected,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final state = tester.state(find.byType(ProjectMediaAlbumPage));
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byType(ActiveProjectControl),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(ValueKey('album-project-${_projectA.id}')),
        findsNothing,
      );

      await _tapVisible(tester, const Key('project-media-open-photo'));
      expect(catalog.readItems, [photo]);
      expect(find.text('saha.png'), findsWidgets);
      await tester.tap(find.text('Kapat'));
      await tester.pumpAndSettle();

      await _tapVisible(tester, const Key('project-media-link-photo-link'));
      expect(find.byType(LogDetailPage), findsOneWidget);
      expect(agenda.getAgendaLogDetailCalls, 1);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(tester.state(find.byType(ProjectMediaAlbumPage)), same(state));

      await _tapVisible(tester, const Key('project-media-open-video'));
      expect(catalog.openedItems, [video]);
      final unhealthyButton = tester.widget<OutlinedButton>(
        find.byKey(const Key('project-media-open-unhealthy')),
      );
      expect(unhealthyButton.onPressed, isNull);

      await _chooseDropdown(tester, const ValueKey('album-media-all'), 'Video');
      await _chooseDropdown(
        tester,
        const ValueKey('album-source-all'),
        'Beton',
      );
      await _chooseDropdown(
        tester,
        const ValueKey('album-context-all'),
        'Mahal • Blok A',
      );
      await _setDateRange(tester);
      expect(
        find.byKey(const Key('clear-project-media-date-filter')),
        findsOneWidget,
      );

      await _chooseSharedProject(tester, _projectB.id);
      expect(reportedProjects, [_projectB.id]);
      expect(catalog.scopedCalls.last, _projectB.id);
      expect(tester.state(find.byType(ProjectMediaAlbumPage)), same(state));
      expect(find.byKey(const ValueKey('album-media-all')), findsOneWidget);
      expect(find.byKey(const ValueKey('album-source-all')), findsOneWidget);
      expect(find.byKey(const ValueKey('album-context-all')), findsOneWidget);
      expect(
        find.byKey(const Key('clear-project-media-date-filter')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('project-media-album-empty')),
        findsOneWidget,
      );

      final refreshBaseline = catalog.scopedCalls.length;
      await tester.tap(find.byKey(const Key('refresh-project-media-album')));
      await tester.pumpAndSettle();
      expect(catalog.scopedCalls.length, refreshBaseline + 1);
      expect(catalog.scopedCalls.last, _projectB.id);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _tapVisible(WidgetTester tester, Key key) async {
  final target = find.byKey(key);
  final list = find.byKey(const Key('project-media-album-list'));
  final scrollable = find.descendant(
    of: list,
    matching: find.byType(Scrollable),
  );
  final state = tester.state<ScrollableState>(scrollable.first);
  while (target.evaluate().isEmpty &&
      state.position.pixels < state.position.maxScrollExtent) {
    final next = (state.position.pixels + 240)
        .clamp(state.position.minScrollExtent, state.position.maxScrollExtent)
        .toDouble();
    state.position.jumpTo(next);
    await tester.pump();
  }
  expect(target, findsOneWidget);
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _chooseDropdown(WidgetTester tester, Key key, String label) async {
  await _scrollAlbumToStart(tester);
  final dropdown = find.byKey(key);
  await tester.ensureVisible(dropdown);
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Future<void> _setDateRange(WidgetTester tester) async {
  await _scrollAlbumToStart(tester);
  final button = find.byKey(const Key('project-media-date-filter'));
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
  final dialog = find.byType(DateRangePickerDialog);
  expect(dialog, findsOneWidget);
  await tester.tap(find.descendant(of: dialog, matching: find.text('1')).last);
  await tester.pumpAndSettle();
  await tester.tap(find.descendant(of: dialog, matching: find.text('2')).last);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Uygula'));
  await tester.pumpAndSettle();
}

Future<void> _scrollAlbumToStart(WidgetTester tester) async {
  final list = find.byKey(const Key('project-media-album-list'));
  final scrollable = find.descendant(
    of: list,
    matching: find.byType(Scrollable),
  );
  final state = tester.state<ScrollableState>(scrollable.first);
  state.position.jumpTo(state.position.minScrollExtent);
  await tester.pump();
}

Future<void> _chooseSharedProject(WidgetTester tester, String projectId) async {
  await tester.tap(
    find.byKey(const Key('active-project-indicator')).hitTestable(),
  );
  await tester.pumpAndSettle();
  await tester.tap(
    find.byKey(ValueKey('active-project-option-$projectId')).hitTestable(),
  );
  await tester.pumpAndSettle();
}

ProjectAttachmentCatalogItem _item({
  required String id,
  required String mimeType,
  required AttachmentCatalogLink link,
  ManagedAttachmentIntegrity integrity = ManagedAttachmentIntegrity.healthy,
}) => ProjectAttachmentCatalogItem(
  physicalAttachmentId: id,
  relativePath: '$id.bin',
  mimeType: mimeType,
  byteSize: 68,
  sha256Value: 'hash-$id',
  createdAt: '2026-09-02T08:00:00Z',
  integrity: integrity,
  links: [link],
);

AttachmentCatalogLink _link({
  required String id,
  required AttachmentCatalogSourceType sourceType,
  required String sourceId,
  required String sourceLabel,
  required String fileName,
  bool sourceAvailable = true,
}) => AttachmentCatalogLink(
  id: id,
  sourceType: sourceType,
  sourceId: sourceId,
  sourceLabel: sourceLabel,
  role: 'evidence',
  originalFileName: fileName,
  stableLocationId: '33333333-3333-4333-8333-333333333333',
  stableLocationName: 'Blok A',
  createdAt: '2026-09-02T08:00:00Z',
  archivedAt: null,
  sourceAvailable: sourceAvailable,
);

class _MediaCatalog
    implements AttachmentCatalogApplication, AttachmentCatalogMediaAccess {
  _MediaCatalog({required this.itemsByProject});

  final Map<String, List<ProjectAttachmentCatalogItem>> itemsByProject;
  final List<String> scopedCalls = [];
  final List<ProjectAttachmentCatalogItem> readItems = [];
  final List<ProjectAttachmentCatalogItem> openedItems = [];

  @override
  Future<List<AttachmentCatalogProject>> listProjects() async => [
    AttachmentCatalogProject(id: _projectA.id, name: _projectA.name),
    AttachmentCatalogProject(id: _projectB.id, name: _projectB.name),
  ];

  @override
  Future<List<ProjectAttachmentCatalogItem>> listProjectAttachments(
    String projectId,
  ) async {
    scopedCalls.add(projectId);
    return List.unmodifiable(itemsByProject[projectId] ?? const []);
  }

  @override
  Future<ManagedAttachmentContent> readAttachment(
    ProjectAttachmentCatalogItem item,
  ) async {
    readItems.add(item);
    return ManagedAttachmentContent(
      fileName: item.displayFileName,
      mimeType: item.mimeType,
      bytes: base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      ),
    );
  }

  @override
  Future<void> openAttachment(ProjectAttachmentCatalogItem item) async {
    openedItems.add(item);
  }
}
