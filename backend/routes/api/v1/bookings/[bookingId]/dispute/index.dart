import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/http/auth_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/http/role_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/features/disputes/application/booking_dispute_service.dart';
import 'package:home_cleaning_marketplace_api/src/http/json_response.dart';

Future<Response> onRequest(RequestContext context, String bookingId) {
  return handleRoleRequest(
    context,
    methods: {HttpMethod.get, HttpMethod.post},
    action: (scoped) async {
      final id = parsePathObjectId(bookingId);
      if (id == null) {
        return bookingNotFoundResponse();
      }
      final disputes = context.read<BookingDisputeService>();
      if (context.request.method == HttpMethod.get) {
        return jsonSuccess(
          await disputes.getForBooking(
            user: scoped.currentUser,
            bookingId: id,
          ),
        );
      }
      final json = await parseJsonObject(context.request);
      return jsonSuccess(
        await disputes.create(
          user: scoped.currentUser,
          bookingId: id,
          categoryRaw: json['category'],
          subjectRaw: json['subject'],
          descriptionRaw: json['description'],
        ),
        statusCode: HttpStatus.created,
      );
    },
  );
}
