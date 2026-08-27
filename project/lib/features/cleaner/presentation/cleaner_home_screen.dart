import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_cleaning_marketplace/app/router/app_routes.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/auth_controller.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/logout_actions.dart';
import 'package:home_cleaning_marketplace/features/cleaner/data/cleaner_profile.dart';
import 'package:home_cleaning_marketplace/features/cleaner/presentation/cleaner_onboarding_controller.dart';
import 'package:home_cleaning_marketplace/features/notifications/presentation/notification_home_link.dart';
import 'package:home_cleaning_marketplace/shared/presentation/app_layout.dart';
import 'package:home_cleaning_marketplace/shared/presentation/app_spacing.dart';
import 'package:home_cleaning_marketplace/shared/widgets/app_status_chip.dart';
import 'package:home_cleaning_marketplace/shared/widgets/app_section.dart';

/// Cleaner dashboard with onboarding and workflow sections.
class CleanerHomeScreen extends ConsumerWidget {
  const CleanerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final state = ref.watch(cleanerOnboardingControllerProvider);
    final profile = state.profile;
    final status = profile?.onboardingStatus;
    final theme = Theme.of(context);
    final approved = status == OnboardingStatus.approved;

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
    } else if (approved) {
      message = 'You are approved. Manage services and availability below.';
    } else {
      message = 'Onboarding status is unavailable.';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Cleaner Home')),
      body: SafeArea(
        child: AppLayout.constrained(
          maxWidth: AppLayout.formMaxWidth,
          child: ListView(
            children: [
              Text(
                'Signed in as ${user?.email ?? 'cleaner'}',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.small),
              Row(
                children: [
                  Text('Onboarding', style: theme.textTheme.titleSmall),
                  const SizedBox(width: AppSpacing.small),
                  Flexible(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: AppStatusChip(label: status?.label ?? 'Unknown'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.small),
              Text(message),
              if (actionLabel != null) ...[
                const SizedBox(height: AppSpacing.normal),
                FilledButton(
                  onPressed: () =>
                      context.push(AppRoutes.cleanerOnboardingPath),
                  child: Text(actionLabel),
                ),
              ],
              const SizedBox(height: AppSpacing.section),
              AppSection(
                title: 'Jobs',
                children: [
                  FilledButton.tonal(
                    onPressed: () =>
                        context.push(AppRoutes.cleanerBookingsPath),
                    child: const Text('Dashboard / Booking Requests'),
                  ),
                ],
              ),
              if (approved) ...[
                const SizedBox(height: AppSpacing.section),
                AppSection(
                  title: 'Setup',
                  children: [
                    FilledButton(
                      onPressed: () =>
                          context.push(AppRoutes.cleanerServicesPath),
                      child: const Text('Services'),
                    ),
                    const SizedBox(height: AppSpacing.small),
                    OutlinedButton(
                      onPressed: () =>
                          context.push(AppRoutes.cleanerAvailabilityPath),
                      child: const Text('Availability'),
                    ),
                    const SizedBox(height: AppSpacing.small),
                    OutlinedButton(
                      onPressed: () =>
                          context.push(AppRoutes.cleanerReviewsPath),
                      child: const Text('My Reviews'),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.section),
              AppSection(
                title: 'Money',
                children: [
                  FilledButton.tonal(
                    onPressed: () =>
                        context.push(AppRoutes.cleanerEarningsPath),
                    child: const Text('Earnings & Payouts'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.section),
              AppSection(
                title: 'Account',
                children: [
                  const NotificationHomeLink(),
                  const SizedBox(height: AppSpacing.small),
                  OutlinedButton(
                    onPressed: () =>
                        context.push(AppRoutes.cleanerOnboardingPath),
                    child: const Text('Profile'),
                  ),
                  const SizedBox(height: AppSpacing.small),
                  OutlinedButton(
                    onPressed: () =>
                        context.push(AppRoutes.accountSecurityPath),
                    child: const Text('Security'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.section),
              const LogoutActions(),
            ],
          ),
        ),
      ),
    );
  }
}
