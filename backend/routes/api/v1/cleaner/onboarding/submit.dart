import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/http/role_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/application/cleaner_onboarding_service.dart';
import 'package:home_cleaning_marketplace_api/src/http/json_response.dart';

Future<Response> onRequest(RequestContext context) {
  return handleRoleRequest(
    context,
    methods: {HttpMethod.post},
    action: (scoped) async {
      final cleaner = context.read<CleanerOnboardingService>();
      final profile = await cleaner.submit(scoped.currentUser.id);
      return jsonSuccess(<String, Object?>{
        'profile': profile.toPublicJson(),
      });
    },
  );
}
