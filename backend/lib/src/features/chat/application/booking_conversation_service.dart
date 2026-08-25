// ignore_for_file: public_member_api_docs
import 'package:home_cleaning_marketplace_api/src/features/authorization/forbidden_exception.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/data/booking_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/chat/data/conversation_member_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/chat/data/conversation_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/chat/data/message_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/chat/domain/chat_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/chat/domain/chat_message.dart';
import 'package:home_cleaning_marketplace_api/src/features/chat/domain/chat_validation.dart';
import 'package:home_cleaning_marketplace_api/src/features/chat/domain/conversation.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/data/cleaner_profile_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/data/customer_profile_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/notifications/application/notification_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/notifications/application/notification_sink.dart';
import 'package:home_cleaning_marketplace_api/src/features/notifications/domain/notification_type.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_account.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// HTTP-independent booking-scoped chat.
class BookingConversationService {
  /// Creates a conversation service.
  BookingConversationService({
    required BookingRepository bookings,
    required ConversationRepository conversations,
    required ConversationMemberRepository members,
    required MessageRepository messages,
    required CustomerProfileRepository customerProfiles,
    required CleanerProfileRepository cleanerProfiles,
    NotificationSink? notifications,
    DateTime Function()? clock,
  }) : _bookings = bookings,
       _conversations = conversations,
       _members = members,
       _messages = messages,
       _customerProfiles = customerProfiles,
       _cleanerProfiles = cleanerProfiles,
       _notifications = notifications ?? const NoOpNotificationSink(),
       _clock = clock ?? DateTime.now;

  final BookingRepository _bookings;
  final ConversationRepository _conversations;
  final ConversationMemberRepository _members;
  final MessageRepository _messages;
  final CustomerProfileRepository _customerProfiles;
  final CleanerProfileRepository _cleanerProfiles;
  final NotificationSink _notifications;
  final DateTime Function() _clock;

  /// Creates or returns the conversation for an owned booking.
  Future<({Map<String, Object?> conversation, bool created})>
  createOrGetForBooking({
    required UserAccount user,
    required ObjectId bookingId,
  }) async {
    _requireChatRole(user);
    final booking = await _ownedBooking(user: user, bookingId: bookingId);
    final existing = await _conversations.findByBookingId(booking.id);
    if (existing != null) {
      await _repairMembers(existing);
      final dto = await _detailDto(conversation: existing, user: user);
      return (conversation: dto.toJson(), created: false);
    }

    final now = _clock().toUtc();
    final conversation = Conversation(
      id: ObjectId(),
      bookingId: booking.id,
      customerUserId: booking.customerUserId,
      cleanerUserId: booking.cleanerUserId,
      createdAt: now,
      updatedAt: now,
      lastMessageAt: now,
    );
    Conversation stored;
    var created = true;
    try {
      stored = await _conversations.createForBooking(conversation);
    } on ConversationDuplicateKeyException {
      stored = await _conversations.findByBookingId(booking.id) ?? conversation;
      created = false;
    }
    await _repairMembers(stored);
    final dto = await _detailDto(conversation: stored, user: user);
    return (conversation: dto.toJson(), created: created);
  }

  /// Lists the authenticated user's conversations. Capped at 50, unpaginated.
  Future<Map<String, Object?>> listConversations({
    required UserAccount user,
  }) async {
    _requireChatRole(user);
    final conversations = await _conversations.listForUser(
      userId: user.id,
      role: user.role,
      limit: ChatValidation.conversationListCap,
    );
    if (conversations.isEmpty) {
      return const <String, Object?>{'items': <Map<String, Object?>>[]};
    }
    final bookingIds = conversations.map((item) => item.bookingId);
    final bookings = <ObjectId, Booking>{};
    for (final id in bookingIds) {
      final booking = await _bookings.findById(id);
      if (booking != null) {
        bookings[id] = booking;
      }
    }
    final latest = await _messages.latestForConversationIds(
      conversations.map((item) => item.id),
    );
    final items = <Map<String, Object?>>[];
    for (final conversation in conversations) {
      final booking = bookings[conversation.bookingId];
      if (booking == null) {
        continue;
      }
      final member = await _members.findMember(
        conversationId: conversation.id,
        userId: user.id,
      );
      final unread = await _messages.countUnreadForMember(
        conversationId: conversation.id,
        currentUserId: user.id,
        lastReadMessageId: member?.lastReadMessageId,
      );
      final last = latest[conversation.id];
      items.add(
        ConversationSummaryDto(
          id: conversation.id,
          bookingId: conversation.bookingId,
          otherPartyDisplayName: await _otherPartyName(
            conversation: conversation,
            user: user,
          ),
          otherPartyRole: conversation.customerUserId == user.id
              ? UserRole.cleaner.wireValue
              : UserRole.customer.wireValue,
          bookingStatus: booking.status.wireValue,
          lastMessagePreview: last == null
              ? null
              : NotificationService.preview(last.body),
          lastMessageAt: conversation.lastMessageAt ?? last?.createdAt,
          unreadCount: unread,
        ).toJson(),
      );
    }
    return <String, Object?>{'items': items};
  }

