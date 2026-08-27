// Release verification utility (Dart SDK only).
//
// Usage (from repository root):
//   dart tools/release_check.dart
//   dart tools/release_check.dart --quick
//   dart tools/release_check.dart --full
//
// Never prints secret values. Never connects to Atlas. Never mutates data.

import 'dart:io';

void main(List<String> args) {
  final quick = args.contains('--quick');
  final full = args.contains('--full');
  final root = _findRepoRoot();
  stdout.writeln('Release check root: ${root.path}');

  var failed = false;

  void check(String name, bool ok, [String detail = '']) {
    final status = ok ? 'PASS' : 'FAIL';
    stdout.writeln('[$status] $name${detail.isEmpty ? '' : ' — $detail'}');
    if (!ok) {
      failed = true;
    }
  }

  check(
    'expected directories',
    Directory.fromUri(root.uri.resolve('backend')).existsSync() &&
        Directory.fromUri(root.uri.resolve('project')).existsSync() &&
        Directory.fromUri(root.uri.resolve('documentation')).existsSync(),
  );

  final ignore = Process.runSync(
    'git',
    <String>['check-ignore', '-v', 'backend/.env'],
    workingDirectory: root.path,
    runInShell: true,
  );
  check(
    'backend/.env ignored',
    ignore.exitCode == 0,
    ignore.stdout.toString().trim(),
  );

  final tracked = Process.runSync(
    'git',
    <String>['ls-files'],
    workingDirectory: root.path,
    runInShell: true,
  );
  if (tracked.exitCode != 0) {
    check('git ls-files', false, 'git failed');
  } else {
    final files = tracked.stdout
        .toString()
        .split(RegExp(r'\r?\n'))
        .where((line) => line.isNotEmpty)
        .toList();
    final forbidden = <String>[];
    for (final path in files) {
      final lower = path.toLowerCase();
      final name = path.split('/').last.toLowerCase();
      if (path == 'backend/.env' ||
          name.endsWith('.apk') ||
          name.endsWith('.aab') ||
          name.endsWith('.jks') ||
          name.endsWith('.keystore') ||
          name == 'key.properties' ||
          name == 'devtools_options.yaml' ||
          lower.contains('/build/') ||
          RegExp(r'(^|/)(_tmp_|tmp_task).*', caseSensitive: false)
              .hasMatch(path)) {
        // Allow documented examples and already-deleted working-tree files
        // pending the next checkpoint commit.
        if (name.endsWith('.example')) {
          continue;
        }
        final onDisk = File.fromUri(root.uri.resolve(path)).existsSync();
        if (!onDisk) {
          continue;
        }
        forbidden.add(path);
      }
    }
    check(
      'no forbidden tracked artifacts',
      forbidden.isEmpty,
      forbidden.isEmpty ? '' : forbidden.join(', '),
    );
  }

  final portEntrypoint = File.fromUri(root.uri.resolve('backend/main.dart'));
  final portConfig = File.fromUri(
    root.uri.resolve('backend/lib/src/config/port_config.dart'),
  );
  final portEntrypointOk =
      portEntrypoint.existsSync() &&
      portEntrypoint.readAsStringSync().contains('PortConfig.resolve');
  final portConfigOk =
      portConfig.existsSync() &&
      portConfig.readAsStringSync().contains('invalidPortMessage');
  check(
    'production PORT startup boundary',
    portEntrypointOk && portConfigOk,
    portEntrypointOk && portConfigOk
        ? 'backend/main.dart + PortConfig'
        : 'missing custom entrypoint or PortConfig',
  );

  if (!quick) {
    failed = !_run(
          'backend dart analyze',
          root,
          'dart',
          <String>['analyze'],
          'backend',
        ) ||
        failed;
    failed = !_run(
          'backend dart test',
          root,
          'dart',
          <String>['test'],
          'backend',
        ) ||
        failed;
  }

  if (full) {
    failed = !_run(
          'flutter analyze',
          root,
          'flutter',
          <String>['analyze'],
          'project',
        ) ||
        failed;
    failed = !_run(
          'flutter test',
          root,
          'flutter',
          <String>['test'],
          'project',
        ) ||
        failed;
  }

  if (failed) {
    stderr.writeln('Release check FAILED');
    exit(1);
  }
  stdout.writeln('Release check PASSED');
}

Directory _findRepoRoot() {
  var dir = Directory.current;
  while (true) {
    final git = Directory.fromUri(dir.uri.resolve('.git'));
    final backend = Directory.fromUri(dir.uri.resolve('backend'));
    if (git.existsSync() && backend.existsSync()) {
      return dir;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      stderr.writeln('Could not locate repository root from ${Directory.current.path}');
      exit(1);
    }
    dir = parent;
  }
}

bool _run(
  String label,
  Directory root,
  String executable,
  List<String> args,
  String relativeWorkingDirectory,
) {
  stdout.writeln('--- $label ---');
  final result = Process.runSync(
    executable,
    args,
    workingDirectory: root.uri.resolve(relativeWorkingDirectory).toFilePath(),
    runInShell: true,
  );
  stdout.write(result.stdout);
  stderr.write(result.stderr);
  final ok = result.exitCode == 0;
  stdout.writeln(ok ? '[$label] PASS' : '[$label] FAIL');
  return ok;
}
