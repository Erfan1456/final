import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/http/role_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/features/finance/application/admin_finance_service.dart';
import 'package:home_cleaning_marketplace_api/src/http/json_response.dart';

Future<Response> onRequest(RequestContext context) {
  return handleRoleRequest(
    context,
    methods: {HttpMethod.get},
    action: (scoped) async {
      final params = context.request.uri.queryParameters;
      final service = context.read<AdminFinanceService>();
      return jsonSuccess(
        await service.reconciliation(
          currency: params['currency'],
          limitRaw: params['limit'],
          after: params['after'],
        ),
      );
    },
  );
}
