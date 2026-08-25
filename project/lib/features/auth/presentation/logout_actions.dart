import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/auth_controller.dart';

/// Shared logout actions used by role home screens.
class LogoutActions extends ConsumerWidget {
  const LogoutActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submitting = ref.watch(authControllerProvider).isSubmitting;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(
          onPressed: submitting
              ? null
              : () => ref.read(authControllerProvider.notifier).logout(),
          child: const Text('Log out'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: submitting
              ? null
              : () => ref.read(authControllerProvider.notifier).logoutAll(),
          child: const Text('Log out all devices'),
        ),
      ],
    );
  }
}
