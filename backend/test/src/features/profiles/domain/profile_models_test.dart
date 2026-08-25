import 'package:home_cleaning_marketplace_api/src/features/addresses/domain/address.dart';
import 'package:home_cleaning_marketplace_api/src/features/addresses/domain/address_validation.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/domain/cleaner_onboarding_status.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/domain/cleaner_profile.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/domain/cleaner_profile_validation.dart';
import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/domain/customer_profile.dart';
import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/domain/profile_field_validation.dart';
import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/domain/profile_validation_exception.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;
import 'package:test/test.dart';

void main() {
  final userId = ObjectId.fromHexString('507f1f77bcf86cd799439011');
  final profileId = ObjectId.fromHexString('507f1f77bcf86cd799439021');
  final addressId = ObjectId.fromHexString('507f1f77bcf86cd799439031');
  final created = DateTime.utc(2026, 8, 25, 12);

  group('CustomerProfile', () {
    test('round-trips BSON and public JSON', () {
      final profile = CustomerProfile(
        id: profileId,
        userId: userId,
        fullName: 'Test Customer',
        phoneE164: '+15555550100',
        defaultAddressId: addressId,
        createdAt: created,
        updatedAt: created,
      );
      final copy = CustomerProfile.fromDocument(profile.toDocument());
      expect(copy.fullName, equals('Test Customer'));
      expect(copy.phoneE164, equals('+15555550100'));
      final json = copy.toPublicJson();
      expect(json['id'], equals(profileId.oid));
      expect(json['user_id'], equals(userId.oid));
      expect(json.containsKey('password_hash'), isFalse);
      expect(profile.toString(), isNot(contains('password')));
    });
  });

  group('Address', () {
    test('round-trips BSON and computed is_default JSON', () {
      final address = Address(
        id: addressId,
        userId: userId,
        label: 'Home',
        line1: '1 Test Street',
        city: 'Dhaka',
        region: 'Dhaka',
        postalCode: '1205',
        countryCode: 'BD',
        createdAt: created,
        updatedAt: created,
      );
      final copy = Address.fromDocument(address.toDocument());
      expect(copy.toDocument().containsKey('is_default'), isFalse);
      expect(copy.toPublicJson(isDefault: true)['is_default'], isTrue);
      expect(copy.toPublicJson(isDefault: false)['is_default'], isFalse);
    });

    test('normalizes country codes to uppercase', () {
      expect(AddressValidation.requireCountryCode('bd'), equals('BD'));
      expect(AddressValidation.requireCountryCode('Us'), equals('US'));
      expect(
        () => AddressValidation.requireCountryCode('BGD'),
        throwsA(isA<ProfileValidationException>()),
      );
    });
  });

  group('CleanerProfile and CleanerOnboardingStatus', () {
    test('wire values are lowercase and fromWire rejects unknowns', () {
      expect(CleanerOnboardingStatus.draft.wireValue, equals('draft'));
      expect(CleanerOnboardingStatus.pending.wireValue, equals('pending'));
      expect(CleanerOnboardingStatus.approved.wireValue, equals('approved'));
      expect(CleanerOnboardingStatus.rejected.wireValue, equals('rejected'));
      expect(CleanerOnboardingStatus.draft.isEditable, isTrue);
      expect(CleanerOnboardingStatus.rejected.isEditable, isTrue);
      expect(CleanerOnboardingStatus.pending.isEditable, isFalse);
      expect(CleanerOnboardingStatus.approved.isEditable, isFalse);
      expect(
        () => CleanerOnboardingStatus.fromWire('PENDING'),
        throwsA(isA<FormatException>()),
      );
    });

    test('round-trips BSON without security fields', () {
      final profile = CleanerProfile(
        id: profileId,
        userId: userId,
        fullName: 'Test Cleaner',
        bio: 'Experienced residential cleaner for apartments.',
        yearsExperience: 3,
        serviceArea: 'Dhaka North',
        onboardingStatus: CleanerOnboardingStatus.draft,
        createdAt: created,
        updatedAt: created,
      );
      final copy = CleanerProfile.fromDocument(profile.toDocument());
      final json = copy.toPublicJson();
      expect(json['onboarding_status'], equals('draft'));
      expect(json.containsKey('password_hash'), isFalse);
      expect(profile.toString(), contains('draft'));
    });
  });

  group('ProfileFieldValidation', () {
    test('trims full name and rejects short or control values', () {
      expect(ProfileFieldValidation.requireFullName('  Ada  '), equals('Ada'));
      expect(
        () => ProfileFieldValidation.requireFullName('A'),
        throwsA(isA<ProfileValidationException>()),
      );
      expect(
        () => ProfileFieldValidation.requireFullName('A\nB'),
        throwsA(isA<ProfileValidationException>()),
      );
    });

    test('phone empty becomes null and E.164 is required when present', () {
      expect(ProfileFieldValidation.optionalPhoneE164('  '), isNull);
      expect(ProfileFieldValidation.optionalPhoneE164(null), isNull);
      expect(
        ProfileFieldValidation.optionalPhoneE164('+15555550100'),
        equals('+15555550100'),
      );
      expect(
        () => ProfileFieldValidation.optionalPhoneE164('15555550100'),
        throwsA(isA<ProfileValidationException>()),
      );
    });
  });

  group('CleanerProfileValidation', () {
    test('rejects string and double years_experience', () {
      expect(CleanerProfileValidation.requireYearsExperience(0), equals(0));
      expect(CleanerProfileValidation.requireYearsExperience(50), equals(50));
      expect(
        () => CleanerProfileValidation.requireYearsExperience(3.0),
        throwsA(isA<ProfileValidationException>()),
      );
      expect(
        () => CleanerProfileValidation.requireYearsExperience('3'),
        throwsA(isA<ProfileValidationException>()),
      );
      expect(
        () => CleanerProfileValidation.requireYearsExperience(-1),
        throwsA(isA<ProfileValidationException>()),
      );
    });

    test('requires bio and service area length bounds', () {
      expect(
        () => CleanerProfileValidation.requireBio('too short'),
        throwsA(isA<ProfileValidationException>()),
      );
      expect(
        CleanerProfileValidation.requireServiceArea('  Dhaka  '),
        equals('Dhaka'),
      );
    });
  });
}
