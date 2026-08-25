import 'package:home_cleaning_marketplace_api/src/database/collection_names.dart';
import 'package:home_cleaning_marketplace_api/src/features/addresses/data/address_indexes.dart';
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
  group('ensureAddressIndexes', () {
    test('requests user_id and user_id+created_at indexes', () async {
      final recorder = _RecordingEnsureIndex();
      await ensureAddressIndexes(ensureIndex: recorder.call);

      expect(recorder.calls, hasLength(2));
      expect(recorder.calls[0]['name'], equals(addressesUserIdIndexName));
      expect(recorder.calls[0]['name'], equals('addresses_user_id'));
      expect(
        recorder.calls[0]['keys'],
        equals(const <String, dynamic>{addressesUserIdField: 1}),
      );
      expect(recorder.calls[0]['unique'], isFalse);
      expect(
        recorder.calls[0]['collectionName'],
        equals(CollectionNames.addresses),
      );

      expect(
        recorder.calls[1]['name'],
        equals(addressesUserIdCreatedAtIndexName),
      );
      expect(recorder.calls[1]['name'], equals('addresses_user_id_created_at'));
      expect(
        recorder.calls[1]['keys'],
        equals(const <String, dynamic>{
          addressesUserIdField: 1,
          addressesCreatedAtField: -1,
        }),
      );
      expect(recorder.calls[1]['unique'], isFalse);
    });
  });
}
