import 'package:flutter_test/flutter_test.dart';
import 'package:home_cleaning_marketplace/features/addresses/data/address.dart';
import 'package:home_cleaning_marketplace/features/admin/data/admin_cleaner_models.dart';
import 'package:home_cleaning_marketplace/features/cleaner/data/cleaner_profile.dart';
import 'package:home_cleaning_marketplace/features/customer/data/customer_profile.dart';

import '../../../helpers/feature_test_fakes.dart';

void main() {
  group('CustomerProfile', () {
    test('parses a safe profile and keeps UTC dates', () {
      final profile = CustomerProfile.fromJson(customerProfileJson());
      expect(profile.fullName, equals('Test Customer'));
      expect(profile.phoneE164, equals('+15555550100'));
      expect(profile.createdAt.isUtc, isTrue);
      expect(profile.toString(), isNot(contains('+15555550100')));
    });

    test('treats missing phone as null', () {
      final profile = CustomerProfile.fromJson(
        customerProfileJson(phoneE164: null),
      );
      expect(profile.phoneE164, isNull);
    });
  });

  group('Address', () {
    test('parses computed is_default without Mongo internals', () {
      final address = Address.fromJson(addressJson(isDefault: true));
      expect(address.isDefault, isTrue);
      expect(address.countryCode, equals('BD'));
      expect(
        address.toString(),
        equals('Address(id: ${address.id}, label: Home)'),
      );
    });
  });

  group('OnboardingStatus', () {
    test('parses known lowercase wire values', () {
      expect(OnboardingStatus.fromWire('draft'), OnboardingStatus.draft);
      expect(OnboardingStatus.fromWire('pending'), OnboardingStatus.pending);
      expect(OnboardingStatus.fromWire('approved'), OnboardingStatus.approved);
      expect(OnboardingStatus.fromWire('rejected'), OnboardingStatus.rejected);
    });

    test('unknown server values become unknown without crashing', () {
      expect(OnboardingStatus.fromWire('suspended'), OnboardingStatus.unknown);
      expect(OnboardingStatus.fromWire('PENDING'), OnboardingStatus.unknown);
    });
  });

  group('CleanerProfile', () {
    test('parses a draft profile', () {
      final profile = CleanerProfile.fromJson(cleanerProfileJson());
      expect(profile.onboardingStatus, OnboardingStatus.draft);
      expect(profile.yearsExperience, equals(3));
    });

    test('preserves rejection metadata', () {
      final profile = CleanerProfile.fromJson(
        cleanerProfileJson(
          status: 'rejected',
          rejectionReason: 'Please add more service-area detail.',
          reviewedBy: '507f1f77bcf86cd799439099',
        ),
      );
      expect(profile.onboardingStatus, OnboardingStatus.rejected);
      expect(profile.rejectionReason, contains('service-area'));
      expect(profile.reviewedBy, equals('507f1f77bcf86cd799439099'));
    });
  });

  group('Admin models', () {
    test('parses a list page and next_cursor', () {
      final page = AdminCleanerApplicationPage.fromJson(<String, dynamic>{
        'items': <dynamic>[adminSummaryJson()],
        'next_cursor': '507f1f77bcf86cd799439042',
      });
      expect(page.items, hasLength(1));
      expect(page.items.first.email, equals('pending.cleaner@example.com'));
      expect(page.nextCursor, equals('507f1f77bcf86cd799439042'));
    });

    test('parses detail from user + profile', () {
      final detail = AdminCleanerApplicationDetail.fromJson(<String, dynamic>{
        'user': <String, dynamic>{
          'id': '507f1f77bcf86cd799439077',
          'email': 'pending.cleaner@example.com',
          'role': 'cleaner',
        },
        'profile': cleanerProfileJson(status: 'pending'),
      });
      expect(detail.email, equals('pending.cleaner@example.com'));
      expect(detail.profile.onboardingStatus, OnboardingStatus.pending);
    });
  });
}
