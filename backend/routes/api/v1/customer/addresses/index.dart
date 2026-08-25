import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/http/auth_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/http/role_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/application/customer_account_service.dart';
import 'package:home_cleaning_marketplace_api/src/http/json_response.dart';

Future<Response> onRequest(RequestContext context) {
  return handleRoleRequest(
    context,
    methods: {HttpMethod.get, HttpMethod.post},
    action: (scoped) async {
      final customer = context.read<CustomerAccountService>();
      final userId = scoped.currentUser.id;
      if (context.request.method == HttpMethod.get) {
        final addresses = await customer.listAddresses(userId);
        return jsonSuccess(<String, Object>{
          'addresses': [
            for (final item in addresses) item.toPublicJson(),
          ],
        });
      }
      final json = await parseJsonObject(context.request);
      final created = await customer.createAddress(
        userId: userId,
        label: json['label'],
        line1: json['line1'],
        line2: json['line2'],
        city: json['city'],
        region: json['region'],
        postalCode: json['postal_code'],
        countryCode: json['country_code'],
      );
      return jsonSuccess(
        <String, Object?>{'address': created.toPublicJson()},
        statusCode: HttpStatus.created,
      );
    },
  );
}
