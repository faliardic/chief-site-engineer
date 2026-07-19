import 'dart:async';

import 'package:chief_site_engineer/core/record_id.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/platform/capabilities.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

class LocalNotificationRequest {
  LocalNotificationRequest({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledAtUtc,
  }) {
    if (id.trim().isEmpty || title.trim().isEmpty || body.trim().isEmpty) {
      throw const TimeContractViolation(
        'notification fields must not be empty',
      );
    }
    CseTimeCodec.decodeCanonicalUtc(scheduledAtUtc);
  }

  final String id;
  final String title;
  final String body;
  final String scheduledAtUtc;
}

abstract interface class LocalNotificationPort {
  Future<void> schedule(LocalNotificationRequest request);
}

enum NotificationScheduleOutcome { scheduled, denied, invalid, unavailable }

class SafeNotificationScheduler {
  const SafeNotificationScheduler({
    required this.permissions,
    required this.notifications,
    required this.clock,
  });

  final SafeCapabilityService permissions;
  final LocalNotificationPort notifications;
  final DateTime Function() clock;

  Future<NotificationScheduleOutcome> schedule(
    LocalNotificationRequest request,
  ) async {
    final scheduledAt = CseTimeCodec.decodeCanonicalUtc(request.scheduledAtUtc);
    final now = clock();
    if (!now.isUtc || !scheduledAt.isAfter(now)) {
      return NotificationScheduleOutcome.invalid;
    }
    final permission = await permissions.request(DeviceCapability.notification);
    if (permission == CapabilityStatus.denied) {
      return NotificationScheduleOutcome.denied;
    }
    if (permission == CapabilityStatus.unavailable) {
      return NotificationScheduleOutcome.unavailable;
    }
    try {
      await notifications.schedule(request);
      return NotificationScheduleOutcome.scheduled;
    } on Object {
      return NotificationScheduleOutcome.unavailable;
    }
  }
}

enum NotificationPermissionState { granted, denied, unavailable }

class ReminderNotificationRequest {
  ReminderNotificationRequest({
    required this.platformId,
    required this.reminderId,
    required this.title,
    required this.body,
    required this.scheduledAtUtc,
    this.repeatIntervalMinutes,
  }) {
    if (platformId < 1 || platformId > 2147483647) {
      throw const TimeContractViolation('invalid platform notification id');
    }
    if (!RecordId.isUuid(reminderId) ||
        title.trim().isEmpty ||
        body.trim().isEmpty) {
      throw const TimeContractViolation('invalid reminder notification');
    }
    CseTimeCodec.decodeCanonicalUtc(scheduledAtUtc);
    if (repeatIntervalMinutes != null && repeatIntervalMinutes != 60) {
      throw const TimeContractViolation('invalid reminder repeat interval');
    }
  }

  final int platformId;
  final String reminderId;
  final String title;
  final String body;
  final String scheduledAtUtc;
  final int? repeatIntervalMinutes;
}

class PendingReminderNotification {
  const PendingReminderNotification({
    required this.platformId,
    required this.reminderId,
  });

  final int platformId;
  final String? reminderId;
}

abstract interface class ReminderNotificationGateway {
  int get maximumPendingNotifications;

  String? get initialTapReminderId;

  Stream<String> get notificationTaps;

  Future<void> initialize();

  Future<NotificationPermissionState> permissionStatus();

  Future<NotificationPermissionState> requestPermission();

  Future<List<PendingReminderNotification>> pendingNotifications();

  Future<void> schedule(ReminderNotificationRequest request);

  Future<void> cancel(int platformId);
}

class UnavailableReminderNotificationGateway
    implements ReminderNotificationGateway {
  const UnavailableReminderNotificationGateway();

  @override
  int get maximumPendingNotifications => 0;

  @override
  String? get initialTapReminderId => null;

  @override
  Stream<String> get notificationTaps => const Stream<String>.empty();

  @override
  Future<void> cancel(int platformId) async {}

  @override
  Future<void> initialize() async {}

  @override
  Future<List<PendingReminderNotification>> pendingNotifications() async =>
      const [];

  @override
  Future<NotificationPermissionState> permissionStatus() async =>
      NotificationPermissionState.unavailable;

  @override
  Future<NotificationPermissionState> requestPermission() async =>
      NotificationPermissionState.unavailable;

  @override
  Future<void> schedule(ReminderNotificationRequest request) async {
    throw StateError('notifications unavailable');
  }
}

