import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/http/auth_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/http/role_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/features/chat/application/booking_conversation_service.dart';
import 'package:home_cleaning_marketplace_api/src/http/json_response.dart';

Future<Response> onRequest(RequestContext context, String conversationId) {
  return handleRoleRequest(
    context,
    methods: {HttpMethod.get, HttpMethod.post},
    action: (scoped) async {
      final id = parsePathObjectId(conversationId);
      if (id == null) {
        return conversationNotFoundResponse();
      }
      final conversations = context.read<BookingConversationService>();
      if (context.request.method == HttpMethod.get) {
        final query = context.request.uri.queryParameters;
        return jsonSuccess(
          await conversations.listMessages(
            user: scoped.currentUser,
            conversationId: id,
            limitRaw: query['limit'],
            before: query['before'],
            after: query['after'],
          ),
        );
      }
      final json = await parseJsonObject(context.request);
      final headers = context.request.headers;
      final result = await conversations.sendMessage(
        user: scoped.currentUser,
        conversationId: id,
        idempotencyKeyRaw:
            headers['idempotency-key'] ?? headers['Idempotency-Key'],
        bodyRaw: json['body'],
      );
      return jsonSuccess(
        <String, Object?>{'message': result.message},
        statusCode: result.created ? HttpStatus.created : HttpStatus.ok,
      );
    },
  );
}
