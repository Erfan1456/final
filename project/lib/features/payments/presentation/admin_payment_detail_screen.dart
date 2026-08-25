import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/features/payments/data/payment_models.dart';
import 'package:home_cleaning_marketplace/features/payments/presentation/admin_payment_controller.dart';

class AdminPaymentDetailScreen extends ConsumerStatefulWidget {
  const AdminPaymentDetailScreen({super.key, required this.paymentId});

  final String paymentId;

  @override
  ConsumerState<AdminPaymentDetailScreen> createState() =>
      _AdminPaymentDetailScreenState();
}

class _AdminPaymentDetailScreenState
    extends ConsumerState<AdminPaymentDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref
          .read(adminPaymentControllerProvider.notifier)
          .loadDetail(widget.paymentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminPaymentControllerProvider);
    final detail = state.detail;
    return Scaffold(
      appBar: AppBar(title: const Text('Payment transaction')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: state.loading && detail == null
              ? const Center(child: CircularProgressIndicator())
              : detail == null
              ? Text(state.errorMessage ?? 'Payment was not found.')
              : ListView(
                  children: [
                    Text('Payment ${detail.shortId}'),
                    Text('Status: ${detail.status.label}'),
                    Text('Provider: ${detail.provider.label}'),
                    Text(
                      formatPaymentAmount(
                        detail.amountMinor,
                        detail.currencyCode,
                      ),
                    ),
                    Text(
                      'Refunded: ${formatPaymentAmount(detail.refundedAmountMinor, detail.currencyCode)}',
                    ),
                    Text('Attempt ${detail.attemptNumber}'),
                    Text('Booking ${detail.bookingId}'),
                    if (detail.serviceSnapshotName != null)
                      Text(detail.serviceSnapshotName!),
                    if (detail.bookingStatus != null)
                      Text('Booking status: ${detail.bookingStatus}'),
                    if (detail.customerUserId != null)
                      Text('Customer ${detail.customerUserId}'),
                    if (detail.cleanerUserId != null)
                      Text('Cleaner ${detail.cleanerUserId}'),
                    Text('Created ${detail.createdAt.toIso8601String()}'),
                    if (detail.paidAt != null)
                      Text('Paid ${detail.paidAt!.toIso8601String()}'),
                    if (detail.failedAt != null)
                      Text('Failed ${detail.failedAt!.toIso8601String()}'),
                    if (detail.failureCode != null)
                      Text('Failure: ${detail.failureCode}'),
                    if (detail.failureMessage != null)
                      Text(detail.failureMessage!),
                    const SizedBox(height: 16),
                    const Text('Webhook events'),
                    for (final event in state.events)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          '${event.eventType} · ${event.processingStatus}\n'
                          '${event.providerEventId}',
                        ),
                      ),
                    if (state.errorMessage != null) Text(state.errorMessage!),
                    if (detail.allowsRefund) ...[
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: state.saving
                            ? null
                            : () => _openRefundDialog(detail),
                        child: Text(state.saving ? 'Refunding...' : 'Refund'),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _openRefundDialog(AdminPaymentDetail detail) async {
    ref.read(adminPaymentControllerProvider.notifier).beginRefundAttempt();
    final draft = await showDialog<_RefundDraft>(
      context: context,
      builder: (context) => const _RefundDialog(),
    );
    if (!mounted || draft == null) {
      return;
    }
    await ref
        .read(adminPaymentControllerProvider.notifier)
        .refund(
          paymentId: detail.id,
          reason: draft.reason,
          amountMinor: draft.amountMinor,
        );
  }
}

class _RefundDraft {
  const _RefundDraft({required this.reason, this.amountMinor});

  final String reason;
  final int? amountMinor;
}

class _RefundDialog extends StatefulWidget {
  const _RefundDialog();

  @override
  State<_RefundDialog> createState() => _RefundDialogState();
}

class _RefundDialogState extends State<_RefundDialog> {
  final _amount = TextEditingController();
  final _reason = TextEditingController();
  String _validation = '';

  @override
  void dispose() {
    _amount.dispose();
    _reason.dispose();
    super.dispose();
  }

  void _submit() {
    final reason = _reason.text.trim();
    if (reason.length < 5 || reason.length > 500) {
      setState(() {
        _validation = 'Reason must be between 5 and 500 characters.';
      });
      return;
    }
    final amountText = _amount.text.trim();
    int? amount;
    if (amountText.isNotEmpty) {
      amount = int.tryParse(amountText);
      if (amount == null || amount < 1) {
        setState(() {
          _validation = 'Amount must be a positive whole number.';
        });
        return;
      }
    }
    Navigator.of(context)
        .pop(_RefundDraft(reason: reason, amountMinor: amount));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Refund'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _amount,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Amount (minor units, optional)',
            ),
          ),
          TextField(
            controller: _reason,
            maxLength: 500,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Reason'),
          ),
          if (_validation.isNotEmpty) Text(_validation),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Back'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Refund')),
      ],
    );
  }
}
