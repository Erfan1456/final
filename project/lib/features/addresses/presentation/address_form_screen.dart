import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/features/addresses/data/address.dart';
import 'package:home_cleaning_marketplace/features/addresses/presentation/address_controller.dart';

/// Create or edit a service address.
class AddressFormScreen extends ConsumerStatefulWidget {
  const AddressFormScreen({super.key, this.addressId});

  final String? addressId;

  @override
  ConsumerState<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends ConsumerState<AddressFormScreen> {
  final _label = TextEditingController();
  final _line1 = TextEditingController();
  final _line2 = TextEditingController();
  final _city = TextEditingController();
  final _region = TextEditingController();
  final _postal = TextEditingController();
  final _country = TextEditingController();
  String? _localError;
  bool _filled = false;

  @override
  void dispose() {
    _label.dispose();
    _line1.dispose();
    _line2.dispose();
    _city.dispose();
    _region.dispose();
    _postal.dispose();
    _country.dispose();
    super.dispose();
  }

  void _fill(Address address) {
    if (_filled) {
      return;
    }
    _filled = true;
    _label.text = address.label;
    _line1.text = address.line1;
    _line2.text = address.line2 ?? '';
    _city.text = address.city;
    _region.text = address.region;
    _postal.text = address.postalCode;
    _country.text = address.countryCode;
  }

  Future<void> _save() async {
    final country = _country.text.trim().toUpperCase();
    if (_label.text.trim().isEmpty ||
        _line1.text.trim().isEmpty ||
        _city.text.trim().isEmpty ||
        _region.text.trim().isEmpty ||
        _postal.text.trim().isEmpty ||
        !RegExp(r'^[A-Z]{2}$').hasMatch(country)) {
      setState(
        () => _localError =
            'Please complete the address, including a 2-letter country code.',
      );
      return;
    }
    setState(() => _localError = null);
    _country.text = country;
    final notifier = ref.read(addressControllerProvider.notifier);
    final ok = widget.addressId == null
        ? await notifier.create(
            label: _label.text,
            line1: _line1.text,
            line2: _line2.text,
            city: _city.text,
            region: _region.text,
            postalCode: _postal.text,
            countryCode: country,
          )
        : await notifier.update(
            id: widget.addressId!,
            label: _label.text,
            line1: _line1.text,
            line2: _line2.text,
            city: _city.text,
            region: _region.text,
            postalCode: _postal.text,
            countryCode: country,
          );
    if (ok && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addressControllerProvider);
    final existing = widget.addressId == null
        ? null
        : state.addresses
              .where((item) => item.id == widget.addressId)
              .firstOrNull;
    if (existing != null) {
      _fill(existing);
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.addressId == null ? 'Add address' : 'Edit address'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextField(
              controller: _label,
              decoration: const InputDecoration(labelText: 'Label'),
            ),
            TextField(
              controller: _line1,
              decoration: const InputDecoration(labelText: 'Address line 1'),
            ),
            TextField(
              controller: _line2,
              decoration: const InputDecoration(
                labelText: 'Address line 2 (optional)',
              ),
            ),
            TextField(
              controller: _city,
              decoration: const InputDecoration(labelText: 'City'),
            ),
            TextField(
              controller: _region,
              decoration: const InputDecoration(labelText: 'Region'),
            ),
            TextField(
              controller: _postal,
              decoration: const InputDecoration(labelText: 'Postal code'),
            ),
            TextField(
              controller: _country,
              decoration: const InputDecoration(labelText: 'Country code'),
              textCapitalization: TextCapitalization.characters,
              onChanged: (value) {
                final upper = value.toUpperCase();
                if (upper != value) {
                  _country.value = TextEditingValue(
                    text: upper,
                    selection: TextSelection.collapsed(offset: upper.length),
                  );
                }
              },
            ),
            if (_localError != null || state.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(_localError ?? state.errorMessage!),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: state.saving ? null : _save,
              child: Text(state.saving ? 'Saving...' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}
