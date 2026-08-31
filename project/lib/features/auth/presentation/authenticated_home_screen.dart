import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/auth_controller.dart';

/// Post-authentication placeholder showing the current safe account.
class AuthenticatedHomeScreen extends ConsumerWidget {
  const AuthenticatedHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;
    final submitting = auth.isSubmitting;

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
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
              Text('Signed in', style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 24),
              if (user != null) ...[
                Text('Email: ${user.email}'),
                const SizedBox(height: 8),
                Text('Role: ${user.role}'),
                const SizedBox(height: 8),
                Text(
                  user.emailVerified ? 'Email verified' : 'Email not verified',
                ),
              ],
              const Spacer(),
              FilledButton(
                onPressed: submitting
                    ? null
                    : () => ref.read(authControllerProvider.notifier).logout(),
                child: const Text('Log out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
