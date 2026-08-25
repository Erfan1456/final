import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/config/server_config.dart';
import 'package:home_cleaning_marketplace_api/src/database/mongo_database.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/application/role_scoped_composition.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/http/role_http_errors.dart';
import 'package:home_cleaning_marketplace_api/src/features/payments/application/payment_webhook_service.dart';

Handler middleware(Handler handler) {
  return (context) async {
    try {
      final service = _tryRead<PaymentWebhookService>(context);
      if (service != null) {
        return await handler(
          context.provide<PaymentWebhookService>(() => service),
        );
      }
      final mongo = context.read<MongoDatabase>();
      final config = context.read<ServerConfig>();
      final webhooks = await RoleScopedComposition.paymentWebhooks(
        mongo: mongo,
        config: config,
      );
      return await handler(
        context.provide<PaymentWebhookService>(() => webhooks),
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
