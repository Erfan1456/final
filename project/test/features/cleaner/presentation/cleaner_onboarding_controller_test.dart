import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_cleaning_marketplace/core/network/api_failure.dart';
import 'package:home_cleaning_marketplace/features/cleaner/data/cleaner_profile.dart';
import 'package:home_cleaning_marketplace/features/cleaner/data/cleaner_profile_api.dart';
import 'package:home_cleaning_marketplace/features/cleaner/presentation/cleaner_onboarding_controller.dart';

import '../../../helpers/feature_test_fakes.dart';

class _FakeCleanerApi extends CleanerProfileApi {
  _FakeCleanerApi() : super(Dio());

  CleanerProfile? nextProfile;
  ApiFailure? nextError;
  int saveCalls = 0;
  int submitCalls = 0;

  void _throwIfNeeded() {
    final error = nextError;
    if (error != null) {
      throw error;
    }
  }

  @override
  Future<CleanerProfile?> getProfile() async {
    _throwIfNeeded();
    return nextProfile;
  }

  @override
  Future<CleanerProfile> saveProfile(Map<String, Object?> body) async {
    saveCalls += 1;
    _throwIfNeeded();
    nextProfile = CleanerProfile.fromJson(cleanerProfileJson());
    return nextProfile!;
  }

  @override
  Future<CleanerProfile> submit() async {
    submitCalls += 1;
    _throwIfNeeded();
    nextProfile = CleanerProfile.fromJson(
      cleanerProfileJson(
        status: 'pending',
        submittedAt: '2026-08-25T12:30:00.000Z',
      ),
    );
    return nextProfile!;
  }
}

void main() {
  late _FakeCleanerApi api;
  late ProviderContainer container;

  setUp(() {
    api = _FakeCleanerApi();
    container = ProviderContainer(
      overrides: [cleanerProfileApiProvider.overrideWithValue(api)],
    );
  });

  tearDown(() => container.dispose());

  Future<CleanerOnboardingState> settle() async {
    container.listen(cleanerOnboardingControllerProvider, (_, _) {});
    await pumpEventQueue();
    return container.read(cleanerOnboardingControllerProvider);
  }

  test('load null profile', () async {
    api.nextProfile = null;
    final state = await settle();
    expect(state.hasProfile, isFalse);
  });

  test('load draft profile', () async {
    api.nextProfile = CleanerProfile.fromJson(cleanerProfileJson());
    final state = await settle();
    expect(state.status, OnboardingStatus.draft);
  });

  test('load pending, approved, and rejected', () async {
    api.nextProfile = CleanerProfile.fromJson(
      cleanerProfileJson(status: 'pending'),
    );
    expect((await settle()).status, OnboardingStatus.pending);

    api.nextProfile = CleanerProfile.fromJson(
      cleanerProfileJson(status: 'approved'),
    );
    await container.read(cleanerOnboardingControllerProvider.notifier).load();
    expect(
      container.read(cleanerOnboardingControllerProvider).status,
      OnboardingStatus.approved,
    );

    api.nextProfile = CleanerProfile.fromJson(
      cleanerProfileJson(
        status: 'rejected',
        rejectionReason: 'Please expand the bio.',
      ),
    );
    await container.read(cleanerOnboardingControllerProvider.notifier).load();
    expect(
      container
          .read(cleanerOnboardingControllerProvider)
          .profile
          ?.rejectionReason,
      equals('Please expand the bio.'),
    );
  });

  test('save and submit succeed', () async {
    api.nextProfile = CleanerProfile.fromJson(cleanerProfileJson());
    await settle();
    final notifier = container.read(
      cleanerOnboardingControllerProvider.notifier,
    );
    expect(
      await notifier.save(<String, Object?>{'full_name': 'Test Cleaner'}),
      isTrue,
    );
    expect(api.saveCalls, equals(1));
    expect(await notifier.submit(), isTrue);
    expect(api.submitCalls, equals(1));
    expect(
      container.read(cleanerOnboardingControllerProvider).status,
      OnboardingStatus.pending,
    );
  });

  test('safe error stays user-readable', () async {
    api.nextError = ApiFailure(
      code: 'cleaner_profile_locked',
      message: messageForApiCode('cleaner_profile_locked'),
    );
    final state = await settle();
    expect(state.errorMessage, contains('cannot be edited'));
  });
}
