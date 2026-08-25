import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/http/role_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/features/notifications/application/notification_service.dart';
import 'package:home_cleaning_marketplace_api/src/http/json_response.dart';

Future<Response> onRequest(RequestContext context, String notificationId) {
  return handleRoleRequest(
    context,
    methods: {HttpMethod.post},
    action: (scoped) async {
      final id = parsePathObjectId(notificationId);
      if (id == null) {
        return notificationNotFoundResponse();
      }
      final notifications = context.read<NotificationService>();
      return jsonSuccess(
        await notifications.markRead(
          user: scoped.currentUser,
          notificationId: id,
        ),
      );
    },
  );
}
