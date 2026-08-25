import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/http/auth_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/http/role_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/features/reviews/application/customer_review_service.dart';
import 'package:home_cleaning_marketplace_api/src/http/json_response.dart';

Future<Response> onRequest(RequestContext context, String bookingId) {
  return handleRoleRequest(
    context,
    methods: {HttpMethod.get, HttpMethod.put},
    action: (scoped) async {
      final id = parsePathObjectId(bookingId);
      if (id == null) {
        return bookingNotFoundResponse();
      }
      final reviews = context.read<CustomerReviewService>();
      if (context.request.method == HttpMethod.get) {
        return jsonSuccess(
          await reviews.getForBooking(
            user: scoped.currentUser,
            bookingId: id,
          ),
        );
      }
      final json = await parseJsonObject(context.request);
      final result = await reviews.upsertForCompletedBooking(
        user: scoped.currentUser,
        bookingId: id,
        ratingRaw: json['rating'],
        commentRaw: json['comment'],
      );
      return jsonSuccess(
        <String, Object?>{'review': result.review},
        statusCode: result.created ? HttpStatus.created : HttpStatus.ok,
      );
    },
  );
}
