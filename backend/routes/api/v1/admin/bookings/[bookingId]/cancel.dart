import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/http/auth_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/http/role_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/application/admin_booking_operations_service.dart';
import 'package:home_cleaning_marketplace_api/src/http/json_response.dart';

Future<Response> onRequest(RequestContext context, String bookingId) {
  return handleRoleRequest(
    context,
    methods: {HttpMethod.post},
    action: (scoped) async {
      final id = parsePathObjectId(bookingId);
      if (id == null) {
        return bookingNotFoundResponse();
      }
      final json = await parseJsonObject(context.request);
      final bookings = context.read<AdminBookingOperationsService>();
      return jsonSuccess(
        await bookings.cancel(
          user: scoped.currentUser,
          bookingId: id,
          reasonRaw: json['reason'],
        ),
      );
    },
  );
}
