import 'package:chief_site_engineer/application/onboarding_preference.dart';
import 'package:chief_site_engineer/platform/device_onboarding_preference.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('version gate offers only an unhandled or older guide', () async {
    final preference = _MemoryOnboardingPreference();
    final gate = OnboardingPreferenceGate(preference);

    expect(await gate.shouldOffer(), isTrue);
    preference.handledVersion = guidedOnboardingVersion - 1;
    expect(await gate.shouldOffer(), isTrue);
    preference.handledVersion = guidedOnboardingVersion;
    expect(await gate.shouldOffer(), isFalse);
    preference.handledVersion = guidedOnboardingVersion + 1;
    expect(await gate.shouldOffer(), isFalse);
  });

  test('Skip and Finish share the same versioned handled write', () async {
    final preference = _MemoryOnboardingPreference();
    final gate = OnboardingPreferenceGate(preference);

    await gate.markHandled();
    await gate.markHandled();

    expect(preference.writes, const [
      guidedOnboardingVersion,
      guidedOnboardingVersion,
    ]);
    expect(preference.handledVersion, guidedOnboardingVersion);
  });

  test('read and write failures fail open without escaping', () async {
    final readGate = OnboardingPreferenceGate(
      _ThrowingOnboardingPreference(throwOnRead: true),
    );
    final writeGate = OnboardingPreferenceGate(
      _ThrowingOnboardingPreference(throwOnWrite: true),
    );

    expect(await readGate.shouldOffer(), isFalse);
    await expectLater(writeGate.markHandled(), completes);
  });

  test('device adapter reads and writes one integer UI key only', () async {
    final values = <String, Object>{};
    final reads = <String>[];
    final writes = <(String, int)>[];
    final preference = DeviceOnboardingPreference(
      readInt: (key) async {
        reads.add(key);
        return values[key] as int?;
      },
      writeInt: (key, value) async {
        writes.add((key, value));
        values[key] = value;
      },
    );

    expect(await preference.readHandledVersion(), isNull);
    await preference.writeHandledVersion(guidedOnboardingVersion);
    expect(await preference.readHandledVersion(), guidedOnboardingVersion);

    expect(reads, everyElement(guidedOnboardingHandledVersionPreferenceKey));
    expect(writes, const [
      (guidedOnboardingHandledVersionPreferenceKey, guidedOnboardingVersion),
    ]);
    expect(values.keys, {guidedOnboardingHandledVersionPreferenceKey});
    expect(values.values.single, isA<int>());
    expect(values.values.single, isNot(isA<String>()));
  });

  test('unconfigured Flutter test device backend fails open', () async {
    final gate = OnboardingPreferenceGate(const DeviceOnboardingPreference());

    expect(await gate.shouldOffer(), isFalse);
    await expectLater(gate.markHandled(), completes);
  });
}

class _MemoryOnboardingPreference implements OnboardingPreference {
  int? handledVersion;
  final writes = <int>[];

  @override
  Future<int?> readHandledVersion() async => handledVersion;

  @override
  Future<void> writeHandledVersion(int version) async {
    writes.add(version);
    handledVersion = version;
  }
}

class _ThrowingOnboardingPreference implements OnboardingPreference {
  _ThrowingOnboardingPreference({
    this.throwOnRead = false,
    this.throwOnWrite = false,
  });

  final bool throwOnRead;
  final bool throwOnWrite;

  @override
  Future<int?> readHandledVersion() async {
    if (throwOnRead) throw StateError('synthetic preference read failure');
    return null;
  }

  @override
  Future<void> writeHandledVersion(int version) async {
    if (throwOnWrite) throw StateError('synthetic preference write failure');
  }
}
