import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_cleaning_marketplace/app/router/app_routes.dart';
import 'package:home_cleaning_marketplace/features/addresses/presentation/address_controller.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/auth_controller.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/logout_actions.dart';
import 'package:home_cleaning_marketplace/features/customer/presentation/customer_profile_controller.dart';

/// Customer dashboard.
class CustomerHomeScreen extends ConsumerWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final profile = ref.watch(customerProfileControllerProvider);
    final addresses = ref.watch(addressControllerProvider);
    final defaultAddress = addresses.defaultAddress;

    return Scaffold(
      appBar: AppBar(title: const Text('Customer home')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Home Cleaning Service Marketplace',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(user?.email ?? ''),
              const SizedBox(height: 16),
              Text(
                profile.hasProfile
                    ? 'Profile complete'
                    : 'Profile not created yet',
              ),
              const SizedBox(height: 8),
              if (defaultAddress != null)
                Text(
                  'Default address: ${defaultAddress.label}, ${defaultAddress.line1}, ${defaultAddress.city}',
                )
              else
                const Text('No default address selected'),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.push(AppRoutes.customerProfilePath),
                child: const Text('Manage Profile'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.push(AppRoutes.customerAddressesPath),
                child: const Text('Manage Addresses'),
              ),
              const Spacer(),
              const LogoutActions(),
            ],
          ),
        ),
      ),
    );
  }
}
