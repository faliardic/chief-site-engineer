import 'dart:io';

import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/platform/notification_gateway.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('REM06 foreground notification handoff', () {
    const channel = MethodChannel('dexterous.com/flutter/local_notifications');
    const id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
    final calls = <MethodCall>[];
    Map<String, Object?> launch = {};
    late _IntentAndroidPlugin android;
    setUp(() {
      calls.clear();
      launch = {'notificationLaunchedApp': false};
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      android = _IntentAndroidPlugin();
      FlutterLocalNotificationsPlatform.instance = android;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            if (call.method == 'initialize') return true;
            if (call.method == 'getNotificationAppLaunchDetails') return launch;
            return null;
          });
    });
    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });
    for (final repeat in [null, 60]) {
      test(
        'one visible non-cancelling Ertele action, repeat=$repeat',
        () async {
          final gateway = FlutterReminderNotificationGateway();
          await gateway.schedule(
            ReminderNotificationRequest(
              platformId: 123,
              reminderId: id,
              title: 'Başlık',
              body: 'Aynı içerik',
              scheduledAtUtc: '2026-09-09T06:00:00Z',
              repeatIntervalMinutes: repeat,
            ),
          );
          final call = calls.singleWhere(
            (c) =>
                c.method ==
                (repeat == null
                    ? 'zonedSchedule'
                    : 'periodicallyShowWithDuration'),
          );
          final args = call.arguments as Map;
          expect(args['payload'], 'reminder:$id');
          expect(args['title'], 'Başlık');
          expect(args['body'], 'Aynı içerik');
          final platform = args['platformSpecifics'] as Map;
          final actions = platform['actions'] as List;
          expect(actions, hasLength(1));
          final action = actions.single as Map;
          expect(
            action['id'],
            FlutterReminderNotificationGateway.snoozeActionId,
          );
          expect(action['title'], 'Ertele');
          expect(action['showsUserInterface'], isTrue);
          expect(action['cancelNotification'], isFalse);
          expect(action['invisible'], isFalse);
          expect(android.backgroundCallback, isNull);
          expect(calls.any((c) => c.method == 'cancel'), isFalse);
        },
      );
    }
    test(
      'REM06 application forwards typed intents without opening persistence',
      () async {
        launch = {
          'notificationLaunchedApp': true,
          'notificationResponse': {
            'notificationResponseType': 1,
            'payload': 'reminder:$id',
            'actionId': FlutterReminderNotificationGateway.snoozeActionId,
          },
        };
        final gateway = FlutterReminderNotificationGateway();
        await gateway.initialize();
        final app = SqliteAgendaApplication(
          databasePath: 'unused-notification-handoff',
          databaseFactory: _NoNotificationDatabase(),
          clock: () => DateTime.utc(2026, 9, 7),
          notificationGateway: gateway,
        );
        final initial = app.takeInitialNotificationIntent()!;
        expect(initial.reminderId, id);
        expect(initial.action, ReminderNotificationAction.snooze);
        expect(app.takeInitialNotificationIntent(), isNull);
        final next = app.notificationIntents.first;
        android.foregroundCallback!(
          const NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotificationAction,
            payload: 'reminder:$id',
            actionId: FlutterReminderNotificationGateway.snoozeActionId,
          ),
        );
        expect((await next).action, ReminderNotificationAction.snooze);
        expect(calls.map((c) => c.method), [
          'initialize',
          'getNotificationAppLaunchDetails',
        ]);
      },
    );
    test(
      'REM06 application preserves legacy body intents with once-only launch',
      () async {
        final app = SqliteAgendaApplication(
          databasePath: 'unused-notification-handoff',
          databaseFactory: _NoNotificationDatabase(),
          clock: () => DateTime.utc(2026, 9, 7),
          notificationGateway: _LegacyBodyGateway(),
        );
        expect(
          app.takeInitialNotificationIntent()?.action,
          ReminderNotificationAction.openDetail,
        );
        expect(app.takeInitialNotificationIntent(), isNull);
        final intent = await app.notificationIntents.first;
        expect(intent.reminderId, id);
        expect(intent.action, ReminderNotificationAction.openDetail);
      },
    );
    for (final action in ReminderNotificationAction.values) {
      test('cold launch preserves $action and is consumed once', () async {
        launch = {
          'notificationLaunchedApp': true,
          'notificationResponse': {
            'notificationId': 123,
            'payload': 'reminder:$id',
            'notificationResponseType':
                action == ReminderNotificationAction.snooze ? 1 : 0,
            'actionId': action == ReminderNotificationAction.snooze
                ? FlutterReminderNotificationGateway.snoozeActionId
                : null,
          },
        };
        final gateway = FlutterReminderNotificationGateway();
        await gateway.initialize();
        if (action == ReminderNotificationAction.snooze) {
          expect(gateway.initialTapReminderId, isNull);
        }
        final intent = gateway.takeInitialNotificationIntent()!;
        expect(intent.reminderId, id);
        expect(intent.action, action);
        expect(gateway.takeInitialNotificationIntent(), isNull);
        await gateway.initialize();
        expect(gateway.takeInitialNotificationIntent(), isNull);
      });
    }
    test(
      'running responses distinguish body, Ertele and invalid actions',
      () async {
        final gateway = FlutterReminderNotificationGateway();
        await gateway.initialize();
        final intents = <ReminderNotificationIntent>[];
        final legacy = <String>[];
        final typedSubscription = gateway.notificationIntents.listen(
          intents.add,
        );
        final legacySubscription = gateway.notificationTaps.listen(legacy.add);
        android.foregroundCallback!(
          const NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotification,
            payload: 'reminder:$id',
          ),
        );
        android.foregroundCallback!(
          const NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotificationAction,
            payload: 'reminder:$id',
            actionId: FlutterReminderNotificationGateway.snoozeActionId,
          ),
        );
        for (final payload in ['reminder:invalid', 'other:$id']) {
          android.foregroundCallback!(
            NotificationResponse(
              notificationResponseType:
                  NotificationResponseType.selectedNotificationAction,
              payload: payload,
              actionId: FlutterReminderNotificationGateway.snoozeActionId,
            ),
          );
        }
        android.foregroundCallback!(
          const NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotificationAction,
            payload: 'reminder:$id',
            actionId: 'unknown-action',
          ),
        );
        await Future<void>.delayed(Duration.zero);
        expect(intents.map((i) => i.reminderId), [id, id]);
        expect(intents.map((i) => i.action), ReminderNotificationAction.values);
        expect(legacy, [id]);
        expect(calls.map((c) => c.method), [
          'initialize',
          'getNotificationAppLaunchDetails',
        ]);
        await typedSubscription.cancel();
        await legacySubscription.cancel();
      },
    );
    test(
      'response during bootstrap is retained without becoming a body tap',
      () async {
        final gateway = FlutterReminderNotificationGateway();
        await gateway.initialize();
        android.foregroundCallback!(
          const NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotificationAction,
            payload: 'reminder:$id',
            actionId: FlutterReminderNotificationGateway.snoozeActionId,
          ),
        );
        expect(
          gateway.takeInitialNotificationIntent()?.action,
          ReminderNotificationAction.snooze,
        );
        expect(gateway.takeInitialNotificationIntent(), isNull);
        expect(gateway.initialTapReminderId, isNull);
      },
    );
    test('iOS does not acquire an Android Ertele intent', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      FlutterLocalNotificationsPlatform.instance =
          IOSFlutterLocalNotificationsPlugin();
      launch = {
        'notificationLaunchedApp': true,
        'notificationResponse': {
          'notificationResponseType': 1,
          'payload': 'reminder:$id',
          'actionId': FlutterReminderNotificationGateway.snoozeActionId,
        },
      };
      final gateway = FlutterReminderNotificationGateway();
      await gateway.initialize();
      expect(gateway.takeInitialNotificationIntent(), isNull);
    });
    test('gateway installs no background callback or mutation path', () {
      final source = File(
        'lib/platform/notification_gateway.dart',
      ).readAsStringSync();
      expect(
        source,
        isNot(contains('onDidReceiveBackgroundNotificationResponse')),
      );
      expect(source, isNot(contains('mutateReminder')));
    });
  });
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
      expect(
        receiver,
        contains(
          'com.dexterous.flutterlocalnotifications.'
          'ScheduledNotificationBootReceiver',
        ),
      );
      expect(receiver, contains('.asSubclass(BroadcastReceiver.class)'));
      expect(receiver, contains('.getDeclaredConstructor().newInstance()'));
      expect(receiver, contains('receiver.onReceive(context, intent)'));
      expect(
        receiver,
        isNot(
          contains('FlutterLocalNotificationsPlugin.rescheduleNotifications'),
        ),
      );
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
      expect(project, contains('com.faliardic.sefim'));
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

      expect(schema, contains('static const schemaVersion = 23'));
      expect(schema, contains('CREATE TABLE workforce_members'));
      expect(schema, contains('CREATE TABLE attendance_days'));
      expect(schema, contains('CREATE TABLE attendance_entries'));
      expect(schema, contains('CREATE TABLE attendance_events'));
      expect(schema, contains('CREATE TABLE concrete_pours'));
      expect(schema, contains('CREATE TABLE managed_attachments'));
      expect(schema, contains('CREATE TABLE attachment_links'));
      expect(schema, contains('CREATE TABLE attachment_link_events'));
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

class _IntentAndroidPlugin extends AndroidFlutterLocalNotificationsPlugin {
  DidReceiveNotificationResponseCallback? foregroundCallback;
  DidReceiveBackgroundNotificationResponseCallback? backgroundCallback;

  @override
  Future<bool> initialize({
    required AndroidInitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback?
    onDidReceiveBackgroundNotificationResponse,
  }) {
    foregroundCallback = onDidReceiveNotificationResponse;
    backgroundCallback = onDidReceiveBackgroundNotificationResponse;
    return super.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          onDidReceiveBackgroundNotificationResponse,
    );
  }
}

class _NoNotificationDatabase implements DatabaseFactory {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Notification handoff must not access persistence');
}

class _LegacyBodyGateway extends UnavailableReminderNotificationGateway {
  @override
  String? get initialTapReminderId => 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
  @override
  Stream<String> get notificationTaps => Stream.value(initialTapReminderId!);
}
