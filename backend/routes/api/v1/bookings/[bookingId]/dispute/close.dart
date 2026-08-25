import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/http/role_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/features/disputes/application/booking_dispute_service.dart';
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
      final disputes = context.read<BookingDisputeService>();
      return jsonSuccess(
        await disputes.close(user: scoped.currentUser, bookingId: id),
      );
    },
  );
}
