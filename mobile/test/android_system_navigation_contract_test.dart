import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('entrypoint enables edge-to-edge before runApp', () {
    final mainSource = _source('lib/main.dart');
    final bindingIndex = mainSource.indexOf(
      'WidgetsFlutterBinding.ensureInitialized();',
    );
    final edgeToEdgeIndex = mainSource.indexOf(
      'await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);',
    );
    final runAppIndex = mainSource.indexOf('runApp(');

    expect(bindingIndex, greaterThanOrEqualTo(0));
    expect(edgeToEdgeIndex, greaterThan(bindingIndex));
    expect(runAppIndex, greaterThan(edgeToEdgeIndex));
    expect(mainSource, isNot(contains('SystemUiMode.manual')));
  });

  test(
    'Android opts into predictive Back and retains resize configuration',
    () {
      final manifest = _source('android/app/src/main/AndroidManifest.xml');

      expect(manifest, contains('android:enableOnBackInvokedCallback="true"'));
      final configChanges = RegExp(
        r'android:configChanges="([^"]+)"',
      ).firstMatch(manifest);
      expect(configChanges, isNotNull);
      final configuredChanges = configChanges!.group(1)!.split('|');
      expect(
        configuredChanges,
        orderedEquals(<String>[
          'orientation',
          'keyboardHidden',
          'keyboard',
          'screenSize',
          'smallestScreenSize',
          'locale',
          'layoutDirection',
          'fontScale',
          'screenLayout',
          'density',
          'uiMode',
        ]),
      );
      expect(manifest, isNot(contains('android:screenOrientation')));
      expect(manifest, isNot(contains('android:onBackPressed')));
    },
  );

  test('shell keeps safe insets without legacy Back interception', () {
    final appSource = _source('lib/app.dart');
    final activitySource = _source(
      'android/app/src/main/kotlin/com/faliardic/chiefsiteengineer/'
      'MainActivity.kt',
    );

    expect(appSource, contains('body: SafeArea('));
    expect(appSource, isNot(contains('extendBody: true')));
    expect(appSource, isNot(contains('extendBodyBehindAppBar: true')));
    expect(appSource, isNot(contains('WillPopScope')));
    expect(activitySource, isNot(contains('onBackPressed')));
    expect(activitySource, isNot(contains('OnBackInvoked')));
    expect(activitySource, isNot(contains('KEYCODE_BACK')));
  });
}

String _source(String path) =>
    File(path).readAsStringSync().replaceAll('\r\n', '\n');
