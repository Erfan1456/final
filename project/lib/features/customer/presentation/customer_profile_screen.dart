import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/features/customer/presentation/customer_profile_controller.dart';

/// Customer profile form.
class CustomerProfileScreen extends ConsumerStatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  ConsumerState<CustomerProfileScreen> createState() =>
      _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends ConsumerState<CustomerProfileScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  String? _localError;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _syncFromState() {
    final profile = ref.read(customerProfileControllerProvider).profile;
    if (profile != null && _name.text.isEmpty) {
      _name.text = profile.fullName;
      _phone.text = profile.phoneE164 ?? '';
    }
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.runes.length < 2 || name.runes.length > 100) {
      setState(() => _localError = 'Full name must be 2–100 characters.');
      return;
    }
    final phoneRaw = _phone.text.trim();
    final phone = phoneRaw.isEmpty ? null : phoneRaw;
    if (phone != null && !RegExp(r'^\+[0-9]{8,15}$').hasMatch(phone)) {
      setState(() => _localError = 'Enter a phone number in E.164 format.');
      return;
    }
    setState(() => _localError = null);
    final ok = await ref
        .read(customerProfileControllerProvider.notifier)
        .save(fullName: name, phoneE164: phone);
    if (ok && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerProfileControllerProvider);
    _syncFromState();
    return Scaffold(
      appBar: AppBar(title: const Text('Customer profile')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: state.loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  children: [
                    TextField(
                      controller: _name,
                      decoration: const InputDecoration(labelText: 'Full name'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone (optional E.164)',
                      ),
                    ),
                    if (_localError != null || state.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _localError ?? state.errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: state.saving ? null : _save,
                      child: Text(state.saving ? 'Saving...' : 'Save'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
