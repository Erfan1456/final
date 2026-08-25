import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/config/server_config.dart';
import 'package:home_cleaning_marketplace_api/src/database/mongo_database.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/application/role_scoped_composition.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/http/role_http_errors.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/application/sandbox_payment_simulation_service.dart';
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
      final service = _tryRead<SandboxPaymentSimulationService>(context);
      if (service != null) {
        return await handler(
          context.provide<SandboxPaymentSimulationService>(() => service),
        );
      }
      final mongo = context.read<MongoDatabase>();
      final simulation = await RoleScopedComposition.sandboxSimulation(
        mongo: mongo,
        config: config,
      );
      return await handler(
        context.provide<SandboxPaymentSimulationService>(() => simulation),
      );
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
