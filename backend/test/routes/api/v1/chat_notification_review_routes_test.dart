import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/authenticated_user_context.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/data/booking_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/domain/booking_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/chat/application/booking_conversation_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/chat/data/conversation_member_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/chat/data/conversation_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/chat/data/message_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/data/cleaner_profile_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/data/customer_profile_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/domain/customer_profile.dart';
import 'package:home_cleaning_marketplace_api/src/features/notifications/application/notification_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/notifications/data/notification_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/reviews/application/admin_review_moderation_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/reviews/application/customer_review_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/reviews/data/review_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_role.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;
import 'package:test/test.dart';

import '../../../../routes/api/v1/admin/reviews/[reviewId]/hide.dart'
    as hide_route;
import '../../../../routes/api/v1/conversations/[conversationId]/messages.dart'
    as messages_route;
import '../../../../routes/api/v1/conversations/booking/[bookingId]/index.dart'
    as booking_conversation;
import '../../../../routes/api/v1/customer/bookings/[bookingId]/review.dart'
    as customer_review;
import '../../../../routes/api/v1/notifications/unread-count.dart'
    as unread_route;
import '../../../helpers/account_route_test_utils.dart';
import '../../../helpers/auth_route_test_utils.dart';
import '../../../helpers/marketplace_test_fixtures.dart';
import '../../../helpers/memory_collection_store.dart';
import '../../../helpers/payment_test_fixtures.dart';
import '../../../helpers/recording_notification_sink.dart';

class _MockContext extends Mock implements RequestContext {}

