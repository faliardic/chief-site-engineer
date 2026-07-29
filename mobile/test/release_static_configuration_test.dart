import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Turkish Flutter SDK localization dependency and root config are exact',
    () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final normalizedPubspec = pubspec
          .replaceAll('\r\n', '\n')
          .replaceAll('\r', '\n');
      final app = File('lib/app.dart').readAsStringSync();

      expect(
        normalizedPubspec,
        contains('flutter_localizations:\n    sdk: flutter'),
      );
      expect(app, contains("static const locale = Locale('tr');"));
      expect(
        app,
        contains('static const supportedLocales = <Locale>[locale];'),
      );
      expect(app, contains('GlobalMaterialLocalizations.delegate'));
      expect(app, contains('GlobalWidgetsLocalizations.delegate'));
      expect(app, contains('GlobalCupertinoLocalizations.delegate'));
      expect(app, isNot(contains("Locale('en")));
      expect(pubspec, isNot(contains('easy_localization')));
      expect(pubspec, isNot(contains('intl_utils')));
    },
  );

  test('Android release identity API and permission contract is exact', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final permissions = RegExp(
      r'<uses-permission android:name="([^"]+)"',
    ).allMatches(manifest).map((match) => match.group(1)).toSet();

    expect(gradle, contains('compileSdk = 36'));
    expect(gradle, contains('targetSdk = 36'));
    expect(gradle, contains('ndkVersion = "28.2.13676358"'));
    expect(gradle, contains('CSE_ACCEPTANCE_HARNESS'));
    expect(gradle, contains('".acceptance" else ".debug"'));
    expect(gradle, contains('CSE_KEY_PROPERTIES_FILE'));
    expect(permissions, {
      'android.permission.CAMERA',
      'android.permission.POST_NOTIFICATIONS',
      'android.permission.RECEIVE_BOOT_COMPLETED',
      'android.permission.SCHEDULE_EXACT_ALARM',
    });
    expect(manifest, contains('android:allowBackup="false"'));
    expect(manifest, contains('android:usesCleartextTraffic="false"'));
    expect(RegExp('tools:node="remove"').allMatches(manifest), hasLength(4));
    expect(manifest, isNot(contains('USE_EXACT_ALARM')));
    expect(manifest, isNot(contains('FOREGROUND_SERVICE')));
    expect(manifest, isNot(contains('android.permission.INTERNET')));
  });

  test('field sidecar and synthetic entrypoints are fail-closed isolated', () {
    final mainSource = File('lib/main.dart').readAsStringSync();
    final deliverySource = File(
      'integration_test/background_delivery_sidecar_main.dart',
    ).readAsStringSync();
    final rebootSource = File(
      'integration_test/background_reboot_sidecar_main.dart',
    ).readAsStringSync();
    final gate = File('../scripts/release_gate.ps1').readAsStringSync();
    final acceptanceBuild = File(
      '../scripts/build_mobile_acceptance_apks.ps1',
    ).readAsStringSync();

    expect(mainSource, contains('CSE_ENTRYPOINT_NORMAL_LIB_MAIN_DART_V1'));
    expect(deliverySource, contains('CSE_ENTRYPOINT_BACKGROUND_ACCEPTANCE_V1'));
    expect(rebootSource, contains('CSE_ENTRYPOINT_REBOOT_ACCEPTANCE_V1'));
    expect(gate, contains("'--target', 'lib\\main.dart'"));
    expect(gate, contains('verify_flutter_apk_entrypoint.py'));
    expect(gate, contains('issue212-reminder-pilot-ux-debug.apk'));
    expect(
      acceptanceBuild,
      contains('issue207-background-acceptance-debug.apk'),
    );
    expect(acceptanceBuild, contains('issue207-reboot-acceptance-debug.apk'));
    expect(acceptanceBuild, contains('android-arm64,android-x64'));
  });

  test('iOS privacy manifest and archive target are statically wired', () {
    final privacy = File('ios/Runner/PrivacyInfo.xcprivacy').readAsStringSync();
    final project = File(
      'ios/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();
    final info = File('ios/Runner/Info.plist').readAsStringSync();

    expect(privacy, contains('<key>NSPrivacyTracking</key>'));
    expect(privacy, contains('<false/>'));
    expect(privacy, contains('<key>NSPrivacyCollectedDataTypes</key>'));
    expect(project, contains('PrivacyInfo.xcprivacy in Resources'));
    expect(project, isNot(contains('TARGETED_DEVICE_FAMILY = "1,2"')));
    expect('TARGETED_DEVICE_FAMILY = 1;'.allMatches(project).length, 3);
    expect(project, contains('com.faliardic.chiefsiteengineer.debug'));
    expect(info, contains(r'<string>$(APP_DISPLAY_NAME)</string>'));
  });

  test('all declared iOS AppIcons have exact dimensions and no alpha', () {
    final root = Directory('ios/Runner/Assets.xcassets/AppIcon.appiconset');
    final contents =
        jsonDecode(File('${root.path}/Contents.json').readAsStringSync())
            as Map<String, Object?>;
    final images = contents['images']! as List<Object?>;

    for (final raw in images) {
      final image = Map<String, Object?>.from(raw! as Map);
      final fileName = image['filename'] as String?;
      if (fileName == null) continue;
      final scale = int.parse((image['scale']! as String).replaceAll('x', ''));
      final points = double.parse((image['size']! as String).split('x').first);
      final expected = (points * scale).round();
      final header = _pngHeader(File('${root.path}/$fileName'));
      expect(header.width, expected, reason: fileName);
      expect(header.height, expected, reason: fileName);
      expect(
        header.colorType,
        2,
        reason: '$fileName must be RGB without alpha',
      );
    }
  });
}

({int width, int height, int colorType}) _pngHeader(File file) {
  final bytes = file.readAsBytesSync();
  expect(bytes.sublist(0, 8), [137, 80, 78, 71, 13, 10, 26, 10]);
  final data = ByteData.sublistView(Uint8List.fromList(bytes));
  return (
    width: data.getUint32(16),
    height: data.getUint32(20),
    colorType: data.getUint8(25),
  );
}
