import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/application/admin_cleaner_review_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/data/cleaner_profile_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/domain/cleaner_onboarding_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/domain/cleaner_profile.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/domain/cleaner_profile_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/domain/profile_validation_exception.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/data/mongo_user_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/data/user_document_store.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/account_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_account.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;
import 'package:test/test.dart';

import '../../../../helpers/memory_collection_store.dart';

class _MemoryUsers implements UserDocumentStore {
  final documents = <Map<String, dynamic>>[];

  @override
  Future<Map<String, dynamic>?> findOne(Map<String, dynamic> selector) async {
    for (final document in documents) {
      if (document['_id'] == selector['_id']) {
        return Map<String, dynamic>.from(document);
      }
    }
    return null;
  }

  @override
  Future<List<Map<String, dynamic>>> findMany(
    Map<String, dynamic> selector, {
    Map<String, int>? sort,
    int? limit,
  }) async {
    final ids = (selector['_id'] as Map)[r'$in'] as List;
    return [
      for (final document in documents)
        if (ids.contains(document['_id'])) Map<String, dynamic>.from(document),
    ];
  }

  @override
  Future<UserInsertResult> insertOne(Map<String, dynamic> document) async {
    documents.add(document);
    return const UserInsertResult.success();
  }

  @override
  Future<UserUpdateResult> updateOne({
    required Map<String, dynamic> selector,
    required Map<String, dynamic> update,
  }) async {
    return const UserUpdateResult.failed();
  }
}

