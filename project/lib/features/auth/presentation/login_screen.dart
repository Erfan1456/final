import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_cleaning_marketplace/app/router/app_routes.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/auth_controller.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/auth_validation.dart';
import 'package:home_cleaning_marketplace/shared/presentation/app_layout.dart';
import 'package:home_cleaning_marketplace/shared/presentation/app_spacing.dart';
import 'package:home_cleaning_marketplace/shared/widgets/app_buttons.dart';

/// Email/password sign-in.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

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
        .login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  void _openVerificationPending() {
    context.go(
      AppRoutes.verifyEmailPendingLocation(email: _emailController.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final submitting = auth.isSubmitting;
    final emailNotVerified = auth.errorCode == 'email_not_verified';

    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: SafeArea(
        child: AppLayout.constrained(
          maxWidth: AppLayout.formMaxWidth,
          child: ListView(
            children: [
              Text(
                'Home Cleaning Service Marketplace',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.section),
              Form(
                key: _formKey,
                child: Column(
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
                    const SizedBox(height: AppSpacing.normal),
                    TextFormField(
                      controller: _passwordController,
                      enabled: !submitting,
                      obscureText: _obscurePassword,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? 'Show password'
                              : 'Hide password',
                          onPressed: submitting
                              ? null
                              : () => setState(() {
                                  _obscurePassword = !_obscurePassword;
                                }),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      onFieldSubmitted: (_) {
                        if (!submitting) {
                          _submit();
                        }
                      },
                      validator: (value) =>
                          AuthValidation.loginPasswordError(value ?? ''),
                    ),
                    if (auth.errorMessage != null) ...[
                      const SizedBox(height: AppSpacing.normal),
                      Text(
                        auth.errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    if (emailNotVerified) ...[
                      const SizedBox(height: AppSpacing.small),
                      TextButton(
                        onPressed: submitting ? null : _openVerificationPending,
                        child: const Text('Verify your email'),
                      ),
                    ],
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: submitting
                            ? null
                            : () => context.push(
                                AppRoutes.forgotPasswordLocation(
                                  email: _emailController.text.trim(),
                                ),
                              ),
                        child: const Text('Forgot password?'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.section),
                    AppLoadingButton(
                      label: 'Sign in',
                      loading: submitting,
                      onPressed: _submit,
                    ),
                    TextButton(
                      onPressed: submitting
                          ? null
                          : () => context.go(AppRoutes.signupPath),
                      child: const Text('Create an account'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
