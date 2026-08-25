import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/http/role_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/application/admin_cleaner_review_service.dart';
import 'package:home_cleaning_marketplace_api/src/http/json_response.dart';

Future<Response> onRequest(RequestContext context, String userId) {
  return handleRoleRequest(
    context,
    methods: {HttpMethod.get},
    action: (scoped) async {
      final id = parsePathObjectId(userId);
      if (id == null) {
        return cleanerApplicationNotFoundResponse();
      }
      final admin = context.read<AdminCleanerReviewService>();
      final detail = await admin.getApplication(id);
      return jsonSuccess(detail.toPublicJson());
    },
  );
}
