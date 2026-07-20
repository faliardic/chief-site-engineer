import 'package:chief_site_engineer/platform/notification_gateway.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

const _channel = MethodChannel('dexterous.com/flutter/local_notifications');
const _reminderId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final calls = <MethodCall>[];
  final pending = <Map<String, Object?>>[];

  setUp(() {
    calls.clear();
    pending.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
          calls.add(call);
          switch (call.method) {
            case 'initialize':
              return true;
            case 'getNotificationAppLaunchDetails':
              return <String, Object?>{'notificationLaunchedApp': false};
            case 'pendingNotificationRequests':
              return pending;
            case 'zonedSchedule':
              final arguments = Map<String, Object?>.from(
                call.arguments as Map,
              );
              pending.removeWhere((item) => item['id'] == arguments['id']);
              pending.add({
                'id': arguments['id'],
                'title': arguments['title'],
                'body': arguments['body'],
                'payload': arguments['payload'],
              });
              return null;
            case 'cancel':
              pending.removeWhere((item) => item['id'] == call.arguments);
              return null;
            default:
              return null;
          }
        });
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  test(
    'Android anchors inexact hourly repeat at the future due time',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      FlutterLocalNotificationsPlatform.instance =
          AndroidFlutterLocalNotificationsPlugin();
      final gateway = FlutterReminderNotificationGateway();
      final dueAt = DateTime.utc(2026, 7, 21, 6);

      await withClock(
        Clock.fixed(DateTime.utc(2026, 7, 20, 8)),
        () => gateway.schedule(_request(dueAt)),
      );

      final periodic = calls.singleWhere(
        (call) => call.method == 'periodicallyShowWithDuration',
      );
      final arguments = Map<String, Object?>.from(periodic.arguments as Map);
      final platform = Map<String, Object?>.from(
        arguments['platformSpecifics']! as Map,
      );
      expect(
        arguments['calledAt'],
        dueAt.subtract(const Duration(hours: 1)).millisecondsSinceEpoch,
      );
      expect(arguments['repeatIntervalMilliseconds'], 3600000);
      expect(platform['scheduleMode'], 'inexactAllowWhileIdle');
      expect(calls.where((call) => call.method == 'zonedSchedule'), isEmpty);
    },
  );

  test(
    'iOS persists due and next hours as one complete logical reminder',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      FlutterLocalNotificationsPlatform.instance =
          IOSFlutterLocalNotificationsPlugin();
      final gateway = FlutterReminderNotificationGateway();
      final dueAt = DateTime.utc(2026, 7, 21, 6);
      expect(gateway.pendingNotificationSlotCost(60), 24);
      expect(gateway.pendingNotificationSlotCost(null), 1);

      await withClock(
        Clock.fixed(DateTime.utc(2026, 7, 20, 8)),
        () => gateway.schedule(_request(dueAt)),
      );

      final scheduled = calls
          .where((call) => call.method == 'zonedSchedule')
          .toList(growable: false);
      expect(
        scheduled,
        hasLength(
          FlutterReminderNotificationGateway.rollingRepeatOccurrenceCount,
        ),
      );
      expect(_scheduledLocal(scheduled[0]), '2026-07-21T09:00:00');
      expect(_scheduledLocal(scheduled[1]), '2026-07-21T10:00:00');
      expect(_scheduledLocal(scheduled[2]), '2026-07-21T11:00:00');
      expect(
        scheduled.every(
          (call) => (call.arguments as Map)['payload'].toString().startsWith(
            'reminder:$_reminderId|rolling:12345:',
          ),
        ),
        isTrue,
      );
      expect(
        scheduled.every((call) => (call.arguments as Map)['id'] as int < 0),
        isTrue,
      );
      final logicalPending = await gateway.pendingNotifications();
      expect(logicalPending, hasLength(1));
      expect(logicalPending.single.platformId, 12345);
      expect(logicalPending.single.reminderId, _reminderId);
      expect(logicalPending.single.scheduleComplete, isTrue);

      pending.removeAt(0);
      final incomplete = await gateway.pendingNotifications();
      expect(incomplete.single.scheduleComplete, isFalse);

      await gateway.cancel(12345);
      expect(pending, isEmpty);
      expect(
        calls
            .where((call) => call.method == 'cancel')
            .map((call) => call.arguments),
        contains(12345),
      );
    },
  );
}

ReminderNotificationRequest _request(DateTime dueAt) =>
    ReminderNotificationRequest(
      platformId: 12345,
      reminderId: _reminderId,
      title: 'Beton saha görevi',
      body: 'Yapı denetime haber ver',
      scheduledAtUtc: CseTimeCodec.encodeUtc(dueAt),
      repeatIntervalMinutes: 60,
    );

String _scheduledLocal(MethodCall call) =>
    (call.arguments as Map)['scheduledDateTime']! as String;
