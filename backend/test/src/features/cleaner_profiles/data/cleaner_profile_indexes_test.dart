import 'package:home_cleaning_marketplace_api/src/database/collection_names.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/data/cleaner_profile_indexes.dart';
import 'package:test/test.dart';

class _RecordingEnsureIndex {
  final calls = <Map<String, dynamic>>[];

  Future<void> call({
    required String collectionName,
    required Map<String, dynamic> keys,
    required bool unique,
    required String name,
  }) async {
    calls.add(<String, dynamic>{
      'collectionName': collectionName,
      'keys': Map<String, dynamic>.from(keys),
      'unique': unique,
      'name': name,
    });
  }
}

void main() {
  group('ensureCleanerProfileIndexes', () {
    test('requests unique user_id and status+_id indexes', () async {
      final recorder = _RecordingEnsureIndex();
      await ensureCleanerProfileIndexes(ensureIndex: recorder.call);

      expect(recorder.calls, hasLength(2));
      expect(
        recorder.calls[0]['name'],
        equals(cleanerProfilesUserIdUniqueIndexName),
      );
      expect(
        recorder.calls[0]['name'],
        equals('cleaner_profiles_user_id_unique'),
      );
      expect(
        recorder.calls[0]['keys'],
        equals(const <String, dynamic>{cleanerProfilesUserIdField: 1}),
      );
      expect(recorder.calls[0]['unique'], isTrue);
      expect(
        recorder.calls[0]['collectionName'],
        equals(CollectionNames.cleanerProfiles),
      );

      expect(
        recorder.calls[1]['name'],
        equals(cleanerProfilesStatusIdIndexName),
      );
      expect(recorder.calls[1]['name'], equals('cleaner_profiles_status_id'));
      expect(
        recorder.calls[1]['keys'],
        equals(const <String, dynamic>{
          cleanerProfilesOnboardingStatusField: 1,
          '_id': 1,
        }),
      );
      expect(recorder.calls[1]['unique'], isFalse);
    });
  });
}
