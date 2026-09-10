import 'dart:async';
import 'dart:io';

import 'package:chief_site_engineer/application/agenda_application.dart';
import 'package:chief_site_engineer/domain/agenda_models.dart';
import 'package:chief_site_engineer/platform/notification_gateway.dart';
import 'package:chief_site_engineer/storage/app_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(sqfliteFfiInit);
  group('REM06 foreground notification handoff', () {
    const channel = MethodChannel('dexterous.com/flutter/local_notifications');
    const id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
    final calls = <MethodCall>[];
    Map<String, Object?> launch = {};
    Completer<Object?>? initializeGate;
    Completer<Object?>? launchGate;
    late _IntentAndroidPlugin android;
    setUp(() {
      calls.clear();
      launch = {'notificationLaunchedApp': false};
      initializeGate = null;
      launchGate = null;
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      android = _IntentAndroidPlugin();
      FlutterLocalNotificationsPlatform.instance = android;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            if (call.method == 'initialize') {
              return initializeGate?.future ?? true;
            }
            if (call.method == 'getNotificationAppLaunchDetails') {
              return launchGate?.future ?? launch;
            }
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
              scheduledAtUtc: '2036-09-09T06:00:00Z',
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
          expect(args['payload'], startsWith('reminder:$id|request:'));
          expect(
            (args['payload'] as String).split('|request:').last,
            matches(RegExp(r'^[0-9a-f]{64}$')),
          );
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
    test(
      'NB-01 late launch reaches the subscribed shell after one initial take',
      () async {
        initializeGate = Completer<Object?>();
        final evidence = <StartupPhaseEvent>[];
        final diagnostics = StartupPhaseDiagnostics(sink: evidence.add);
        final attempts = NotificationPlatformAttemptRegistry();
        final gateway = FlutterReminderNotificationGateway();

        Future<void> initializeWithFreshBudget() {
          final context = NotificationExecutionContext(
            budget: NotificationExecutionBudget(
              diagnostics: diagnostics,
              attempts: attempts,
              perAwaitLimit: const Duration(milliseconds: 20),
              totalLimit: const Duration(milliseconds: 60),
            ),
            origin: StartupDiagnosticOrigin.bootstrap,
          );
          return runWithNotificationExecution(context, gateway.initialize);
        }

        await expectLater(
          initializeWithFreshBudget(),
          throwsA(isA<NotificationPlatformBoundaryException>()),
        );
        expect(
          calls.where((call) => call.method == 'initialize'),
          hasLength(1),
        );
        expect(
          calls.where(
            (call) => call.method == 'getNotificationAppLaunchDetails',
          ),
          isEmpty,
        );

        initializeGate!.complete(true);
        await Future<void>.delayed(Duration.zero);
        launchGate = Completer<Object?>();
        await expectLater(
          initializeWithFreshBudget(),
          throwsA(isA<NotificationPlatformBoundaryException>()),
        );
        expect(
          calls.where((call) => call.method == 'initialize'),
          hasLength(1),
        );
        expect(
          calls.where(
            (call) => call.method == 'getNotificationAppLaunchDetails',
          ),
          hasLength(1),
        );

        final streamed = gateway.notificationIntents.first;
        expect(gateway.takeInitialNotificationIntent(), isNull);

        launchGate!.complete({
          'notificationLaunchedApp': true,
          'notificationResponse': {
            'notificationResponseType': 0,
            'payload': 'reminder:$id',
          },
        });
        final intent = await streamed;
        expect(intent.reminderId, id);
        expect(intent.action, ReminderNotificationAction.openDetail);
        expect(gateway.takeInitialNotificationIntent(), isNull);
        await initializeWithFreshBudget();
        expect(gateway.takeInitialNotificationIntent(), isNull);
        expect(
          evidence.where(
            (event) => event.outcome == StartupPhaseOutcome.timedOut,
          ),
          hasLength(2),
        );
      },
    );
    test(
      'NB-01 newer foreground intent suppresses late launch replay',
      () async {
        launchGate = Completer<Object?>();
        final gateway = FlutterReminderNotificationGateway();
        final context = NotificationExecutionContext(
          budget: NotificationExecutionBudget(
            diagnostics: StartupPhaseDiagnostics(sink: (_) {}),
            perAwaitLimit: const Duration(milliseconds: 20),
            totalLimit: const Duration(milliseconds: 60),
          ),
          origin: StartupDiagnosticOrigin.bootstrap,
        );
        await expectLater(
          runWithNotificationExecution(context, gateway.initialize),
          throwsA(isA<NotificationPlatformBoundaryException>()),
        );
        final received = <ReminderNotificationIntent>[];
        final subscription = gateway.notificationIntents.listen(received.add);
        android.foregroundCallback!(
          const NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotificationAction,
            payload: 'reminder:$id',
            actionId: FlutterReminderNotificationGateway.snoozeActionId,
          ),
        );
        launchGate!.complete({
          'notificationLaunchedApp': true,
          'notificationResponse': {
            'notificationResponseType': 0,
            'payload': 'reminder:$id',
          },
        });
        await Future<void>.delayed(Duration.zero);
        expect(received, hasLength(1));
        expect(received.single.action, ReminderNotificationAction.snooze);
        expect(gateway.takeInitialNotificationIntent(), isNull);
        await subscription.cancel();
      },
    );

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

      expect(schema, contains('static const schemaVersion = 24'));
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

  test(
    'NB-01 every non-interactive phase is bounded and fault-visible',
    () async {
      const phases = [
        StartupPhase.pluginInitialize,
        StartupPhase.launchDetails,
        StartupPhase.permissionStatus,
        StartupPhase.pendingInitial,
        StartupPhase.pendingVerification,
        StartupPhase.cancel,
        StartupPhase.schedule,
        StartupPhase.inexactFallback,
      ];
      for (final phase in phases) {
        final events = <StartupPhaseEvent>[];
        final hanging = Completer<Object?>();
        final budget = NotificationExecutionBudget(
          diagnostics: StartupPhaseDiagnostics(sink: events.add),
          perAwaitLimit: const Duration(milliseconds: 1),
          totalLimit: const Duration(milliseconds: 4),
        );
        await expectLater(
          budget.awaitPlatform<Object?>(
            phase: phase,
            origin: StartupDiagnosticOrigin.backgroundReconciliation,
            operationKey: 'hang-${phase.name}',
            operation: () => hanging.future,
          ),
          throwsA(isA<NotificationPlatformBoundaryException>()),
        );
        expect(events.last.outcome, StartupPhaseOutcome.timedOut);

        final faultEvents = <StartupPhaseEvent>[];
        final faultBudget = NotificationExecutionBudget(
          diagnostics: StartupPhaseDiagnostics(sink: faultEvents.add),
        );
        await expectLater(
          faultBudget.awaitPlatform<void>(
            phase: phase,
            origin: StartupDiagnosticOrigin.backgroundReconciliation,
            operationKey: 'fault-${phase.name}',
            operation: () => Future<void>.error(StateError('private detail')),
          ),
          throwsA(isA<StateError>()),
        );
        expect(faultEvents.last.outcome, StartupPhaseOutcome.failed);
      }
    },
  );

  test(
    'NB-01 shared budget is hard-capped and starts no work after deadline',
    () async {
      var elapsed = Duration.zero;
      var calls = 0;
      final events = <StartupPhaseEvent>[];
      final budget = NotificationExecutionBudget(
        diagnostics: StartupPhaseDiagnostics(
          sink: events.add,
          elapsed: () => elapsed,
        ),
        perAwaitLimit: const Duration(seconds: 20),
        totalLimit: const Duration(seconds: 20),
      );
      expect(budget.perAwaitLimit, const Duration(seconds: 2));
      expect(budget.totalLimit, const Duration(seconds: 8));

      for (var index = 0; index < 4; index += 1) {
        await budget.awaitPlatform<void>(
          phase: StartupPhase.schedule,
          origin: StartupDiagnosticOrigin.rollingOccurrences,
          operationKey: 'aggregate-$index',
          operation: () {
            calls += 1;
            elapsed += const Duration(milliseconds: 1900);
            return Future.value();
          },
        );
      }
      await expectLater(
        budget.awaitPlatform<void>(
          phase: StartupPhase.schedule,
          origin: StartupDiagnosticOrigin.finalReconciliation,
          operationKey: 'aggregate-overrun',
          operation: () {
            calls += 1;
            elapsed += const Duration(milliseconds: 500);
            return Future.value();
          },
        ),
        throwsA(isA<NotificationPlatformBoundaryException>()),
      );
      await expectLater(
        budget.awaitPlatform<void>(
          phase: StartupPhase.schedule,
          origin: StartupDiagnosticOrigin.finalReconciliation,
          operationKey: 'must-not-start',
          operation: () {
            calls += 1;
            return Future.value();
          },
        ),
        throwsA(isA<NotificationPlatformBoundaryException>()),
      );
      expect(calls, 5);
      expect(events.last.outcome, StartupPhaseOutcome.deadlineExhausted);

      var gapElapsed = Duration.zero;
      var gapCalls = 0;
      final gapBudget = NotificationExecutionBudget(
        diagnostics: StartupPhaseDiagnostics(elapsed: () => gapElapsed),
      );
      await gapBudget.awaitPlatform<void>(
        phase: StartupPhase.pendingInitial,
        origin: StartupDiagnosticOrigin.backgroundReconciliation,
        operationKey: 'before-gap',
        operation: () async {
          gapCalls += 1;
        },
      );
      gapElapsed = const Duration(seconds: 8);
      await expectLater(
        gapBudget.awaitPlatform<void>(
          phase: StartupPhase.pendingVerification,
          origin: StartupDiagnosticOrigin.backgroundReconciliation,
          operationKey: 'after-gap',
          operation: () async {
            gapCalls += 1;
          },
        ),
        throwsA(isA<NotificationPlatformBoundaryException>()),
      );
      expect(gapCalls, 1);

      final terminalBudget = NotificationExecutionBudget(
        diagnostics: StartupPhaseDiagnostics(sink: (_) {}),
        perAwaitLimit: const Duration(milliseconds: 1),
      );
      await expectLater(
        terminalBudget.awaitPlatform<void>(
          phase: StartupPhase.schedule,
          origin: StartupDiagnosticOrigin.backgroundReconciliation,
          operationKey: 'first-timeout',
          operation: () => Completer<void>().future,
        ),
        throwsA(isA<NotificationPlatformBoundaryException>()),
      );
      var afterTimeoutCalls = 0;
      await expectLater(
        terminalBudget.awaitPlatform<void>(
          phase: StartupPhase.schedule,
          origin: StartupDiagnosticOrigin.backgroundReconciliation,
          operationKey: 'after-timeout',
          operation: () async {
            afterTimeoutCalls += 1;
          },
        ),
        throwsA(isA<NotificationPlatformBoundaryException>()),
      );
      expect(afterTimeoutCalls, 0);
    },
  );

  test(
    'NB-01 unresolved platform calls are single-flight and late-safe',
    () async {
      final registry = NotificationPlatformAttemptRegistry();
      final pending = Completer<int>();
      var calls = 0;

      NotificationExecutionBudget budget() => NotificationExecutionBudget(
        diagnostics: StartupPhaseDiagnostics(sink: (_) {}),
        attempts: registry,
        perAwaitLimit: const Duration(milliseconds: 1),
        totalLimit: const Duration(milliseconds: 3),
      );

      Future<int> wait() => budget().awaitPlatform<int>(
        phase: StartupPhase.pendingInitial,
        origin: StartupDiagnosticOrigin.backgroundReconciliation,
        operationKey: 'same-native-call',
        operation: () {
          calls += 1;
          return pending.future;
        },
      );

      await expectLater(
        wait(),
        throwsA(isA<NotificationPlatformBoundaryException>()),
      );
      await expectLater(
        wait(),
        throwsA(isA<NotificationPlatformBoundaryException>()),
      );
      expect(calls, 1);

      var changedRequestCalls = 0;
      NotificationPlatformBoundaryException? conflict;
      try {
        await budget().awaitPlatform<int>(
          phase: StartupPhase.cancel,
          origin: StartupDiagnosticOrigin.backgroundReconciliation,
          operationKey: 'cancel-same-target',
          targetKey: 'same-native-call',
          requestKey: 'changed-semantic-request',
          operation: () async {
            changedRequestCalls += 1;
            return 99;
          },
        );
      } on NotificationPlatformBoundaryException catch (error) {
        conflict = error;
      }
      expect(
        conflict?.safeErrorCode,
        StartupSafeErrorCode.platformCallInFlight,
      );
      expect(changedRequestCalls, 0);

      pending.complete(7);
      await Future<void>.delayed(Duration.zero);
      final value = await budget().awaitPlatform<int>(
        phase: StartupPhase.pendingInitial,
        origin: StartupDiagnosticOrigin.backgroundReconciliation,
        operationKey: 'same-native-call',
        operation: () {
          calls += 1;
          return Future.value(8);
        },
      );
      expect(value, 8);
      expect(calls, 2);

      final sinkFailureBudget = NotificationExecutionBudget(
        diagnostics: StartupPhaseDiagnostics(
          sink: (_) => throw StateError('diagnostic sink failed'),
        ),
      );
      expect(
        await sinkFailureBudget.awaitPlatform<int>(
          phase: StartupPhase.pendingInitial,
          origin: StartupDiagnosticOrigin.backgroundReconciliation,
          operationKey: 'sink-failure',
          operation: () async => 9,
        ),
        9,
      );
    },
  );

  test(
    'NB-01 iOS rolling resumes a verified prefix and invalidates reschedule',
    () async {
      const channel = MethodChannel(
        'dexterous.com/flutter/local_notifications',
      );
      final pending = <int, Map<String, Object?>>{};
      final cancelled = <int>[];
      var elapsed = Duration.zero;
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      FlutterLocalNotificationsPlatform.instance =
          IOSFlutterLocalNotificationsPlugin();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            final arguments = call.arguments is Map
                ? Map<Object?, Object?>.from(call.arguments as Map)
                : const <Object?, Object?>{};
            switch (call.method) {
              case 'initialize':
                return true;
              case 'getNotificationAppLaunchDetails':
                return {'notificationLaunchedApp': false};
              case 'pendingNotificationRequests':
                return pending.values.toList(growable: false);
              case 'zonedSchedule':
                final id = arguments['id']! as int;
                pending[id] = {
                  'id': id,
                  'title': arguments['title'],
                  'body': arguments['body'],
                  'payload': arguments['payload'],
                };
                elapsed += const Duration(milliseconds: 600);
                return null;
              case 'cancel':
                final id = call.arguments! as int;
                cancelled.add(id);
                pending.remove(id);
                return null;
            }
            return null;
          });
      try {
        final gateway = FlutterReminderNotificationGateway();
        const reminderId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
        final request = ReminderNotificationRequest(
          platformId: 74401,
          reminderId: reminderId,
          title: 'Saatlik zincir',
          body: 'Doğrulanmış prefix',
          scheduledAtUtc: '2036-09-09T06:00:00Z',
          repeatIntervalMinutes: 60,
        );
        Future<void> scheduleTurn(ReminderNotificationRequest value) {
          final context = NotificationExecutionContext(
            budget: NotificationExecutionBudget(
              diagnostics: StartupPhaseDiagnostics(elapsed: () => elapsed),
            ),
            origin: StartupDiagnosticOrigin.rollingOccurrences,
          );
          return runWithNotificationExecution(
            context,
            () => gateway.schedule(value),
          );
        }

        await expectLater(
          scheduleTurn(request),
          throwsA(isA<NotificationPlatformBoundaryException>()),
        );
        expect(pending.length, inInclusiveRange(1, 23));
        expect(cancelled.where((id) => id < 0), isEmpty);

        await scheduleTurn(request);
        expect(
          pending.length,
          FlutterReminderNotificationGateway.rollingRepeatOccurrenceCount,
        );
        final oldFingerprints = pending.values
            .map((item) => (item['payload']! as String).split('|request:').last)
            .toSet();
        expect(oldFingerprints, hasLength(1));

        final changed = ReminderNotificationRequest(
          platformId: 74401,
          reminderId: reminderId,
          title: 'Saatlik zincir güncellendi',
          body: 'Doğrulanmış prefix',
          scheduledAtUtc: '2036-09-09T06:00:00Z',
          repeatIntervalMinutes: 60,
        );
        await expectLater(
          scheduleTurn(changed),
          throwsA(isA<NotificationPlatformBoundaryException>()),
        );
        expect(
          cancelled.where((id) => id < 0),
          hasLength(
            FlutterReminderNotificationGateway.rollingRepeatOccurrenceCount,
          ),
        );
        expect(
          pending.values.every(
            (item) => !oldFingerprints.contains(
              (item['payload']! as String).split('|request:').last,
            ),
          ),
          isTrue,
        );
      } finally {
        debugDefaultTargetPlatformOverride = null;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      }
    },
  );

  test(
    'NB-01 application semantic phase reaches the Flutter MethodChannel await',
    () async {
      const channel = MethodChannel(
        'dexterous.com/flutter/local_notifications',
      );
      final calls = <MethodCall>[];
      final verificationGate = Completer<Object?>();
      var pendingCalls = 0;
      final temporaryRoot = await Directory.systemTemp.createTemp(
        'cse_notification_seam_',
      );
      final databasePath =
          '${temporaryRoot.path}${Platform.pathSeparator}cse.sqlite';
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      FlutterLocalNotificationsPlatform.instance = _IntentAndroidPlugin();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            if (call.method == 'initialize') return true;
            if (call.method == 'getNotificationAppLaunchDetails') {
              return {'notificationLaunchedApp': false};
            }
            if (call.method == 'pendingNotificationRequests') {
              pendingCalls += 1;
              return pendingCalls == 1 ? <Object?>[] : verificationGate.future;
            }
            if (call.method == 'zonedSchedule') return null;
            return null;
          });
      try {
        final now = DateTime.utc(2026, 9, 9, 8);
        final database = AppDatabase(
          path: databasePath,
          factory: databaseFactoryFfi,
          clock: () => now,
        );
        await database.open();
        await database.close();
        final events = <StartupPhaseEvent>[];
        final application = SqliteAgendaApplication(
          databasePath: databasePath,
          databaseFactory: databaseFactoryFfi,
          clock: () => now,
          notificationGateway: _GrantedFlutterReminderNotificationGateway(),
          notificationPerAwaitLimit: const Duration(milliseconds: 100),
          notificationTotalLimit: const Duration(seconds: 1),
          notificationDiagnostics: StartupPhaseDiagnostics(sink: events.add),
        );
        await application.createProject(
          const CreateProjectCommand(
            id: '11111111-1111-4111-8111-111111111111',
            name: 'MethodChannel şantiyesi',
          ),
        );

        await application.createReminder(
          CreateReminderCommand(
            id: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1',
            eventId: 'eeeeeeee-eeee-4eee-8eee-000000744031',
            title: 'Gerçek seam',
            kind: ReminderKind.action,
            schedule: ReminderScheduleKind.custom,
            customAttentionAt: '2036-09-09T09:00:00Z',
          ),
        );

        expect(
          pendingCalls,
          2,
          reason:
              'calls=${calls.map((call) => call.method).join(',')} '
              'events=${events.map((event) => '${event.phase.name}:${event.outcome.name}').join(',')}',
        );
        expect(
          calls.where((call) => call.method == 'zonedSchedule'),
          hasLength(1),
        );
        final timeout = events.lastWhere(
          (event) =>
              event.phase == StartupPhase.pendingVerification &&
              event.outcome == StartupPhaseOutcome.timedOut,
        );
        expect(
          timeout.origin,
          StartupDiagnosticOrigin.backgroundReconciliation,
        );
        final detail = await application.getReminderLifecycleDetail(
          'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1',
        );
        expect(detail.notification.syncState, NotificationSyncState.failed);
        expect(
          detail.notification.safeErrorCode,
          'native_result_unknown_timeout',
        );
      } finally {
        if (!verificationGate.isCompleted) {
          verificationGate.complete(<Object?>[]);
        }
        await Future<void>.delayed(Duration.zero);
        debugDefaultTargetPlatformOverride = null;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
        if (await temporaryRoot.exists()) {
          await temporaryRoot.delete(recursive: true);
        }
      }
    },
  );

  test(
    'NB-01 Flutter seam preserves target lock and semantic diagnostics phases',
    () async {
      const channel = MethodChannel(
        'dexterous.com/flutter/local_notifications',
      );
      final calls = <MethodCall>[];
      Completer<Object?>? platformGate;
      var failSchedule = false;
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      FlutterLocalNotificationsPlatform.instance = _IntentAndroidPlugin();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            if (call.method == 'initialize') return true;
            if (call.method == 'getNotificationAppLaunchDetails') {
              return {'notificationLaunchedApp': false};
            }
            if (call.method == 'pendingNotificationRequests') {
              return platformGate?.future ?? <Object?>[];
            }
            if (call.method == 'zonedSchedule') {
              if (failSchedule) {
                throw PlatformException(code: 'synthetic-failure');
              }
              return platformGate?.future;
            }
            return null;
          });
      try {
        final gateway = FlutterReminderNotificationGateway();
        await gateway.initialize();
        final pendingEvents = <StartupPhaseEvent>[];
        platformGate = Completer<Object?>();
        final pendingContext =
            NotificationExecutionContext(
              budget: NotificationExecutionBudget(
                diagnostics: StartupPhaseDiagnostics(sink: pendingEvents.add),
                perAwaitLimit: const Duration(milliseconds: 2),
              ),
              origin: StartupDiagnosticOrigin.finalReconciliation,
            ).forPlatformCall(
              StartupPhase.pendingVerification,
              'pending-verification',
            );
        await expectLater(
          runWithNotificationExecution(
            pendingContext,
            gateway.pendingNotifications,
          ),
          throwsA(isA<NotificationPlatformBoundaryException>()),
        );
        expect(pendingEvents.last.phase, StartupPhase.pendingVerification);
        expect(pendingEvents.last.outcome, StartupPhaseOutcome.timedOut);
        expect(
          pendingEvents.last.origin,
          StartupDiagnosticOrigin.finalReconciliation,
        );
        platformGate.complete(<Object?>[]);
        await Future<void>.delayed(Duration.zero);

        calls.clear();
        platformGate = Completer<Object?>();
        final targetAttempts = NotificationPlatformAttemptRegistry();
        final request = ReminderNotificationRequest(
          platformId: 74402,
          reminderId: 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
          title: 'Target lock',
          body: 'Semantic request',
          scheduledAtUtc: '2036-09-09T06:00:00Z',
        );
        final scheduleContext = NotificationExecutionContext(
          budget: NotificationExecutionBudget(
            diagnostics: StartupPhaseDiagnostics(sink: (_) {}),
            attempts: targetAttempts,
            perAwaitLimit: const Duration(milliseconds: 2),
          ),
          origin: StartupDiagnosticOrigin.backgroundReconciliation,
        ).forPlatformCall(StartupPhase.schedule, 'schedule:74402');
        await expectLater(
          runWithNotificationExecution(
            scheduleContext,
            () => gateway.schedule(request),
          ),
          throwsA(isA<NotificationPlatformBoundaryException>()),
        );
        final cancelContext = NotificationExecutionContext(
          budget: NotificationExecutionBudget(
            diagnostics: StartupPhaseDiagnostics(sink: (_) {}),
            attempts: targetAttempts,
          ),
          origin: StartupDiagnosticOrigin.backgroundReconciliation,
        ).forPlatformCall(StartupPhase.cancel, 'cancel:74402');
        NotificationPlatformBoundaryException? conflict;
        try {
          await runWithNotificationExecution(
            cancelContext,
            () => gateway.cancel(74402),
          );
        } on NotificationPlatformBoundaryException catch (error) {
          conflict = error;
        }
        expect(
          conflict?.safeErrorCode,
          StartupSafeErrorCode.platformCallInFlight,
        );
        expect(calls.where((call) => call.method == 'cancel'), isEmpty);
        platformGate.complete(null);
        await Future<void>.delayed(Duration.zero);

        failSchedule = true;
        final fallbackEvents = <StartupPhaseEvent>[];
        final fallbackContext = NotificationExecutionContext(
          budget: NotificationExecutionBudget(
            diagnostics: StartupPhaseDiagnostics(sink: fallbackEvents.add),
          ),
          origin: StartupDiagnosticOrigin.finalReconciliation,
        ).forPlatformCall(StartupPhase.inexactFallback, 'fallback:74402');
        await expectLater(
          runWithNotificationExecution(
            fallbackContext,
            () => gateway.scheduleInexactFallback(request),
          ),
          throwsA(isA<PlatformException>()),
        );
        expect(fallbackEvents.last.phase, StartupPhase.inexactFallback);
        expect(fallbackEvents.last.outcome, StartupPhaseOutcome.failed);
        expect(
          fallbackEvents.last.safeErrorCode,
          StartupSafeErrorCode.platformFailure,
        );
      } finally {
        debugDefaultTargetPlatformOverride = null;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      }
    },
  );
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

class _GrantedFlutterReminderNotificationGateway
    extends FlutterReminderNotificationGateway {
  @override
  Future<NotificationPermissionState> permissionStatus() async =>
      NotificationPermissionState.granted;

  @override
  Future<NotificationPermissionState> requestPermission() async =>
      NotificationPermissionState.granted;
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
