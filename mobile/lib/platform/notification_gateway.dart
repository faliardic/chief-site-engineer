import 'package:chief_site_engineer/core/time/cse_time_codec.dart';
import 'package:chief_site_engineer/platform/capabilities.dart';

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
