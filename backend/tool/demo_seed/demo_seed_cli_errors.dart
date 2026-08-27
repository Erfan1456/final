import 'demo_seed_exception.dart';

/// Renders a seed CLI failure without leaking secrets.
///
/// Known [DemoSeedException] messages are printed as-is. Any other error
/// produces only [unexpectedMessage] — never [error.toString] or a stack.
String renderSeedCliFailure(
  Object error, {
  required String unexpectedMessage,
}) {
  if (error is DemoSeedException) {
    return error.message;
  }
  return unexpectedMessage;
}

/// Writes [renderSeedCliFailure] to [write] (typically `stderr.writeln`).
void reportSeedCliFailure(
  Object error, {
  required String unexpectedMessage,
  required void Function(String) write,
}) {
  write(
    renderSeedCliFailure(
      error,
      unexpectedMessage: unexpectedMessage,
    ),
  );
}
