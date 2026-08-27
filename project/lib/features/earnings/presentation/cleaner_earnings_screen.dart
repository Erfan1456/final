import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_cleaning_marketplace/app/router/app_routes.dart';
import 'package:home_cleaning_marketplace/features/earnings/presentation/cleaner_earnings_controller.dart';
import 'package:home_cleaning_marketplace/features/payments/data/payment_models.dart';
import 'package:home_cleaning_marketplace/shared/presentation/app_spacing.dart';
import 'package:home_cleaning_marketplace/shared/widgets/app_async_states.dart';
import 'package:home_cleaning_marketplace/shared/widgets/app_confirmation_dialog.dart';
import 'package:home_cleaning_marketplace/shared/widgets/app_section.dart';

class CleanerEarningsScreen extends ConsumerWidget {
  const CleanerEarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cleanerEarningsControllerProvider);
    final summary = state.selectedSummary;
    return Scaffold(
      appBar: AppBar(title: const Text('Earnings & Payouts')),
      body: SafeArea(
        child: state.loading && state.summary == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  if (state.errorMessage != null) Text(state.errorMessage!),
                  if ((state.summary?.currencies ?? const []).length > 1)
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final item in state.summary!.currencies)
                          ChoiceChip(
                            label: Text(item.currencyCode),
                            selected:
                                item.currencyCode == state.selectedCurrency,
                            onSelected: (_) => ref
                                .read(
                                  cleanerEarningsControllerProvider.notifier,
                                )
                                .selectCurrency(item.currencyCode),
                          ),
                      ],
                    ),
                  if (summary == null)
                    const Text('No earnings have been recorded yet.')
                  else ...[
                    Text(
                      'Gross service value: ${summary.format(summary.grossEarnedMinor)}',
                    ),
                    Text(
                      'Platform fees: ${summary.format(summary.platformFeesMinor)}',
                    ),
                    Text(
                      'Refund adjustments: ${summary.format(summary.cleanerRefundAdjustmentsMinor)}',
                    ),
                    Text(
                      'Net earnings ledger: ${summary.format(summary.netLedgerMinor)}',
                    ),
                    Text(
                      'Reserved payouts: ${summary.format(summary.reservedPayoutMinor)}',
                    ),
                    Text('Paid out: ${summary.format(summary.paidOutMinor)}'),
                    Text(
                      'Available balance: ${summary.format(summary.availableBalanceMinor)}',
                    ),
                    if (summary.availableBalanceMinor < 0)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Available balance is negative. Future earnings offset this deficit before another payout can be requested.',
                        ),
                      ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () =>
                        context.push(AppRoutes.cleanerEarningsLedgerPath),
                    child: const Text('Earnings ledger'),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.tonal(
                    onPressed: () => context.push(AppRoutes.cleanerPayoutsPath),
                    child: const Text('Payout history'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () =>
                        context.push(AppRoutes.cleanerPayoutRequestPath),
                    child: const Text('Request payout'),
                  ),
                ],
              ),
      ),
    );
  }
}

class CleanerEarningsLedgerScreen extends ConsumerWidget {
  const CleanerEarningsLedgerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cleanerEarningsControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Earnings ledger')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (state.errorMessage != null) Text(state.errorMessage!),
            for (final entry in state.ledger)
              ListTile(
                title: Text(
                  '${entry.entryType.label} · ${formatPaymentAmount(entry.cleanerAmountMinor, entry.currencyCode)}',
                ),
                subtitle: Text(
                  'Booking ${entry.bookingId}\n${entry.createdAt.toIso8601String()}',
                ),
                textColor: entry.isNegativeAdjustment ? Colors.red : null,
              ),
            if (state.ledgerCursor != null)
              FilledButton(
                onPressed: state.loadingMore
                    ? null
                    : () => ref
                          .read(cleanerEarningsControllerProvider.notifier)
                          .loadMoreLedger(),
                child: const Text('Load More'),
              ),
          ],
        ),
      ),
    );
  }
}

class CleanerPayoutHistoryScreen extends ConsumerWidget {
  const CleanerPayoutHistoryScreen({super.key});

