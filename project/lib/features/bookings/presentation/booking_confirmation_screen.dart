import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_cleaning_marketplace/app/router/app_routes.dart';
import 'package:home_cleaning_marketplace/features/addresses/data/address.dart';
import 'package:home_cleaning_marketplace/features/addresses/presentation/address_controller.dart';
import 'package:home_cleaning_marketplace/features/availability/presentation/cleaner_availability_screen.dart';
import 'package:home_cleaning_marketplace/features/bookings/data/booking_models.dart';
import 'package:home_cleaning_marketplace/features/bookings/presentation/customer_booking_controller.dart';
import 'package:home_cleaning_marketplace/features/catalog/data/marketplace_service.dart';
import 'package:home_cleaning_marketplace/features/discovery/presentation/discovery_controller.dart';

class BookingConfirmationScreen extends ConsumerStatefulWidget {
  const BookingConfirmationScreen({
    super.key,
    required this.cleanerUserId,
    required this.slotId,
  });

  final String cleanerUserId;
  final String slotId;

  @override
  ConsumerState<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState
    extends ConsumerState<BookingConfirmationScreen> {
  String? _selectedAddressId;
  final _notes = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref
          .read(discoveryControllerProvider.notifier)
          .loadDetail(widget.cleanerUserId);
      ref.read(customerBookingControllerProvider.notifier).beginSubmitAttempt();
    });
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final discovery = ref.watch(discoveryControllerProvider);
    final addresses = ref.watch(addressControllerProvider);
    final booking = ref.watch(customerBookingControllerProvider);
    final detail = discovery.detail;
    final slot = detail == null
        ? null
        : [
            for (final item in detail.availability)
              if (item.id == widget.slotId) item,
          ].firstOrNull;
    final items = addresses.addresses;
    final selectedId =
        _selectedAddressId ??
        addresses.defaultAddress?.id ??
        (items.isEmpty ? null : items.first.id);
    Address? selectedAddress;
    for (final address in items) {
      if (address.id == selectedId) {
        selectedAddress = address;
      }
    }
    final preview = slot == null || detail == null
        ? null
        : quotedTotalMinorPreview(
            hourlyRateMinor: detail.hourlyRateMinor,
            durationMinutes: slot.duration.inMinutes,
          );

    return Scaffold(
      appBar: AppBar(title: const Text('Confirm booking')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: discovery.loading && detail == null
              ? const Center(child: CircularProgressIndicator())
              : detail == null || slot == null
              ? Text(
                  discovery.errorMessage ??
                      'That time slot is no longer available.',
                )
              : ListView(
                  children: [
                    Text(
                      detail.fullName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(detail.service.name),
                    Text(
                      '${formatLocalDateTime(slot.startAt)} → ${formatLocalDateTime(slot.endAt)}',
                    ),
                    Text('Duration: ${slot.duration.inMinutes} minutes'),
                    Text(
                      formatMinorHourlyRate(
                        detail.hourlyRateMinor,
                        detail.currencyCode,
                      ),
                    ),
                    Text(formatQuotedTotal(preview!, detail.currencyCode)),
                    const SizedBox(height: 16),
                    if (items.isEmpty) ...[
                      const Text('Add an address before booking'),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: () =>
                            context.push(AppRoutes.customerAddressNewPath),
                        child: const Text('Add address'),
                      ),
                    ] else ...[
                      const Text('Service address'),
                      const SizedBox(height: 8),
                      for (final address in items)
                        ListTile(
                          title: Text(address.label),
                          subtitle: Text('${address.line1}, ${address.city}'),
                          selected: address.id == selectedId,
                          onTap: () {
                            setState(() => _selectedAddressId = address.id);
                          },
                        ),
                      if (selectedAddress != null)
                        Text(
                          '${selectedAddress.label} · ${selectedAddress.line1}, ${selectedAddress.city}',
                        ),
                    ],
                    const SizedBox(height: 16),
                    TextField(
                      controller: _notes,
                      maxLength: 500,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Customer notes (optional)',
                      ),
                    ),
                    if (booking.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(booking.errorMessage!),
                      ),
                    FilledButton(
                      onPressed: booking.submitting || selectedId == null
                          ? null
                          : () async {
                              final created = await ref
                                  .read(
                                    customerBookingControllerProvider.notifier,
                                  )
                                  .submit(
                                    availabilitySlotId: slot.id,
                                    addressId: selectedId,
                                    customerNotes: _notes.text,
                                  );
                              if (!context.mounted || created == null) {
                                return;
                              }
                              context.go(
                                AppRoutes.customerBookingDetailLocation(
                                  created.id,
                                ),
                              );
                            },
                      child: Text(
                        booking.submitting ? 'Booking...' : 'Confirm Booking',
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
