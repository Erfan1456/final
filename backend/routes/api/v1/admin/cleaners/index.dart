import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/http/role_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/application/admin_cleaner_review_service.dart';
import 'package:home_cleaning_marketplace_api/src/http/json_response.dart';

Future<Response> onRequest(RequestContext context) {
  return handleRoleRequest(
    context,
    methods: {HttpMethod.get},
    action: (scoped) async {
      final admin = context.read<AdminCleanerReviewService>();
      final query = context.request.uri.queryParameters;
      final page = await admin.listApplications(
        status: query['status'],
        limit: query['limit'],
        after: query['after'],
      );
      return jsonSuccess(<String, Object?>{
        'items': [
          for (final item in page.items) item.toPublicJson(),
        ],
        'next_cursor': page.nextCursor,
      });
    },
  );
}
