import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Network-layer session events independent of UI.
enum AuthSessionEvent {
  /// Refresh failed or the session can no longer be restored.
  expired,
}

/// Broadcast bus so interceptors can signal expiry without AuthController.
class AuthSessionEventBus {
  final StreamController<AuthSessionEvent> _controller =
      StreamController<AuthSessionEvent>.broadcast();

  /// Stream of session events.
  Stream<AuthSessionEvent> get stream => _controller.stream;

  /// Notifies listeners that the session is no longer usable.
  void emitExpired() {
    if (!_controller.isClosed) {
      _controller.add(AuthSessionEvent.expired);
    }
  }

  /// Closes the stream.
  void dispose() {
    _controller.close();
  }
}

/// Process-scoped session event bus.
final authSessionEventsProvider = Provider<AuthSessionEventBus>((ref) {
  final bus = AuthSessionEventBus();
  ref.onDispose(bus.dispose);
  return bus;
});
