import 'package:home_cleaning_marketplace_api/src/features/authorization/approved_cleaner_policy.dart';
import 'package:home_cleaning_marketplace_api/src/features/availability/data/availability_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/availability/domain/availability_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/availability/domain/availability_slot.dart';
import 'package:home_cleaning_marketplace_api/src/features/availability/domain/availability_validation.dart';
import 'package:home_cleaning_marketplace_api/src/features/bookings/data/booking_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/data/cleaner_profile_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_profiles/domain/cleaner_profile.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_services/data/cleaner_service_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_services/domain/cleaner_service_exceptions.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_services/domain/cleaner_service_offering.dart';
import 'package:home_cleaning_marketplace_api/src/features/cleaner_services/domain/cleaner_service_validation.dart';
import 'package:home_cleaning_marketplace_api/src/features/customer_profiles/domain/profile_validation_exception.dart';
import 'package:home_cleaning_marketplace_api/src/features/discovery/domain/cleaner_discovery_models.dart';
import 'package:home_cleaning_marketplace_api/src/features/reviews/data/review_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/reviews/domain/review.dart';
import 'package:home_cleaning_marketplace_api/src/features/reviews/domain/review_validation.dart';
import 'package:home_cleaning_marketplace_api/src/features/services/application/canonical_service_catalog.dart';
import 'package:home_cleaning_marketplace_api/src/features/services/data/service_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/services/domain/marketplace_service.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/data/user_repository.dart';
import 'package:home_cleaning_marketplace_api/src/features/users/domain/user_account.dart';
import 'package:home_cleaning_marketplace_api/src/http/api_date_time.dart';
import 'package:mongo_dart/mongo_dart.dart' hide ServerConfig;

/// HTTP-independent customer discovery. Uses bounded batch queries, not N+1.
class CleanerDiscoveryService {
  /// Creates a discovery service.
  CleanerDiscoveryService({
    required ServiceRepository services,
    required CleanerServiceRepository offerings,
    required CleanerProfileRepository profiles,
    required UserRepository users,
    required AvailabilityRepository slots,
    required BookingRepository bookings,
    ReviewRepository? reviews,
    DateTime Function()? clock,
  }) : _services = services,
       _offerings = offerings,
       _profiles = profiles,
       _users = users,
       _slots = slots,
       _bookings = bookings,
       _reviews = reviews,
       _clock = clock ?? DateTime.now;

  /// Default page size.
  static const int defaultLimit = 20;

  /// Minimum page size.
  static const int minLimit = 1;

  /// Maximum page size.
  static const int maxLimit = 50;
  static const int _maxFillBatches = 10;

  final ServiceRepository _services;
  final CleanerServiceRepository _offerings;
  final CleanerProfileRepository _profiles;
  final UserRepository _users;
  final AvailabilityRepository _slots;
  final BookingRepository _bookings;
  final ReviewRepository? _reviews;
  final DateTime Function() _clock;

  /// Lists discoverable cleaners using the supplied query values.
  Future<CleanerDiscoveryPage> listCleaners({
    Object? serviceSlug,
    Object? currency,
    Object? maxRateMinor,
    Object? minExperience,
    Object? availableFrom,
    Object? availableTo,
    Object? limitRaw,
    Object? after,
  }) async {
    final service = await _activeServiceBySlug(
      serviceSlug is String && serviceSlug.trim().isNotEmpty
          ? serviceSlug
          : CanonicalHomeCleaningService.slug,
    );
    if (service == null) {
      return const CleanerDiscoveryPage(items: [], nextCursor: null);
    }
    final limit = _requireLimit(limitRaw);
    final currencyCode = _optionalCurrency(currency);
    final maxRate = _optionalMaxRate(maxRateMinor);
    final minYears = _optionalMinExperience(minExperience);
    final window = _optionalDiscoveryWindow(
      availableFrom: availableFrom,
      availableTo: availableTo,
    );
    final now = _clock().toUtc();
    var cursor = _optionalObjectId(after);
    final accumulated = <CleanerDiscoverySummary>[];
    var sourceHasMore = true;
    var batches = 0;

    while (accumulated.length <= limit &&
        sourceHasMore &&
        batches < _maxFillBatches) {
      batches += 1;
      final page = await _offerings.discoveryPage(
        serviceId: service.id,
        limit: limit,
        currencyCode: currencyCode,
        maxRateMinor: maxRate,
        after: cursor,
      );
      if (page.items.isEmpty) {
        sourceHasMore = false;
        break;
      }
      sourceHasMore = page.hasMore;
      cursor = page.items.last.id;
      accumulated.addAll(
        await _eligibleSummaries(
          offerings: page.items,
          service: service,
          minYears: minYears,
          window: window,
          now: now,
        ),
      );
    }

    final hasMore = accumulated.length > limit;
    final items = hasMore ? accumulated.sublist(0, limit) : accumulated;
    return CleanerDiscoveryPage(
      items: items,
      nextCursor: hasMore ? items.last.offeringId : null,
    );
  }

