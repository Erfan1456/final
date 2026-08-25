import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_cleaning_marketplace/features/payments/data/payment_models.dart';
import 'package:home_cleaning_marketplace/features/payments/presentation/admin_payment_controller.dart';

class AdminPaymentListScreen extends ConsumerWidget {
  const AdminPaymentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminPaymentControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Payments')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final status in <(String, String?)>[
                    ('All', null),
                    ('Pending', 'pending'),
                    ('Paid', 'paid'),
                    ('Failed', 'failed'),
                    ('Refunded', 'refunded'),
                  ])
                    ChoiceChip(
                      label: Text(status.$1),
                      selected: state.filters.status == status.$2,
                      onSelected: (_) => ref
                          .read(adminPaymentControllerProvider.notifier)
                          .applyFilters(
                            state.filters.copyWith(
                              status: status.$2,
                              clearStatus: status.$2 == null,
                            ),
                          ),
                    ),
                  ChoiceChip(
                    label: const Text('Sandbox'),
                    selected: state.filters.provider == 'sandbox',
                    onSelected: (selected) => ref
                        .read(adminPaymentControllerProvider.notifier)
                        .applyFilters(
                          state.filters.copyWith(
                            provider: selected ? 'sandbox' : null,
                            clearProvider: !selected,
                          ),
                        ),
                  ),
                  ChoiceChip(
                    label: const Text('BDT'),
                    selected: state.filters.currency == 'BDT',
                    onSelected: (selected) => ref
                        .read(adminPaymentControllerProvider.notifier)
                        .applyFilters(
                          state.filters.copyWith(
                            currency: selected ? 'BDT' : null,
                            clearCurrency: !selected,
                          ),
                        ),
                  ),
                ],
              ),
            ),
            if (state.errorMessage != null) Text(state.errorMessage!),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  for (final item in state.items)
                    ListTile(
                      title: Text('${item.shortId} · ${item.status.label}'),
                      subtitle: Text(
                        'Booking ${item.bookingId}\n'
                        '${item.provider.label} · '
                        '${formatPaymentAmount(item.amountMinor, item.currencyCode)}\n'
                        'Attempt ${item.attemptNumber} · '
                        '${item.createdAt.toIso8601String()}',
                      ),
                      isThreeLine: true,
                      onTap: () => context.push('/admin/payments/${item.id}'),
                    ),
                  if (state.nextCursor != null)
                    FilledButton(
                      onPressed: state.loading || state.loadingMore
                          ? null
                          : () => ref
                                .read(adminPaymentControllerProvider.notifier)
                                .loadMore(),
                      child: const Text('Load More'),
                    ),
                  if (state.loading)
                    const Center(child: CircularProgressIndicator()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
