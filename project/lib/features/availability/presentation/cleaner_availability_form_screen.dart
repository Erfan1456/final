import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/features/availability/data/availability_slot.dart';
import 'package:home_cleaning_marketplace/features/availability/presentation/availability_controller.dart';
import 'package:home_cleaning_marketplace/features/catalog/presentation/catalog_controller.dart';
import 'package:home_cleaning_marketplace/features/cleaner/data/cleaner_profile.dart';
import 'package:home_cleaning_marketplace/features/cleaner/presentation/cleaner_onboarding_controller.dart';

/// Create or edit a future availability slot.
class CleanerAvailabilityFormScreen extends ConsumerStatefulWidget {
  const CleanerAvailabilityFormScreen({super.key, this.slotId});

  final String? slotId;

  @override
  ConsumerState<CleanerAvailabilityFormScreen> createState() =>
      _CleanerAvailabilityFormScreenState();
}

class _CleanerAvailabilityFormScreenState
    extends ConsumerState<CleanerAvailabilityFormScreen> {
  String? _serviceId;
  DateTime? _start;
  DateTime? _end;

  @override
  Widget build(BuildContext context) {
    final approved =
        ref
            .watch(cleanerOnboardingControllerProvider)
            .profile
            ?.onboardingStatus ==
        OnboardingStatus.approved;
    final catalog = ref.watch(catalogControllerProvider);
    final availability = ref.watch(availabilityControllerProvider);
    final existing = widget.slotId == null
        ? null
        : availability.slotById(widget.slotId!);
    _serviceId ??=
        existing?.serviceId ??
        (catalog.items.isEmpty ? null : catalog.items.first.id);
    _start ??= existing?.startAt.toLocal();
    _end ??= existing?.endAt.toLocal();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.slotId == null ? 'Add Availability' : 'Edit Availability',
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: !approved
              ? const Text('Approval required')
              : ListView(
                  children: [
                    DropdownButtonFormField<String>(
                      key: const Key('availability-service'),
                      initialValue: _serviceId,
                      items: [
                        for (final service in catalog.items)
                          DropdownMenuItem(
                            value: service.id,
                            child: Text(service.name),
                          ),
                      ],
                      onChanged: (value) => setState(() => _serviceId = value),
                      decoration: const InputDecoration(labelText: 'Service'),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('Start date'),
                      subtitle: Text(_label(_start)),
                      onTap: () => _pick(isStart: true),
                    ),
                    ListTile(
                      title: const Text('Start time'),
                      subtitle: Text(_timeLabel(_start)),
                      onTap: () => _pick(isStart: true, timeOnly: true),
                    ),
                    ListTile(
                      title: const Text('End date'),
                      subtitle: Text(_label(_end)),
                      onTap: () => _pick(isStart: false),
                    ),
                    ListTile(
                      title: const Text('End time'),
                      subtitle: Text(_timeLabel(_end)),
                      onTap: () => _pick(isStart: false, timeOnly: true),
                    ),
                    if (availability.errorMessage != null)
                      Text(availability.errorMessage!),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: availability.saving ? null : _submit,
                      child: availability.saving
                          ? const Text('Saving...')
                          : const Text('Save'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  String _label(DateTime? value) {
    if (value == null) {
      return 'Select date';
    }
    return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }

  String _timeLabel(DateTime? value) {
    if (value == null) {
      return 'Select time';
    }
    return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _pick({required bool isStart, bool timeOnly = false}) async {
    final current = (isStart ? _start : _end) ?? DateTime.now();
    if (!timeOnly) {
      final date = await showDatePicker(
        context: context,
        initialDate: current,
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 400)),
      );
      if (date == null) {
        return;
      }
      setState(() {
        final merged = DateTime(
          date.year,
          date.month,
          date.day,
          current.hour,
          current.minute,
        );
        if (isStart) {
          _start = merged;
        } else {
          _end = merged;
        }
      });
      return;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null) {
      return;
    }
    setState(() {
      final merged = DateTime(
        current.year,
        current.month,
        current.day,
        time.hour,
        time.minute,
      );
      if (isStart) {
        _start = merged;
      } else {
        _end = merged;
      }
    });
  }

  Future<void> _submit() async {
    final serviceId = _serviceId;
    final start = _start;
    final end = _end;
    if (serviceId == null || start == null || end == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service, start, and end are required.')),
      );
      return;
    }
    final notifier = ref.read(availabilityControllerProvider.notifier);
    final ok = widget.slotId == null
        ? await notifier.create(
            serviceId: serviceId,
            startAt: AvailabilitySlot.toApiTimestamp(start),
            endAt: AvailabilitySlot.toApiTimestamp(end),
          )
        : await notifier.update(
            slotId: widget.slotId!,
            serviceId: serviceId,
            startAt: AvailabilitySlot.toApiTimestamp(start),
            endAt: AvailabilitySlot.toApiTimestamp(end),
          );
    if (ok && mounted) {
      Navigator.of(context).pop();
    }
  }
}