  /// Returns customer-safe detail or [CleanerNotFoundException].
  Future<CleanerDiscoveryDetail> getCleanerDetail({
    required ObjectId cleanerUserId,
    Object? serviceSlug,
  }) async {
    final service = await _activeServiceBySlug(
      serviceSlug is String && serviceSlug.trim().isNotEmpty
          ? serviceSlug
          : CanonicalHomeCleaningService.slug,
    );
    if (service == null) {
      throw const CleanerNotFoundException();
    }
    final offering = await _offerings.findActiveOffering(
      cleanerUserId: cleanerUserId,
      serviceId: service.id,
    );
    if (offering == null) {
      throw const CleanerNotFoundException();
    }
    final users = await _users.findByIds([cleanerUserId]);
    final profiles = await _profiles.findByUserIds([cleanerUserId]);
    if (users.length != 1 || profiles.length != 1) {
      throw const CleanerNotFoundException();
    }
    final user = users.single;
    final profile = profiles.single;
    if (!ApprovedCleanerPolicy.isDiscoverable(user: user, profile: profile)) {
      throw const CleanerNotFoundException();
    }
    final now = _clock().toUtc();
    final slots = await _unreserved(
      await _slots.listFutureForCleanerAndService(
        cleanerUserId: cleanerUserId,
        serviceId: service.id,
        from: now,
        to: now.add(AvailabilityValidation.defaultDetailHorizon),
        limit: AvailabilityValidation.maxDetailSlots,
      ),
    );
    final reviews = _reviews;
    CleanerReviewAggregate? aggregate;
    var publicReviews = const <Map<String, Object?>>[];
    if (reviews != null) {
      final aggregates = await reviews.aggregateForCleanerIds([cleanerUserId]);
      aggregate = aggregates[cleanerUserId];
      publicReviews = [
        for (final review in await reviews.latestPublishedForCleaner(
          cleanerUserId: cleanerUserId,
          limit: ReviewValidation.publicDetailLimit,
        ))
          review.toPublicJson(),
      ];
    }
    return CleanerDiscoveryDetail(
      cleanerUserId: cleanerUserId.oid,
      fullName: profile.fullName,
      bio: profile.bio,
      yearsExperience: profile.yearsExperience,
      serviceArea: profile.serviceArea,
      service: service,
      hourlyRateMinor: offering.hourlyRateMinor,
      currencyCode: offering.currencyCode,
      availability: slots,
      ratingAverage: aggregate?.ratingAverage,
      reviewCount: aggregate?.reviewCount ?? 0,
      reviews: publicReviews,
    );
  }

  Future<List<CleanerDiscoverySummary>> _eligibleSummaries({
    required List<CleanerServiceOffering> offerings,
    required MarketplaceService service,
    required int? minYears,
    required ({DateTime from, DateTime to})? window,
    required DateTime now,
  }) async {
    if (offerings.isEmpty) {
      return const <CleanerDiscoverySummary>[];
    }
    final cleanerIds = [
      for (final offering in offerings) offering.cleanerUserId,
    ];
    final users = await _users.findByIds(cleanerIds);
    final profiles = await _profiles.findByUserIds(cleanerIds);
    final usersById = <String, UserAccount>{
      for (final user in users) user.id.oid: user,
    };
    final profilesByUserId = <String, CleanerProfile>{
      for (final profile in profiles) profile.userId.oid: profile,
    };

    var remaining = <CleanerServiceOffering>[];
    for (final offering in offerings) {
      final user = usersById[offering.cleanerUserId.oid];
      final profile = profilesByUserId[offering.cleanerUserId.oid];
      if (user == null || profile == null) {
        continue;
      }
      if (!ApprovedCleanerPolicy.isDiscoverable(user: user, profile: profile)) {
        continue;
      }
      if (minYears != null && profile.yearsExperience < minYears) {
        continue;
      }
      remaining.add(offering);
    }

    final remainingIds = [
      for (final offering in remaining) offering.cleanerUserId,
    ];
    if (window != null) {
      final overlapping = await _unreserved(
        await _slots.listOverlappingForCleaners(
          cleanerUserIds: remainingIds,
          serviceId: service.id,
          from: window.from,
          to: window.to,
        ),
      );
      final overlappingIds = {
        for (final slot in overlapping)
          if (slot.startAt.isAfter(now)) slot.cleanerUserId.oid,
      };
      remaining = [
        for (final offering in remaining)
          if (overlappingIds.contains(offering.cleanerUserId.oid)) offering,
      ];
    }

    final nextByCleaner = <String, DateTime>{};
    final nextSlots = await _unreserved(
      await _slots.listFutureForCleanersAndService(
        cleanerUserIds: [
          for (final offering in remaining) offering.cleanerUserId,
        ],
        serviceId: service.id,
        now: now,
      ),
    );
    for (final slot in nextSlots) {
      nextByCleaner.putIfAbsent(slot.cleanerUserId.oid, () => slot.startAt);
    }

    final aggregates = await _reviewAggregates([
      for (final offering in remaining) offering.cleanerUserId,
    ]);

    return [
      for (final offering in remaining)
        CleanerDiscoverySummary.fromJoined(
          offering: offering,
          service: service,
          fullName: profilesByUserId[offering.cleanerUserId.oid]!.fullName,
          bio: profilesByUserId[offering.cleanerUserId.oid]!.bio,
          yearsExperience:
              profilesByUserId[offering.cleanerUserId.oid]!.yearsExperience,
          serviceArea:
              profilesByUserId[offering.cleanerUserId.oid]!.serviceArea,
          nextAvailableAt: nextByCleaner[offering.cleanerUserId.oid],
          ratingAverage: aggregates[offering.cleanerUserId]?.ratingAverage,
          reviewCount: aggregates[offering.cleanerUserId]?.reviewCount ?? 0,
        ),
    ];
  }

