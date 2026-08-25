import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/http/role_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/features/discovery/application/cleaner_discovery_service.dart';
import 'package:home_cleaning_marketplace_api/src/http/json_response.dart';

Future<Response> onRequest(RequestContext context, String cleanerUserId) {
  return handleRoleRequest(
    context,
    methods: {HttpMethod.get},
    action: (scoped) async {
      final id = parsePathObjectId(cleanerUserId);
      if (id == null) {
        return cleanerNotFoundResponse();
      }
      final discovery = context.read<CleanerDiscoveryService>();
      final detail = await discovery.getCleanerDetail(
        cleanerUserId: id,
        serviceSlug: context.request.uri.queryParameters['service'],
      );
      return jsonSuccess(detail.toJson());
    },
  );
}
