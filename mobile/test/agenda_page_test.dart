import 'dart:async';

import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/features/agenda/agenda_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_agenda_application.dart';

const _projectA = MobileProject(
  id: 'project-a',
  name: 'Kuzey Şantiyesi',
  createdAt: '2026-09-05T06:00:00Z',
  updatedAt: '2026-09-05T06:00:00Z',
  revision: 1,
);
const _projectB = MobileProject(
  id: 'project-b',
  name: 'Güney Şantiyesi',
  createdAt: '2026-09-05T06:00:00Z',
  updatedAt: '2026-09-05T06:00:00Z',
  revision: 1,
);

void main() {
  testWidgets('stale active-project reload cannot retarget Agenda', (
    tester,
  ) async {
    final agenda = FakeAgendaApplication(
      projects: const [_projectA, _projectB],
    );
    Widget page(String projectId) => MaterialApp(
      home: AgendaPage(agenda: agenda, activeProjectId: projectId),
    );

    await tester.pumpWidget(page(_projectA.id));
    await tester.pumpAndSettle();
    expect(agenda.lastAgendaQuery?.projectId, _projectA.id);

    final staleReload = Completer<List<MobileProject>>();
    final freshReload = Completer<List<MobileProject>>();
    agenda.listProjectsResponses.addAll([
      staleReload.future,
      freshReload.future,
    ]);

    await tester.pumpWidget(page(_projectB.id));
    await tester.pump();
    await tester.pumpWidget(page(_projectA.id));
    await tester.pump();

    freshReload.complete(const [_projectA, _projectB]);
    await tester.pumpAndSettle();
    expect(agenda.lastAgendaQuery?.projectId, _projectA.id);
    final queryCount = agenda.agendaQueries.length;

    staleReload.complete(const []);
    await tester.pumpAndSettle();
    expect(agenda.lastAgendaQuery?.projectId, _projectA.id);
    expect(agenda.agendaQueries, hasLength(queryCount));
    expect(
      find.text('Aktif proje seçilmeden Ajanda kaydı gösterilmez.'),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}
