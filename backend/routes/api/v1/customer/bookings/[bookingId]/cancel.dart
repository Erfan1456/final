import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/http/auth_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/http/role_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/application/customer_booking_service.dart';
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
      final bookings = context.read<CustomerBookingService>();
      final booking = await bookings.cancelBooking(
        user: scoped.currentUser,
        bookingId: id,
        reasonRaw: json['reason'],
      );
      return jsonSuccess(<String, Object?>{'booking': booking});
    },
  );
}
