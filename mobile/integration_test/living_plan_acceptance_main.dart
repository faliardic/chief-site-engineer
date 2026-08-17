import 'dart:async';

import 'package:chief_site_engineer/app.dart';
import 'package:chief_site_engineer/bootstrap/app_bootstrap.dart';
import 'package:chief_site_engineer/core/environment.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/storage/app_directories.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import 'support/living_plan_acceptance_fixture.dart';

const cseLivingPlanAcceptanceEntrypointMarker =
    'CSE_ENTRYPOINT_LIVING_PLAN_ACCEPTANCE_V1';
const livingPlanAcceptanceEnvironmentLabel = 'Kabul ortamı · sentetik veri';

Future<void> main() async {
  final fatalErrors = ValueNotifier<String?>(null);
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      CseTimeCodec.initialize();
      debugPrint(cseLivingPlanAcceptanceEntrypointMarker);
      FlutterError.onError = (_) {
        fatalErrors.value = 'flutter_framework_error';
      };
      PlatformDispatcher.instance.onError = (_, _) {
        fatalErrors.value = 'uncaught_platform_error';
        return true;
      };
      ErrorWidget.builder = (_) =>
          const SafeDiagnosticPanel(code: 'widget_render_error');

      try {
        final environment = AppEnvironment.current();
        final directories = AppDirectories.fromSupportRoot(
          await getApplicationSupportDirectory(),
          environment,
        );
        await ensureLivingPlanAcceptanceFixture(
          directories: directories,
          databaseFactory: sqflite.databaseFactory,
          clock: () => DateTime.now().toUtc(),
        );
        runApp(
          CseApp(
            bootstrap: AppBootstrap.production().start(),
            fatalErrors: fatalErrors,
            environmentLabel: livingPlanAcceptanceEnvironmentLabel,
          ),
        );
      } on Object {
        runApp(
          const MaterialApp(
            title: CseApp.productName,
            home: Scaffold(
              body: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(livingPlanAcceptanceEnvironmentLabel),
                    ),
                    Expanded(
                      child: SafeDiagnosticPanel(
                        code: 'acceptance_fixture_failed',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    },
    (_, _) {
      fatalErrors.value = 'uncaught_async_error';
    },
  );
}
