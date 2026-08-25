import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/http/auth_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/http/role_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/application/admin_cleaner_review_service.dart';
import 'package:home_cleaning_marketplace_api/src/http/json_response.dart';

Future<Response> onRequest(RequestContext context, String userId) {
  return handleRoleRequest(
    context,
    methods: {HttpMethod.post},
    action: (scoped) async {
      final id = parsePathObjectId(userId);
      if (id == null) {
        return cleanerApplicationNotFoundResponse();
      }
      final json = await parseJsonObject(context.request);
      final admin = context.read<AdminCleanerReviewService>();
      final profile = await admin.reject(
        targetUserId: id,
        adminUserId: scoped.currentUser.id,
        reason: json['reason'],
      );
      return jsonSuccess(<String, Object?>{
        'profile': profile.toPublicJson(),
      });
    },
  );
}
