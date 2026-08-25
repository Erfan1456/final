import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:home_cleaning_marketplace/app/router/app_routes.dart';
import 'package:home_cleaning_marketplace/features/catalog/data/marketplace_service.dart';
import 'package:home_cleaning_marketplace/features/discovery/presentation/cleaner_comparison_screen.dart';
import 'package:home_cleaning_marketplace/features/discovery/presentation/cleaner_discovery_detail_screen.dart';
import 'package:home_cleaning_marketplace/features/discovery/presentation/cleaner_discovery_screen.dart';
import 'package:home_cleaning_marketplace/features/discovery/presentation/comparison_controller.dart';
import 'package:home_cleaning_marketplace/features/discovery/presentation/discovery_controller.dart';

import '../../../helpers/feature_test_fakes.dart';

void main() {
  testWidgets('discovery list shows cards, rate, and load more', (
    tester,
  ) async {
    final discovery = SeededDiscoveryController(
      DiscoveryState(
        loading: false,
        items: [testDiscoverySummary()],
        nextCursor: 'cursor-1',
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          discoveryControllerProvider.overrideWith(() => discovery),
          comparisonControllerProvider.overrideWith(
            () => SeededComparisonController(const ComparisonState()),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: AppRoutes.customerDiscoverPath,
            routes: [
              GoRoute(
                path: AppRoutes.customerDiscoverPath,
                builder: (context, state) => const CleanerDiscoveryScreen(),
              ),
              GoRoute(
                path: AppRoutes.customerCleanerDetailPath,
                builder: (context, state) =>
                    const Scaffold(body: Text('Detail route')),
              ),
              GoRoute(
                path: AppRoutes.customerComparePath,
                builder: (context, state) =>
                    const Scaffold(body: Text('Compare route')),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Ada Cleaner'), findsOneWidget);
    expect(find.text('4 years · Dhaka North'), findsOneWidget);
    expect(find.text(formatMinorHourlyRate(250000, 'BDT')), findsOneWidget);
    expect(find.text('View Details'), findsOneWidget);
    expect(find.text('Add to Compare'), findsOneWidget);
    expect(find.text('Load More'), findsOneWidget);
    expect(find.text('Filters'), findsOneWidget);
    expect(find.textContaining('phone'), findsNothing);
    expect(find.textContaining('email'), findsNothing);
    expect(find.textContaining('@'), findsNothing);

    await tester.tap(find.text('Load More'));
    await tester.pump();
    expect(discovery.loadMoreCalls, equals(1));

    await tester.tap(find.text('View Details'));
    await tester.pumpAndSettle();
    expect(find.text('Detail route'), findsOneWidget);
  });

  testWidgets('filters sheet applies values', (tester) async {
    final discovery = SeededDiscoveryController(
      const DiscoveryState(loading: false),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          discoveryControllerProvider.overrideWith(() => discovery),
          comparisonControllerProvider.overrideWith(
            () => SeededComparisonController(const ComparisonState()),
          ),
        ],
        child: const MaterialApp(home: CleanerDiscoveryScreen()),
      ),
    );
    await tester.tap(find.text('Filters'));
    await tester.pumpAndSettle();
    expect(find.text('Service: Home Cleaning'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), 'USD');
    await tester.enterText(find.byType(TextField).at(1), '100000');
    await tester.enterText(find.byType(TextField).at(2), '2');
    await tester.tap(find.text('Apply filters'));
    await tester.pumpAndSettle();
    expect(discovery.loadCalls, equals(1));
    expect(discovery.lastFilters?.currency, equals('USD'));
    expect(discovery.lastFilters?.maxRateMinor, equals(100000));
    expect(discovery.lastFilters?.minExperience, equals(2));
  });

  testWidgets('comparison selection maxes at three', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          discoveryControllerProvider.overrideWith(
            () => SeededDiscoveryController(
              DiscoveryState(
                loading: false,
                items: [
                  testDiscoverySummary(cleanerUserId: '1', fullName: 'Ada'),
                  testDiscoverySummary(cleanerUserId: '2', fullName: 'Bea'),
                  testDiscoverySummary(cleanerUserId: '3', fullName: 'Cara'),
                  testDiscoverySummary(cleanerUserId: '4', fullName: 'Dee'),
                ],
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: CleanerDiscoveryScreen()),
      ),
    );

    await tester.tap(find.text('Add to Compare').at(0));
    await tester.pump();
    await tester.tap(find.text('Add to Compare').at(0));
    await tester.pump();
    await tester.tap(find.text('Add to Compare').at(0));
    await tester.pump();
    expect(find.text('Compare 3/3'), findsOneWidget);
    await tester.tap(find.text('Add to Compare'));
    await tester.pump();
    expect(find.text('You can compare at most 3 cleaners.'), findsOneWidget);
  });

  testWidgets('detail shows safe public fields and no contacts', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          discoveryControllerProvider.overrideWith(
            () => SeededDiscoveryController(
              DiscoveryState(loading: false, detail: testDiscoveryDetail()),
            ),
          ),
          comparisonControllerProvider.overrideWith(
            () => SeededComparisonController(const ComparisonState()),
          ),
        ],
        child: const MaterialApp(
          home: CleanerDiscoveryDetailScreen(
            cleanerUserId: '507f1f77bcf86cd799439081',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ada Cleaner'), findsOneWidget);
    expect(find.text('Reliable cleaner for apartments.'), findsOneWidget);
    expect(find.text('Home Cleaning'), findsOneWidget);
    expect(find.text('Billing: hourly'), findsOneWidget);
    expect(
      find.text('Booking will use available slots in a later workflow.'),
      findsOneWidget,
    );
    expect(find.textContaining('phone'), findsNothing);
    expect(find.textContaining('@'), findsNothing);
    expect(find.text('Book'), findsNothing);
  });

  testWidgets('comparison screen notes mixed currencies', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          comparisonControllerProvider.overrideWith(
            () => SeededComparisonController(
              ComparisonState(
                items: [
                  testDiscoverySummary(currencyCode: 'BDT'),
                  testDiscoverySummary(
                    cleanerUserId: '2',
                    fullName: 'Bea Cleaner',
                    currencyCode: 'USD',
                    hourlyRateMinor: 4000,
                  ),
                ],
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: CleanerComparisonScreen()),
      ),
    );
    expect(find.text('Ada Cleaner'), findsOneWidget);
    expect(find.text('Bea Cleaner'), findsOneWidget);
    expect(
      find.text(
        'Prices in different currencies are not automatically comparable.',
      ),
      findsOneWidget,
    );
    expect(find.text(formatMinorHourlyRate(250000, 'BDT')), findsOneWidget);
    expect(find.text(formatMinorHourlyRate(4000, 'USD')), findsOneWidget);
  });
}
