// ignore_for_file: public_member_api_docs
import 'package:home_cleaning_marketplace_api/src/features/audit/domain/audit_action.dart';
import 'package:home_cleaning_marketplace_api/src/features/audit/domain/audit_exceptions.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Audit log query validation.
abstract final class AuditValidation {
  static const int defaultLimit = 20;
  static const int minLimit = 1;
  static const int maxLimit = 50;

  static AuditAction? optionalAction(Object? raw) {
    if (raw == null) {
      return null;
    }
    if (raw is! String) {
      throw const InvalidAuditQueryException();
    }
    try {
      return AuditAction.fromWire(raw.trim());
    } on FormatException {
      throw const InvalidAuditQueryException();
    }
  }

  static String? optionalTargetType(Object? raw) {
    if (raw == null) {
      return null;
    }
    if (raw is! String) {
      throw const InvalidAuditQueryException();
    }
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    switch (trimmed) {
      case AuditTargetType.user:
      case AuditTargetType.cleanerProfile:
      case AuditTargetType.review:
      case AuditTargetType.payment:
      case AuditTargetType.dispute:
      case AuditTargetType.booking:
        return trimmed;
      default:
        throw const InvalidAuditQueryException();
    }
  }

  static int requireLimit(Object? raw) {
    if (raw == null) {
      return defaultLimit;
    }
    final value = raw is int
        ? raw
        : raw is String
        ? int.tryParse(raw.trim())
        : null;
    if (value == null || value < minLimit || value > maxLimit) {
      throw const InvalidAuditQueryException();
    }
    return value;
  }

  static ObjectId? optionalObjectId(Object? raw) {
    if (raw == null) {
      return null;
    }
    if (raw is ObjectId) {
      return raw;
    }
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        return ObjectId.fromHexString(raw.trim());
      } catch (_) {
        throw const AuditLogNotFoundException();
      }
    }
    throw const AuditLogNotFoundException();
  }

  static DateTime? optionalUtcDateTime(Object? raw) {
    if (raw == null) {
      return null;
    }
    if (raw is DateTime) {
      return raw.toUtc();
    }
    if (raw is String && raw.trim().isNotEmpty) {
      final parsed = DateTime.tryParse(raw.trim());
      if (parsed == null) {
        throw const InvalidAuditQueryException();
      }
      return parsed.toUtc();
    }
    throw const InvalidAuditQueryException();
  }
}
