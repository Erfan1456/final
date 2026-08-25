import 'package:home_cleaning_marketplace_api/src/features/authorization/approved_cleaner_policy.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/data/cleaner_profile_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/domain/cleaner_onboarding_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_services/domain/cleaner_service_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:test/test.dart';

import '../../../helpers/marketplace_test_fixtures.dart';
import '../../../helpers/memory_collection_store.dart';

void main() {
  late MemoryCollectionDocumentStore store;
  late ApprovedCleanerPolicy policy;

  setUp(() {
    store = MemoryCollectionDocumentStore();
    policy = ApprovedCleanerPolicy(
      profiles: MongoCleanerProfileRepository(documents: store),
    );
  });

  test('approved cleaner is allowed', () async {
    final user = testUserAccount();
    store.documents.add(testCleanerProfileRecord(userId: user.id).toDocument());
    final profile = await policy.requireApproved(user);
    expect(profile.onboardingStatus, CleanerOnboardingStatus.approved);
  });

  test('draft, pending, rejected, and missing profiles are blocked', () async {
    final user = testUserAccount();
    for (final status in [
      CleanerOnboardingStatus.draft,
      CleanerOnboardingStatus.pending,
      CleanerOnboardingStatus.rejected,
    ]) {
      store.documents
        ..clear()
        ..add(
          testCleanerProfileRecord(
            userId: user.id,
            status: status,
          ).toDocument(),
        );
      await expectLater(
        policy.requireApproved(user),
        throwsA(isA<CleanerNotApprovedException>()),
      );
    }
    store.documents.clear();
    await expectLater(
      policy.requireApproved(user),
      throwsA(isA<CleanerNotApprovedException>()),
    );
  });

  test('customer accounts are blocked by the policy', () async {
    final user = testUserAccount(role: UserRole.customer);
    store.documents.add(testCleanerProfileRecord(userId: user.id).toDocument());
    await expectLater(
      policy.requireApproved(user),
      throwsA(isA<CleanerNotApprovedException>()),
    );
  });
}