  /// Returns one owned conversation.
  Future<Map<String, Object?>> getConversation({
    required UserAccount user,
    required ObjectId conversationId,
  }) async {
    _requireChatRole(user);
    final conversation = await _requireMemberConversation(
      user: user,
      conversationId: conversationId,
    );
    final dto = await _detailDto(conversation: conversation, user: user);
    return dto.toJson();
  }

  /// Message history with keyset pagination.
  Future<Map<String, Object?>> listMessages({
    required UserAccount user,
    required ObjectId conversationId,
    Object? limitRaw,
    Object? before,
    Object? after,
  }) async {
    _requireChatRole(user);
    await _requireMemberConversation(
      user: user,
      conversationId: conversationId,
    );
    final query = ChatValidation.parseMessageQuery(
      limitRaw: limitRaw,
      before: before,
      after: after,
    );
    final List<ChatMessage> items;
    if (query.after != null) {
      items = await _messages.after(
        conversationId: conversationId,
        afterId: query.after!,
        limit: query.limit,
      );
    } else if (query.before != null) {
      items = await _messages.before(
        conversationId: conversationId,
        beforeId: query.before!,
        limit: query.limit,
      );
    } else {
      items = await _messages.latest(
        conversationId: conversationId,
        limit: query.limit,
      );
    }
    return <String, Object?>{
      'items': [
        for (final item in items) item.toPublicJson(currentUserId: user.id),
      ],
    };
  }

  /// Sends an immutable plaintext message. Idempotent by sender+key.
  Future<({Map<String, Object?> message, bool created})> sendMessage({
    required UserAccount user,
    required ObjectId conversationId,
    required String? idempotencyKeyRaw,
    required Object? bodyRaw,
  }) async {
    _requireChatRole(user);
    final conversation = await _requireMemberConversation(
      user: user,
      conversationId: conversationId,
    );
    final booking = await _bookings.findById(conversation.bookingId);
    if (booking == null || !booking.status.allowsChatMessages) {
      throw const ConversationReadOnlyException();
    }
    final key = ChatValidation.requireIdempotencyKey(idempotencyKeyRaw);
    final body = ChatValidation.requireBody(bodyRaw);
    final existing = await _messages.findBySenderIdempotency(
      conversationId: conversation.id,
      senderUserId: user.id,
      clientIdempotencyKey: key,
    );
    if (existing != null) {
      if (existing.body != body) {
        throw const IdempotencyKeyReusedException();
      }
      return (
        message: existing.toPublicJson(currentUserId: user.id),
        created: false,
      );
    }

    final now = _clock().toUtc();
    final message = ChatMessage(
      id: ObjectId(),
      conversationId: conversation.id,
      senderUserId: user.id,
      senderRole: user.role,
      body: body,
      clientIdempotencyKey: key,
      createdAt: now,
    );
    ChatMessage stored;
    try {
      stored = await _messages.create(message);
    } on MessageDuplicateKeyException {
      final replay = await _messages.findBySenderIdempotency(
        conversationId: conversation.id,
        senderUserId: user.id,
        clientIdempotencyKey: key,
      );
      if (replay == null) {
        throw const MessageWriteException();
      }
      if (replay.body != body) {
        throw const IdempotencyKeyReusedException();
      }
      return (
        message: replay.toPublicJson(currentUserId: user.id),
        created: false,
      );
    }

    await _conversations.touchLastMessage(
      id: conversation.id,
      lastMessageAt: now,
    );
    await _notifications.notifyBestEffort(
      userId: conversation.otherPartyId(user.id),
      type: NotificationType.messageReceived,
      title: 'New message',
      body: NotificationService.preview(body),
      dedupeKey: 'message:${stored.id.oid}',
      resourceType: 'booking',
      resourceId: conversation.bookingId,
    );
    return (
      message: stored.toPublicJson(currentUserId: user.id),
      created: true,
    );
  }

