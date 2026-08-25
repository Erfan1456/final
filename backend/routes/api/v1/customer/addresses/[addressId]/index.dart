import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/http/auth_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/http/role_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/application/customer_account_service.dart';
import 'package:home_cleaning_marketplace_api/src/http/json_response.dart';

Future<Response> onRequest(RequestContext context, String addressId) {
  return handleRoleRequest(
    context,
    methods: {HttpMethod.get, HttpMethod.put, HttpMethod.delete},
    action: (scoped) async {
      final id = parsePathObjectId(addressId);
      if (id == null) {
        return addressNotFoundResponse();
      }
      final customer = context.read<CustomerAccountService>();
      final userId = scoped.currentUser.id;
      if (context.request.method == HttpMethod.get) {
        final item = await customer.getAddress(
          userId: userId,
          addressId: id,
        );
        return jsonSuccess(<String, Object?>{
          'address': item.toPublicJson(),
        });
      }
      if (context.request.method == HttpMethod.put) {
        final json = await parseJsonObject(context.request);
        final item = await customer.updateAddress(
          userId: userId,
          addressId: id,
          label: json['label'],
          line1: json['line1'],
          line2: json['line2'],
          city: json['city'],
          region: json['region'],
          postalCode: json['postal_code'],
          countryCode: json['country_code'],
        );
        return jsonSuccess(<String, Object?>{
          'address': item.toPublicJson(),
        });
      }
      await customer.deleteAddress(userId: userId, addressId: id);
      return jsonSuccess(const <String, bool>{'deleted': true});
    },
  );
}
