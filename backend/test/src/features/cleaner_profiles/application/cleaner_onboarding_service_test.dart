import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/application/cleaner_onboarding_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/data/cleaner_profile_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/domain/cleaner_onboarding_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/domain/cleaner_profile.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/domain/cleaner_profile_exceptions.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;
import 'package:test/test.dart';

import '../../../../helpers/memory_collection_store.dart';

void main() {
  late MemoryCollectionDocumentStore store;
  late CleanerOnboardingService service;
  final userId = ObjectId.fromHexString('507f1f77bcf86cd799439011');
  const bio = 'Experienced residential cleaner for apartments.';

  setUp(() {
    store = MemoryCollectionDocumentStore();
    service = CleanerOnboardingService(
      profiles: MongoCleanerProfileRepository(documents: store),
    );
  });

  Future<CleanerProfile> save() {
    return service.saveProfile(
      userId: userId,
      fullName: 'Test Cleaner',
      phoneE164: '+15555550100',
      bio: bio,
      yearsExperience: 3,
      serviceArea: 'Dhaka North',
    );
  }

  group('CleanerOnboardingService', () {
    test('getProfile is null before onboarding', () async {
      expect(await service.getProfile(userId), isNull);
    });

    test('save creates a draft and updates it', () async {
      final created = await save();
      expect(created.onboardingStatus, equals(CleanerOnboardingStatus.draft));
      final updated = await service.saveProfile(
        userId: userId,
        fullName: 'Updated Cleaner',
        phoneE164: null,
        bio: bio,
        yearsExperience: 4,
        serviceArea: 'Dhaka South',
      );
      expect(updated.id, equals(created.id));
      expect(updated.fullName, equals('Updated Cleaner'));
      expect(store.documents, hasLength(1));
    });

    test('submit draft becomes pending', () async {
      await save();
      final submitted = await service.submit(userId);
      expect(
        submitted.onboardingStatus,
        equals(CleanerOnboardingStatus.pending),
      );
      expect(submitted.submittedAt, isNotNull);
    });

    test('pending and approved profiles are locked', () async {
      await save();
      await service.submit(userId);
      expect(save(), throwsA(isA<CleanerProfileLockedException>()));
      expect(
        service.submit(userId),
        throwsA(isA<InvalidOnboardingStateException>()),
      );
    });

    test('submit without a profile fails', () async {
      expect(
        service.submit(userId),
        throwsA(isA<CleanerProfileRequiredException>()),
      );
    });

    test(
      'rejected profile can be edited and resubmitted clearing review metadata',
      () async {
        await save();
        await service.submit(userId);
        final now = DateTime.now().toUtc();
        store.documents.single
          ..['onboarding_status'] = 'rejected'
          ..['rejection_reason'] = 'Documents were incomplete.'
          ..['reviewed_at'] = now
          ..['reviewed_by'] = ObjectId.fromHexString(
            '507f1f77bcf86cd799439088',
          );

        final edited = await save();
        expect(
          edited.onboardingStatus,
          equals(CleanerOnboardingStatus.rejected),
        );
        final resubmitted = await service.submit(userId);
        expect(
          resubmitted.onboardingStatus,
          equals(CleanerOnboardingStatus.pending),
        );
        expect(resubmitted.rejectionReason, isNull);
        expect(resubmitted.reviewedAt, isNull);
        expect(resubmitted.reviewedBy, isNull);
      },
    );

    test('approved cannot be submitted or silently downgraded', () async {
      await save();
      await service.submit(userId);
      store.documents.single['onboarding_status'] = 'approved';
      expect(save(), throwsA(isA<CleanerProfileLockedException>()));
      expect(
        service.submit(userId),
        throwsA(isA<InvalidOnboardingStateException>()),
      );
      expect(
        store.documents.single['onboarding_status'],
        equals('approved'),
      );
    });
  });
}