  Future<void> _cancelPayout(
    BuildContext context,
    WidgetRef ref,
    String payoutId,
  ) async {
    final confirmed = await showAppConfirmationDialog(
      context: context,
      title: 'Cancel this payout request?',
      message: 'The reserved payout amount will be released back to your available balance.',
      confirmLabel: 'Cancel request',
      isDestructive: true,
    );
    if (confirmed) {
      await ref
          .read(cleanerEarningsControllerProvider.notifier)
          .cancelPayout(payoutId);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cleanerEarningsControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Payout history')),
      body: SafeArea(
        child: AppAsyncContent(
          loading: state.loading && state.payouts.isEmpty,
          hasData: state.payouts.isNotEmpty,
          errorMessage: state.errorMessage,
          emptyTitle: 'No payout requests yet.',
          builder: (context) => ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (state.errorMessage != null) Text(state.errorMessage!),
              for (final payout in state.payouts) ...[
                ListTile(
                  title: Text(
                    '${formatPaymentAmount(payout.amountMinor, payout.currencyCode)} · ${payout.status.label}',
                  ),
                  subtitle: Text(
                    'Attempt ${payout.attemptNumber} · ${payout.requestedAt.toIso8601String()}'
                    '${payout.rejectionReason == null ? '' : '\n${payout.rejectionReason}'}',
                  ),
                ),
                if (payout.status.canCancel)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: state.saving
                          ? null
                          : () => _cancelPayout(context, ref, payout.id),
                      child: const Text('Cancel Request'),
                    ),
                  ),
              ],
              if (state.payoutsCursor != null)
                FilledButton(
                  onPressed: state.loadingMore
                      ? null
                      : () => ref
                            .read(cleanerEarningsControllerProvider.notifier)
                            .loadMorePayouts(),
                  child: const Text('Load More'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class CleanerPayoutRequestScreen extends ConsumerStatefulWidget {
  const CleanerPayoutRequestScreen({super.key});

  @override
  ConsumerState<CleanerPayoutRequestScreen> createState() =>
      _CleanerPayoutRequestScreenState();
}

class _CleanerPayoutRequestScreenState
    extends ConsumerState<CleanerPayoutRequestScreen> {
  final _amount = TextEditingController();
  String? _currency;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.read(cleanerEarningsControllerProvider.notifier).beginPayoutRequest();
    });
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cleanerEarningsControllerProvider);
    final summary = state.selectedSummary;
    final currencies = state.summary?.currencies ?? const [];
    final currency = _currency ?? state.selectedCurrency ?? 'BDT';
    return Scaffold(
      appBar: AppBar(title: const Text('Request payout')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (state.errorMessage != null) Text(state.errorMessage!),
            Text(
              'Available balance: ${summary == null ? 'n/a' : summary.format(summary.availableBalanceMinor)}',
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue:
                  currencies.any((item) => item.currencyCode == currency)
                  ? currency
                  : (currencies.isEmpty ? null : currencies.first.currencyCode),
              items: [
                for (final item in currencies)
                  DropdownMenuItem(
                    value: item.currencyCode,
                    child: Text(item.currencyCode),
                  ),
              ],
              onChanged: (value) => setState(() => _currency = value),
              decoration: const InputDecoration(labelText: 'Currency'),
            ),
            TextField(
              controller: _amount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (minor units)',
              ),
            ),
            const SizedBox(height: AppSpacing.normal),
            const AppDevelopmentBanner(
              message:
                  'Development Sandbox — payouts are simulated only and do '
                  'not transfer real money. No bank or wallet destination is '
                  'collected yet.',
            ),
            const SizedBox(height: AppSpacing.normal),
            FilledButton(
              onPressed: state.saving
                  ? null
                  : () async {
                      final parsed = int.tryParse(_amount.text.trim());
                      if (parsed == null || parsed < 1) {
                        return;
                      }
                      final ok = await ref
                          .read(cleanerEarningsControllerProvider.notifier)
                          .requestPayout(
                            amountMinor: parsed,
                            currencyCode: currency,
                          );
                      if (ok && context.mounted) {
                        context.pop();
                      }
                    },
              child: const Text('Request Payout'),
            ),
          ],
        ),
      ),
    );
  }
}
