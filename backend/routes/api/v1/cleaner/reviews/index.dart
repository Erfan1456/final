import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/http/role_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/features/reviews/application/cleaner_review_service.dart';
import 'package:home_cleaning_marketplace_api/src/http/json_response.dart';

Future<Response> onRequest(RequestContext context) {
  return handleRoleRequest(
    context,
    methods: {HttpMethod.get},
    action: (scoped) async {
      final query = context.request.uri.queryParameters;
      final reviews = context.read<CleanerReviewService>();
      return jsonSuccess(
        await reviews.listOwnReviews(
          user: scoped.currentUser,
          status: query['status'],
          limitRaw: query['limit'],
          after: query['after'],
        ),
      );
    },
  );
}
