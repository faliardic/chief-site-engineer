import 'package:chief_site_engineer/platform/attachment_gateway.dart';
import 'package:chief_site_engineer/platform/capabilities.dart';
import 'package:chief_site_engineer/platform/notification_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

class _PermissionGateway implements PermissionGateway {
  _PermissionGateway(this.status, {this.shouldThrow = false});

  final CapabilityStatus status;
  final bool shouldThrow;

  @override
  Future<CapabilityStatus> request(DeviceCapability capability) async {
    if (shouldThrow) {
      throw StateError('platform channel unavailable');
    }
    return status;
  }
}

class _AttachmentPicker implements AttachmentPickerPort {
  var calls = 0;

  @override
  Future<SelectedAttachment?> pick(AttachmentSource source) async {
    calls += 1;
    return SelectedAttachment(name: 'photo.jpg', bytes: [1, 2], source: source);
  }
}

class _NotificationPort implements LocalNotificationPort {
  var calls = 0;

  @override
  Future<void> schedule(LocalNotificationRequest request) async {
    calls += 1;
  }
}

void main() {
  test(
    'permission gateway exception becomes unavailable without a crash',
    () async {
      final service = SafeCapabilityService(
        _PermissionGateway(CapabilityStatus.granted, shouldThrow: true),
      );

      expect(
        await service.request(DeviceCapability.camera),
        CapabilityStatus.unavailable,
      );
    },
  );

  test('denied camera permission never invokes the picker', () async {
    final picker = _AttachmentPicker();
    final service = SafeAttachmentPicker(
      permissions: SafeCapabilityService(
        _PermissionGateway(CapabilityStatus.denied),
      ),
      picker: picker,
    );

    final result = await service.pick(AttachmentSource.camera);

    expect(result.$1, AttachmentPickOutcome.denied);
    expect(result.$2, isNull);
    expect(picker.calls, 0);
  });

  test('denied notification permission leaves scheduler untouched', () async {
    final notifications = _NotificationPort();
    final scheduler = SafeNotificationScheduler(
      permissions: SafeCapabilityService(
        _PermissionGateway(CapabilityStatus.denied),
      ),
      notifications: notifications,
      clock: () => DateTime.utc(2026, 7, 19, 8),
    );
    final request = LocalNotificationRequest(
      id: 'reminder-1',
      title: 'Kontrol',
      body: 'Donatı kontrolünü unutma',
      scheduledAtUtc: '2026-07-19T09:00:00Z',
    );

    expect(
      await scheduler.schedule(request),
      NotificationScheduleOutcome.denied,
    );
    expect(notifications.calls, 0);
  });

  test(
    'past notification schedule fails closed before permission mutation',
    () async {
      final notifications = _NotificationPort();
      final scheduler = SafeNotificationScheduler(
        permissions: SafeCapabilityService(
          _PermissionGateway(CapabilityStatus.granted),
        ),
        notifications: notifications,
        clock: () => DateTime.utc(2026, 7, 19, 10),
      );
      final request = LocalNotificationRequest(
        id: 'reminder-2',
        title: 'Kontrol',
        body: 'Eski zaman',
        scheduledAtUtc: '2026-07-19T09:00:00Z',
      );

      expect(
        await scheduler.schedule(request),
        NotificationScheduleOutcome.invalid,
      );
      expect(notifications.calls, 0);
    },
  );
}
