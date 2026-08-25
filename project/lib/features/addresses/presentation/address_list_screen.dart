import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_cleaning_marketplace/app/router/app_routes.dart';
import 'package:home_cleaning_marketplace/features/addresses/presentation/address_controller.dart';

/// Owned customer addresses.
class AddressListScreen extends ConsumerWidget {
  const AddressListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addressControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Addresses')),
      body: SafeArea(
        child: state.loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (state.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(state.errorMessage!),
                    ),
                  FilledButton(
                    onPressed: () =>
                        context.push(AppRoutes.customerAddressNewPath),
                    child: const Text('Add'),
                  ),
                  const SizedBox(height: 12),
                  for (final address in state.addresses)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              address.label,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(address.line1),
                            Text(
                              '${address.city}, ${address.region} ${address.countryCode}',
                            ),
                            if (address.isDefault) const Text('Default'),
                            Wrap(
                              spacing: 8,
                              children: [
                                TextButton(
                                  onPressed: () => context.push(
                                    '/customer/addresses/${address.id}/edit',
                                  ),
                                  child: const Text('Edit'),
                                ),
                                TextButton(
                                  onPressed: state.saving
                                      ? null
                                      : () => ref
                                            .read(
                                              addressControllerProvider
                                                  .notifier,
                                            )
                                            .setDefault(address.id),
                                  child: const Text('Set Default'),
                                ),
                                TextButton(
                                  onPressed: state.saving
                                      ? null
                                      : () async {
                                          final confirmed =
                                              await showDialog<bool>(
                                                context: context,
                                                builder: (context) {
                                                  return AlertDialog(
                                                    title: const Text(
                                                      'Delete address?',
                                                    ),
                                                    content: Text(
                                                      'Delete ${address.label}?',
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                              context,
                                                              false,
                                                            ),
                                                        child: const Text(
                                                          'Cancel',
                                                        ),
                                                      ),
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                              context,
                                                              true,
                                                            ),
                                                        child: const Text(
                                                          'Delete',
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                          if (confirmed == true) {
                                            await ref
                                                .read(
                                                  addressControllerProvider
                                                      .notifier,
                                                )
                                                .delete(address.id);
                                          }
                                        },
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
