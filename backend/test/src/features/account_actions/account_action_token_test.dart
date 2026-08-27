import 'package:home_cleaning_marketplace_api/src/features/account_actions/application/account_action_token_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/account_actions/data/account_action_token_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/features/account_actions/data/account_action_token_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/account_actions/domain/account_action_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/account_actions/domain/account_action_policy.dart';
import 'package:home_cleaning_marketplace_api/src/features/account_actions/domain/account_action_purpose.dart';
import 'package:home_cleaning_marketplace_api/src/features/account_actions/security/account_action_token_crypto.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;
import 'package:test/test.dart';

import '../../../helpers/memory_account_action_documents.dart';

void main() {
  final userId = ObjectId.fromHexString('507f1f77bcf86cd799439011');
  final now = DateTime.utc(2026, 8, 25, 12);
  const rawToken = 'fixed-test-token-value-not-real';
  const tokenBytes = [
    7,
    7,
    7,
    7,
    7,
    7,
    7,
    7,
    7,
    7,
    7,
    7,
    7,
    7,
    7,
    7,
    7,
    7,
    7,
    7,
    7,
    7,
    7,
    7,
    7,
    7,
    7,
    7,
    7,
    7,
    7,
    7,
  ];

  group('AccountActionTokenCrypto', () {
    test('generates 32-byte unpadded base64url tokens', () {
      final generator = AccountActionTokenGenerator(
        randomBytes: (_) => tokenBytes,
      );
      final token = generator.generate();
      expect(token.length, greaterThan(40));
      expect(token.contains('='), isFalse);
      expect(RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(token), isTrue);
    });

    test('hashes to lowercase SHA-256 hex', () {
      final hasher = AccountActionTokenHasher();
      final hash = hasher.hash(rawToken);
      expect(hash.length, equals(64));
      expect(hash, equals(hash.toLowerCase()));
      expect(hash, isNot(equals(rawToken)));
    });
  });

  group('AccountActionTokenService', () {
    late MemoryAccountActionDocuments store;
    late AccountActionTokenRepository repository;
    late AccountActionTokenService service;

    setUp(() {
      store = MemoryAccountActionDocuments();
      repository = MongoAccountActionTokenRepository(documents: store);
      service = AccountActionTokenService(
        tokens: repository,
        generator: AccountActionTokenGenerator(randomBytes: (_) => tokenBytes),
        clock: () => now,
      );
    });

    test('persists hash only, not raw token', () async {
      final issued = await service.issue(
        userId: userId,
        purpose: AccountActionPurpose.emailVerification,
      );
      expect(issued.rawToken, isNotEmpty);
      expect(
        store.documents.single['token_hash'],
        equals(service.hashRawToken(issued.rawToken)),
      );
      expect(store.documents.single.containsKey('raw_token'), isFalse);
    });

    test('verification tokens expire after 24 hours', () async {
      final issued = await service.issue(
        userId: userId,
        purpose: AccountActionPurpose.emailVerification,
      );
      expect(
        issued.token.expiresAt.difference(now),
        equals(AccountActionPolicy.emailVerificationLifetime),
      );
    });

    test('reset tokens expire after 30 minutes', () async {
      final issued = await service.issue(
        userId: userId,
        purpose: AccountActionPurpose.passwordReset,
      );
      expect(
        issued.token.expiresAt.difference(now),
        equals(AccountActionPolicy.passwordResetLifetime),
      );
    });

    test('replacement revokes prior live token', () async {
      var counter = 0;
      service = AccountActionTokenService(
        tokens: repository,
        generator: AccountActionTokenGenerator(
          randomBytes: (length) => List<int>.generate(
            length,
            (index) => counter++,
          ),
        ),
        clock: () => now,
      );
      final first = await service.issue(
        userId: userId,
        purpose: AccountActionPurpose.emailVerification,
      );
      await service.issue(
        userId: userId,
        purpose: AccountActionPurpose.emailVerification,
      );
      await expectLater(
        service.claim(
          rawToken: first.rawToken,
          purpose: AccountActionPurpose.emailVerification,
        ),
        throwsA(isA<InvalidAccountActionTokenException>()),
      );
    });

    test('claim succeeds once then fails', () async {
      final issued = await service.issue(
        userId: userId,
        purpose: AccountActionPurpose.passwordReset,
      );
      await service.claim(
        rawToken: issued.rawToken,
        purpose: AccountActionPurpose.passwordReset,
      );
      await expectLater(
        service.claim(
          rawToken: issued.rawToken,
          purpose: AccountActionPurpose.passwordReset,
        ),
        throwsA(isA<InvalidAccountActionTokenException>()),
      );
    });

    test('expired token fails claim', () async {
      final issued = await service.issue(
        userId: userId,
        purpose: AccountActionPurpose.passwordReset,
      );
      service = AccountActionTokenService(
        tokens: repository,
        generator: AccountActionTokenGenerator(randomBytes: (_) => tokenBytes),
        clock: () => now.add(const Duration(hours: 1)),
      );
      await expectLater(
        service.claim(
          rawToken: issued.rawToken,
          purpose: AccountActionPurpose.passwordReset,
        ),
        throwsA(isA<InvalidAccountActionTokenException>()),
      );
    });

    test('wrong purpose fails claim', () async {
      final issued = await service.issue(
        userId: userId,
        purpose: AccountActionPurpose.emailVerification,
      );
      await expectLater(
        service.claim(
          rawToken: issued.rawToken,
          purpose: AccountActionPurpose.passwordReset,
        ),
        throwsA(isA<InvalidAccountActionTokenException>()),
      );
    });
  });

  group('ensureAccountActionTokenIndexes', () {
    test('requests the three approved indexes', () async {
      final calls = <Map<String, dynamic>>[];
      await ensureAccountActionTokenIndexes(
        ensureIndex:
            ({
              required String collectionName,
              required Map<String, dynamic> keys,
              required bool unique,
              required String name,
              int? expireAfterSeconds,
            }) async {
              calls.add(<String, dynamic>{
                'name': name,
                'keys': keys,
                'unique': unique,
                'expireAfterSeconds': expireAfterSeconds,
              });
            },
      );
      expect(calls, hasLength(3));
      expect(
        calls.map((call) => call['name']),
        containsAll(<String>[
          accountActionTokensTokenHashUniqueIndexName,
          accountActionTokensUserPurposeCreatedIndexName,
          accountActionTokensExpiresTtlIndexName,
        ]),
      );
      expect(calls.last['expireAfterSeconds'], equals(0));
    });
  });
}
