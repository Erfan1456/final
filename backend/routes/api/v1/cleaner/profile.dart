import 'package:dart_frog/dart_frog.dart';
import 'package:home_cleaning_marketplace_api/src/features/auth/http/auth_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/features/authorization/http/role_route_helpers.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/application/cleaner_onboarding_service.dart';
import 'package:home_cleaning_marketplace_api/src/http/json_response.dart';

Future<Response> onRequest(RequestContext context) {
  return handleRoleRequest(
    context,
    methods: {HttpMethod.get, HttpMethod.put},
    action: (scoped) async {
      final cleaner = context.read<CleanerOnboardingService>();
      final userId = scoped.currentUser.id;
      if (context.request.method == HttpMethod.get) {
        final profile = await cleaner.getProfile(userId);
        return jsonSuccess(<String, Object?>{
          'profile': profile?.toPublicJson(),
        });
      }
      final json = await parseJsonObject(context.request);
      final profile = await cleaner.saveProfile(
        userId: userId,
        fullName: json['full_name'],
        phoneE164: json['phone_e164'],
        bio: json['bio'],
        yearsExperience: json['years_experience'],
        serviceArea: json['service_area'],
      );
      return jsonSuccess(<String, Object?>{
        'profile': profile.toPublicJson(),
      });
    },
  );
}
