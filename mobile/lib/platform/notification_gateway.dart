import 'dart:async';

import 'package:chief_site_engineer/core/record_id.dart';
import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/platform/capabilities.dart';
import 'package:clock/clock.dart';
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
    this.scheduleComplete = true,
  });

  final int platformId;
  final String? reminderId;
  final bool scheduleComplete;
}

abstract interface class ReminderNotificationGateway {
  int get maximumPendingNotifications;

  int pendingNotificationSlotCost(int? repeatIntervalMinutes);

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
  int pendingNotificationSlotCost(int? repeatIntervalMinutes) => 1;

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
  static const rollingRepeatOccurrenceCount = 24;

  final FlutterLocalNotificationsPlugin _plugin;
  final StreamController<String> _taps = StreamController<String>.broadcast();
  bool _initialized = false;
  String? _initialTapReminderId;

  @override
  int get maximumPendingNotifications =>
      defaultTargetPlatform == TargetPlatform.iOS ? 60 : 256;

  @override
  int pendingNotificationSlotCost(int? repeatIntervalMinutes) =>
      defaultTargetPlatform == TargetPlatform.iOS &&
          repeatIntervalMinutes != null
      ? rollingRepeatOccurrenceCount
      : 1;

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
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return pending
          .map(
            (item) => PendingReminderNotification(
              platformId: item.id,
              reminderId: _parsePayload(item.payload),
            ),
          )
          .toList(growable: false);
    }
    final logical = <PendingReminderNotification>[];
    final rolling = <int, _RollingPendingGroup>{};
    for (final item in pending) {
      final metadata = _parseRollingPayload(item.payload);
      if (metadata == null) {
        logical.add(
          PendingReminderNotification(
            platformId: item.id,
            reminderId: _parsePayload(item.payload),
          ),
        );
        continue;
      }
      rolling
          .putIfAbsent(
            metadata.rootPlatformId,
            () => _RollingPendingGroup(metadata.rootPlatformId),
          )
          .add(metadata);
    }
    logical.addAll(rolling.values.map((group) => group.toPending()));
    logical.sort((left, right) => left.platformId.compareTo(right.platformId));
    return logical;
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
      final interval = Duration(minutes: minutes);
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _scheduleIosRolling(request, instant, interval, details);
        return;
      }
      await withClock(
        Clock.fixed(instant.subtract(interval)),
        () => _plugin.periodicallyShowWithDuration(
          id: request.platformId,
          title: request.title,
          body: request.body,
          repeatDurationInterval: interval,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: '$_payloadPrefix${request.reminderId}',
        ),
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
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _cancelIosRollingGroup(platformId);
    }
    await _plugin.cancel(id: platformId);
  }

  Future<void> _scheduleIosRolling(
    ReminderNotificationRequest request,
    DateTime dueAt,
    Duration interval,
    NotificationDetails details,
  ) async {
    await _cancelIosRollingGroup(request.platformId);
    await _plugin.cancel(id: request.platformId);
    final pending = await _plugin.pendingNotificationRequests();
    final occupiedIds = pending.map((item) => item.id).toSet();
    final firstOccurrence = _firstFutureOccurrence(
      dueAt,
      interval,
      clock.now().toUtc(),
    );
    final scheduledIds = <int>[];
    try {
      for (var slot = 0; slot < rollingRepeatOccurrenceCount; slot += 1) {
        final physicalId = _rollingPlatformId(request.platformId, slot);
        if (occupiedIds.contains(physicalId)) {
          throw StateError('rolling notification id collision');
        }
        await _plugin.zonedSchedule(
          id: physicalId,
          title: request.title,
          body: request.body,
          scheduledDate: timezone.TZDateTime.from(
            firstOccurrence.add(interval * slot),
            timezone.local,
          ),
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: _rollingPayload(request, slot),
        );
        scheduledIds.add(physicalId);
      }
    } on Object {
      for (final physicalId in scheduledIds) {
        await _plugin.cancel(id: physicalId);
      }
      rethrow;
    }
  }

  Future<void> _cancelIosRollingGroup(int rootPlatformId) async {
    final pending = await _plugin.pendingNotificationRequests();
    final physicalIds = pending
        .where(
          (item) =>
              _parseRollingPayload(item.payload)?.rootPlatformId ==
              rootPlatformId,
        )
        .map((item) => item.id)
        .toList(growable: false);
    for (final physicalId in physicalIds) {
      await _plugin.cancel(id: physicalId);
    }
  }

  DateTime _firstFutureOccurrence(
    DateTime dueAt,
    Duration interval,
    DateTime now,
  ) {
    if (dueAt.isAfter(now)) return dueAt;
    final elapsedIntervals =
        now.difference(dueAt).inMilliseconds ~/ interval.inMilliseconds;
    return dueAt.add(interval * (elapsedIntervals + 1));
  }

  int _rollingPlatformId(int rootPlatformId, int slot) {
    const maximumPositiveId = 0x7fffffff;
    const slotStride = 104729;
    final positive =
        ((rootPlatformId - 1 + slot * slotStride) % maximumPositiveId) + 1;
    return -positive;
  }

  String _rollingPayload(ReminderNotificationRequest request, int slot) =>
      '$_payloadPrefix${request.reminderId}'
      '|rolling:${request.platformId}:$slot:$rollingRepeatOccurrenceCount';

  String? _parsePayload(String? payload) {
    if (payload == null || !payload.startsWith(_payloadPrefix)) return null;
    final reminderId = payload
        .substring(_payloadPrefix.length)
        .split('|')
        .first;
    return RecordId.isUuid(reminderId) ? reminderId : null;
  }

  _RollingPayload? _parseRollingPayload(String? payload) {
    final reminderId = _parsePayload(payload);
    if (reminderId == null || payload == null) return null;
    final parts = payload.split('|');
    if (parts.length != 2 || !parts[1].startsWith('rolling:')) return null;
    final values = parts[1].substring('rolling:'.length).split(':');
    if (values.length != 3) return null;
    final rootPlatformId = int.tryParse(values[0]);
    final slot = int.tryParse(values[1]);
    final count = int.tryParse(values[2]);
    if (rootPlatformId == null ||
        rootPlatformId < 1 ||
        rootPlatformId > 0x7fffffff ||
        slot == null ||
        slot < 0 ||
        count == null ||
        count < 1) {
      return null;
    }
    return _RollingPayload(
      reminderId: reminderId,
      rootPlatformId: rootPlatformId,
      slot: slot,
      count: count,
    );
  }
}

class _RollingPayload {
  const _RollingPayload({
    required this.reminderId,
    required this.rootPlatformId,
    required this.slot,
    required this.count,
  });

  final String reminderId;
  final int rootPlatformId;
  final int slot;
  final int count;
}

class _RollingPendingGroup {
  _RollingPendingGroup(this.rootPlatformId);

  final int rootPlatformId;
  final Set<int> slots = <int>{};
  String? reminderId;
  var entryCount = 0;
  var valid = true;

  void add(_RollingPayload payload) {
    entryCount += 1;
    reminderId ??= payload.reminderId;
    if (reminderId != payload.reminderId ||
        payload.count !=
            FlutterReminderNotificationGateway.rollingRepeatOccurrenceCount ||
        payload.slot >= payload.count) {
      valid = false;
    }
    slots.add(payload.slot);
  }

  PendingReminderNotification toPending() {
    final expectedCount =
        FlutterReminderNotificationGateway.rollingRepeatOccurrenceCount;
    return PendingReminderNotification(
      platformId: rootPlatformId,
      reminderId: valid ? reminderId : null,
      scheduleComplete:
          valid && entryCount == expectedCount && slots.length == expectedCount,
    );
  }
}