void main() {
  late ObjectId customerId;
  late ObjectId cleanerId;
  late ObjectId bookingId;
  late MemoryCollectionDocumentStore bookings;
  late BookingConversationService chat;
  late CustomerReviewService customerReviews;
  late AdminReviewModerationService adminReviews;
  late NotificationService notifications;
  late AuthenticatedUserContext customerScoped;
  late AuthenticatedUserContext adminScoped;

  final customer = fakeAuthResult().user;

  setUp(() {
    customerId = customer.id;
    cleanerId = ObjectId.fromHexString('507f1f77bcf86cd7994390c2');
    bookingId = ObjectId.fromHexString('507f1f77bcf86cd7994390b1');
    bookings = MemoryCollectionDocumentStore();
    final conversations = MemoryCollectionDocumentStore();
    final members = MemoryCollectionDocumentStore();
    final messages = MemoryCollectionDocumentStore();
    final notificationDocs = MemoryCollectionDocumentStore();
    final reviews = MemoryCollectionDocumentStore();
    final customerProfiles = MemoryCollectionDocumentStore();
    final cleanerProfiles = MemoryCollectionDocumentStore();
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
        status: BookingStatus.completed,
      ).toDocument(),
    );
    final bookingRepo = MongoBookingRepository(documents: bookings);
    final reviewRepo = MongoReviewRepository(documents: reviews);
    final sink = RecordingNotificationSink();
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
    customerReviews = CustomerReviewService(
      bookings: bookingRepo,
      reviews: reviewRepo,
      notifications: sink,
    );
    adminReviews = AdminReviewModerationService(reviews: reviewRepo);
    notifications = NotificationService(
      notifications: MongoNotificationRepository(documents: notificationDocs),
    );
    customerScoped = AuthenticatedUserContext(
      principal: fakePrincipal(),
      currentUser: customer,
    );
    adminScoped = AuthenticatedUserContext(
      principal: fakePrincipal(role: UserRole.admin),
      currentUser: testUserAccount(role: UserRole.admin),
    );
  });

  RequestContext customerCtx(Request request) {
    final context = _MockContext();
    when(() => context.request).thenReturn(request);
    when(() => context.read<AuthenticatedUserContext>()).thenReturn(
      customerScoped,
    );
    when(() => context.read<BookingConversationService>()).thenReturn(chat);
    when(() => context.read<CustomerReviewService>()).thenReturn(
      customerReviews,
    );
    when(() => context.read<NotificationService>()).thenReturn(notifications);
    return context;
  }

  test(
    'conversation create is 201 then 200 and messages omit idempotency',
    () async {
      bookings.documents[0] = testConfirmedBooking(
        customerId: customerId,
        cleanerId: cleanerId,
        id: bookingId,
      ).toDocument();
      final created = await booking_conversation.onRequest(
        customerCtx(
          Request(
            'POST',
            Uri.parse(
              'http://localhost/api/v1/conversations/booking/${bookingId.oid}',
            ),
          ),
        ),
        bookingId.oid,
      );
      expect(created.statusCode, equals(HttpStatus.created));
      final replay = await booking_conversation.onRequest(
        customerCtx(
          Request(
            'POST',
            Uri.parse(
              'http://localhost/api/v1/conversations/booking/${bookingId.oid}',
            ),
          ),
        ),
        bookingId.oid,
      );
      expect(replay.statusCode, equals(HttpStatus.ok));
      final createdBody =
          jsonDecode(await created.body()) as Map<String, dynamic>;
      final createdData = createdBody['data'] as Map<String, dynamic>;
      final conversation = createdData['conversation'] as Map<String, dynamic>;
      final conversationId = conversation['id'] as String;
      final sent = await messages_route.onRequest(
        customerCtx(
          Request(
            'POST',
            Uri.parse(
              'http://localhost/api/v1/conversations/$conversationId/messages',
            ),
            headers: <String, String>{
              HttpHeaders.contentTypeHeader: 'application/json',
              'Idempotency-Key': 'message-idempotency-16',
            },
            body: jsonEncode(<String, String>{'body': 'Hello'}),
          ),
        ),
        conversationId,
      );
      expect(sent.statusCode, equals(HttpStatus.created));
      expect(await sent.body(), isNot(contains('client_idempotency_key')));
    },
  );

  test('customer review create then update and admin hide', () async {
    final created = await customer_review.onRequest(
      customerCtx(
        Request(
          'PUT',
          Uri.parse(
            'http://localhost/api/v1/customer/bookings/${bookingId.oid}/review',
          ),
          headers: <String, String>{
            HttpHeaders.contentTypeHeader: 'application/json',
          },
          body: jsonEncode(<String, Object?>{'rating': 5, 'comment': 'Great'}),
        ),
      ),
      bookingId.oid,
    );
    expect(created.statusCode, equals(HttpStatus.created));
    final updated = await customer_review.onRequest(
      customerCtx(
        Request(
          'PUT',
          Uri.parse(
            'http://localhost/api/v1/customer/bookings/${bookingId.oid}/review',
          ),
          headers: <String, String>{
            HttpHeaders.contentTypeHeader: 'application/json',
          },
          body: jsonEncode(<String, Object?>{'rating': 4, 'comment': 'Good'}),
        ),
      ),
      bookingId.oid,
    );
    expect(updated.statusCode, equals(HttpStatus.ok));
    final createdBody =
        jsonDecode(await created.body()) as Map<String, dynamic>;
    final createdData = createdBody['data'] as Map<String, dynamic>;
    final review = createdData['review'] as Map<String, dynamic>;
    final reviewId = review['id'] as String;
    final adminContext = _MockContext();
    when(() => adminContext.request).thenReturn(
      Request(
        'POST',
        Uri.parse('http://localhost/api/v1/admin/reviews/$reviewId/hide'),
        headers: <String, String>{
          HttpHeaders.contentTypeHeader: 'application/json',
        },
        body: jsonEncode(<String, String>{'reason': 'Off-topic comment here'}),
      ),
    );
    when(
      () => adminContext.read<AuthenticatedUserContext>(),
    ).thenReturn(adminScoped);
    when(
      () => adminContext.read<AdminReviewModerationService>(),
    ).thenReturn(adminReviews);
    final hidden = await hide_route.onRequest(adminContext, reviewId);
    expect(hidden.statusCode, equals(HttpStatus.ok));
    final hiddenBody = jsonDecode(await hidden.body()) as Map;
    expect((hiddenBody['data'] as Map)['moderation_status'], 'hidden');
  });

  test('unread count is zero for a new user', () async {
    final response = await unread_route.onRequest(
      customerCtx(
        Request(
          'GET',
          Uri.parse('http://localhost/api/v1/notifications/unread-count'),
        ),
      ),
    );
    expect(response.statusCode, equals(HttpStatus.ok));
    final body = jsonDecode(await response.body()) as Map;
    expect((body['data'] as Map)['unread_count'], 0);
  });
}
