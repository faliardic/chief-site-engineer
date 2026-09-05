import 'dart:async';

import 'package:chief_site_engineer/app.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/features/agenda/agenda_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_agenda_application.dart';

void main() {
  testWidgets(
    'project creation waits for fresh projects and rejects stale reload',
    (tester) async {
      final agenda = FakeAgendaApplication();
      await tester.pumpWidget(MaterialApp(home: AgendaPage(agenda: agenda)));
      await tester.pumpAndSettle();

      final initialAgendaQueryCount = agenda.agendaQueries.length;
      final staleProjectReload = Completer<List<MobileProject>>();
      final freshProjectReload = Completer<List<MobileProject>>();
      agenda.listProjectsResponses.addAll([
        staleProjectReload.future,
        freshProjectReload.future,
      ]);

      FlutterErrorDetails? renderFailure;
      final previousErrorWidgetBuilder = ErrorWidget.builder;
      ErrorWidget.builder = (details) {
        renderFailure = details;
        return const SafeDiagnosticPanel(code: 'widget_render_error');
      };

      Future<DropdownButton<String?>> projectDropdown() async {
        // Let the preceding dialog finish closing while project reads remain
        // deliberately pending, then use the current filter-panel surface.
        await tester.pump(const Duration(milliseconds: 300));
        final filters = find.byKey(const Key('agenda-filter-action'));
        expect(filters.hitTestable(), findsOneWidget);
        await tester.tap(filters.hitTestable());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        final dropdown = tester.widget<DropdownButton<String?>>(
          find.descendant(
            of: find.byKey(const Key('agenda-project-filter')),
            matching: find.byType(DropdownButton<String?>),
          ),
        );
        await tester.tap(find.byKey(const Key('agenda-filter-cancel')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        return dropdown;
      }

      try {
        await tester.tap(find.byKey(const Key('create-agenda-project')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('agenda-project-name')),
          'Gecikmeli Yeni Proje',
        );
        await tester.tap(find.byKey(const Key('save-agenda-project')));
        for (
          var index = 0;
          index < 10 && agenda.listProjectsCalls < 3;
          index += 1
        ) {
          await tester.pump();
        }

        expect(agenda.listProjectsCalls, 3);
        expect(agenda.projects, hasLength(1));
        final createdProject = agenda.projects.single;
        var dropdown = await projectDropdown();
        expect(dropdown.value, isNull);
        expect(
          dropdown.items!.where((item) => item.value == createdProject.id),
          isEmpty,
        );
        expect(find.byType(SafeDiagnosticPanel), findsNothing);
        expect(renderFailure, isNull);
        expect(tester.takeException(), isNull);

        freshProjectReload.complete(List.unmodifiable(agenda.projects));
        for (var index = 0; index < 10; index += 1) {
          await tester.pump();
          dropdown = await projectDropdown();
          if (dropdown.value == createdProject.id) break;
        }

        dropdown = await projectDropdown();
        expect(dropdown.value, createdProject.id);
        expect(
          dropdown.items!.where((item) => item.value == createdProject.id),
          hasLength(1),
        );
        expect(
          agenda.agendaQueries.skip(initialAgendaQueryCount),
          everyElement(
            isA<AgendaQuery>().having(
              (query) => query.projectId,
              'projectId',
              createdProject.id,
            ),
          ),
        );

        staleProjectReload.complete(const []);
        await tester.pumpAndSettle();

        dropdown = await projectDropdown();
        expect(dropdown.value, createdProject.id);
        expect(
          dropdown.items!.where((item) => item.value == createdProject.id),
          hasLength(1),
        );
        expect(
          agenda.projects.where((item) => item.id == createdProject.id),
          hasLength(1),
        );
        expect(agenda.lastAgendaQuery?.projectId, createdProject.id);
        expect(agenda.agendaQueries, hasLength(initialAgendaQueryCount + 1));
        expect(find.byType(SafeDiagnosticPanel), findsNothing);
      } finally {
        if (!freshProjectReload.isCompleted) {
          freshProjectReload.complete(List.unmodifiable(agenda.projects));
        }
        if (!staleProjectReload.isCompleted) {
          staleProjectReload.complete(const []);
        }
        ErrorWidget.builder = previousErrorWidgetBuilder;
      }

      expect(renderFailure, isNull);
      expect(tester.takeException(), isNull);
    },
  );
}
