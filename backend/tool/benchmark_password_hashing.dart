import 'dart:io';

import 'package:home_cleaning_marketplace_api/src/features/auth/security/argon2id_password_hasher.dart';

/// Measures approved Argon2id hash/verify latency. Prints timing only.
Future<void> main() async {
  const fakePassword = 'fake-benchmark-pw';
  final hasher = Argon2idPasswordHasher();
  const rounds = 3;

  final hashWatch = Stopwatch()..start();
  var encoded = '';
  for (var i = 0; i < rounds; i++) {
    encoded = hasher.hash(fakePassword);
  }
  hashWatch.stop();

  final verifyWatch = Stopwatch()..start();
  for (var i = 0; i < rounds; i++) {
    hasher.verify(password: fakePassword, encodedHash: encoded);
  }
  verifyWatch.stop();

  final hashAverageMs = hashWatch.elapsedMilliseconds / rounds;
  final verifyAverageMs = verifyWatch.elapsedMilliseconds / rounds;

  stdout
    ..writeln('Argon2id hash average (ms): ${hashAverageMs.toStringAsFixed(1)}')
    ..writeln(
      'Argon2id verify average (ms): ${verifyAverageMs.toStringAsFixed(1)}',
    );
}
