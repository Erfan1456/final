import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_cleaning_marketplace/app/router/app_routes.dart';
import 'package:home_cleaning_marketplace/features/admin/presentation/admin_finance_controller.dart';
import 'package:home_cleaning_marketplace/features/payments/data/payment_models.dart';

class AdminFinanceScreen extends ConsumerWidget {
  const AdminFinanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminFinanceControllerProvider);
    final summary = state.summary;
    return Scaffold(
      appBar: AppBar(title: const Text('Finance')),
      body: SafeArea(
        child: state.loading && summary == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  if (state.errorMessage != null) Text(state.errorMessage!),
                  ChoiceChip(
                    label: const Text('BDT'),
                    selected: state.currency == 'BDT',
                    onSelected: (selected) => ref
                        .read(adminFinanceControllerProvider.notifier)
                        .loadSummary(currency: selected ? 'BDT' : null),
                  ),
                  if (summary == null)
                    const Text('No finance summary is available.')
                  else ...[
                    Text(
                      'From ${summary.from.toIso8601String()} to ${summary.to.toIso8601String()}',
                    ),
                    for (final item in summary.currencies) ...[
                      const SizedBox(height: 16),
                      Text(item.currencyCode),
                      Text(
                        'Gross service volume: ${formatPaymentAmount(item.grossServiceVolumeMinor, item.currencyCode)}',
                      ),
                      Text(
                        'Platform fees: ${formatPaymentAmount(item.platformFeeMinor, item.currencyCode)}',
                      ),
                      Text(
                        'Cleaner net earnings: ${formatPaymentAmount(item.cleanerNetEarningsMinor, item.currencyCode)}',
                      ),
                      Text(
                        'Refunds: ${formatPaymentAmount(item.refundGrossMinor, item.currencyCode)}',
                      ),
                      Text(
                        'Payout requested: ${formatPaymentAmount(item.payoutRequestedMinor, item.currencyCode)}',
                      ),
                      Text(
                        'Payout processing: ${formatPaymentAmount(item.payoutProcessingMinor, item.currencyCode)}',
                      ),
                      Text(
                        'Payout paid: ${formatPaymentAmount(item.payoutPaidMinor, item.currencyCode)}',
                      ),
                      Text(
                        'Payout failed: ${formatPaymentAmount(item.payoutFailedMinor, item.currencyCode)}',
                      ),
                    ],
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () =>
                        context.push(AppRoutes.adminFinanceReconciliationPath),
                    child: const Text('Reconciliation Issues'),
                  ),
                ],
              ),
      ),
    );
  }
}

class AdminFinanceReconciliationScreen extends ConsumerStatefulWidget {
  const AdminFinanceReconciliationScreen({super.key});

  @override
  ConsumerState<AdminFinanceReconciliationScreen> createState() =>
      _AdminFinanceReconciliationScreenState();
}

class _AdminFinanceReconciliationScreenState
    extends ConsumerState<AdminFinanceReconciliationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.read(adminFinanceControllerProvider.notifier).loadReconciliation();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminFinanceControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Reconciliation')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Read-only detection. This screen does not repair financial records.',
            ),
            if (state.errorMessage != null) Text(state.errorMessage!),
            if (state.issues.isEmpty && !state.loading)
              const Text('No reconciliation issues were found.'),
            for (final issue in state.issues)
              ListTile(
                title: Text(issue.label),
                subtitle: Text(
                  'Booking ${issue.bookingId} · ${issue.currencyCode}\n${issue.explanation}',
                ),
              ),
            if (state.nextCursor != null)
              FilledButton(
                onPressed: state.loadingMore
                    ? null
                    : () => ref
                          .read(adminFinanceControllerProvider.notifier)
                          .loadMoreReconciliation(),
                child: const Text('Load More'),
              ),
          ],
        ),
      ),
    );
  }
}

class AdminCleanerFinanceScreen extends ConsumerStatefulWidget {
  const AdminCleanerFinanceScreen({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<AdminCleanerFinanceScreen> createState() =>
      _AdminCleanerFinanceScreenState();
}

class _AdminCleanerFinanceScreenState
    extends ConsumerState<AdminCleanerFinanceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref
          .read(adminFinanceControllerProvider.notifier)
          .loadCleanerFinance(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminFinanceControllerProvider);
    final detail = state.cleanerFinance;
    return Scaffold(
      appBar: AppBar(title: const Text('Cleaner finance')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: state.loading && detail == null
              ? const Center(child: CircularProgressIndicator())
              : detail == null
              ? Text(state.errorMessage ?? 'Cleaner finance was not found.')
              : ListView(
                  children: [
                    Text(detail.cleanerDisplayName),
                    for (final item in detail.currencies) ...[
                      const SizedBox(height: 12),
                      Text(item.currencyCode),
                      Text(
                        'Available balance: ${item.format(item.availableBalanceMinor)}',
                      ),
                      Text('Net ledger: ${item.format(item.netLedgerMinor)}'),
                    ],
                    const SizedBox(height: 16),
                    const Text('Recent ledger'),
                    for (final entry in detail.recentLedger)
                      Text(
                        '${entry.entryType.label} · ${formatPaymentAmount(entry.cleanerAmountMinor, entry.currencyCode)}',
                      ),
                    const SizedBox(height: 16),
                    const Text('Recent payouts'),
                    for (final payout in detail.recentPayouts)
                      Text(
                        '${payout.status.label} · ${formatPaymentAmount(payout.amountMinor, payout.currencyCode)}',
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}
