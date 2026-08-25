import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_cleaning_marketplace/core/network/api_failure.dart';
import 'package:home_cleaning_marketplace/features/addresses/presentation/address_controller.dart';
import 'package:home_cleaning_marketplace/features/addresses/presentation/address_form_screen.dart';
import 'package:home_cleaning_marketplace/features/addresses/presentation/address_list_screen.dart';

import '../../../helpers/feature_test_fakes.dart';

void main() {
  testWidgets('AddressList shows default indicator and actions', (
    tester,
  ) async {
    final controller = SeededAddressController(
      AddressListState(
        loading: false,
        addresses: [testAddress(isDefault: true)],
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [addressControllerProvider.overrideWith(() => controller)],
        child: const MaterialApp(home: AddressListScreen()),
      ),
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('1 Test Street'), findsOneWidget);
    expect(find.text('Dhaka, Dhaka BD'), findsOneWidget);
    expect(find.text('Default'), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Set Default'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
  });

  testWidgets('AddressList confirms delete', (tester) async {
    final controller = SeededAddressController(
      AddressListState(loading: false, addresses: [testAddress()]),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [addressControllerProvider.overrideWith(() => controller)],
        child: const MaterialApp(home: AddressListScreen()),
      ),
    );

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete address?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Delete').last);
    await tester.pumpAndSettle();
    expect(controller.deleteCalls, equals(1));
  });

  testWidgets('AddressList set default is invoked', (tester) async {
    final controller = SeededAddressController(
      AddressListState(loading: false, addresses: [testAddress()]),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [addressControllerProvider.overrideWith(() => controller)],
        child: const MaterialApp(home: AddressListScreen()),
      ),
    );
    await tester.tap(find.text('Set Default'));
    await tester.pump();
    expect(controller.defaultCalls, equals(1));
  });

  testWidgets('AddressList shows address limit error', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          addressControllerProvider.overrideWith(
            () => SeededAddressController(
              AddressListState(
                loading: false,
                errorMessage: messageForApiCode('address_limit_reached'),
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: AddressListScreen()),
      ),
    );
    expect(find.text('You can save at most 20 addresses.'), findsOneWidget);
  });

  testWidgets('AddressForm validates country code', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          addressControllerProvider.overrideWith(
            () =>
                SeededAddressController(const AddressListState(loading: false)),
          ),
        ],
        child: const MaterialApp(home: AddressFormScreen()),
      ),
    );
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.textContaining('2-letter country code'), findsOneWidget);
  });

  testWidgets('AddressForm creates an address', (tester) async {
    final controller = SeededAddressController(
      const AddressListState(loading: false),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [addressControllerProvider.overrideWith(() => controller)],
        child: const MaterialApp(home: AddressFormScreen()),
      ),
    );

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Office');
    await tester.enterText(fields.at(1), '2 Test Street');
    await tester.enterText(fields.at(3), 'Dhaka');
    await tester.enterText(fields.at(4), 'Dhaka');
    await tester.enterText(fields.at(5), '1206');
    await tester.enterText(fields.at(6), 'bd');
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(controller.createCalls, equals(1));
  });

  testWidgets('AddressForm edit loads existing values', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          addressControllerProvider.overrideWith(
            () => SeededAddressController(
              AddressListState(loading: false, addresses: [testAddress()]),
            ),
          ),
        ],
        child: MaterialApp(
          home: AddressFormScreen(addressId: testAddress().id),
        ),
      ),
    );
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('1 Test Street'), findsOneWidget);
    expect(find.text('BD'), findsOneWidget);
  });
}
