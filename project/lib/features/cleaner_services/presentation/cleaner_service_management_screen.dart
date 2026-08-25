import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/features/catalog/data/marketplace_service.dart';
import 'package:home_cleaning_marketplace/features/catalog/presentation/catalog_controller.dart';
import 'package:home_cleaning_marketplace/features/cleaner/data/cleaner_profile.dart';
import 'package:home_cleaning_marketplace/features/cleaner/presentation/cleaner_onboarding_controller.dart';
import 'package:home_cleaning_marketplace/features/cleaner_services/presentation/cleaner_service_controller.dart';

/// Cleaner offering configuration for platform catalog services.
class CleanerServiceManagementScreen extends ConsumerStatefulWidget {
  const CleanerServiceManagementScreen({super.key});

  @override
  ConsumerState<CleanerServiceManagementScreen> createState() =>
      _CleanerServiceManagementScreenState();
}

class _CleanerServiceManagementScreenState
    extends ConsumerState<CleanerServiceManagementScreen> {
  final _rate = TextEditingController();
  final _currency = TextEditingController(text: 'BDT');
  bool _active = true;

  @override
  void dispose() {
    _rate.dispose();
    _currency.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onboarding = ref.watch(cleanerOnboardingControllerProvider);
    final approved =
        onboarding.profile?.onboardingStatus == OnboardingStatus.approved;
    final catalog = ref.watch(catalogControllerProvider);
    final offerings = ref.watch(cleanerServiceControllerProvider);
    final service = catalog.items.isEmpty ? null : catalog.items.first;
    final existing = service == null ? null : offerings.offeringFor(service.id);
    if (existing != null && _rate.text.isEmpty) {
      _rate.text = '${existing.hourlyRateMinor}';
      _currency.text = existing.currencyCode;
      _active = existing.isActive;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Services')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: !approved
              ? const Text('Approval required')
              : catalog.loading || offerings.loading
              ? const Center(child: CircularProgressIndicator())
              : service == null
              ? const Text('No platform services are available.')
              : ListView(
                  children: [
                    Text(
                      service.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('Billing: ${service.billingModel.wireValue}'),
                    const SizedBox(height: 8),
                    const Text(
                      'Enter the hourly price in the smallest currency unit.',
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _rate,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Hourly rate (minor units)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _currency,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Currency code',
                      ),
                    ),
                    SwitchListTile(
                      title: const Text('Active'),
                      value: _active,
                      onChanged: (value) => setState(() => _active = value),
                    ),
                    if (offerings.errorMessage != null)
                      Text(offerings.errorMessage!),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: offerings.saving ? null : () => _save(service),
                      child: offerings.saving
                          ? const Text('Saving...')
                          : const Text('Save'),
                    ),
                    if (existing != null && existing.isActive) ...[
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: offerings.saving
                            ? null
                            : () => ref
                                  .read(
                                    cleanerServiceControllerProvider.notifier,
                                  )
                                  .deactivate(service.id),
                        child: const Text('Deactivate'),
                      ),
                    ],
                    if (existing != null && !existing.isActive) ...[
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: offerings.saving
                            ? null
                            : () => _save(service, active: true),
                        child: const Text('Reactivate'),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _save(MarketplaceService service, {bool? active}) async {
    final parsed = int.tryParse(_rate.text.trim());
    if (parsed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hourly rate must be a whole number.')),
      );
      return;
    }
    final currency = _currency.text.trim();
    if (currency.length != 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Currency code must be three letters.')),
      );
      return;
    }
    await ref
        .read(cleanerServiceControllerProvider.notifier)
        .save(
          serviceId: service.id,
          hourlyRateMinor: parsed,
          currencyCode: currency,
          isActive: active ?? _active,
        );
  }
}
