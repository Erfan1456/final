import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/http/role_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/features/notifications/application/notification_service.dart';
import 'package:home_cleaning_marketplace_api/src/http/json_response.dart';

Future<Response> onRequest(RequestContext context) {
  return handleRoleRequest(
    context,
    methods: {HttpMethod.get},
    action: (scoped) async {
      final query = context.request.uri.queryParameters;
      final notifications = context.read<NotificationService>();
      return jsonSuccess(
        await notifications.listForUser(
          user: scoped.currentUser,
          unread: query['unread'],
          limitRaw: query['limit'],
          after: query['after'],
        ),
      );
    },
  );
}
