import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_cleaning_marketplace/app/router/app_routes.dart';
import 'package:home_cleaning_marketplace/features/auth/data/auth_failure.dart';
import 'package:home_cleaning_marketplace/features/auth/data/auth_repository.dart';
import 'package:home_cleaning_marketplace/features/auth/presentation/auth_validation.dart';
import 'package:home_cleaning_marketplace/shared/presentation/app_layout.dart';
import 'package:home_cleaning_marketplace/shared/presentation/app_spacing.dart';
import 'package:home_cleaning_marketplace/shared/widgets/app_buttons.dart';

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
  final _confirmPasswordController = TextEditingController();
  String _role = 'customer';
  bool _submitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      final result = await ref
          .read(authRepositoryProvider)
          .signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            role: _role,
          );
      if (!mounted) {
        return;
      }
      context.go(
        AppRoutes.verifyEmailPendingLocation(
          email: result.user.email,
          token: result.developmentAction?.token,
        ),
      );
    } on AuthFailure catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
        _errorMessage = 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _emailController,
                      enabled: !_submitting,
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
                      enabled: !_submitting,
                      obscureText: _obscurePassword,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: InputDecoration(
                        labelText: 'Password',
                        helperText: '15–128 characters',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? 'Show password'
                              : 'Hide password',
                          onPressed: _submitting
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
                      validator: (value) =>
                          AuthValidation.signupPasswordError(value ?? ''),
                    ),
                    const SizedBox(height: AppSpacing.normal),
                    TextFormField(
                      controller: _confirmPasswordController,
                      enabled: !_submitting,
                      obscureText: _obscureConfirm,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: InputDecoration(
                        labelText: 'Confirm password',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          tooltip: _obscureConfirm
                              ? 'Show password'
                              : 'Hide password',
                          onPressed: _submitting
                              ? null
                              : () => setState(() {
                                  _obscureConfirm = !_obscureConfirm;
                                }),
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return 'Passwords do not match.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.normal),
                    Text('Role', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: AppSpacing.small),
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
                      onSelectionChanged: _submitting
                          ? null
                          : (selection) {
                              setState(() {
                                _role = selection.first;
                              });
                            },
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: AppSpacing.normal),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.section),
                    AppLoadingButton(
                      label: 'Create account',
                      loading: _submitting,
                      onPressed: _submit,
                    ),
                    TextButton(
                      onPressed: _submitting
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
      ),
    );
  }
}
