import 'dart:io';

import 'package:chief_site_engineer/app.dart';
import 'package:chief_site_engineer/bootstrap/app_bootstrap.dart';
import 'package:chief_site_engineer/core/environment.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/storage/app_directories.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Android offline agenda and linked reminder survive application restart',
    (tester) async {
      final temporaryRoot = await Directory.systemTemp.createTemp(
        'cse_mobile_integration_',
      );
      addTearDown(() async {
        if (await temporaryRoot.exists()) {
          await temporaryRoot.delete(recursive: true);
        }
      });
      final directories = AppDirectories.fromSupportRoot(
        temporaryRoot,
        AppEnvironment.debug,
      );
      final observedAt = CseTimeCodec.encodeUtc(DateTime.now().toUtc());
      final first = await AppBootstrap(
        environment: AppEnvironment.debug,
        directoriesProvider: () async => directories,
        databaseFactory: databaseFactory,
        clock: () => DateTime.now().toUtc(),
      ).start();
      expect(first, isA<BootstrapSuccess>());
      final firstSuccess = first as BootstrapSuccess;
      await firstSuccess.agenda.createProject(
        const CreateProjectCommand(
          id: '11111111-1111-4111-8111-111111111111',
          name: 'Emülatör Şantiyesi',
        ),
      );
      final log = await firstSuccess.agenda.createAgendaLog(
        CreateAgendaLogCommand(
          id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1',
          eventId: 'eeeeeeee-eeee-4eee-8eee-000000000001',
          projectId: '11111111-1111-4111-8111-111111111111',
          observedAt: observedAt,
          category: AgendaCategory.inspection,
          description: 'Android offline Ajanda kaydı',
          location: 'A Blok',
        ),
      );
      await firstSuccess.agenda.createReminder(
        CreateReminderCommand(
          id: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1',
          eventId: 'eeeeeeee-eeee-4eee-8eee-000000000002',
          projectId: log.projectId,
          sourceLogId: log.id,
          title: 'Android offline reminder',
          kind: ReminderKind.action,
          schedule: ReminderScheduleKind.inbox,
        ),
      );
      final restarted = await AppBootstrap(
        environment: AppEnvironment.debug,
        directoriesProvider: () async => directories,
        databaseFactory: databaseFactory,
        clock: () => DateTime.now().toUtc(),
      ).start();
      expect(restarted, isA<BootstrapSuccess>());
      expect(
        (restarted as BootstrapSuccess).smokeRecordCreatedAt,
        firstSuccess.smokeRecordCreatedAt,
      );
      final restartedSuccess = restarted;
      final persisted = await restartedSuccess.agenda.getAgendaLogDetail(
        log.id,
      );
      expect(persisted.log.description, 'Android offline Ajanda kaydı');
      expect(persisted.reminders.single.title, 'Android offline reminder');
      final observedDay = CseTimeCodec.istanbulDayKey(observedAt);
      final restartedDay = await restartedSuccess.agenda.listAgenda(
        AgendaQuery(istanbulDay: observedDay),
      );
      expect(restartedDay.single.id, log.id);

      await tester.pumpWidget(
        CseApp(bootstrap: Future.value(restartedSuccess)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Saha hafızanız cihazınızda.'), findsOneWidget);
      expect(find.text('Offline temel hazır'), findsOneWidget);
      await tester.tap(find.text('Ajanda').last);
      await tester.pumpAndSettle();
      expect(find.text(observedDay), findsOneWidget);
      await tester.drag(
        find.byKey(const Key('agenda-day-list')),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();
      expect(find.text('Android offline Ajanda kaydı'), findsOneWidget);
      await tester.tap(find.text('Hatırlatıcı').last);
      await tester.pumpAndSettle();
      await tester.drag(
        find.byKey(const Key('reminder-list')),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();
      expect(find.text('Android offline reminder'), findsOneWidget);
    },
  );
}
