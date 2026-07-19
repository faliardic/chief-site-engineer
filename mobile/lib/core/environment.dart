enum AppEnvironment {
  debug(storageSegment: 'debug', label: 'Geliştirme'),
  release(storageSegment: 'release', label: 'Yayın');

  const AppEnvironment({required this.storageSegment, required this.label});

  static const releaseApplicationId = 'com.faliardic.chiefsiteengineer';
  static const environmentContractVersion = 1;

  final String storageSegment;
  final String label;

  static AppEnvironment current({bool? isProduct}) {
    final product = isProduct ?? const bool.fromEnvironment('dart.vm.product');
    return product ? AppEnvironment.release : AppEnvironment.debug;
  }
}
