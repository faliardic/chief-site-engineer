import 'package:chief_site_engineer/platform/capabilities.dart';

enum AttachmentSource { camera, photoLibrary, filePicker }

class SelectedAttachment {
  const SelectedAttachment({
    required this.name,
    required this.bytes,
    required this.source,
  });

  final String name;
  final List<int> bytes;
  final AttachmentSource source;
}

abstract interface class AttachmentPickerPort {
  Future<SelectedAttachment?> pick(AttachmentSource source);
}

enum AttachmentPickOutcome { selected, denied, cancelled, unavailable }

class SafeAttachmentPicker {
  const SafeAttachmentPicker({required this.permissions, required this.picker});

  final SafeCapabilityService permissions;
  final AttachmentPickerPort picker;

  Future<(AttachmentPickOutcome, SelectedAttachment?)> pick(
    AttachmentSource source,
  ) async {
    final capability = switch (source) {
      AttachmentSource.camera => DeviceCapability.camera,
      AttachmentSource.photoLibrary => DeviceCapability.photoLibrary,
      AttachmentSource.filePicker => DeviceCapability.filePicker,
    };
    final permission = await permissions.request(capability);
    if (permission == CapabilityStatus.denied) {
      return (AttachmentPickOutcome.denied, null);
    }
    if (permission == CapabilityStatus.unavailable) {
      return (AttachmentPickOutcome.unavailable, null);
    }
    try {
      final selected = await picker.pick(source);
      if (selected == null) {
        return (AttachmentPickOutcome.cancelled, null);
      }
      return (AttachmentPickOutcome.selected, selected);
    } on Object {
      return (AttachmentPickOutcome.unavailable, null);
    }
  }
}
