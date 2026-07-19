import 'dart:async';

/// Serializes every operation that can observe or mutate the mobile data root.
///
/// Backup and restore use the same queue as Agenda, Reminder, Puantaj and Beton.
/// Therefore a snapshot never races an open application mutation and operations
/// submitted while an exclusive task is running start only after it finishes.
class MobileOperationCoordinator {
  Future<void> _tail = Future<void>.value();

  Future<T> run<T>(Future<T> Function() operation) => _enqueue(operation);

  Future<T> runExclusive<T>(Future<T> Function() operation) =>
      _enqueue(operation);

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final completer = Completer<T>();
    _tail = _tail
        .then((_) async {
          try {
            completer.complete(await operation());
          } on Object catch (error, stackTrace) {
            completer.completeError(error, stackTrace);
          }
        })
        .catchError((Object _, StackTrace _) {});
    return completer.future;
  }
}
