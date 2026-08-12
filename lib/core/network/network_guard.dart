import 'dart:async';

/// Maximum time any network fetch may take before it is treated as a
/// failure. Prevents screens from spinning forever on a stalled request.
const Duration networkTimeout = Duration(seconds: 15);

/// Runs [future] with a hard timeout so a hung request surfaces as a
/// visible error (with a Retry action) instead of an endless spinner.
Future<T> guardNetwork<T>(
  Future<T> future, {
  String operation = 'request',
}) {
  return future.timeout(
    networkTimeout,
    onTimeout: () => throw TimeoutException('$operation timed out'),
  );
}
