import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/features/availability/presentation/cleaner_availability_screen.dart';
import 'package:home_cleaning_marketplace/features/bookings/data/booking_models.dart';
import 'package:home_cleaning_marketplace/features/disputes/data/dispute_models.dart';
import 'package:home_cleaning_marketplace/features/disputes/presentation/admin_dispute_controller.dart';

class AdminDisputeDetailScreen extends ConsumerStatefulWidget {
  const AdminDisputeDetailScreen({super.key, required this.disputeId});

  final String disputeId;

  @override
  ConsumerState<AdminDisputeDetailScreen> createState() =>
      _AdminDisputeDetailScreenState();
}

class _AdminDisputeDetailScreenState
    extends ConsumerState<AdminDisputeDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref
          .read(adminDisputeControllerProvider.notifier)
          .loadDetail(widget.disputeId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminDisputeControllerProvider);
    final detail = state.detail;
    return Scaffold(
      appBar: AppBar(title: const Text('Dispute detail')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: state.loading && detail == null
              ? const Center(child: CircularProgressIndicator())
              : detail == null
              ? Text(state.errorMessage ?? 'Dispute was not found.')
              : ListView(
                  children: [
                    Text(detail.dispute.status.label),
                    Text(detail.dispute.category.label),
                    Text(detail.dispute.subject),
                    Text(detail.dispute.description),
                    Text('Booking ${detail.dispute.bookingId}'),
                    Text(
                      '${detail.dispute.customerDisplayName} / ${detail.dispute.cleanerPublicName}',
                    ),
                    if (detail.booking != null) ...[
                      const SizedBox(height: 12),
                      Text(detail.booking!.serviceName),
                      Text(
                        '${formatLocalDateTime(detail.booking!.startAt)} → ${formatLocalDateTime(detail.booking!.endAt)}',
                      ),
                      Text(
                        formatQuotedTotal(
                          detail.booking!.quotedTotalMinor,
                          detail.booking!.currencyCode,
                        ),
                      ),
                    ],
                    if (detail.dispute.resolution != null)
                      Text('Resolution: ${detail.dispute.resolution}'),
                    const SizedBox(height: 16),
                    const Text('History'),
                    for (final entry in detail.dispute.history)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '${entry.toStatus.label} · ${entry.actorRole}'
                          '${entry.note == null ? '' : ' · ${entry.note}'}',
                        ),
                      ),
                    if (state.errorMessage != null) Text(state.errorMessage!),
                    const SizedBox(height: 16),
                    if (detail.dispute.status == DisputeStatus.open)
                      FilledButton(
                        onPressed: state.saving
                            ? null
                            : () => ref
                                  .read(adminDisputeControllerProvider.notifier)
                                  .startReview(detail.dispute.id),
                        child: Text(
                          state.saving ? 'Updating...' : 'Start Review',
                        ),
                      ),
                    if (detail.dispute.status == DisputeStatus.open ||
                        detail.dispute.status == DisputeStatus.underReview) ...[
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: state.saving
                            ? null
                            : () => _openResolveDialog(detail.dispute.id),
                        child: const Text('Resolve'),
                      ),
                    ],
                    if (detail.dispute.status == DisputeStatus.resolved) ...[
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: state.saving
                            ? null
                            : () => ref
                                  .read(adminDisputeControllerProvider.notifier)
                                  .close(detail.dispute.id),
                        child: Text(state.saving ? 'Closing...' : 'Close'),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _openResolveDialog(String disputeId) async {
    final resolution = await showDialog<String>(
      context: context,
      builder: (context) => const _ResolveDisputeDialog(),
    );
    if (!mounted || resolution == null) {
      return;
    }
    await ref
        .read(adminDisputeControllerProvider.notifier)
        .resolve(disputeId: disputeId, resolution: resolution);
  }
}

class _ResolveDisputeDialog extends StatefulWidget {
  const _ResolveDisputeDialog();

  @override
  State<_ResolveDisputeDialog> createState() => _ResolveDisputeDialogState();
}

class _ResolveDisputeDialogState extends State<_ResolveDisputeDialog> {
  final _resolution = TextEditingController();
  String _validation = '';

  @override
  void dispose() {
    _resolution.dispose();
    super.dispose();
  }

  void _submit() {
    final resolution = _resolution.text.trim();
    if (resolution.characters.length < 10 ||
        resolution.characters.length > 3000) {
      setState(() {
        _validation = 'Resolution must be between 10 and 3000 characters.';
      });
      return;
    }
    Navigator.of(context).pop(resolution);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Resolve dispute'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _resolution,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Resolution'),
          ),
          if (_validation.isNotEmpty) Text(_validation),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Back'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Resolve')),
      ],
    );
  }
}
