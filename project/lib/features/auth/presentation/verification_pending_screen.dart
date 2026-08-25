import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_cleaning_marketplace/app/router/app_routes.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/email_verification_controller.dart';

/// Post-signup email verification instructions.
class VerificationPendingScreen extends ConsumerStatefulWidget {
  const VerificationPendingScreen({
    super.key,
    required this.email,
    this.initialToken,
  });

  final String email;
  final String? initialToken;

  @override
  ConsumerState<VerificationPendingScreen> createState() =>
      _VerificationPendingScreenState();
}

class _VerificationPendingScreenState
    extends ConsumerState<VerificationPendingScreen> {
  late final TextEditingController _tokenController;

  @override
  void initState() {
    super.initState();
    _tokenController = TextEditingController(text: widget.initialToken ?? '');
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _resend() async {
    await ref
        .read(emailVerificationControllerProvider.notifier)
        .requestVerification(widget.email);
  }

  Future<void> _verify() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      return;
    }
    final ok = await ref
        .read(emailVerificationControllerProvider.notifier)
        .verify(token);
    if (ok && mounted) {
      context.go(AppRoutes.loginPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(emailVerificationControllerProvider);
    final submitting = state.isSubmitting;

    return Scaffold(
      appBar: AppBar(title: const Text('Verify email')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Check your inbox',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text('We sent a verification link to ${widget.email}.'),
            const SizedBox(height: 24),
            TextFormField(
              controller: _tokenController,
              enabled: !submitting,
              decoration: const InputDecoration(
                labelText: 'Verification token',
                border: OutlineInputBorder(),
                helperText: 'Paste the token from your email.',
              ),
            ),
            if (state.errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                state.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (state.successMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                state.successMessage!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
            if (state.developmentAction != null) ...[
              const SizedBox(height: 16),
              SelectableText(
                'Development token: ${state.developmentAction!.token}',
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: submitting ? null : _verify,
              child: submitting
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Verify email'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: submitting ? null : _resend,
              child: const Text('Resend verification email'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: submitting
                  ? null
                  : () => context.go(AppRoutes.loginPath),
              child: const Text('Back to sign in'),
            ),
          ],
        ),
      ),
    );
  }
}
