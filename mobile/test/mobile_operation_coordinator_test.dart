import 'dart:async';

import 'package:chief_site_engineer/core/mobile_operation_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'exclusive operation waits for mutation and blocks later mutations',
    () async {
      final coordinator = MobileOperationCoordinator();
      final firstGate = Completer<void>();
      final backupGate = Completer<void>();
      final order = <String>[];

      final first = coordinator.run(() async {
        order.add('mutation-1:start');
        await firstGate.future;
        order.add('mutation-1:end');
      });
      final backup = coordinator.runExclusive(() async {
        order.add('backup:start');
        await backupGate.future;
        order.add('backup:end');
      });
      final second = coordinator.run(() async {
        order.add('mutation-2');
      });

      await Future<void>.delayed(Duration.zero);
      expect(order, ['mutation-1:start']);
      firstGate.complete();
      await first;
      await Future<void>.delayed(Duration.zero);
      expect(order, ['mutation-1:start', 'mutation-1:end', 'backup:start']);
      backupGate.complete();
      await Future.wait([backup, second]);
      expect(order, [
        'mutation-1:start',
        'mutation-1:end',
        'backup:start',
        'backup:end',
        'mutation-2',
      ]);
    },
  );

  test('failed operation does not poison the shared queue', () async {
    final coordinator = MobileOperationCoordinator();

    await expectLater(
      coordinator.run<void>(() async => throw StateError('expected')),
      throwsStateError,
    );

    expect(await coordinator.run(() async => 42), 42);
  });
}