void main() {
  late MemoryCollectionDocumentStore profiles;
  late _MemoryUsers users;
  late AdminCleanerReviewService service;
  late MongoCleanerProfileRepository cleanerRepo;
  final adminId = ObjectId.fromHexString('507f1f77bcf86cd799439001');
  final created = DateTime.utc(2026, 8, 25, 12);

  setUp(() {
    profiles = MemoryCollectionDocumentStore();
    users = _MemoryUsers();
    cleanerRepo = MongoCleanerProfileRepository(documents: profiles);
    service = AdminCleanerReviewService(
      profiles: cleanerRepo,
      users: MongoUserRepository(documents: users),
    );
  });

  UserAccount user(ObjectId id, String email) {
    return UserAccount(
      id: id,
      role: UserRole.cleaner,
      email: email,
      emailNormalized: email.toLowerCase(),
      passwordHash: 'hashed-password-must-not-appear',
      accountStatus: AccountStatus.active,
      emailVerified: false,
      createdAt: created,
      updatedAt: created,
    );
  }

  Future<CleanerProfile> seed({
    required ObjectId userId,
    required String email,
    required CleanerOnboardingStatus status,
    ObjectId? profileId,
  }) async {
    final account = user(userId, email);
    users.documents.add(account.toDocument());
    final profile = CleanerProfile(
      id: profileId ?? ObjectId(),
      userId: userId,
      fullName: 'Cleaner ${email.split('@').first}',
      bio: 'Experienced residential cleaner for apartments.',
      yearsExperience: 2,
      serviceArea: 'Dhaka',
      onboardingStatus: status,
      submittedAt: status == CleanerOnboardingStatus.draft ? null : created,
      createdAt: created,
      updatedAt: created,
    );
    profiles.documents.add(profile.toDocument());
    return profile;
  }

  group('AdminCleanerReviewService', () {
    test('lists pending by default and filters by status', () async {
      await seed(
        userId: ObjectId.fromHexString('507f1f77bcf86cd799439011'),
        email: 'pending.one@example.com',
        status: CleanerOnboardingStatus.pending,
      );
      await seed(
        userId: ObjectId.fromHexString('507f1f77bcf86cd799439012'),
        email: 'approved.one@example.com',
        status: CleanerOnboardingStatus.approved,
      );
      final pending = await service.listApplications(
        status: null,
        limit: null,
        after: null,
      );
      expect(pending.items, hasLength(1));
      expect(pending.items.single.email, equals('pending.one@example.com'));
      expect(
        pending.items.single.toPublicJson().containsKey('password_hash'),
        isFalse,
      );

      final approved = await service.listApplications(
        status: 'approved',
        limit: 20,
        after: null,
      );
      expect(approved.items, hasLength(1));
      expect(approved.items.single.email, equals('approved.one@example.com'));
    });

    test('validates limit and cursor', () async {
      expect(
        () => service.listApplications(status: null, limit: 0, after: null),
        throwsA(isA<ProfileValidationException>()),
      );
      expect(
        () => service.listApplications(status: null, limit: 51, after: null),
        throwsA(isA<ProfileValidationException>()),
      );
      expect(
        () => service.listApplications(
          status: null,
          limit: 20,
          after: 'not-an-object-id',
        ),
        throwsA(isA<ProfileValidationException>()),
      );
      expect(
        () =>
            service.listApplications(status: 'unknown', limit: 20, after: null),
        throwsA(isA<ProfileValidationException>()),
      );
    });

    test('paginates with next_cursor', () async {
      final firstId = ObjectId.fromHexString('507f1f77bcf86cd7994390a1');
      final secondId = ObjectId.fromHexString('507f1f77bcf86cd7994390a2');
      await seed(
        userId: ObjectId.fromHexString('507f1f77bcf86cd799439011'),
        email: 'first@example.com',
        status: CleanerOnboardingStatus.pending,
        profileId: firstId,
      );
      await seed(
        userId: ObjectId.fromHexString('507f1f77bcf86cd799439012'),
        email: 'second@example.com',
        status: CleanerOnboardingStatus.pending,
        profileId: secondId,
      );
      final page = await service.listApplications(
        status: 'pending',
        limit: 1,
        after: null,
      );
      expect(page.items, hasLength(1));
      expect(page.nextCursor, equals(firstId.oid));
      final next = await service.listApplications(
        status: 'pending',
        limit: 1,
        after: page.nextCursor,
      );
      expect(next.items.single.email, equals('second@example.com'));
      expect(next.nextCursor, isNull);
    });

    test('detail, missing application, approve and reject', () async {
      final target = ObjectId.fromHexString('507f1f77bcf86cd799439011');
      await seed(
        userId: target,
        email: 'pending.one@example.com',
        status: CleanerOnboardingStatus.pending,
      );
      final detail = await service.getApplication(target);
      expect(detail.user.email, equals('pending.one@example.com'));
      expect(
        detail.toPublicJson().toString(),
        isNot(contains('hashed-password')),
      );

      expect(
        () => service.getApplication(ObjectId()),
        throwsA(isA<CleanerApplicationNotFoundException>()),
      );

      final approved = await service.approve(
        targetUserId: target,
        adminUserId: adminId,
      );
      expect(
        approved.onboardingStatus,
        equals(CleanerOnboardingStatus.approved),
      );
      expect(approved.reviewedBy, equals(adminId));
      expect(approved.rejectionReason, isNull);
      expect(
        () => service.approve(targetUserId: target, adminUserId: adminId),
        throwsA(isA<InvalidOnboardingStateException>()),
      );
    });

    test('reject pending records reason and reviewed_by', () async {
      final target = ObjectId.fromHexString('507f1f77bcf86cd799439013');
      await seed(
        userId: target,
        email: 'pending.two@example.com',
        status: CleanerOnboardingStatus.pending,
      );
      expect(
        () => service.reject(
          targetUserId: target,
          adminUserId: adminId,
          reason: 'no',
        ),
        throwsA(isA<ProfileValidationException>()),
      );
      final rejected = await service.reject(
        targetUserId: target,
        adminUserId: adminId,
        reason: '  Documents were incomplete.  ',
      );
      expect(
        rejected.onboardingStatus,
        equals(CleanerOnboardingStatus.rejected),
      );
      expect(rejected.rejectionReason, equals('Documents were incomplete.'));
      expect(rejected.reviewedBy, equals(adminId));
      expect(
        () => service.reject(
          targetUserId: target,
          adminUserId: adminId,
          reason: 'Documents were incomplete.',
        ),
        throwsA(isA<InvalidOnboardingStateException>()),
      );
    });

    test('approve uses a pending-only selector', () async {
      final target = ObjectId.fromHexString('507f1f77bcf86cd799439014');
      await seed(
        userId: target,
        email: 'draft.one@example.com',
        status: CleanerOnboardingStatus.draft,
      );
      expect(
        () => service.approve(targetUserId: target, adminUserId: adminId),
        throwsA(isA<InvalidOnboardingStateException>()),
      );
      expect(
        profiles.lastUpdateSelector?['onboarding_status'],
        equals('pending'),
      );
      expect(profiles.lastUpdateSelector?['user_id'], equals(target));
    });
  });
}
