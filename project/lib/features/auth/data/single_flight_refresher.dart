import 'package:home_cleaning_marketplace/features/auth/data/auth_token_pair.dart';

/// Ensures at most one refresh Future is in flight.
class SingleFlightRefresher {
  Future<AuthTokenPair>? _inFlight;

  /// Runs [action], sharing the same Future with concurrent callers.
  Future<AuthTokenPair> run(Future<AuthTokenPair> Function() action) {
    final existing = _inFlight;
    if (existing != null) {
      return existing;
    }
    final future = action();
    _inFlight = future;
    return future.whenComplete(() {
      if (identical(_inFlight, future)) {
        _inFlight = null;
      }
    });
  }
}
