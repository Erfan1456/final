import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_cleaning_marketplace/app/router/app_routes.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/auth_controller.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/auth_validation.dart';

/// Customer/cleaner registration.
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _role = 'customer';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    await ref
        .read(authControllerProvider.notifier)
        .signup(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          role: _role,
        );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final submitting = auth.isSubmitting;

    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Home Cleaning Service Marketplace',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    enabled: !submitting,
                    obscureText: true,
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      helperText: '15–128 characters',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        AuthValidation.signupPasswordError(value ?? ''),
                  ),
                  const SizedBox(height: 16),
                  Text('Role', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment<String>(
                        value: 'customer',
                        label: Text('Customer'),
                      ),
                      ButtonSegment<String>(
                        value: 'cleaner',
                        label: Text('Cleaner'),
                      ),
                    ],
                    selected: {_role},
                    onSelectionChanged: submitting
                        ? null
                        : (selection) {
                            setState(() {
                              _role = selection.first;
                            });
                          },
                  ),
                  if (auth.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      auth.errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
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
                        : const Text('Create account'),
                  ),
                  TextButton(
                    onPressed: submitting
                        ? null
                        : () => context.go(AppRoutes.loginPath),
                    child: const Text('Already have an account? Sign in'),
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
