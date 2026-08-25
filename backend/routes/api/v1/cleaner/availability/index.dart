import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/http/auth_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/http/role_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/features/availability/application/cleaner_availability_service.dart';
import 'package:home_cleaning_marketplace_api/src/http/json_response.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

Future<Response> onRequest(RequestContext context) {
  return handleRoleRequest(
    context,
    methods: {HttpMethod.get, HttpMethod.post},
    action: (scoped) async {
      final availability = context.read<CleanerAvailabilityService>();
      if (context.request.method == HttpMethod.get) {
        final query = context.request.uri.queryParameters;
        final serviceIdRaw = query['service_id'];
        ObjectId? serviceId;
        if (serviceIdRaw != null && serviceIdRaw.isNotEmpty) {
          serviceId = parsePathObjectId(serviceIdRaw);
          if (serviceId == null) {
            return serviceNotFoundResponse();
          }
        }
        final items = await availability.list(
          user: scoped.currentUser,
          fromRaw: query['from'],
          toRaw: query['to'],
          serviceId: serviceId,
        );
        return jsonSuccess(<String, Object>{'items': items});
      }
      final json = await parseJsonObject(context.request);
      final created = await availability.create(
        user: scoped.currentUser,
        serviceIdRaw: json['service_id'],
        startAt: json['start_at'],
        endAt: json['end_at'],
      );
      return jsonSuccess(<String, Object?>{'slot': created});
    },
  );
}
