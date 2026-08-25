import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/database/mongo_database.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/application/auth_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/application/role_scoped_composition.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/http/role_http_errors.dart';
import 'package:home_cleaning_marketplace_api/src/features/services/data/service_repository.dart';
import 'package:home_cleaning_marketplace_api/src/http/json_response.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final repository = await _repository(context);
    final items = await repository.listActive();
    return jsonSuccess(<String, Object>{
      'items': [for (final item in items) item.toPublicJson()],
    });
  } on Exception catch (error) {
    return mapRoleScopedException(error);
  }
}

Future<ServiceRepository> _repository(RequestContext context) async {
  try {
    return context.read<ServiceRepository>();
  } catch (_) {
    try {
      return await RoleScopedComposition.services(
        mongo: context.read<MongoDatabase>(),
      );
    } on Exception {
      throw const AuthenticationConfigurationException();
    }
  }
}
