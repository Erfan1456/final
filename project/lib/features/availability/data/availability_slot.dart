/// Open future availability window.
class AvailabilitySlot {
  const AvailabilitySlot({
    required this.id,
    required this.serviceId,
    required this.startAt,
    required this.endAt,
    this.createdAt,
    this.updatedAt,
  });

  factory AvailabilitySlot.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final serviceId = json['service_id'];
    final startAt = json['start_at'];
    final endAt = json['end_at'];
    final createdAt = json['created_at'];
    final updatedAt = json['updated_at'];
    if (id is! String ||
        serviceId is! String ||
        startAt is! String ||
        endAt is! String) {
      throw const FormatException('Availability slot JSON is invalid.');
    }
    return AvailabilitySlot(
      id: id,
      serviceId: serviceId,
      startAt: DateTime.parse(startAt).toUtc(),
      endAt: DateTime.parse(endAt).toUtc(),
      createdAt: createdAt is String ? DateTime.parse(createdAt).toUtc() : null,
      updatedAt: updatedAt is String ? DateTime.parse(updatedAt).toUtc() : null,
    );
  }

  final String id;
  final String serviceId;
  final DateTime startAt;
  final DateTime endAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Duration get duration => endAt.difference(startAt);

  /// ISO-8601 UTC timestamp with explicit Z offset.
  static String toApiTimestamp(DateTime value) {
    return value.toUtc().toIso8601String();
  }
}
