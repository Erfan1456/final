import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/http/role_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/features/reviews/application/admin_review_moderation_service.dart';
import 'package:home_cleaning_marketplace_api/src/http/json_response.dart';

Future<Response> onRequest(RequestContext context, String reviewId) {
  return handleRoleRequest(
    context,
    methods: {HttpMethod.post},
    action: (scoped) async {
      final id = parsePathObjectId(reviewId);
      if (id == null) {
        return reviewNotFoundResponse();
      }
      final reviews = context.read<AdminReviewModerationService>();
      return jsonSuccess(await reviews.unhide(reviewId: id));
    },
  );
}
