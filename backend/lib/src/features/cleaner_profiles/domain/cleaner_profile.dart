import 'package:home_cleaning_marketplace_api/src/database/document_fields.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/domain/cleaner_onboarding_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/domain/cleaner_profile_exceptions.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Persisted cleaner marketplace profile and current onboarding lifecycle.
class CleanerProfile {
  /// Creates a cleaner profile. [id] is the MongoDB `_id`.
  const CleanerProfile({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.bio,
    required this.yearsExperience,
    required this.serviceArea,
    required this.onboardingStatus,
    required this.createdAt,
    required this.updatedAt,
    this.phoneE164,
    this.submittedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.rejectionReason,
  });

  /// Parses a MongoDB `cleaner_profiles` document.
  factory CleanerProfile.fromDocument(Map<String, dynamic> document) {
    Exception error(String message) => CleanerProfileDocumentException(message);
    return CleanerProfile(
      id: DocumentFields.requireObjectId(document, '_id', error),
      userId: DocumentFields.requireObjectId(document, 'user_id', error),
      fullName: DocumentFields.requireString(document, 'full_name', error),
      phoneE164: DocumentFields.optionalString(document, 'phone_e164', error),
      bio: DocumentFields.requireString(document, 'bio', error),
      yearsExperience: DocumentFields.requireInt(
        document,
        'years_experience',
        error,
      ),
      serviceArea: DocumentFields.requireString(
        document,
        'service_area',
        error,
      ),
      onboardingStatus: CleanerOnboardingStatus.fromWire(
        DocumentFields.requireString(document, 'onboarding_status', error),
      ),
      submittedAt: DocumentFields.optionalUtcDateTime(
        document,
        'submitted_at',
        error,
      ),
      reviewedAt: DocumentFields.optionalUtcDateTime(
        document,
        'reviewed_at',
        error,
      ),
      reviewedBy: DocumentFields.optionalObjectId(
        document,
        'reviewed_by',
        error,
      ),
      rejectionReason: DocumentFields.optionalString(
        document,
        'rejection_reason',
        error,
      ),
      createdAt: DocumentFields.requireUtcDateTime(
        document,
        'created_at',
        error,
      ),
      updatedAt: DocumentFields.requireUtcDateTime(
        document,
        'updated_at',
        error,
      ),
    );
  }

  /// MongoDB `_id`.
  final ObjectId id;

  /// Owning `users._id`. Never taken from an HTTP body.
  final ObjectId userId;

  /// Trimmed human-readable name.
  final String fullName;

  /// Optional simplified E.164 phone.
  final String? phoneE164;

  /// Plain-text bio.
  final String bio;

  /// Years of experience, 0–50 inclusive.
  final int yearsExperience;

  /// Human-readable service-area text. Not a geofence.
  final String serviceArea;

  /// Current onboarding lifecycle status.
  final CleanerOnboardingStatus onboardingStatus;

  /// When the current pending review was submitted.
  final DateTime? submittedAt;

  /// When an administrator last reviewed the pending application.
  final DateTime? reviewedAt;

  /// Administrator `users._id` who last reviewed, if any.
  final ObjectId? reviewedBy;

  /// Rejection reason when status is rejected.
  final String? rejectionReason;

  /// UTC creation timestamp.
  final DateTime createdAt;

  /// UTC last-update timestamp.
  final DateTime updatedAt;

  /// MongoDB document representation.
  Map<String, dynamic> toDocument() {
    return <String, dynamic>{
      '_id': id,
      'user_id': userId,
      'full_name': fullName,
      'phone_e164': phoneE164,
      'bio': bio,
      'years_experience': yearsExperience,
      'service_area': serviceArea,
      'onboarding_status': onboardingStatus.wireValue,
      'submitted_at': submittedAt?.toUtc(),
      'reviewed_at': reviewedAt?.toUtc(),
      'reviewed_by': reviewedBy,
      'rejection_reason': rejectionReason,
      'created_at': createdAt.toUtc(),
      'updated_at': updatedAt.toUtc(),
    };
  }

  /// Safe public JSON for cleaner and admin responses.
  Map<String, Object?> toPublicJson() {
    return <String, Object?>{
      'id': id.oid,
      'user_id': userId.oid,
      'full_name': fullName,
      'phone_e164': phoneE164,
      'bio': bio,
      'years_experience': yearsExperience,
      'service_area': serviceArea,
      'onboarding_status': onboardingStatus.wireValue,
      'submitted_at': submittedAt?.toUtc().toIso8601String(),
      'reviewed_at': reviewedAt?.toUtc().toIso8601String(),
      'reviewed_by': reviewedBy?.oid,
      'rejection_reason': rejectionReason,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  @override
  String toString() =>
      'CleanerProfile(id: ${id.oid}, userId: ${userId.oid}, '
      'status: ${onboardingStatus.wireValue})';
}
