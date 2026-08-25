import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_cleaning_marketplace/app/router/app_routes.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/auth_controller.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/logout_actions.dart';
import 'package:home_cleaning_marketplace/features/cleaner/data/cleaner_profile.dart';
import 'package:home_cleaning_marketplace/features/cleaner/presentation/cleaner_onboarding_controller.dart';

/// Cleaner dashboard with onboarding status.
class CleanerHomeScreen extends ConsumerWidget {
  const CleanerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final state = ref.watch(cleanerOnboardingControllerProvider);
    final profile = state.profile;
    final status = profile?.onboardingStatus;

    String message;
    String? actionLabel;
    if (state.loading) {
      message = 'Loading onboarding status...';
    } else if (profile == null) {
      message = 'Start onboarding to apply as a cleaner.';
      actionLabel = 'Start onboarding';
    } else if (status == OnboardingStatus.draft) {
      message = 'Continue onboarding.';
      actionLabel = 'Continue onboarding';
    } else if (status == OnboardingStatus.pending) {
      message = 'Your application is pending administrator review.';
    } else if (status == OnboardingStatus.rejected) {
      message =
          'Rejected: ${profile.rejectionReason ?? 'Please edit and resubmit.'}';
      actionLabel = 'Edit and resubmit';
    } else if (status == OnboardingStatus.approved) {
      message = 'You are approved. Manage services and availability below.';
    } else {
      message = 'Onboarding status is unavailable.';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Cleaner home')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user?.email ?? ''),
              const SizedBox(height: 8),
              Text('Onboarding: ${status?.wireValue ?? 'none'}'),
              const SizedBox(height: 16),
              Text(message),
              if (actionLabel != null) ...[
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () =>
                      context.push(AppRoutes.cleanerOnboardingPath),
                  child: Text(actionLabel),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () => context.push(AppRoutes.cleanerBookingsPath),
                child: const Text('Booking Requests / Jobs'),
              ),
              if (status == OnboardingStatus.approved) ...[
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.push(AppRoutes.cleanerServicesPath),
                  child: const Text('Manage Services'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () =>
                      context.push(AppRoutes.cleanerAvailabilityPath),
                  child: const Text('Manage Availability'),
                ),
              ],
              const Spacer(),
              const LogoutActions(),
            ],
          ),
        ),
      ),
    );
  }
}
