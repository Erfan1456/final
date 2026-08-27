import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_cleaning_marketplace/app/router/app_routes.dart';
import 'package:home_cleaning_marketplace/features/admin/presentation/admin_payout_controller.dart';
import 'package:home_cleaning_marketplace/features/bookings/presentation/booking_widgets.dart';
import 'package:home_cleaning_marketplace/features/earnings/data/earnings_models.dart';
import 'package:home_cleaning_marketplace/features/payments/data/payment_models.dart';
import 'package:home_cleaning_marketplace/shared/widgets/app_async_states.dart';

class AdminPayoutListScreen extends ConsumerWidget {
  const AdminPayoutListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminPayoutControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Payouts')),
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
                    ('Requested', 'requested'),
                    ('Processing', 'processing'),
                    ('Paid', 'paid'),
                    ('Failed', 'failed'),
                    ('Cancelled', 'cancelled'),
                    ('Rejected', 'rejected'),
                    ('All', null),
                  ])
                    ChoiceChip(
                      label: Text(status.$1),
                      selected: state.filters.status == status.$2,
                      onSelected: (_) => ref
                          .read(adminPayoutControllerProvider.notifier)
                          .applyFilters(
                            state.filters.copyWith(
                              status: status.$2,
                              clearStatus: status.$2 == null,
                            ),
                          ),
                    ),
                  ChoiceChip(
                    label: const Text('BDT'),
                    selected: state.filters.currency == 'BDT',
                    onSelected: (selected) => ref
                        .read(adminPayoutControllerProvider.notifier)
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
            if (state.errorMessage != null && state.items.isNotEmpty)
              Text(state.errorMessage!),
            Expanded(
              child: AppAsyncContent(
                loading: state.loading,
                hasData: state.items.isNotEmpty,
                errorMessage: state.errorMessage,
                onRetry: () =>
                    ref.read(adminPayoutControllerProvider.notifier).load(),
                emptyTitle: 'No requested payouts.',
                builder: (context) => ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final item in state.items)
                      ListTile(
                        title: Text(
                          '${item.cleanerDisplayName ?? 'Cleaner'} · ${item.status.label}',
                        ),
                        subtitle: Text(
                          '${formatPaymentAmount(item.amountMinor, item.currencyCode)}\n'
                          '${item.requestedAt.toIso8601String()}',
                        ),
                        onTap: () => context.push(
                          AppRoutes.adminPayoutDetailLocation(item.id),
                        ),
                      ),
                    if (state.nextCursor != null)
                      FilledButton(
                        onPressed: state.loadingMore
                            ? null
                            : () => ref
                                  .read(adminPayoutControllerProvider.notifier)
                                  .loadMore(),
                        child: const Text('Load More'),
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

class AdminPayoutDetailScreen extends ConsumerStatefulWidget {
  const AdminPayoutDetailScreen({super.key, required this.payoutId});

  final String payoutId;

  @override
  ConsumerState<AdminPayoutDetailScreen> createState() =>
      _AdminPayoutDetailScreenState();
}

class _AdminPayoutDetailScreenState
    extends ConsumerState<AdminPayoutDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref
          .read(adminPayoutControllerProvider.notifier)
          .loadDetail(widget.payoutId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminPayoutControllerProvider);
    final detail = state.detail;
    final payout = detail?.payout;
    return Scaffold(
      appBar: AppBar(title: const Text('Payout detail')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: state.loading && detail == null
              ? const Center(child: CircularProgressIndicator())
              : detail == null || payout == null
              ? Text(state.errorMessage ?? 'Payout was not found.')
              : ListView(
                  children: [
                    Text(payout.cleanerDisplayName ?? 'Cleaner'),
                    Text(
                      formatPaymentAmount(
                        payout.amountMinor,
                        payout.currencyCode,
                      ),
                    ),
                    Text(payout.status.label),
                    Text('Attempt ${payout.attemptNumber}'),
                    Text(
                      'Available: ${detail.earningsSummary.format(detail.earningsSummary.availableBalanceMinor)}',
                    ),
                    Text('Requested: ${payout.requestedAt.toIso8601String()}'),
                    if (payout.rejectionReason != null)
                      Text(payout.rejectionReason!),
                    const SizedBox(height: 12),
                    const Text('Provider events'),
                    for (final event in detail.providerEvents)
                      Text('${event.eventType} · ${event.processingStatus}'),
                    if (state.errorMessage != null) Text(state.errorMessage!),
                    if (payout.status == PayoutStatus.requested) ...[
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: state.saving
                            ? null
                            : () => ref
                                  .read(adminPayoutControllerProvider.notifier)
                                  .process(widget.payoutId),
                        child: const Text('Process'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: state.saving ? null : () => _reject(),
                        child: const Text('Reject'),
                      ),
                    ],
                    if (payout.simulationAvailable) ...[
                      const SizedBox(height: 24),
                      const Text('Development Sandbox'),
                      const Text(
                        'These controls exercise payout state through a signed sandbox webhook. They do not transfer money.',
                      ),
                      const SizedBox(height: 8),
                      FilledButton.tonal(
                        onPressed: state.saving
                            ? null
                            : () => ref
                                  .read(adminPayoutControllerProvider.notifier)
                                  .simulateSuccess(widget.payoutId),
                        child: const Text('Simulate Success'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: state.saving
                            ? null
                            : () => ref
                                  .read(adminPayoutControllerProvider.notifier)
                                  .simulateFailure(widget.payoutId),
                        child: const Text('Simulate Failure'),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _reject() async {
    final prompt = await promptBookingReason(
      context,
      title: 'Reject payout',
      required: true,
    );
    if (!mounted || !prompt.submitted || prompt.reason == null) {
      return;
    }
    await ref
        .read(adminPayoutControllerProvider.notifier)
        .reject(payoutId: widget.payoutId, reason: prompt.reason!);
  }
}
