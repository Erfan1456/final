import 'package:home_cleaning_marketplace_api/src/database/collection_document_store.dart';
import 'package:home_cleaning_marketplace_api/src/database/collection_names.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/domain/cleaner_onboarding_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/domain/cleaner_profile.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/domain/cleaner_profile_exceptions.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Validated cleaner profile fields for create/update.
class CleanerProfileWriteData {
  /// Creates validated cleaner profile fields.
  const CleanerProfileWriteData({
    required this.fullName,
    required this.bio,
    required this.yearsExperience,
    required this.serviceArea,
    this.phoneE164,
  });

  /// Trimmed full name.
  final String fullName;

  /// Optional E.164 phone.
  final String? phoneE164;

  /// Plain-text bio.
  final String bio;

  /// Years of experience, 0–50.
  final int yearsExperience;

  /// Human-readable service-area text.
  final String serviceArea;
}

/// One page of cleaner applications for admin listing.
class CleanerApplicationPage {
  /// Creates a page of [items] with an optional [nextCursor].
  const CleanerApplicationPage({
    required this.items,
    required this.nextCursor,
  });

  /// Page items in `_id` ascending order.
  final List<CleanerProfile> items;

  /// Hex ObjectId cursor for the next page, or `null`.
  final String? nextCursor;
}

/// Persistence contract for cleaner onboarding profiles.
abstract class CleanerProfileRepository {
  /// Returns the profile owned by [userId], or `null`.
  Future<CleanerProfile?> findByUserId(ObjectId userId);

  /// Returns profiles whose `user_id` is in [ids]. Missing ids are omitted.
  Future<List<CleanerProfile>> findByUserIds(Iterable<ObjectId> ids);

  /// Inserts a draft profile. Duplicate `user_id` is reported.
  Future<CleanerProfile> createDraft({
    required ObjectId userId,
    required CleanerProfileWriteData data,
  });

  /// Updates editable fields only when status is draft or rejected.
  Future<CleanerProfile?> updateEditableAtomically({
    required ObjectId userId,
    required CleanerProfileWriteData data,
  });

  /// Transitions draft/rejected to pending using a conditional selector.
  Future<CleanerProfile?> submitAtomically(ObjectId userId);

  /// Lists applications for [status] with `_id` ascending and optional cursor.
  Future<CleanerApplicationPage> listByStatusPage({
    required CleanerOnboardingStatus status,
    required int limit,
    ObjectId? after,
  });

  /// Approves only when status is pending.
  Future<CleanerProfile?> approvePendingAtomically({
    required ObjectId userId,
    required ObjectId reviewedBy,
  });

  /// Rejects only when status is pending.
  Future<CleanerProfile?> rejectPendingAtomically({
    required ObjectId userId,
    required ObjectId reviewedBy,
    required String reason,
  });
}

/// MongoDB implementation of [CleanerProfileRepository].
class MongoCleanerProfileRepository implements CleanerProfileRepository {
  /// Creates a repository over [documents].
  MongoCleanerProfileRepository({required CollectionDocumentStore documents})
    : _documents = documents;

  /// Creates a repository using the cleaner_profiles collection on [db].
  factory MongoCleanerProfileRepository.fromDb(Db db) {
    return MongoCleanerProfileRepository(
      documents: MongoCollectionDocumentStore(
        db.collection(CollectionNames.cleanerProfiles),
      ),
    );
  }

  final CollectionDocumentStore _documents;

  @override
  Future<CleanerProfile?> findByUserId(ObjectId userId) {
    return _find(<String, dynamic>{'user_id': userId});
  }

  @override
  Future<List<CleanerProfile>> findByUserIds(Iterable<ObjectId> ids) async {
    final unique = ids.toSet().toList();
    if (unique.isEmpty) {
      return const <CleanerProfile>[];
    }
    final documents = await _documents.findMany(
      selector: <String, dynamic>{
        'user_id': <String, dynamic>{r'$in': unique},
      },
    );
    return documents.map(CleanerProfile.fromDocument).toList();
  }

  @override
  Future<CleanerProfile> createDraft({
    required ObjectId userId,
    required CleanerProfileWriteData data,
  }) async {
    final now = DateTime.now().toUtc();
    final profile = CleanerProfile(
      id: ObjectId(),
      userId: userId,
      fullName: data.fullName,
      phoneE164: data.phoneE164,
      bio: data.bio,
      yearsExperience: data.yearsExperience,
      serviceArea: data.serviceArea,
      onboardingStatus: CleanerOnboardingStatus.draft,
      createdAt: now,
      updatedAt: now,
    );
    final result = await _documents.insertOne(profile.toDocument());
    if (result.isDuplicateKey) {
      throw const DuplicateCleanerProfileException();
    }
    if (!result.isSuccess) {
      throw const CleanerProfileWriteException();
    }
    return profile;
  }

