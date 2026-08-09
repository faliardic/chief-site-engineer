import 'package:chief_site_engineer/platform/attachment_gateway.dart';
import 'package:chief_site_engineer/platform/capabilities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('single pick compatibility and camera pickMany stay single', () async {
    final port = _Picker(single: _item('camera.jpg', [1]));
    final picker = _safe(port);

    final single = await picker.pick(AttachmentSource.camera);
    final many = await picker.pickMany(AttachmentSource.camera);

    expect(single.$1, AttachmentPickOutcome.selected);
    expect(single.$2?.name, 'camera.jpg');
    expect(many.$1, AttachmentPickOutcome.selected);
    expect(many.$2.map((item) => item.name), ['camera.jpg']);
    expect(port.singleCalls, 2);
    expect(port.manyCalls, 0);
  });

  test(
    'photo and file pickMany preserve deterministic selection order',
    () async {
      final port = _Picker(
        many: [
          _item('first.jpg', [1]),
          _item('second.pdf', [2, 3]),
        ],
      );
      final picker = _safe(port);

      final photos = await picker.pickMany(AttachmentSource.photoLibrary);
      final files = await picker.pickMany(AttachmentSource.filePicker);

      expect(photos.$1, AttachmentPickOutcome.selected);
      expect(photos.$2.map((item) => item.name), ['first.jpg', 'second.pdf']);
      expect(files.$1, AttachmentPickOutcome.selected);
      expect(files.$2.map((item) => item.name), ['first.jpg', 'second.pdf']);
      expect(port.manyCalls, 2);
    },
  );

  test(
    'pickMany cancel denied unavailable and picker errors fail safe',
    () async {
      final cancelled = await _safe(
        _Picker(many: const []),
      ).pickMany(AttachmentSource.photoLibrary);
      expect(cancelled.$1, AttachmentPickOutcome.cancelled);
      expect(cancelled.$2, isEmpty);

      final deniedPort = _Picker(
        many: [
          _item('x.jpg', [1]),
        ],
      );
      final denied = await _safe(
        deniedPort,
        status: CapabilityStatus.denied,
      ).pickMany(AttachmentSource.photoLibrary);
      expect(denied.$1, AttachmentPickOutcome.denied);
      expect(denied.$2, isEmpty);
      expect(deniedPort.manyCalls, 0);

      final unavailable = await _safe(
        _Picker(
          many: [
            _item('x.jpg', [1]),
          ],
        ),
        status: CapabilityStatus.unavailable,
      ).pickMany(AttachmentSource.filePicker);
      expect(unavailable.$1, AttachmentPickOutcome.unavailable);
      expect(unavailable.$2, isEmpty);

      final failed = await _safe(
        _Picker(throwMany: true),
      ).pickMany(AttachmentSource.filePicker);
      expect(failed.$1, AttachmentPickOutcome.unavailable);
      expect(failed.$2, isEmpty);
    },
  );

  test('pickMany enforces item count and total byte guards', () async {
    final countGuard = SafeAttachmentPicker(
      permissions: SafeCapabilityService(_Permission(CapabilityStatus.granted)),
      picker: _Picker(
        many: [
          _item('1.jpg', [1]),
          _item('2.jpg', [2]),
        ],
      ),
      batchItemLimit: 1,
    );
    final countResult = await countGuard.pickMany(
      AttachmentSource.photoLibrary,
    );
    expect(countResult.$1, AttachmentPickOutcome.unavailable);
    expect(countResult.$2, isEmpty);

    final byteGuard = SafeAttachmentPicker(
      permissions: SafeCapabilityService(_Permission(CapabilityStatus.granted)),
      picker: _Picker(
        many: [
          _item('1.jpg', [1, 2]),
          _item('2.jpg', [3, 4]),
        ],
      ),
      batchByteLimit: 3,
    );
    final byteResult = await byteGuard.pickMany(AttachmentSource.filePicker);
    expect(byteResult.$1, AttachmentPickOutcome.unavailable);
    expect(byteResult.$2, isEmpty);
  });
}

SafeAttachmentPicker _safe(
  _Picker port, {
  CapabilityStatus status = CapabilityStatus.granted,
}) => SafeAttachmentPicker(
  permissions: SafeCapabilityService(_Permission(status)),
  picker: port,
);

SelectedAttachment _item(String name, List<int> bytes) => SelectedAttachment(
  name: name,
  bytes: bytes,
  source: AttachmentSource.photoLibrary,
);

class _Permission implements PermissionGateway {
  const _Permission(this.status);

  final CapabilityStatus status;

  @override
  Future<CapabilityStatus> request(DeviceCapability capability) async => status;
}

class _Picker implements AttachmentPickerPort, MultipleAttachmentPickerPort {
  _Picker({this.single, this.many, this.throwMany = false});

  final SelectedAttachment? single;
  final List<SelectedAttachment>? many;
  final bool throwMany;
  int singleCalls = 0;
  int manyCalls = 0;

  @override
  Future<SelectedAttachment?> pick(AttachmentSource source) async {
    singleCalls += 1;
    return single;
  }

  @override
  Future<List<SelectedAttachment>?> pickMany(AttachmentSource source) async {
    manyCalls += 1;
    if (throwMany) throw StateError('picker unavailable');
    return many;
  }
}
