import 'package:home_cleaning_marketplace_api/src/database/document_write_results.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/forbidden_exception.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/data/booking_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/chat/application/booking_conversation_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/chat/data/conversation_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/features/chat/data/conversation_member_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/features/chat/data/conversation_member_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/chat/data/conversation_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/chat/data/message_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/features/chat/data/message_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/chat/domain/chat_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/data/cleaner_profile_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/data/customer_profile_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/domain/customer_profile.dart';
import 'package:home_cleaning_marketplace_api/src/features/notifications/application/notification_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/notifications/data/notification_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/features/notifications/data/notification_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/notifications/domain/notification_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/notifications/domain/notification_type.dart';
import 'package:home_cleaning_marketplace_api/src/features/reviews/application/admin_review_moderation_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/reviews/application/cleaner_review_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/reviews/application/customer_review_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/reviews/data/review_indexes.dart';
import 'package:home_cleaning_marketplace_api/src/features/reviews/data/review_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/reviews/domain/review_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;
import 'package:test/test.dart';

import '../../../helpers/marketplace_test_fixtures.dart';
import '../../../helpers/memory_collection_store.dart';
import '../../../helpers/payment_test_fixtures.dart';
import '../../../helpers/recording_notification_sink.dart';

void main() {
  late ObjectId customerId;
  late ObjectId cleanerId;
  late ObjectId bookingId;
  late MemoryCollectionDocumentStore bookings;
  late MemoryCollectionDocumentStore conversations;
  late MemoryCollectionDocumentStore members;
  late MemoryCollectionDocumentStore messages;
  late MemoryCollectionDocumentStore notifications;
  late MemoryCollectionDocumentStore reviews;
  late MemoryCollectionDocumentStore customerProfiles;
  late MemoryCollectionDocumentStore cleanerProfiles;
  late BookingConversationService chat;
  late NotificationService notificationService;
  late CustomerReviewService customerReviews;
  late CleanerReviewService cleanerReviews;
  late AdminReviewModerationService adminReviews;
  late RecordingNotificationSink sink;
  late MongoBookingRepository bookingRepo;
  late MongoReviewRepository reviewRepo;

  final customer = testUserAccount(
    id: ObjectId.fromHexString('507f1f77bcf86cd7994390c1'),
    role: UserRole.customer,
    email: 'pat.customer@example.com',
  );
  final cleaner = testUserAccount(
    id: ObjectId.fromHexString('507f1f77bcf86cd7994390c2'),
    email: 'lee.cleaner@example.com',
  );
  final admin = testUserAccount(
    id: ObjectId.fromHexString('507f1f77bcf86cd7994390c3'),
    role: UserRole.admin,
    email: 'admin@example.com',
  );
  final foreign = testUserAccount(
    id: ObjectId.fromHexString('507f1f77bcf86cd7994390c4'),
    role: UserRole.customer,
    email: 'foreign@example.com',
  );

  setUp(() {
    customerId = customer.id;
    cleanerId = cleaner.id;
    bookingId = ObjectId.fromHexString('507f1f77bcf86cd7994390b1');
    bookings = MemoryCollectionDocumentStore();
    conversations = MemoryCollectionDocumentStore();
    members = MemoryCollectionDocumentStore();
    messages = MemoryCollectionDocumentStore();
    notifications = MemoryCollectionDocumentStore();
    reviews = MemoryCollectionDocumentStore();
    customerProfiles = MemoryCollectionDocumentStore();
    cleanerProfiles = MemoryCollectionDocumentStore();
    sink = RecordingNotificationSink();
    bookingRepo = MongoBookingRepository(documents: bookings);
    reviewRepo = MongoReviewRepository(documents: reviews);
    customerProfiles.documents.add(
      CustomerProfile(
        id: ObjectId(),
        userId: customerId,
        fullName: 'Pat Customer',
        createdAt: marketplaceTestNow(),
        updatedAt: marketplaceTestNow(),
      ).toDocument(),
    );
    cleanerProfiles.documents.add(
      testCleanerProfileRecord(userId: cleanerId).toDocument(),
    );
    bookings.documents.add(
      testConfirmedBooking(
        customerId: customerId,
        cleanerId: cleanerId,
        id: bookingId,
      ).toDocument(),
    );
    chat = BookingConversationService(
      bookings: bookingRepo,
      conversations: MongoConversationRepository(documents: conversations),
      members: MongoConversationMemberRepository(documents: members),
      messages: MongoMessageRepository(documents: messages),
      customerProfiles: MongoCustomerProfileRepository(
        documents: customerProfiles,
      ),
      cleanerProfiles: MongoCleanerProfileRepository(
        documents: cleanerProfiles,
      ),
      notifications: sink,
    );
    notificationService = NotificationService(
      notifications: MongoNotificationRepository(documents: notifications),
    );
    customerReviews = CustomerReviewService(
      bookings: bookingRepo,
      reviews: reviewRepo,
      notifications: sink,
    );
    cleanerReviews = CleanerReviewService(reviews: reviewRepo);
    adminReviews = AdminReviewModerationService(reviews: reviewRepo);
  });

  group('chat authorization', () {
    test('customer and cleaner create/get the same conversation', () async {
      final first = await chat.createOrGetForBooking(
        user: customer,
        bookingId: bookingId,
      );
      expect(first.created, isTrue);
      final replay = await chat.createOrGetForBooking(
        user: customer,
        bookingId: bookingId,
      );
      expect(replay.created, isFalse);
      expect(replay.conversation['id'], first.conversation['id']);
      final cleanerView = await chat.createOrGetForBooking(
        user: cleaner,
        bookingId: bookingId,
      );
      expect(cleanerView.conversation['id'], first.conversation['id']);
      expect(members.documents, hasLength(2));
    });

    test('foreign customer cannot see the conversation', () async {
      await chat.createOrGetForBooking(user: customer, bookingId: bookingId);
      await expectLater(
        () => chat.createOrGetForBooking(user: foreign, bookingId: bookingId),
        throwsA(isA<ConversationNotFoundException>()),
      );
    });

    test('admin cannot participate in booking chat', () async {
      await expectLater(
        () => chat.createOrGetForBooking(user: admin, bookingId: bookingId),
        throwsA(isA<ForbiddenException>()),
      );
    });
  });

  group('messages', () {
    test('send, replay, conflict, and read-only', () async {
      final created = await chat.createOrGetForBooking(
        user: customer,
        bookingId: bookingId,
      );
      final conversationId = ObjectId.fromHexString(
        created.conversation['id']! as String,
      );
      const key = 'message-idempotency-16';
      final first = await chat.sendMessage(
        user: customer,
        conversationId: conversationId,
        idempotencyKeyRaw: key,
        bodyRaw: 'Hello\nthere',
      );
      expect(first.created, isTrue);
      expect(first.message['is_mine'], isTrue);
      expect(first.message.containsKey('client_idempotency_key'), isFalse);
      final replay = await chat.sendMessage(
        user: customer,
        conversationId: conversationId,
        idempotencyKeyRaw: key,
        bodyRaw: 'Hello\nthere',
      );
      expect(replay.created, isFalse);
      expect(sink.created, hasLength(1));
      await expectLater(
        () => chat.sendMessage(
          user: customer,
          conversationId: conversationId,
          idempotencyKeyRaw: key,
          bodyRaw: 'Different',
        ),
        throwsA(isA<IdempotencyKeyReusedException>()),
      );
      await expectLater(
        () => chat.sendMessage(
          user: customer,
          conversationId: conversationId,
          idempotencyKeyRaw: 'another-idempotency1',
          bodyRaw: 'bad\u0001',
        ),
        throwsA(isA<InvalidMessageException>()),
      );

      bookings.documents[0] = testConfirmedBooking(
        customerId: customerId,
        cleanerId: cleanerId,
        id: bookingId,
        status: BookingStatus.completed,
      ).toDocument();
      await expectLater(
        () => chat.sendMessage(
          user: customer,
          conversationId: conversationId,
          idempotencyKeyRaw: 'closed-booking-key16',
          bodyRaw: 'too late',
        ),
        throwsA(isA<ConversationReadOnlyException>()),
      );
    });

    test('pagination before/after and both-cursor rejection', () async {
      final created = await chat.createOrGetForBooking(
        user: customer,
        bookingId: bookingId,
      );
      final conversationId = ObjectId.fromHexString(
        created.conversation['id']! as String,
      );
      for (var i = 0; i < 3; i++) {
        await chat.sendMessage(
          user: customer,
          conversationId: conversationId,
          idempotencyKeyRaw: 'pagination-key-16-$i',
          bodyRaw: 'm$i',
        );
      }
      final latest = await chat.listMessages(
        user: customer,
        conversationId: conversationId,
        limitRaw: 2,
      );
      final items = latest['items']! as List<Object?>;
      expect(items, hasLength(2));
      final firstId = (items.first! as Map<String, dynamic>)['id'] as String;
      final lastId = (items.last! as Map<String, dynamic>)['id'] as String;
      final older = await chat.listMessages(
        user: customer,
        conversationId: conversationId,
        before: firstId,
      );
      expect(older['items']! as List<Object?>, isNotEmpty);
      final newer = await chat.listMessages(
        user: customer,
        conversationId: conversationId,
        after: lastId,
      );
      expect(newer['items'], isA<List<Object?>>());
      await expectLater(
        () => chat.listMessages(
          user: customer,
          conversationId: conversationId,
          before: firstId,
          after: lastId,
        ),
        throwsA(isA<InvalidMessageCursorException>()),
      );
    });

    test('mark read updates only the authenticated member', () async {
      final created = await chat.createOrGetForBooking(
        user: customer,
        bookingId: bookingId,
      );
      final conversationId = ObjectId.fromHexString(
        created.conversation['id']! as String,
      );
      await chat.sendMessage(
        user: customer,
        conversationId: conversationId,
        idempotencyKeyRaw: 'customer-message-16',
        bodyRaw: 'Hello cleaner',
      );
      final cleanerBefore = await chat.getConversation(
        user: cleaner,
        conversationId: conversationId,
      );
      expect(cleanerBefore['unread_count'], greaterThan(0));
      await chat.markRead(user: customer, conversationId: conversationId);
      final cleanerAfter = await chat.getConversation(
        user: cleaner,
        conversationId: conversationId,
      );
      expect(cleanerAfter['unread_count'], greaterThan(0));
      await chat.markRead(user: cleaner, conversationId: conversationId);
      final cleanerRead = await chat.getConversation(
        user: cleaner,
        conversationId: conversationId,
      );
      expect(cleanerRead['unread_count'], 0);
    });
  });

  group('notifications', () {
    test('list, unread, mark one, mark all, foreign 404', () async {
      await notificationService.createIdempotentNotification(
        userId: customerId,
        type: NotificationType.bookingConfirmed,
        title: 'Your booking was confirmed',
        body: 'Your booking was confirmed.',
        dedupeKey: 'booking:${bookingId.oid}:confirmed',
        resourceType: 'booking',
        resourceId: bookingId,
      );
      await notificationService.createIdempotentNotification(
        userId: customerId,
        type: NotificationType.bookingConfirmed,
        title: 'Your booking was confirmed',
        body: 'Your booking was confirmed.',
        dedupeKey: 'booking:${bookingId.oid}:confirmed',
        resourceType: 'booking',
        resourceId: bookingId,
      );
      expect(notifications.documents, hasLength(1));
      expect(
        (await notificationService.unreadCount(user: customer))['unread_count'],
        1,
      );
      final listed = await notificationService.listForUser(user: customer);
      final id = ObjectId.fromHexString(
        ((listed['items']! as List).first as Map)['id'] as String,
      );
      await notificationService.markRead(user: customer, notificationId: id);
      expect(
        (await notificationService.unreadCount(user: customer))['unread_count'],
        0,
      );
      await expectLater(
        () => notificationService.markRead(
          user: cleaner,
          notificationId: id,
        ),
        throwsA(isA<NotificationNotFoundException>()),
      );
      await notificationService.markAllRead(user: customer);
    });

    test('best-effort failure does not throw', () async {
      sink.throwOnCreate = true;
      await sink.notifyBestEffort(
        userId: customerId,
        type: NotificationType.messageReceived,
        title: 'New message',
        body: 'hi',
        dedupeKey: 'message:x',
      );
    });
  });

  group('reviews', () {
    test('completed booking create/update and hidden stays hidden', () async {
      bookings.documents[0] = testConfirmedBooking(
        customerId: customerId,
        cleanerId: cleanerId,
        id: bookingId,
        status: BookingStatus.completed,
      ).toDocument();
      final created = await customerReviews.upsertForCompletedBooking(
        user: customer,
        bookingId: bookingId,
        ratingRaw: 5,
        commentRaw: 'Great job',
      );
      expect(created.created, isTrue);
      expect(sink.created.last['type'], NotificationType.reviewReceived);
      final updated = await customerReviews.upsertForCompletedBooking(
        user: customer,
        bookingId: bookingId,
        ratingRaw: 4,
        commentRaw: 'Still good',
      );
      expect(updated.created, isFalse);
      expect(
        sink.created.where((Map<String, Object?> row) {
          return row['type'] == NotificationType.reviewReceived;
        }),
        hasLength(1),
      );

      final reviewId = ObjectId.fromHexString(created.review['id']! as String);
      await adminReviews.hide(
        user: admin,
        reviewId: reviewId,
        reasonRaw: 'Off-topic review text',
      );
      final afterHide = await customerReviews.upsertForCompletedBooking(
        user: customer,
        bookingId: bookingId,
        ratingRaw: 3,
        commentRaw: 'Edited while hidden',
      );
      expect(afterHide.review['moderation_status'], 'hidden');
      expect(afterHide.review['rating'], 3);

      await expectLater(
        () => customerReviews.upsertForCompletedBooking(
          user: customer,
          bookingId: bookingId,
          ratingRaw: 0,
          commentRaw: 'nope',
        ),
        throwsA(isA<InvalidReviewRatingException>()),
      );
      bookings.documents[0] = testConfirmedBooking(
        customerId: customerId,
        cleanerId: cleanerId,
        id: bookingId,
      ).toDocument();
      await expectLater(
        () => customerReviews.upsertForCompletedBooking(
          user: customer,
          bookingId: bookingId,
          ratingRaw: 5,
          commentRaw: 'too soon',
        ),
        throwsA(isA<ReviewNotAllowedException>()),
      );
    });

    test('cleaner and admin list omit customer contact data', () async {
      bookings.documents[0] = testConfirmedBooking(
        customerId: customerId,
        cleanerId: cleanerId,
        id: bookingId,
        status: BookingStatus.completed,
      ).toDocument();
      await customerReviews.upsertForCompletedBooking(
        user: customer,
        bookingId: bookingId,
        ratingRaw: 5,
        commentRaw: 'Nice',
      );
      final cleanerList = await cleanerReviews.listOwnReviews(user: cleaner);
      final cleanerItems = cleanerList['items']! as List<Object?>;
      final item = cleanerItems.first! as Map<String, dynamic>;
      expect(item['reviewer_display_name'], 'Verified customer');
      expect(item.containsKey('customer_user_id'), isFalse);
      expect(item.toString(), isNot(contains('@')));
      final adminList = await adminReviews.list();
      expect(adminList['items']! as List<Object?>, isNotEmpty);
    });
  });

  group('indexes', () {
    test('conversation, message, notification, and review specs', () async {
      final requested = <Map<String, Object?>>[];
      Future<void> capture({
        required String collectionName,
        required Map<String, dynamic> keys,
        required bool unique,
        required String name,
      }) async {
        requested.add(<String, Object?>{
          'collection': collectionName,
          'keys': keys,
          'unique': unique,
          'name': name,
        });
      }

      await ensureConversationIndexes(ensureIndex: capture);
      await ensureConversationMemberIndexes(ensureIndex: capture);
      await ensureMessageIndexes(ensureIndex: capture);
      await ensureNotificationIndexes(ensureIndex: capture);
      await ensureReviewIndexes(ensureIndex: capture);
      expect(
        requested.map((row) => row['name']),
        containsAll(<String>[
          conversationsBookingUniqueIndexName,
          conversationsCustomerLastMessageIndexName,
          conversationsCleanerLastMessageIndexName,
          conversationMembersConversationUserUniqueIndexName,
          messagesConversationIdDescIndexName,
          messagesSenderIdempotencyUniqueIndexName,
          notificationsUserIdDescIndexName,
          notificationsUserReadIdDescIndexName,
          notificationsUserDedupeUniqueIndexName,
          reviewsBookingUniqueIndexName,
          reviewsCleanerStatusIdDescIndexName,
          reviewsCustomerIdDescIndexName,
          reviewsStatusRatingIdDescIndexName,
        ]),
      );
      expect(
        requested.map((row) => row['name']),
        isNot(contains('conversation_members_user_conversation')),
      );
    });
  });

  test('duplicate message insert race compares body', () async {
    final created = await chat.createOrGetForBooking(
      user: customer,
      bookingId: bookingId,
    );
    final conversationId = ObjectId.fromHexString(
      created.conversation['id']! as String,
    );
    messages.insertResult = const DocumentInsertResult.duplicate();
    await expectLater(
      () => chat.sendMessage(
        user: customer,
        conversationId: conversationId,
        idempotencyKeyRaw: 'race-idempotency-16',
        bodyRaw: 'hello',
      ),
      throwsA(isA<MessageWriteException>()),
    );
  });
}
