import 'package:home_cleaning_marketplace_api/src/features/auth/security/argon2id_password_hasher.dart';
import 'package:test/test.dart';

void main() {
  const password = 'fifteen-chars!!';
  const otherPassword = 'sixteen-chars!!!';
  const spaced = ' fifteen chars ';
  const unicode = 'パスワードパスワードパスワード';
  const weakerEncoded =
      r'$argon2id$v=19$m=16,t=2,p=1$c29tZXNhbHRzYWx0$u1eU6mZFG4/OOoTdAtM5SQ';
  const argon2iEncoded =
      r'$argon2i$v=19$m=19456,t=2,p=1$c29tZXNhbHRzYWx0$u1eU6mZFG4/OOoTdAtM5SQ';
  const damaged = r'$argon2id$v=19$m=19456,t=2,p=1$not-valid';

  final hasher = Argon2idPasswordHasher();

  group('Argon2idPasswordHasher.hash', () {
    test('produces an Argon2id encoded value with approved parameters', () {
      final encoded = hasher.hash(password);

      expect(encoded.startsWith(r'$argon2id$'), isTrue);
      expect(encoded, contains('m=$argon2idMemoryKib'));
      expect(encoded, contains('t=$argon2idIterations'));
      expect(encoded, contains('p=$argon2idParallelism'));
      expect(hasher.needsRehash(encoded), isFalse);
    });

    test('uses a unique salt so the same password hashes differently', () {
      final first = hasher.hash(password);
      final second = hasher.hash(password);

      expect(first, isNot(equals(second)));
      expect(hasher.verify(password: password, encodedHash: first), isTrue);
      expect(hasher.verify(password: password, encodedHash: second), isTrue);
    });
  });

  group('Argon2idPasswordHasher.verify', () {
    late String encoded;

    setUp(() {
      encoded = hasher.hash(password);
    });

    test('accepts the correct password', () {
      expect(hasher.verify(password: password, encodedHash: encoded), isTrue);
    });

    test('rejects an incorrect password', () {
      expect(
        hasher.verify(password: otherPassword, encodedHash: encoded),
        isFalse,
      );
    });

    test('requires exact spaces', () {
      final spacedHash = hasher.hash(spaced);

      expect(hasher.verify(password: spaced, encodedHash: spacedHash), isTrue);
      expect(
        hasher.verify(password: spaced.trim(), encodedHash: spacedHash),
        isFalse,
      );
    });

    test('treats case differences as a different password', () {
      expect(
        hasher.verify(password: password.toUpperCase(), encodedHash: encoded),
        isFalse,
      );
    });

    test('verifies a Unicode password', () {
      expect(unicode.runes.length, greaterThanOrEqualTo(15));
      final unicodeHash = hasher.hash(unicode);

      expect(
        hasher.verify(password: unicode, encodedHash: unicodeHash),
        isTrue,
      );
    });

    test('returns false for malformed encoded hashes', () {
      expect(hasher.verify(password: password, encodedHash: ''), isFalse);
      expect(
        hasher.verify(password: password, encodedHash: 'not-a-password-hash'),
        isFalse,
      );
      expect(hasher.verify(password: password, encodedHash: damaged), isFalse);
    });
  });

  group('Argon2idPasswordHasher.needsRehash', () {
    test('is false for a current production hash', () {
      final encoded = hasher.hash(password);

      expect(hasher.needsRehash(encoded), isFalse);
    });

    test('is true for a weaker Argon2id cost', () {
      expect(hasher.needsRehash(weakerEncoded), isTrue);
    });

    test('is true for a different algorithm', () {
      expect(hasher.needsRehash(argon2iEncoded), isTrue);
    });

    test('is true for malformed hashes', () {
      expect(hasher.needsRehash(''), isTrue);
      expect(hasher.needsRehash('not-a-password-hash'), isTrue);
      expect(hasher.needsRehash(damaged), isTrue);
    });
  });
}
