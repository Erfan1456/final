import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// Sanitized BSON field readers. Messages must not include field values.
abstract final class DocumentFields {
  /// Requires [field] to be an [ObjectId].
  static ObjectId requireObjectId(
    Map<String, dynamic> document,
    String field,
    Exception Function(String message) onError,
  ) {
    final value = document[field];
    if (value is ObjectId) {
      return value;
    }
    throw onError('$field must be ObjectId.');
  }

  /// Returns [field] as [ObjectId], or `null` when absent or JSON null.
  static ObjectId? optionalObjectId(
    Map<String, dynamic> document,
    String field,
    Exception Function(String message) onError,
  ) {
    if (!document.containsKey(field) || document[field] == null) {
      return null;
    }
    final value = document[field];
    if (value is ObjectId) {
      return value;
    }
    throw onError('$field must be ObjectId or null.');
  }

  /// Requires [field] to be a [String].
  static String requireString(
    Map<String, dynamic> document,
    String field,
    Exception Function(String message) onError,
  ) {
    final value = document[field];
    if (value is String) {
      return value;
    }
    throw onError('$field must be String.');
  }

  /// Returns [field] as [String], or `null` when absent or JSON null.
  static String? optionalString(
    Map<String, dynamic> document,
    String field,
    Exception Function(String message) onError,
  ) {
    if (!document.containsKey(field) || document[field] == null) {
      return null;
    }
    final value = document[field];
    if (value is String) {
      return value;
    }
    throw onError('$field must be String or null.');
  }

  /// Requires [field] to be a Dart [int]. Rejects [double] and other [num].
  static int requireInt(
    Map<String, dynamic> document,
    String field,
    Exception Function(String message) onError,
  ) {
    final value = document[field];
    if (value is int) {
      return value;
    }
    throw onError('$field must be int.');
  }

  /// Requires [field] to be a Dart [bool]. Rejects other types.
  static bool requireBool(
    Map<String, dynamic> document,
    String field,
    Exception Function(String message) onError,
  ) {
    final value = document[field];
    if (value is bool) {
      return value;
    }
    throw onError('$field must be bool.');
  }

  /// Requires [field] to be a UTC [DateTime].
  static DateTime requireUtcDateTime(
    Map<String, dynamic> document,
    String field,
    Exception Function(String message) onError,
  ) {
    final value = document[field];
    if (value is DateTime) {
      return value.toUtc();
    }
    throw onError('$field must be DateTime.');
  }

  /// Returns [field] as UTC [DateTime], or `null` when absent or JSON null.
  static DateTime? optionalUtcDateTime(
    Map<String, dynamic> document,
    String field,
    Exception Function(String message) onError,
  ) {
    if (!document.containsKey(field) || document[field] == null) {
      return null;
    }
    final value = document[field];
    if (value is DateTime) {
      return value.toUtc();
    }
    throw onError('$field must be DateTime or null.');
  }
}
