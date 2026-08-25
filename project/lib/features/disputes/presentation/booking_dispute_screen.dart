import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/features/availability/presentation/cleaner_availability_screen.dart';
import 'package:home_cleaning_marketplace/features/disputes/data/dispute_models.dart';
import 'package:home_cleaning_marketplace/features/disputes/presentation/booking_dispute_controller.dart';

class BookingDisputeScreen extends ConsumerStatefulWidget {
  const BookingDisputeScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  ConsumerState<BookingDisputeScreen> createState() =>
      _BookingDisputeScreenState();
}

class _BookingDisputeScreenState extends ConsumerState<BookingDisputeScreen> {
  final _subject = TextEditingController();
  final _description = TextEditingController();
  DisputeCategory _category = DisputeCategory.serviceQuality;
  String _validation = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref
          .read(bookingDisputeControllerProvider.notifier)
          .load(widget.bookingId);
    });
  }

  @override
  void dispose() {
    _subject.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingDisputeControllerProvider);
    final dispute = state.dispute;
    return Scaffold(
      appBar: AppBar(title: const Text('Dispute')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: state.loading && dispute == null
              ? const Center(child: CircularProgressIndicator())
              : dispute == null
              ? _CreateForm(
                  category: _category,
                  subject: _subject,
                  description: _description,
                  validation: _validation,
                  saving: state.saving,
                  errorMessage: state.errorMessage,
                  onCategory: (value) => setState(() => _category = value),
                  onSubmit: _submitCreate,
                )
              : _ExistingDispute(
                  dispute: dispute,
                  saving: state.saving,
                  errorMessage: state.errorMessage,
                  onClose: dispute.canClose
                      ? () => ref
                            .read(bookingDisputeControllerProvider.notifier)
                            .close(widget.bookingId)
                      : null,
                ),
        ),
      ),
    );
  }

  Future<void> _submitCreate() async {
    final subject = _subject.text.trim();
    final description = _description.text.trim();
    if (subject.characters.length < 5 || subject.characters.length > 120) {
      setState(() {
        _validation = 'Subject must be between 5 and 120 characters.';
      });
      return;
    }
    if (description.characters.length < 20 ||
        description.characters.length > 3000) {
      setState(() {
        _validation = 'Description must be between 20 and 3000 characters.';
      });
      return;
    }
    setState(() => _validation = '');
    await ref
        .read(bookingDisputeControllerProvider.notifier)
        .create(
          bookingId: widget.bookingId,
          category: _category.wireValue,
          subject: subject,
          description: description,
        );
  }
}

class _CreateForm extends StatelessWidget {
  const _CreateForm({
    required this.category,
    required this.subject,
    required this.description,
    required this.validation,
    required this.saving,
    required this.errorMessage,
    required this.onCategory,
    required this.onSubmit,
  });

  final DisputeCategory category;
  final TextEditingController subject;
  final TextEditingController description;
  final String validation;
  final bool saving;
  final String? errorMessage;
  final ValueChanged<DisputeCategory> onCategory;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const Text('Category'),
        DropdownButton<DisputeCategory>(
          value: category,
          isExpanded: true,
          items: [
            for (final option in DisputeCategory.selectable)
              DropdownMenuItem(value: option, child: Text(option.label)),
          ],
          onChanged: (value) {
            if (value != null) {
              onCategory(value);
            }
          },
        ),
        TextField(
          controller: subject,
          decoration: const InputDecoration(labelText: 'Subject'),
        ),
        TextField(
          controller: description,
          maxLines: 6,
          decoration: const InputDecoration(labelText: 'Description'),
        ),
        if (validation.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(validation),
        ],
        if (errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(errorMessage!),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: saving ? null : onSubmit,
          child: Text(saving ? 'Submitting...' : 'Submit Dispute'),
        ),
      ],
    );
  }
}

class _ExistingDispute extends StatelessWidget {
  const _ExistingDispute({
    required this.dispute,
    required this.saving,
    required this.errorMessage,
    required this.onClose,
  });

  final BookingDispute dispute;
  final bool saving;
  final String? errorMessage;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Text(dispute.status.label),
        Text(dispute.category.label),
        Text(dispute.subject),
        Text(dispute.description),
        Text('With ${dispute.counterpartName}'),
        if (dispute.resolution != null) ...[
          const SizedBox(height: 12),
          Text('Resolution: ${dispute.resolution}'),
        ],
        const SizedBox(height: 16),
        const Text('History'),
        for (final entry in dispute.history)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${entry.toStatus.label} · ${entry.actorRole}'
              '${entry.note == null ? '' : ' · ${entry.note}'}'
              ' · ${formatLocalDateTime(entry.createdAt)}',
            ),
          ),
        if (errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(errorMessage!),
        ],
        if (onClose != null) ...[
          const SizedBox(height: 16),
          FilledButton(
            onPressed: saving ? null : onClose,
            child: Text(saving ? 'Closing...' : 'Close Dispute'),
          ),
        ],
      ],
    );
  }
}
