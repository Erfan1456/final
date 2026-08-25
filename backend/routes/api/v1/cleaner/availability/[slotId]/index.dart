import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/http/auth_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/http/role_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/features/availability/application/cleaner_availability_service.dart';
import 'package:home_cleaning_marketplace_api/src/http/json_response.dart';

Future<Response> onRequest(RequestContext context, String slotId) {
  return handleRoleRequest(
    context,
    methods: {HttpMethod.get, HttpMethod.put, HttpMethod.delete},
    action: (scoped) async {
      final id = parsePathObjectId(slotId);
      if (id == null) {
        return availabilityNotFoundResponse();
      }
      final availability = context.read<CleanerAvailabilityService>();
      if (context.request.method == HttpMethod.get) {
        final slot = await availability.get(
          user: scoped.currentUser,
          slotId: id,
        );
        return jsonSuccess(<String, Object?>{'slot': slot});
      }
      if (context.request.method == HttpMethod.delete) {
        await availability.delete(user: scoped.currentUser, slotId: id);
        return jsonSuccess(const <String, Object?>{'deleted': true});
      }
      final json = await parseJsonObject(context.request);
      final slot = await availability.update(
        user: scoped.currentUser,
        slotId: id,
        serviceIdRaw: json['service_id'],
        startAt: json['start_at'],
        endAt: json['end_at'],
      );
      return jsonSuccess(<String, Object?>{'slot': slot});
    },
  );
}
