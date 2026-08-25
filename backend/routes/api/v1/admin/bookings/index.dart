import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/http/role_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/application/admin_booking_operations_service.dart';
import 'package:home_cleaning_marketplace_api/src/http/json_response.dart';

Future<Response> onRequest(RequestContext context) {
  return handleRoleRequest(
    context,
    methods: {HttpMethod.get},
    action: (scoped) async {
      final query = context.request.uri.queryParameters;
      final bookings = context.read<AdminBookingOperationsService>();
      return jsonSuccess(
        await bookings.list(
          status: query['status'],
          customerUserId: query['customer_user_id'],
          cleanerUserId: query['cleaner_user_id'],
          serviceId: query['service_id'],
          from: query['from'],
          to: query['to'],
          limitRaw: query['limit'],
          after: query['after'],
        ),
      );
    },
  );
}
