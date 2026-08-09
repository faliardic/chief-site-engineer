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

abstract interface class MultipleAttachmentPickerPort {
  Future<List<SelectedAttachment>?> pickMany(AttachmentSource source);
}

enum AttachmentPickOutcome { selected, denied, cancelled, unavailable }

class SafeAttachmentPicker {
  const SafeAttachmentPicker({
    required this.permissions,
    required this.picker,
    this.batchItemLimit = maximumBatchItems,
    this.batchByteLimit = maximumBatchBytes,
  });

  static const maximumBatchItems = 20;
  static const maximumBatchBytes = 100 * 1024 * 1024;

  final SafeCapabilityService permissions;
  final AttachmentPickerPort picker;
  final int batchItemLimit;
  final int batchByteLimit;

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

  Future<(AttachmentPickOutcome, List<SelectedAttachment>)> pickMany(
    AttachmentSource source,
  ) async {
    final capability = switch (source) {
      AttachmentSource.camera => DeviceCapability.camera,
      AttachmentSource.photoLibrary => DeviceCapability.photoLibrary,
      AttachmentSource.filePicker => DeviceCapability.filePicker,
    };
    final permission = await permissions.request(capability);
    if (permission == CapabilityStatus.denied) {
      return (AttachmentPickOutcome.denied, const <SelectedAttachment>[]);
    }
    if (permission == CapabilityStatus.unavailable) {
      return (AttachmentPickOutcome.unavailable, const <SelectedAttachment>[]);
    }
    try {
      final List<SelectedAttachment>? selected;
      if (source == AttachmentSource.camera) {
        final single = await picker.pick(source);
        selected = single == null ? null : [single];
      } else if (picker case final MultipleAttachmentPickerPort multiple) {
        selected = await multiple.pickMany(source);
      } else {
        final single = await picker.pick(source);
        selected = single == null ? null : [single];
      }
      if (selected == null || selected.isEmpty) {
        return (AttachmentPickOutcome.cancelled, const <SelectedAttachment>[]);
      }
      if (selected.length > batchItemLimit) {
        return (
          AttachmentPickOutcome.unavailable,
          const <SelectedAttachment>[],
        );
      }
      var totalBytes = 0;
      for (final item in selected) {
        totalBytes += item.bytes.length;
        if (totalBytes > batchByteLimit) {
          return (
            AttachmentPickOutcome.unavailable,
            const <SelectedAttachment>[],
          );
        }
      }
      return (
        AttachmentPickOutcome.selected,
        List<SelectedAttachment>.unmodifiable(selected),
      );
    } on Object {
      return (AttachmentPickOutcome.unavailable, const <SelectedAttachment>[]);
    }
  }
}
