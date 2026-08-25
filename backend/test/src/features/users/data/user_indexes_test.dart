import 'package:home_cleaning_marketplace_api/src/database/collection_names.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/data/user_indexes.dart';
import 'package:test/test.dart';

class _RecordingEnsureIndex {
  final names = <String>[];
  String? collectionName;
  Map<String, dynamic>? keys;
  bool? unique;
  String? name;
  int calls = 0;

  Future<void> call({
    required String collectionName,
    required Map<String, dynamic> keys,
    required bool unique,
    required String name,
  }) async {
    calls += 1;
    this.collectionName = collectionName;
    this.keys = Map<String, dynamic>.from(keys);
    this.unique = unique;
    this.name = name;
    names.add(name);
  }
}

void main() {
  group('ensureUserIndexes', () {
    test('requests the unique email_normalized index on users', () async {
      final recorder = _RecordingEnsureIndex();

      await ensureUserIndexes(ensureIndex: recorder.call);

      expect(recorder.calls, equals(2));
      expect(recorder.names, contains(usersEmailNormalizedUniqueIndexName));
      expect(recorder.names, contains(usersRoleStatusIdDescIndexName));
      expect(recorder.collectionName, equals(CollectionNames.users));
      expect(recorder.collectionName, equals('users'));
    });
  });
}
