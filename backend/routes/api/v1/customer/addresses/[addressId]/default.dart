import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/http/role_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/application/customer_account_service.dart';
import 'package:home_cleaning_marketplace_api/src/http/json_response.dart';

Future<Response> onRequest(RequestContext context, String addressId) {
  return handleRoleRequest(
    context,
    methods: {HttpMethod.put},
    action: (scoped) async {
      final id = parsePathObjectId(addressId);
      if (id == null) {
        return addressNotFoundResponse();
      }
      final customer = context.read<CustomerAccountService>();
      final profile = await customer.setDefaultAddress(
        userId: scoped.currentUser.id,
        addressId: id,
      );
      return jsonSuccess(<String, Object?>{
        'profile': profile.toPublicJson(),
      });
    },
  );
}
