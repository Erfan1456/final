import 'package:home_cleaning_marketplace_api/src/database/collection_names.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/sessions/session_indexes.dart';
import 'package:test/test.dart';

class _RecordingEnsureIndex {
  final calls = <Map<String, dynamic>>[];

  Future<void> call({
    required String collectionName,
    required Map<String, dynamic> keys,
    required bool unique,
    required String name,
    int? expireAfterSeconds,
  }) async {
    calls.add(<String, dynamic>{
      'collectionName': collectionName,
      'keys': Map<String, dynamic>.from(keys),
      'unique': unique,
      'name': name,
      'expireAfterSeconds': expireAfterSeconds,
    });
  }
}

void main() {
  group('ensureUserSessionIndexes', () {
    test('requests the four approved user_sessions indexes', () async {
      final recorder = _RecordingEnsureIndex();

      await ensureUserSessionIndexes(ensureIndex: recorder.call);

      expect(recorder.calls, hasLength(4));
      expect(
        recorder.calls.map((call) => call['collectionName']).toSet(),
        equals(<String>{CollectionNames.userSessions}),
      );

      expect(
        recorder.calls[0]['name'],
        equals(userSessionsRefreshTokenHashUniqueIndexName),
      );
      expect(
        recorder.calls[0]['keys'],
        equals(const <String, dynamic>{userSessionsRefreshTokenHashField: 1}),
      );
      expect(recorder.calls[0]['unique'], isTrue);

      expect(
        recorder.calls[1]['name'],
        equals(userSessionsUsedRefreshTokenHashesIndexName),
      );
      expect(
        recorder.calls[1]['keys'],
        equals(
          const <String, dynamic>{userSessionsUsedRefreshTokenHashesField: 1},
        ),
      );
      expect(recorder.calls[1]['unique'], isFalse);

      expect(recorder.calls[2]['name'], equals(userSessionsUserIdIndexName));
      expect(
        recorder.calls[2]['keys'],
        equals(const <String, dynamic>{userSessionsUserIdField: 1}),
      );
      expect(recorder.calls[2]['unique'], isFalse);

      expect(
        recorder.calls[3]['name'],
        equals(userSessionsExpiresAtTtlIndexName),
      );
      expect(
        recorder.calls[3]['keys'],
        equals(const <String, dynamic>{userSessionsExpiresAtField: 1}),
      );
      expect(recorder.calls[3]['unique'], isFalse);
      expect(recorder.calls[3]['expireAfterSeconds'], equals(0));
    });
  });
}
