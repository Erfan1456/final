import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/config/configuration_validation.dart';
import 'package:home_cleaning_marketplace_api/src/config/port_config.dart';

/// Dart Frog custom entrypoint — validates `PORT` before binding.
///
/// Generated `build/bin/server.dart` still parses `PORT` with `tryParse` and
/// may pass a fallback port into this method. We re-resolve from the
/// environment and fail fast for an explicitly invalid value so the process
/// never serves on a silently substituted port.
Future<HttpServer> run(Handler handler, InternetAddress ip, int port) {
  try {
    final resolvedPort = PortConfig.resolve();
    return serve(handler, ip, resolvedPort);
  } on ConfigurationException catch (error) {
    stderr.writeln(error.message);
    exit(1);
  }
}
