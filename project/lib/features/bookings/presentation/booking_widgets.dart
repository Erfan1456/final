import 'package:flutter/material.dart';
import 'package:home_cleaning_marketplace/features/bookings/data/booking_models.dart';

class BookingStatusHistoryList extends StatelessWidget {
  const BookingStatusHistoryList({super.key, required this.history});

  final List<BookingStatusHistoryEntry> history;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Status history'),
        const SizedBox(height: 8),
        for (final entry in history)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${entry.toStatus.label} · ${entry.actorRole}'
              '${entry.reason == null ? '' : ' · ${entry.reason}'}',
            ),
          ),
      ],
    );
  }
}

class BookingAddressView extends StatelessWidget {
  const BookingAddressView({
    super.key,
    required this.address,
    required this.fullAddressAllowed,
  });

  final BookingAddressSnapshot address;
  final bool fullAddressAllowed;

  @override
  Widget build(BuildContext context) {
    if (!fullAddressAllowed || !address.isFull) {
      return Text('Location: ${address.coarseSummary}');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (address.label != null) Text(address.label!),
        if (address.line1 != null) Text(address.line1!),
        if (address.line2 != null) Text(address.line2!),
        Text('${address.city}, ${address.region}'),
        if (address.postalCode != null) Text(address.postalCode!),
        Text(address.countryCode),
      ],
    );
  }
}

const bookingFilterOptions = <(String, BookingStatus?)>[
  ('All', null),
  ('Pending', BookingStatus.pending),
  ('Confirmed', BookingStatus.confirmed),
  ('In Progress', BookingStatus.inProgress),
  ('Completed', BookingStatus.completed),
  ('Cancelled', BookingStatus.cancelled),
  ('Declined', BookingStatus.declined),
];

class BookingReasonPrompt {
  const BookingReasonPrompt({required this.submitted, this.reason});

  final bool submitted;
  final String? reason;
}

Future<BookingReasonPrompt> promptBookingReason(
  BuildContext context, {
  required String title,
  required bool required,
}) async {
  var value = '';
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: TextField(
          maxLength: 500,
          maxLines: 3,
          onChanged: (next) => value = next,
          decoration: const InputDecoration(labelText: 'Reason'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Back'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      );
    },
  );
  final trimmed = value.trim();
  if (confirmed != true) {
    return const BookingReasonPrompt(submitted: false);
  }
  if (required && trimmed.length < 5) {
    return const BookingReasonPrompt(submitted: true, reason: '');
  }
  return BookingReasonPrompt(
    submitted: true,
    reason: trimmed.isEmpty ? null : trimmed,
  );
}
