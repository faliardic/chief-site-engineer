import 'dart:async';

import 'package:chief_site_engineer/app.dart';
import 'package:chief_site_engineer/bootstrap/app_bootstrap.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

const cseNormalEntrypointMarker = 'CSE_ENTRYPOINT_NORMAL_LIB_MAIN_DART_V1';

Future<void> main() async {
  final fatalErrors = ValueNotifier<String?>(null);
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      debugPrint(cseNormalEntrypointMarker);
      CseTimeCodec.initialize();
      FlutterError.onError = (_) {
        fatalErrors.value = 'flutter_framework_error';
      };
      PlatformDispatcher.instance.onError = (_, _) {
        fatalErrors.value = 'uncaught_platform_error';
        return true;
      };
      ErrorWidget.builder = (_) =>
          const SafeDiagnosticPanel(code: 'widget_render_error');
      runApp(
        CseApp(
          bootstrap: AppBootstrap.production().start(),
          fatalErrors: fatalErrors,
        ),
      );
    },
    (_, _) {
      fatalErrors.value = 'uncaught_async_error';
    },
  );
}
