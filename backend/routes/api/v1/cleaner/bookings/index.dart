import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/http/role_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/application/cleaner_booking_service.dart';
import 'package:home_cleaning_marketplace_api/src/http/json_response.dart';

Future<Response> onRequest(RequestContext context) {
  return handleRoleRequest(
    context,
    methods: {HttpMethod.get},
    action: (scoped) async {
      final query = context.request.uri.queryParameters;
      final bookings = context.read<CleanerBookingService>();
      final data = await bookings.listBookings(
        user: scoped.currentUser,
        status: query['status'],
        limitRaw: query['limit'],
        after: query['after'],
      );
      return jsonSuccess(data);
    },
  );
}
