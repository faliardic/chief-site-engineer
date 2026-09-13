const guidedOnboardingVersion = 1;

abstract interface class OnboardingPreference {
  Future<int?> readHandledVersion();

  Future<void> writeHandledVersion(int version);
}

/// Keeps preference failures outside bootstrap and product-data flows.
final class OnboardingPreferenceGate {
  const OnboardingPreferenceGate(
    this.preference, {
    this.currentVersion = guidedOnboardingVersion,
  });

  final OnboardingPreference preference;
  final int currentVersion;

  Future<bool> shouldOffer() async {
    try {
      final handledVersion = await preference.readHandledVersion();
      return handledVersion == null || handledVersion < currentVersion;
    } on Object {
      return false;
    }
  }

  Future<void> markHandled() async {
    try {
      await preference.writeHandledVersion(currentVersion);
    } on Object {
      // The guide is optional UI. A failed write must not block the shell.
    }
  }
}
