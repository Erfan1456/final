import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/features/cleaner/data/cleaner_profile.dart';
import 'package:home_cleaning_marketplace/features/cleaner/presentation/cleaner_onboarding_controller.dart';

/// Cleaner onboarding form.
class CleanerOnboardingScreen extends ConsumerStatefulWidget {
  const CleanerOnboardingScreen({super.key});

  @override
  ConsumerState<CleanerOnboardingScreen> createState() =>
      _CleanerOnboardingScreenState();
}

class _CleanerOnboardingScreenState
    extends ConsumerState<CleanerOnboardingScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _bio = TextEditingController();
  final _years = TextEditingController();
  final _area = TextEditingController();
  bool _filled = false;
  String? _localError;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _bio.dispose();
    _years.dispose();
    _area.dispose();
    super.dispose();
  }

  void _fill() {
    final profile = ref.read(cleanerOnboardingControllerProvider).profile;
    if (profile == null || _filled) {
      return;
    }
    _filled = true;
    _name.text = profile.fullName;
    _phone.text = profile.phoneE164 ?? '';
    _bio.text = profile.bio;
    _years.text = '${profile.yearsExperience}';
    _area.text = profile.serviceArea;
  }

  Future<void> _save() async {
    final years = int.tryParse(_years.text.trim());
    if (_name.text.trim().runes.length < 2 ||
        _bio.text.trim().runes.length < 20 ||
        years == null ||
        _area.text.trim().runes.length < 2) {
      setState(() => _localError = 'Please complete all onboarding fields.');
      return;
    }
    setState(() => _localError = null);
    await ref.read(cleanerOnboardingControllerProvider.notifier).save(
      <String, Object?>{
        'full_name': _name.text,
        'phone_e164': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        'bio': _bio.text,
        'years_experience': years,
        'service_area': _area.text,
      },
    );
  }

  Future<void> _submit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit for review?'),
        content: const Text(
          'Submit your saved profile for administrator review?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final saved = await ref
          .read(cleanerOnboardingControllerProvider.notifier)
          .save(<String, Object?>{
            'full_name': _name.text,
            'phone_e164': _phone.text.trim().isEmpty
                ? null
                : _phone.text.trim(),
            'bio': _bio.text,
            'years_experience': int.tryParse(_years.text.trim()) ?? 0,
            'service_area': _area.text,
          });
      if (saved) {
        await ref.read(cleanerOnboardingControllerProvider.notifier).submit();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cleanerOnboardingControllerProvider);
    _fill();
    final editable =
        state.profile == null ||
        state.status.isEditable ||
        state.status == OnboardingStatus.unknown;
    return Scaffold(
      appBar: AppBar(title: const Text('Cleaner onboarding')),
      body: SafeArea(
        child: state.loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  if (state.profile?.rejectionReason != null)
                    Text('Rejected: ${state.profile!.rejectionReason}'),
                  TextField(
                    controller: _name,
                    enabled: editable,
                    decoration: const InputDecoration(labelText: 'Full name'),
                  ),
                  TextField(
                    controller: _phone,
                    enabled: editable,
                    decoration: const InputDecoration(
                      labelText: 'Phone (optional)',
                    ),
                  ),
                  TextField(
                    controller: _bio,
                    enabled: editable,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Bio'),
                  ),
                  TextField(
                    controller: _years,
                    enabled: editable,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Years of experience',
                    ),
                  ),
                  TextField(
                    controller: _area,
                    enabled: editable,
                    decoration: const InputDecoration(
                      labelText: 'Service area',
                    ),
                  ),
                  if (_localError != null || state.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(_localError ?? state.errorMessage!),
                  ],
                  if (editable) ...[
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: state.saving ? null : _save,
                      child: Text(state.saving ? 'Saving...' : 'Save'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: state.submitting ? null : _submit,
                      child: Text(
                        state.submitting
                            ? 'Submitting...'
                            : 'Submit for Review',
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
