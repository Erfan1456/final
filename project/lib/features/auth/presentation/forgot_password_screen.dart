import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_cleaning_marketplace/app/router/app_routes.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/auth_validation.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/password_recovery_controller.dart';

/// Request a password-reset email.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    await ref
        .read(passwordRecoveryControllerProvider.notifier)
        .requestReset(_emailController.text.trim());
  }

  void _openResetWithDevToken(String token) {
    context.push(AppRoutes.resetPasswordLocation(token: token));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(passwordRecoveryControllerProvider);
    final submitting = state.isSubmitting;

    return Scaffold(
      appBar: AppBar(title: const Text('Forgot password')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Reset your password',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            const Text(
              'Enter your email and we will send reset instructions if an account exists.',
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _emailController,
                    enabled: !submitting,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        AuthValidation.emailError(value ?? ''),
                  ),
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      state.errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
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
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: submitting
                          ? null
                          : () => _openResetWithDevToken(
                              state.developmentAction!.token,
                            ),
                      child: const Text('Continue to reset password'),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: submitting ? null : _submit,
                    child: submitting
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Send reset instructions'),
                  ),
                  TextButton(
                    onPressed: submitting
                        ? null
                        : () => context.go(AppRoutes.loginPath),
                    child: const Text('Back to sign in'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