  /// Updates the authenticated member's read cursor only.
  Future<Map<String, Object?>> markRead({
    required UserAccount user,
    required ObjectId conversationId,
    Object? messageIdRaw,
  }) async {
    _requireChatRole(user);
    final conversation = await _requireMemberConversation(
      user: user,
      conversationId: conversationId,
    );
    ObjectId targetId;
    if (messageIdRaw == null) {
      final latest = await _messages.latest(
        conversationId: conversation.id,
        limit: 1,
      );
      if (latest.isEmpty) {
        return <String, Object?>{'unread_count': 0};
      }
      targetId = latest.last.id;
    } else {
      final parsed = _tryObjectId(messageIdRaw);
      if (parsed == null) {
        throw const ConversationNotFoundException();
      }
      final message = await _messages.findByIdInConversation(
        conversationId: conversation.id,
        messageId: parsed,
      );
      if (message == null) {
        throw const ConversationNotFoundException();
      }
      targetId = message.id;
    }
    await _members.updateReadState(
      conversationId: conversation.id,
      userId: user.id,
      lastReadMessageId: targetId,
      now: _clock().toUtc(),
    );
    final unread = await _messages.countUnreadForMember(
      conversationId: conversation.id,
      currentUserId: user.id,
      lastReadMessageId: targetId,
    );
    return <String, Object?>{'unread_count': unread};
  }

  void _requireChatRole(UserAccount user) {
    if (user.role != UserRole.customer && user.role != UserRole.cleaner) {
      throw const ForbiddenException();
    }
  }

  Future<Booking> _ownedBooking({
    required UserAccount user,
    required ObjectId bookingId,
  }) async {
    final booking = user.role == UserRole.customer
        ? await _bookings.findCustomerBookingById(
            id: bookingId,
            customerUserId: user.id,
          )
        : await _bookings.findCleanerBookingById(
            id: bookingId,
            cleanerUserId: user.id,
          );
    if (booking == null) {
      throw const ConversationNotFoundException();
    }
    return booking;
  }

  Future<Conversation> _requireMemberConversation({
    required UserAccount user,
    required ObjectId conversationId,
  }) async {
    final conversation = await _conversations.findById(conversationId);
    if (conversation == null || !conversation.isParticipant(user.id)) {
      throw const ConversationNotFoundException();
    }
    final booking = await _bookings.findById(conversation.bookingId);
    if (booking == null) {
      throw const ConversationNotFoundException();
    }
    await _repairMembers(conversation);
    return conversation;
  }

  Future<void> _repairMembers(Conversation conversation) async {
    final now = _clock().toUtc();
    await _members.upsertMember(
      conversationId: conversation.id,
      userId: conversation.customerUserId,
      role: UserRole.customer,
      now: now,
    );
    await _members.upsertMember(
      conversationId: conversation.id,
      userId: conversation.cleanerUserId,
      role: UserRole.cleaner,
      now: now,
    );
  }

  Future<ConversationDetailDto> _detailDto({
    required Conversation conversation,
    required UserAccount user,
  }) async {
    final booking = await _bookings.findById(conversation.bookingId);
    if (booking == null) {
      throw const ConversationNotFoundException();
    }
    final member = await _members.findMember(
      conversationId: conversation.id,
      userId: user.id,
    );
    final unread = await _messages.countUnreadForMember(
      conversationId: conversation.id,
      currentUserId: user.id,
      lastReadMessageId: member?.lastReadMessageId,
    );
    return ConversationDetailDto(
      id: conversation.id,
      bookingId: conversation.bookingId,
      otherPartyDisplayName: await _otherPartyName(
        conversation: conversation,
        user: user,
      ),
      otherPartyRole: conversation.customerUserId == user.id
          ? UserRole.cleaner.wireValue
          : UserRole.customer.wireValue,
      bookingStatus: booking.status.wireValue,
      readOnly: !booking.status.allowsChatMessages,
      unreadCount: unread,
      lastMessageAt: conversation.lastMessageAt,
    );
  }

  Future<String> _otherPartyName({
    required Conversation conversation,
    required UserAccount user,
  }) async {
    if (user.id == conversation.customerUserId) {
      final profile = await _cleanerProfiles.findByUserId(
        conversation.cleanerUserId,
      );
      return profile?.fullName ?? 'Cleaner';
    }
    final profile = await _customerProfiles.findByUserId(
      conversation.customerUserId,
    );
    return profile?.fullName ?? 'Customer';
  }

  ObjectId? _tryObjectId(Object? raw) {
    if (raw is ObjectId) {
      return raw;
    }
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        return ObjectId.fromHexString(raw.trim());
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
