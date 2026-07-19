import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Android notification manifest uses reboot receivers without exact alarm',
    () {
      final manifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();

      expect(manifest, contains('android.permission.POST_NOTIFICATIONS'));
      expect(manifest, contains('android.permission.RECEIVE_BOOT_COMPLETED'));
      expect(manifest, contains('ScheduledNotificationReceiver'));
      expect(manifest, contains('ScheduledNotificationBootReceiver'));
      expect(manifest, isNot(contains('SCHEDULE_EXACT_ALARM')));
      expect(manifest, isNot(contains('USE_EXACT_ALARM')));
    },
  );

  test('Android build keeps notification icon and enables desugaring', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    final keep = File(
      'android/app/src/main/res/raw/keep.xml',
    ).readAsStringSync();

    expect(gradle, contains('isCoreLibraryDesugaringEnabled = true'));
    expect(gradle, contains('desugar_jdk_libs:2.1.4'));
    expect(keep, contains('@mipmap/ic_launcher'));
  });

  test(
    'iOS config delegates UserNotifications without automatic permission',
    () {
      final appDelegate = File(
        'ios/Runner/AppDelegate.swift',
      ).readAsStringSync();
      final project = File(
        'ios/Runner.xcodeproj/project.pbxproj',
      ).readAsStringSync();
      final plist = File('ios/Runner/Info.plist').readAsStringSync();
      final gateway = File(
        'lib/platform/notification_gateway.dart',
      ).readAsStringSync();

      expect(appDelegate, contains('import UserNotifications'));
      expect(
        appDelegate,
        contains('UNUserNotificationCenter.current().delegate'),
      );
      expect(gateway, contains('requestAlertPermission: false'));
      expect(gateway, contains('requestBadgePermission: false'));
      expect(gateway, contains('requestSoundPermission: false'));
      expect(gateway, contains('AndroidScheduleMode.inexactAllowWhileIdle'));
      expect(project, contains('IPHONEOS_DEPLOYMENT_TARGET = 13.0'));
      expect(project, contains('com.faliardic.chiefsiteengineer'));
      expect(plist, contains('UIApplicationSceneManifest'));
    },
  );

  test('notification dependency remains on the binding major version', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final lock = File('pubspec.lock').readAsStringSync();

    expect(pubspec, contains('flutter_local_notifications: ^22.0.1'));
    expect(lock, contains('flutter_local_notifications:'));
    expect(lock, contains('version: "22.1.0"'));
  });

  test('attendance schema and cross-platform share dependency are pinned', () {
    final schema = File('lib/storage/app_database.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final lock = File('pubspec.lock').readAsStringSync();

    expect(schema, contains('static const schemaVersion = 4'));
    expect(schema, contains('CREATE TABLE workforce_members'));
    expect(schema, contains('CREATE TABLE attendance_days'));
    expect(schema, contains('CREATE TABLE attendance_entries'));
    expect(schema, contains('CREATE TABLE attendance_events'));
    expect(pubspec, contains('share_plus: ^12.0.1'));
    expect(lock, contains('share_plus:'));
    expect(lock, contains('version: "12.0.2"'));
  });
}
