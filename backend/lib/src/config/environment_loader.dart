import 'dart:io';

import 'package:dotenv/dotenv.dart';

/// Loads backend process configuration from the platform environment and,
/// when present, an optional local `.env` file.
///
/// Process/environment-map values take precedence over file values.
/// Absence of a local env file is not an error.
///
/// This loader never prints configuration values.
class EnvironmentLoader {
  /// Creates a loader. [envFileName] is a relative or explicit path, never an
  /// absolute Windows development-machine path baked into source.
  const EnvironmentLoader({this.envFileName = '.env'});

  /// Default local env-file name when running from `backend/`.
  final String envFileName;

  static final _envKeyPattern = RegExp(
    r'^(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)=',
  );

  /// Merges optional file values with [processEnvironment].
  ///
  /// When [processEnvironment] is omitted, [Platform.environment] is used.
  /// When [envFilePath] is omitted, [envFileName] is used.
  /// Set [loadEnvFile] to `false` to skip file lookup entirely.
  Map<String, String> load({
    Map<String, String>? processEnvironment,
    String? envFilePath,
    bool loadEnvFile = true,
  }) {
    final process = Map<String, String>.from(
      processEnvironment ?? Platform.environment,
    );

    if (!loadEnvFile) {
      return process;
    }

    final fileValues = _loadFile(envFilePath ?? envFileName);
    return <String, String>{...fileValues, ...process};
  }

  Map<String, String> _loadFile(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      return const <String, String>{};
    }

    final dotenv = DotEnv(quiet: true)..load([file.path]);
    final values = <String, String>{};
    for (final line in file.readAsLinesSync()) {
      final match = _envKeyPattern.firstMatch(line.trim());
      if (match == null) {
        continue;
      }
      final key = match.group(1)!;
      final value = dotenv[key];
      if (value != null) {
        values[key] = value;
      }
    }
    return values;
  }
}
