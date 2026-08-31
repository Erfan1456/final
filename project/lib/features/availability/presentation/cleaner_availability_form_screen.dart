import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/features/availability/data/availability_slot.dart';
import 'package:home_cleaning_marketplace/features/availability/data/availability_window.dart';
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
  String? _localError;

  @override
  void initState() {
    super.initState();
    if (widget.slotId == null) {
      final start = AvailabilityWindow.nextValidStart();
      _start = start;
      _end = AvailabilityWindow.defaultEnd(start);
    }
  }

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
    final errorText = _localError ?? availability.errorMessage;

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
                    Text(
                      'Windows must start in the future, last 60 minutes to 8 '
                      'hours, and use 30-minute steps (for example 10:00–12:00).',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
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
                    if (errorText != null) Text(errorText),
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
        final merged = AvailabilityWindow.alignToIncrement(
          DateTime(
            date.year,
            date.month,
            date.day,
            current.hour,
            current.minute,
          ),
        );
        if (isStart) {
          _start = merged;
          if (_end == null || !_start!.isBefore(_end!)) {
            _end = AvailabilityWindow.defaultEnd(_start!);
          }
        } else {
          _end = merged;
        }
        _localError = null;
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
      final merged = AvailabilityWindow.alignToIncrement(
        DateTime(
          current.year,
          current.month,
          current.day,
          time.hour,
          time.minute,
        ),
      );
      if (isStart) {
        _start = merged;
        if (_end == null || !_start!.isBefore(_end!)) {
          _end = AvailabilityWindow.defaultEnd(_start!);
        }
      } else {
        _end = merged;
      }
      _localError = null;
    });
  }

  Future<void> _submit() async {
    final serviceId = _serviceId;
    final start = _start;
    final end = _end;
    if (serviceId == null || start == null || end == null) {
      setState(() {
        _localError = 'Service, start, and end are required.';
      });
      return;
    }
    final alignedStart = AvailabilityWindow.alignToIncrement(start);
    final alignedEnd = AvailabilityWindow.alignToIncrement(end);
    final invalid = AvailabilityWindow.validate(
      start: alignedStart,
      end: alignedEnd,
    );
    if (invalid != null) {
      setState(() {
        _start = alignedStart;
        _end = alignedEnd;
        _localError = invalid;
      });
      return;
    }
    final notifier = ref.read(availabilityControllerProvider.notifier);
    final ok = widget.slotId == null
        ? await notifier.create(
            serviceId: serviceId,
            startAt: AvailabilitySlot.toApiTimestamp(alignedStart),
            endAt: AvailabilitySlot.toApiTimestamp(alignedEnd),
          )
        : await notifier.update(
            slotId: widget.slotId!,
            serviceId: serviceId,
            startAt: AvailabilitySlot.toApiTimestamp(alignedStart),
            endAt: AvailabilitySlot.toApiTimestamp(alignedEnd),
          );
    if (ok && mounted) {
      Navigator.of(context).pop();
    }
  }
}