  Future<Map<ObjectId, CleanerReviewAggregate>> _reviewAggregates(
    List<ObjectId> cleanerIds,
  ) async {
    final reviews = _reviews;
    if (reviews == null || cleanerIds.isEmpty) {
      return <ObjectId, CleanerReviewAggregate>{};
    }
    return reviews.aggregateForCleanerIds(cleanerIds);
  }

  /// Batch-excludes slots with an active booking reservation. One query.
  Future<List<AvailabilitySlot>> _unreserved(
    List<AvailabilitySlot> slots,
  ) async {
    if (slots.isEmpty) {
      return slots;
    }
    final reserved = await _bookings.findActiveByAvailabilitySlotIds([
      for (final slot in slots) slot.id,
    ]);
    if (reserved.isEmpty) {
      return slots;
    }
    final reservedIds = {
      for (final booking in reserved) booking.availabilitySlotId.oid,
    };
    return [
      for (final slot in slots)
        if (!reservedIds.contains(slot.id.oid)) slot,
    ];
  }

  Future<MarketplaceService?> _activeServiceBySlug(String slug) async {
    final service = await _services.findBySlug(slug.trim());
    if (service == null || !service.active) {
      return null;
    }
    return service;
  }

  int _requireLimit(Object? raw) {
    if (raw == null || (raw is String && raw.trim().isEmpty)) {
      return defaultLimit;
    }
    final value = _asInt(raw);
    if (value == null || value < minLimit || value > maxLimit) {
      throw const ProfileValidationException(
        message: 'limit must be between 1 and 50.',
      );
    }
    return value;
  }

  int? _asInt(Object? raw) {
    if (raw is int) {
      return raw;
    }
    if (raw is String) {
      return int.tryParse(raw.trim());
    }
    return null;
  }

  String? _optionalCurrency(Object? raw) {
    if (raw == null || (raw is String && raw.trim().isEmpty)) {
      return null;
    }
    return CleanerServiceValidation.requireCurrencyCode(raw);
  }

  int? _optionalMaxRate(Object? raw) {
    if (raw == null || (raw is String && raw.trim().isEmpty)) {
      return null;
    }
    final value = raw is int
        ? raw
        : (raw is String ? int.tryParse(raw.trim()) : null);
    return CleanerServiceValidation.requireHourlyRateMinor(value);
  }

  int? _optionalMinExperience(Object? raw) {
    if (raw == null || (raw is String && raw.trim().isEmpty)) {
      return null;
    }
    final value = raw is int
        ? raw
        : (raw is String ? int.tryParse(raw.trim()) : null);
    if (value == null || value < 0 || value > 50) {
      throw const ProfileValidationException(
        message: 'min_experience must be an integer between 0 and 50.',
      );
    }
    return value;
  }

  ({DateTime from, DateTime to})? _optionalDiscoveryWindow({
    required Object? availableFrom,
    required Object? availableTo,
  }) {
    if (availableFrom == null && availableTo == null) {
      return null;
    }
    if (availableFrom == null || availableTo == null) {
      throw const InvalidAvailabilityWindowException(
        message: 'available_from and available_to must be supplied together.',
      );
    }
    DateTime from;
    DateTime to;
    try {
      from = ApiDateTime.parseRequiredUtc(
        availableFrom,
        field: 'available_from',
      );
      to = ApiDateTime.parseRequiredUtc(availableTo, field: 'available_to');
    } on FormatException {
      throw const InvalidAvailabilityWindowException(
        message: 'available_from and available_to must include a timezone.',
      );
    }
    return AvailabilityValidation.requireRange(
      from: from,
      to: to,
      maxRange: AvailabilityValidation.maxDiscoveryWindow,
    );
  }

  ObjectId? _optionalObjectId(Object? raw) {
    if (raw == null || (raw is String && raw.trim().isEmpty)) {
      return null;
    }
    if (raw is! String) {
      throw const ProfileValidationException(
        message: 'after must be a document cursor.',
      );
    }
    try {
      return ObjectId.fromHexString(raw);
    } catch (_) {
      throw const ProfileValidationException(
        message: 'after must be a document cursor.',
      );
    }
  }
}
