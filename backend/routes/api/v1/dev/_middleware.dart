import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/config/server_config.dart';
import 'package:home_cleaning_marketplace_api/src/database/mongo_database.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/application/role_scoped_composition.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/http/role_http_errors.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/application/sandbox_payment_simulation_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/payouts/application/sandbox_payout_simulation_service.dart';
import 'package:home_cleaning_marketplace_api/src/http/json_response.dart';

Handler middleware(Handler handler) {
  return (context) async {
    try {
      final config =
          _tryRead<ServerConfig>(context) ?? context.read<ServerConfig>();
      if (config.isProduction) {
        return jsonError(
          code: 'not_found',
          message: 'Not found.',
          statusCode: HttpStatus.notFound,
        );
      }
      var next = context;
      final paymentSimulation = _tryRead<SandboxPaymentSimulationService>(
        context,
      );
      if (paymentSimulation != null) {
        next = next.provide<SandboxPaymentSimulationService>(
          () => paymentSimulation,
        );
      } else {
        final mongo = context.read<MongoDatabase>();
        final simulation = await RoleScopedComposition.sandboxSimulation(
          mongo: mongo,
          config: config,
        );
        next = next.provide<SandboxPaymentSimulationService>(() => simulation);
      }
      final payoutSimulation = _tryRead<SandboxPayoutSimulationService>(
        context,
      );
      if (payoutSimulation != null) {
        next = next.provide<SandboxPayoutSimulationService>(
          () => payoutSimulation,
        );
      } else {
        final mongo = context.read<MongoDatabase>();
        final simulation = await RoleScopedComposition.sandboxPayoutSimulation(
          mongo: mongo,
          config: config,
        );
        next = next.provide<SandboxPayoutSimulationService>(() => simulation);
      }
      return await handler(next);
    } on Exception catch (error) {
      return mapRoleScopedException(error);
    }
  };
}

T? _tryRead<T>(RequestContext context) {
  try {
    return context.read<T>();
  } catch (_) {
    return null;
  }
}
