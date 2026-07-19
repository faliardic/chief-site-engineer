import 'dart:io';

import 'package:chief_site_engineer/app.dart';
import 'package:chief_site_engineer/bootstrap/app_bootstrap.dart';
import 'package:chief_site_engineer/core/environment.dart';
import 'package:chief_site_engineer/storage/app_directories.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Android shell opens offline and local smoke record survives restart',
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
      final first = await AppBootstrap(
        environment: AppEnvironment.debug,
        directoriesProvider: () async => directories,
        databaseFactory: databaseFactory,
        clock: () => DateTime.utc(2026, 7, 19, 8),
      ).start();
      final restarted = await AppBootstrap(
        environment: AppEnvironment.debug,
        directoriesProvider: () async => directories,
        databaseFactory: databaseFactory,
        clock: () => DateTime.utc(2026, 7, 19, 9),
      ).start();

      expect(first, isA<BootstrapSuccess>());
      expect(restarted, isA<BootstrapSuccess>());
      expect(
        (restarted as BootstrapSuccess).smokeRecordCreatedAt,
        (first as BootstrapSuccess).smokeRecordCreatedAt,
      );

      await tester.pumpWidget(CseApp(bootstrap: Future.value(restarted)));
      await tester.pumpAndSettle();
      expect(find.text('Saha hafızanız cihazınızda.'), findsOneWidget);
      expect(find.text('Offline temel hazır'), findsOneWidget);
    },
  );
}
