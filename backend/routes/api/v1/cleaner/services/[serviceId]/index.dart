import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/http/auth_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/http/role_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_services/application/cleaner_service_management_service.dart';
import 'package:home_cleaning_marketplace_api/src/http/json_response.dart';

Future<Response> onRequest(RequestContext context, String serviceId) {
  return handleRoleRequest(
    context,
    methods: {HttpMethod.put, HttpMethod.delete},
    action: (scoped) async {
      final id = parsePathObjectId(serviceId);
      if (id == null) {
        return serviceNotFoundResponse();
      }
      final management = context.read<CleanerServiceManagementService>();
      if (context.request.method == HttpMethod.delete) {
        final offering = await management.deactivate(
          user: scoped.currentUser,
          serviceId: id,
        );
        return jsonSuccess(<String, Object?>{'offering': offering});
      }
      final json = await parseJsonObject(context.request);
      final offering = await management.upsert(
        user: scoped.currentUser,
        serviceId: id,
        hourlyRateMinor: json['hourly_rate_minor'],
        currencyCode: json['currency_code'],
        isActive: json['is_active'],
      );
      return jsonSuccess(<String, Object?>{'offering': offering});
    },
  );
}