  @override
  Future<CleanerProfile?> updateEditableAtomically({
    required ObjectId userId,
    required CleanerProfileWriteData data,
  }) {
    final now = DateTime.now().toUtc();
    return _modify(
      selector: <String, dynamic>{
        'user_id': userId,
        'onboarding_status': <String, dynamic>{
          r'$in': <String>[
            CleanerOnboardingStatus.draft.wireValue,
            CleanerOnboardingStatus.rejected.wireValue,
          ],
        },
      },
      update: <String, dynamic>{
        r'$set': <String, dynamic>{
          'full_name': data.fullName,
          'phone_e164': data.phoneE164,
          'bio': data.bio,
          'years_experience': data.yearsExperience,
          'service_area': data.serviceArea,
          'updated_at': now,
        },
      },
    );
  }

  @override
  Future<CleanerProfile?> submitAtomically(ObjectId userId) {
    final now = DateTime.now().toUtc();
    return _modify(
      selector: <String, dynamic>{
        'user_id': userId,
        'onboarding_status': <String, dynamic>{
          r'$in': <String>[
            CleanerOnboardingStatus.draft.wireValue,
            CleanerOnboardingStatus.rejected.wireValue,
          ],
        },
      },
      update: <String, dynamic>{
        r'$set': <String, dynamic>{
          'onboarding_status': CleanerOnboardingStatus.pending.wireValue,
          'submitted_at': now,
          'updated_at': now,
          'rejection_reason': null,
          'reviewed_at': null,
          'reviewed_by': null,
        },
      },
    );
  }

  @override
  Future<CleanerApplicationPage> listByStatusPage({
    required CleanerOnboardingStatus status,
    required int limit,
    ObjectId? after,
  }) async {
    final selector = <String, dynamic>{
      'onboarding_status': status.wireValue,
    };
    if (after != null) {
      selector['_id'] = <String, dynamic>{r'$gt': after};
    }
    final documents = await _documents.findMany(
      selector: selector,
      sort: const <String, int>{'_id': 1},
      limit: limit + 1,
    );
    final hasMore = documents.length > limit;
    final page = hasMore ? documents.sublist(0, limit) : documents;
    final items = page.map(CleanerProfile.fromDocument).toList();
    return CleanerApplicationPage(
      items: items,
      nextCursor: hasMore ? items.last.id.oid : null,
    );
  }

  @override
  Future<CleanerProfile?> approvePendingAtomically({
    required ObjectId userId,
    required ObjectId reviewedBy,
  }) {
    final now = DateTime.now().toUtc();
    return _modify(
      selector: <String, dynamic>{
        'user_id': userId,
        'onboarding_status': CleanerOnboardingStatus.pending.wireValue,
      },
      update: <String, dynamic>{
        r'$set': <String, dynamic>{
          'onboarding_status': CleanerOnboardingStatus.approved.wireValue,
          'reviewed_at': now,
          'reviewed_by': reviewedBy,
          'rejection_reason': null,
          'updated_at': now,
        },
      },
    );
  }

  @override
  Future<CleanerProfile?> rejectPendingAtomically({
    required ObjectId userId,
    required ObjectId reviewedBy,
    required String reason,
  }) {
    final now = DateTime.now().toUtc();
    return _modify(
      selector: <String, dynamic>{
        'user_id': userId,
        'onboarding_status': CleanerOnboardingStatus.pending.wireValue,
      },
      update: <String, dynamic>{
        r'$set': <String, dynamic>{
          'onboarding_status': CleanerOnboardingStatus.rejected.wireValue,
          'reviewed_at': now,
          'reviewed_by': reviewedBy,
          'rejection_reason': reason,
          'updated_at': now,
        },
      },
    );
  }

  Future<CleanerProfile?> _modify({
    required Map<String, dynamic> selector,
    required Map<String, dynamic> update,
  }) async {
    final result = await _documents.updateOne(
      selector: selector,
      update: update,
    );
    if (!result.isSuccess && result.matched) {
      throw const CleanerProfileWriteException();
    }
    if (!result.matched) {
      return null;
    }
    final userId = selector['user_id'];
    if (userId is! ObjectId) {
      throw const CleanerProfileWriteException();
    }
    return findByUserId(userId);
  }

  Future<CleanerProfile?> _find(Map<String, dynamic> selector) async {
    final document = await _documents.findOne(selector);
    if (document == null) {
      return null;
    }
    return CleanerProfile.fromDocument(document);
  }
}