class FlutterReminderNotificationGateway
    implements ReminderNotificationGateway {
  FlutterReminderNotificationGateway({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _payloadPrefix = 'reminder:';
  static const _channelId = 'cse_reminders';
  static const _channelName = 'Hatırlatıcılar';
  static const _channelDescription =
      'Chief Site Engineer tek seferlik hatırlatıcıları';

  final FlutterLocalNotificationsPlugin _plugin;
  final StreamController<String> _taps = StreamController<String>.broadcast();
  bool _initialized = false;
  String? _initialTapReminderId;

  @override
  int get maximumPendingNotifications =>
      defaultTargetPlatform == TargetPlatform.iOS ? 60 : 256;

  @override
  String? get initialTapReminderId => _initialTapReminderId;

  @override
  Stream<String> get notificationTaps => _taps.stream;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    timezone_data.initializeTimeZones();
    timezone.setLocalLocation(timezone.getLocation('Europe/Istanbul'));
    final initialized = await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        final reminderId = _parsePayload(response.payload);
        if (reminderId != null) _taps.add(reminderId);
      },
    );
    if (initialized != true) {
      throw StateError('notification initialization failed');
    }
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      _initialTapReminderId = _parsePayload(
        launch?.notificationResponse?.payload,
      );
    }
    _initialized = true;
  }

  @override
  Future<NotificationPermissionState> permissionStatus() async {
    await initialize();
    if (defaultTargetPlatform == TargetPlatform.android) {
      final enabled = await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.areNotificationsEnabled();
      return enabled == true
          ? NotificationPermissionState.granted
          : NotificationPermissionState.denied;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final options = await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.checkPermissions();
      if (options == null) return NotificationPermissionState.unavailable;
      return options.isEnabled
          ? NotificationPermissionState.granted
          : NotificationPermissionState.denied;
    }
    return NotificationPermissionState.unavailable;
  }

  @override
  Future<NotificationPermissionState> requestPermission() async {
    await initialize();
    if (defaultTargetPlatform == TargetPlatform.android) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      return granted == true
          ? NotificationPermissionState.granted
          : NotificationPermissionState.denied;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return granted == true
          ? NotificationPermissionState.granted
          : NotificationPermissionState.denied;
    }
    return NotificationPermissionState.unavailable;
  }

  @override
  Future<List<PendingReminderNotification>> pendingNotifications() async {
    await initialize();
    final pending = await _plugin.pendingNotificationRequests();
    return pending
        .map(
          (item) => PendingReminderNotification(
            platformId: item.id,
            reminderId: _parsePayload(item.payload),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> schedule(ReminderNotificationRequest request) async {
    await initialize();
    final instant = CseTimeCodec.decodeCanonicalUtc(request.scheduledAtUtc);
    final details = const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    if (request.repeatIntervalMinutes case final minutes?) {
      await _plugin.periodicallyShowWithDuration(
        id: request.platformId,
        title: request.title,
        body: request.body,
        repeatDurationInterval: Duration(minutes: minutes),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: '$_payloadPrefix${request.reminderId}',
      );
      return;
    }
    await _plugin.zonedSchedule(
      id: request.platformId,
      title: request.title,
      body: request.body,
      scheduledDate: timezone.TZDateTime.from(instant, timezone.local),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: '$_payloadPrefix${request.reminderId}',
    );
  }

  @override
  Future<void> cancel(int platformId) async {
    await initialize();
    await _plugin.cancel(id: platformId);
  }

  String? _parsePayload(String? payload) {
    if (payload == null || !payload.startsWith(_payloadPrefix)) return null;
    final reminderId = payload.substring(_payloadPrefix.length);
    return RecordId.isUuid(reminderId) ? reminderId : null;
  }
}
