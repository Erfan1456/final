import 'package:flutter_test/flutter_test.dart';
import 'package:home_cleaning_marketplace/features/availability/data/availability_slot.dart';
import 'package:home_cleaning_marketplace/features/catalog/data/marketplace_service.dart';
import 'package:home_cleaning_marketplace/features/cleaner_services/data/cleaner_service_offering.dart';
import 'package:home_cleaning_marketplace/features/discovery/data/cleaner_discovery_models.dart';

void main() {
  test('catalog parse and unknown billing do not crash', () {
    final service = MarketplaceService.fromJson(<String, dynamic>{
      'id': 's1',
      'slug': 'home-cleaning',
      'name': 'Home Cleaning',
      'description': 'Hourly professional cleaning.',
      'billing_model': 'hourly',
    });
    expect(service.billingModel, BillingModel.hourly);
    expect(
      MarketplaceService.fromJson(<String, dynamic>{
        'id': 's1',
        'slug': 'home-cleaning',
        'name': 'Home Cleaning',
        'description': 'Hourly professional cleaning.',
        'billing_model': 'mystery',
      }).billingModel,
      BillingModel.unknown,
    );
    expect(
      formatMinorHourlyRate(250000, 'BDT'),
      equals('BDT 250000 minor units / hour'),
    );
  });

  test('offering parse rejects a double rate', () {
    expect(
      () => CleanerServiceOffering.fromJson(<String, dynamic>{
        'id': 'o1',
        'service': <String, dynamic>{
          'id': 's1',
          'slug': 'home-cleaning',
          'name': 'Home Cleaning',
          'description': 'desc',
          'billing_model': 'hourly',
        },
        'hourly_rate_minor': 250000.5,
        'currency_code': 'BDT',
        'is_active': true,
        'created_at': '2026-08-25T12:00:00.000Z',
        'updated_at': '2026-08-25T12:00:00.000Z',
      }),
      throwsA(isA<FormatException>()),
    );
  });

  test('discovery list parse keeps privacy shape', () {
    final page = CleanerDiscoveryPage.fromJson(<String, dynamic>{
      'items': [
        <String, dynamic>{
          'cleaner_user_id': 'c1',
          'full_name': 'Ada Cleaner',
          'bio_excerpt': 'Reliable cleaner.',
          'years_experience': 4,
          'service_area': 'Dhaka',
          'service': <String, dynamic>{
            'id': 's1',
            'slug': 'home-cleaning',
            'name': 'Home Cleaning',
          },
          'hourly_rate_minor': 250000,
          'currency_code': 'BDT',
          'next_available_at': '2026-09-01T03:00:00.000Z',
        },
      ],
      'next_cursor': 'cursor-1',
    });
    expect(page.nextCursor, equals('cursor-1'));
    expect(page.items.single.fullName, equals('Ada Cleaner'));
    expect(page.items.single.toString(), isNot(contains('phone')));
  });

  test('availability timestamps normalize to UTC', () {
    final slot = AvailabilitySlot.fromJson(<String, dynamic>{
      'id': 'slot-1',
      'service_id': 's1',
      'start_at': '2026-09-01T09:00:00+06:00',
      'end_at': '2026-09-01T11:00:00+06:00',
    });
    expect(slot.startAt.isUtc, isTrue);
    expect(slot.startAt, DateTime.utc(2026, 9, 1, 3));
    expect(AvailabilitySlot.toApiTimestamp(slot.startAt), contains('Z'));
  });
}
