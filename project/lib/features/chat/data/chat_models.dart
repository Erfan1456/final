import 'package:home_cleaning_marketplace/features/bookings/data/booking_models.dart';

class ConversationSummary {
  const ConversationSummary({
    required this.id,
    required this.bookingId,
    required this.otherPartyDisplayName,
    required this.otherPartyRole,
    required this.bookingStatus,
    required this.unreadCount,
    this.lastMessagePreview,
    this.lastMessageAt,
  });

  factory ConversationSummary.fromJson(Map<String, dynamic> json) {
    return ConversationSummary(
      id: _requireString(json, 'id'),
      bookingId: _requireString(json, 'booking_id'),
      otherPartyDisplayName: _requireString(json, 'other_party_display_name'),
      otherPartyRole: _requireString(json, 'other_party_role'),
      bookingStatus: BookingStatus.fromWire(
        _requireString(json, 'booking_status'),
      ),
      lastMessagePreview: json['last_message_preview'] is String
          ? json['last_message_preview'] as String
          : null,
      lastMessageAt: _optionalDate(json, 'last_message_at'),
      unreadCount: _requireInt(json, 'unread_count'),
    );
  }

  final String id;
  final String bookingId;
  final String otherPartyDisplayName;
  final String otherPartyRole;
  final BookingStatus bookingStatus;
  final String? lastMessagePreview;
  final DateTime? lastMessageAt;
  final int unreadCount;

  bool get isReadOnly => isConversationReadOnly(bookingStatus: bookingStatus);
}

class ConversationDetail {
  const ConversationDetail({
    required this.id,
    required this.bookingId,
    required this.otherPartyDisplayName,
    required this.otherPartyRole,
    required this.bookingStatus,
    required this.unreadCount,
    required this.readOnly,
    this.lastMessagePreview,
    this.lastMessageAt,
  });

  factory ConversationDetail.fromJson(Map<String, dynamic> json) {
    final bookingStatus = BookingStatus.fromWire(
      _requireString(json, 'booking_status'),
    );
    final readOnlyFlag = json['read_only'];
    return ConversationDetail(
      id: _requireString(json, 'id'),
      bookingId: _requireString(json, 'booking_id'),
      otherPartyDisplayName: _requireString(json, 'other_party_display_name'),
      otherPartyRole: _requireString(json, 'other_party_role'),
      bookingStatus: bookingStatus,
      lastMessagePreview: json['last_message_preview'] is String
          ? json['last_message_preview'] as String
          : null,
      lastMessageAt: _optionalDate(json, 'last_message_at'),
      unreadCount: _requireInt(json, 'unread_count'),
      readOnly:
          readOnlyFlag == true ||
          isConversationReadOnly(bookingStatus: bookingStatus),
    );
  }

  final String id;
  final String bookingId;
  final String otherPartyDisplayName;
  final String otherPartyRole;
  final BookingStatus bookingStatus;
  final String? lastMessagePreview;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final bool readOnly;
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderUserId,
    required this.senderRole,
    required this.body,
    required this.createdAt,
    required this.isMine,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: _requireString(json, 'id'),
      conversationId: _requireString(json, 'conversation_id'),
      senderUserId: _requireString(json, 'sender_user_id'),
      senderRole: _requireString(json, 'sender_role'),
      body: _requireString(json, 'body'),
      createdAt: DateTime.parse(_requireString(json, 'created_at')).toUtc(),
      isMine: json['is_mine'] == true,
    );
  }

  final String id;
  final String conversationId;
  final String senderUserId;
  final String senderRole;
  final String body;
  final DateTime createdAt;
  final bool isMine;
}

bool isConversationReadOnly({
  required BookingStatus bookingStatus,
  bool readOnly = false,
}) {
  if (readOnly) {
    return true;
  }
  switch (bookingStatus) {
    case BookingStatus.completed:
    case BookingStatus.declined:
    case BookingStatus.cancelled:
      return true;
    case BookingStatus.pending:
    case BookingStatus.confirmed:
    case BookingStatus.inProgress:
    case BookingStatus.unknown:
      return false;
  }
}

String _requireString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) {
    throw FormatException('Chat JSON field $key is invalid.');
  }
  return value;
}

int _requireInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! int) {
    throw FormatException('Chat JSON field $key is invalid.');
  }
  return value;
}

DateTime? _optionalDate(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is! String) {
    throw FormatException('Chat JSON field $key is invalid.');
  }
  return DateTime.parse(value).toUtc();
}
