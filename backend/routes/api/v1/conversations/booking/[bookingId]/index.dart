import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/http/role_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/features/chat/application/booking_conversation_service.dart';
import 'package:home_cleaning_marketplace_api/src/http/json_response.dart';

Future<Response> onRequest(RequestContext context, String bookingId) {
  return handleRoleRequest(
    context,
    methods: {HttpMethod.post},
    action: (scoped) async {
      final id = parsePathObjectId(bookingId);
      if (id == null) {
        return conversationNotFoundResponse();
      }
      final conversations = context.read<BookingConversationService>();
      final result = await conversations.createOrGetForBooking(
        user: scoped.currentUser,
        bookingId: id,
      );
      return jsonSuccess(
        <String, Object?>{'conversation': result.conversation},
        statusCode: result.created ? HttpStatus.created : HttpStatus.ok,
      );
    },
  );
}
