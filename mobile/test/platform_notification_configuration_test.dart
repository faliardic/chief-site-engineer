import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Android uses audited reboot reschedule and scoped exact alarm access',
    () {
      final manifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync().replaceAll('\r\n', '\n');

      expect(manifest, contains('android.permission.POST_NOTIFICATIONS'));
      expect(manifest, contains('android.permission.RECEIVE_BOOT_COMPLETED'));
      expect(manifest, contains('ScheduledNotificationReceiver'));
      expect(manifest, contains('CseReminderBootReceiver'));
      expect(manifest, contains('android.permission.CAMERA'));
      for (final permission in [
        'android.permission.READ_EXTERNAL_STORAGE',
        'android.permission.READ_MEDIA_IMAGES',
        'android.permission.READ_MEDIA_VIDEO',
        'android.permission.READ_MEDIA_AUDIO',
      ]) {
        expect(
          manifest,
          contains('android:name="$permission"\n        tools:node="remove"'),
        );
      }
      expect(manifest, isNot(contains('android.permission.INTERNET')));
      expect(manifest, contains('SCHEDULE_EXACT_ALARM'));
      expect(manifest, isNot(contains('USE_EXACT_ALARM')));
      expect(manifest, isNot(contains('FOREGROUND_SERVICE')));
      final receiver = File(
        'android/app/src/main/java/com/dexterous/flutterlocalnotifications/'
        'CseReminderBootReceiver.java',
      ).readAsStringSync();
      expect(receiver, contains('rescheduleNotifications(context)'));
      expect(receiver, contains('cse_reminder_boot_audit'));
      expect(receiver, isNot(contains('title')));
      expect(receiver, isNot(contains('body')));
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
      expect(gateway, contains('AndroidScheduleMode.exactAllowWhileIdle'));
      expect(gateway, contains('AndroidScheduleMode.inexactAllowWhileIdle'));
      expect(gateway, contains('periodicallyShowWithDuration'));
      expect(gateway, contains('repeatIntervalMinutes'));
      expect(gateway, contains('Clock.fixed(instant)'));
      expect(gateway, contains('rollingRepeatOccurrenceCount = 24'));
      expect(project, contains('IPHONEOS_DEPLOYMENT_TARGET = 13.0'));
      expect(project, contains('com.faliardic.chiefsiteengineer'));
      expect(plist, contains('UIApplicationSceneManifest'));
      expect(plist, contains('NSCameraUsageDescription'));
      expect(plist, contains('NSPhotoLibraryUsageDescription'));
    },
  );

  test('notification dependency remains on the binding major version', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final lock = File('pubspec.lock').readAsStringSync();

    expect(pubspec, contains('flutter_local_notifications: ^22.0.1'));
    expect(pubspec, contains('clock: ^1.1.2'));
    expect(lock, contains('flutter_local_notifications:'));
    expect(lock, contains('version: "22.1.0"'));
  });

  test(
    'concrete schema and cross-platform attachment dependencies are pinned',
    () {
      final schema = File('lib/storage/app_database.dart').readAsStringSync();
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final lock = File('pubspec.lock').readAsStringSync();

      expect(schema, contains('static const schemaVersion = 7'));
      expect(schema, contains('CREATE TABLE workforce_members'));
      expect(schema, contains('CREATE TABLE attendance_days'));
      expect(schema, contains('CREATE TABLE attendance_entries'));
      expect(schema, contains('CREATE TABLE attendance_events'));
      expect(schema, contains('CREATE TABLE concrete_pours'));
      expect(schema, contains('CREATE TABLE concrete_attachments'));
      expect(schema, contains('CREATE TABLE agenda_log_attachments'));
      expect(pubspec, contains('share_plus: ^12.0.1'));
      expect(pubspec, contains('image_picker: ^1.2.1'));
      expect(pubspec, contains('file_picker: ^10.3.10'));
      expect(pubspec, contains('permission_handler: ^12.0.1'));
      expect(pubspec, contains('archive: ^4.0.9'));
      expect(pubspec, contains('cryptography: ^2.9.0'));
      expect(pubspec, contains('open_filex: ^4.7.0'));
      expect(pubspec, contains('pdf: ^3.11.3'));
      expect(pubspec, contains('assets/fonts/Roboto-Regular.ttf'));
      expect(lock, contains('share_plus:'));
      expect(lock, contains('version: "12.0.2"'));
      expect(lock, contains('archive:'));
      expect(lock, contains('cryptography:'));
      expect(lock, contains('open_filex:'));
      expect(lock, contains('pdf:'));
    },
  );

  test('backup picker imports streams into app-private incoming storage', () {
    final gateway = File(
      'lib/platform/mobile_backup_gateway.dart',
    ).readAsStringSync();
    final application = File(
      'lib/application/mobile_backup_application.dart',
    ).readAsStringSync();
    final directories = File(
      'lib/storage/app_directories.dart',
    ).readAsStringSync();

    expect(gateway, contains('withReadStream: true'));
    expect(gateway, contains('maximumPackageBytes = 512 * 1024 * 1024'));
    expect(gateway, contains('await partial.create(exclusive: true)'));
    expect(gateway, contains('await partial.rename(destination.path)'));
    expect(application, contains('PickedBackupPackage package'));
    expect(application, contains('_requireAllowedPackage(package)'));
    expect(
      directories,
      contains("path.join(staging.path, 'incoming_backups')"),
    );
  });
}
