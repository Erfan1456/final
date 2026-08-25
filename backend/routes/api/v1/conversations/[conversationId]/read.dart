import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/http/auth_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/http/role_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/features/chat/application/booking_conversation_service.dart';
import 'package:home_cleaning_marketplace_api/src/http/json_response.dart';

Future<Response> onRequest(RequestContext context, String conversationId) {
  return handleRoleRequest(
    context,
    methods: {HttpMethod.post},
    action: (scoped) async {
      final id = parsePathObjectId(conversationId);
      if (id == null) {
        return conversationNotFoundResponse();
      }
      final json =
          (context.request.headers['content-type'] ?? '').contains(
            'application/json',
          )
          ? await parseJsonObject(context.request)
          : const <String, dynamic>{};
      final conversations = context.read<BookingConversationService>();
      return jsonSuccess(
        await conversations.markRead(
          user: scoped.currentUser,
          conversationId: id,
          messageIdRaw: json['message_id'],
        ),
      );
    },
  );
}
