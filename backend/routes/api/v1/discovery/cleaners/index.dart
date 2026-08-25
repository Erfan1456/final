import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/http/role_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/features/discovery/application/cleaner_discovery_service.dart';
import 'package:home_cleaning_marketplace_api/src/http/json_response.dart';

Future<Response> onRequest(RequestContext context) {
  return handleRoleRequest(
    context,
    methods: {HttpMethod.get},
    action: (scoped) async {
      final query = context.request.uri.queryParameters;
      final discovery = context.read<CleanerDiscoveryService>();
      final page = await discovery.listCleaners(
        serviceSlug: query['service'],
        currency: query['currency'],
        maxRateMinor: query['max_rate_minor'],
        minExperience: query['min_experience'],
        availableFrom: query['available_from'],
        availableTo: query['available_to'],
        limitRaw: query['limit'],
        after: query['after'],
      );
      return jsonSuccess(page.toJson());
    },
  );
}
