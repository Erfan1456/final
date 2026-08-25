import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/http/auth_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/http/role_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/application/customer_booking_service.dart';
import 'package:home_cleaning_marketplace_api/src/http/json_response.dart';

Future<Response> onRequest(RequestContext context) {
  return handleRoleRequest(
    context,
    methods: {HttpMethod.get, HttpMethod.post},
    action: (scoped) async {
      final bookings = context.read<CustomerBookingService>();
      if (context.request.method == HttpMethod.get) {
        final query = context.request.uri.queryParameters;
        final data = await bookings.listBookings(
          user: scoped.currentUser,
          status: query['status'],
          limitRaw: query['limit'],
          after: query['after'],
        );
        return jsonSuccess(data);
      }
      final json = await parseJsonObject(context.request);
      final headers = context.request.headers;
      final result = await bookings.createBooking(
        user: scoped.currentUser,
        idempotencyKeyRaw:
            headers['idempotency-key'] ?? headers['Idempotency-Key'],
        availabilitySlotIdRaw: json['availability_slot_id'],
        addressIdRaw: json['address_id'],
        customerNotesRaw: json['customer_notes'],
      );
      return jsonSuccess(
        <String, Object?>{'booking': result.booking},
        statusCode: result.created ? HttpStatus.created : HttpStatus.ok,
      );
    },
  );
}
