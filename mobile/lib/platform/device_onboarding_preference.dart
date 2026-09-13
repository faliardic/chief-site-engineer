import 'dart:io';

import 'package:chief_site_engineer/application/onboarding_preference.dart';
import 'package:shared_preferences/shared_preferences.dart';

const guidedOnboardingHandledVersionPreferenceKey =
    'guided_onboarding_handled_version';

typedef DevicePreferenceIntReader = Future<int?> Function(String key);
typedef DevicePreferenceIntWriter =
    Future<void> Function(String key, int value);

final class DeviceOnboardingPreference implements OnboardingPreference {
  const DeviceOnboardingPreference({
    DevicePreferenceIntReader? readInt,
    DevicePreferenceIntWriter? writeInt,
  }) : _readInt = readInt,
       _writeInt = writeInt;

  final DevicePreferenceIntReader? _readInt;
  final DevicePreferenceIntWriter? _writeInt;

  @override
  Future<int?> readHandledVersion() {
    final readInt = _readInt;
    if (readInt != null) {
      return readInt(guidedOnboardingHandledVersionPreferenceKey);
    }
    _requireDeviceBackend();
    return SharedPreferencesAsync().getInt(
      guidedOnboardingHandledVersionPreferenceKey,
    );
  }

  @override
  Future<void> writeHandledVersion(int version) {
    final writeInt = _writeInt;
    if (writeInt != null) {
      return writeInt(guidedOnboardingHandledVersionPreferenceKey, version);
    }
    _requireDeviceBackend();
    return SharedPreferencesAsync().setInt(
      guidedOnboardingHandledVersionPreferenceKey,
      version,
    );
  }

  void _requireDeviceBackend() {
    if (Platform.environment['FLUTTER_TEST'] == 'true') {
      throw StateError(
        'Device onboarding preferences are unavailable in tests.',
      );
    }
  }
}
