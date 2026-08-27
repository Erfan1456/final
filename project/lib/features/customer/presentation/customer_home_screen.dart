import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_cleaning_marketplace/app/router/app_routes.dart';
import 'package:home_cleaning_marketplace/features/addresses/presentation/address_controller.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/auth_controller.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/logout_actions.dart';
import 'package:home_cleaning_marketplace/features/customer/presentation/customer_profile_controller.dart';
import 'package:home_cleaning_marketplace/features/notifications/presentation/notification_home_link.dart';
import 'package:home_cleaning_marketplace/shared/presentation/app_layout.dart';
import 'package:home_cleaning_marketplace/shared/presentation/app_spacing.dart';
import 'package:home_cleaning_marketplace/shared/widgets/app_section.dart';

/// Customer dashboard with primary marketplace paths.
class CustomerHomeScreen extends ConsumerWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final profile = ref.watch(customerProfileControllerProvider);
    final addresses = ref.watch(addressControllerProvider);
    final defaultAddress = addresses.defaultAddress;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Customer Home')),
      body: SafeArea(
        child: AppLayout.constrained(
          maxWidth: AppLayout.formMaxWidth,
          child: ListView(
            children: [
              Text(
                'Home Cleaning Service Marketplace',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.small),
              Text(
                'Signed in as ${user?.email ?? 'customer'}',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.section),
              AppSection(
                title: 'Your account',
                subtitle: profile.hasProfile
                    ? 'Profile ready'
                    : 'Complete your profile to book faster',
                children: [
                  Text(
                    defaultAddress == null
                        ? 'No default address selected'
                        : 'Default address: ${defaultAddress.label}, ${defaultAddress.line1}, ${defaultAddress.city}',
                  ),
                  const SizedBox(height: AppSpacing.small),
                  FilledButton.tonal(
                    onPressed: () =>
                        context.push(AppRoutes.customerProfilePath),
                    child: const Text('Profile'),
                  ),
                  const SizedBox(height: AppSpacing.small),
                  OutlinedButton(
                    onPressed: () =>
                        context.push(AppRoutes.customerAddressesPath),
                    child: const Text('Addresses'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.section),
              AppSection(
                title: 'Book a cleaner',
                children: [
                  FilledButton(
                    onPressed: () =>
                        context.push(AppRoutes.customerDiscoverPath),
                    child: const Text('Find a Cleaner'),
                  ),
                  const SizedBox(height: AppSpacing.small),
                  OutlinedButton(
                    onPressed: () =>
                        context.push(AppRoutes.customerBookingsPath),
                    child: const Text('My Bookings'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.section),
              AppSection(
                title: 'Updates & security',
                children: [
                  const NotificationHomeLink(),
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
