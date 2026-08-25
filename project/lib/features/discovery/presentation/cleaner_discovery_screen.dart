import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_cleaning_marketplace/app/router/app_routes.dart';
import 'package:home_cleaning_marketplace/features/catalog/data/marketplace_service.dart';
import 'package:home_cleaning_marketplace/features/discovery/data/cleaner_discovery_models.dart';
import 'package:home_cleaning_marketplace/features/discovery/presentation/comparison_controller.dart';
import 'package:home_cleaning_marketplace/features/discovery/presentation/discovery_controller.dart';

/// Customer discovery list with filters, load more, and comparison.
class CleanerDiscoveryScreen extends ConsumerWidget {
  const CleanerDiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(discoveryControllerProvider);
    final comparison = ref.watch(comparisonControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Cleaners'),
        actions: [
          TextButton(
            onPressed: () => context.push(AppRoutes.customerComparePath),
            child: Text('Compare ${comparison.items.length}/3'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => _openFilters(context, ref),
                  child: const Text('Filters'),
                ),
              ),
              if (state.errorMessage != null) Text(state.errorMessage!),
              Expanded(
                child: state.loading
                    ? const Center(child: CircularProgressIndicator())
                    : state.items.isEmpty
                    ? const Center(child: Text('No cleaners found.'))
                    : ListView(
                        children: [
                          for (final item in state.items)
                            _DiscoveryCard(summary: item),
                          if (state.nextCursor != null)
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: OutlinedButton(
                                onPressed: state.loadingMore
                                    ? null
                                    : () => ref
                                          .read(
                                            discoveryControllerProvider
                                                .notifier,
                                          )
                                          .loadMore(),
                                child: Text(
                                  state.loadingMore
                                      ? 'Loading...'
                                      : 'Load More',
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openFilters(BuildContext context, WidgetRef ref) async {
    final current = ref.read(discoveryControllerProvider).filters;
    final currency = TextEditingController(text: current.currency ?? '');
    final maxRate = TextEditingController(
      text: current.maxRateMinor?.toString() ?? '',
    );
    final minExp = TextEditingController(
      text: current.minExperience?.toString() ?? '',
    );
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Service: Home Cleaning'),
              TextField(
                controller: currency,
                decoration: const InputDecoration(labelText: 'Currency'),
              ),
              TextField(
                controller: maxRate,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Maximum rate'),
              ),
              TextField(
                controller: minExp,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Minimum experience',
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  ref
                      .read(discoveryControllerProvider.notifier)
                      .applyFilters(
                        DiscoveryFilters(
                          service: current.service,
                          currency: currency.text.trim().isEmpty
                              ? null
                              : currency.text.trim(),
                          maxRateMinor: int.tryParse(maxRate.text.trim()),
                          minExperience: int.tryParse(minExp.text.trim()),
                        ),
                      );
                },
                child: const Text('Apply filters'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DiscoveryCard extends ConsumerWidget {
  const _DiscoveryCard({required this.summary});

  final CleanerDiscoverySummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comparison = ref.watch(comparisonControllerProvider);
    final selected = comparison.contains(summary.cleanerUserId);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              summary.fullName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text('${summary.yearsExperience} years · ${summary.serviceArea}'),
            Text(
              formatMinorHourlyRate(
                summary.hourlyRateMinor,
                summary.currencyCode,
              ),
            ),
            Text(
              formatDiscoveryRating(summary.ratingAverage, summary.reviewCount),
            ),
            if (summary.nextAvailableAt != null)
              Text('Next available: ${summary.nextAvailableAt!.toLocal()}'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilledButton(
                  onPressed: () => context.push(
                    AppRoutes.customerCleanerDetailPath.replaceFirst(
                      ':cleanerUserId',
                      summary.cleanerUserId,
                    ),
                  ),
                  child: const Text('View Details'),
                ),
                OutlinedButton(
                  onPressed: () {
                    final result = selected
                        ? () {
                            ref
                                .read(comparisonControllerProvider.notifier)
                                .remove(summary.cleanerUserId);
                            return ComparisonAddResult.added;
                          }()
                        : ref
                              .read(comparisonControllerProvider.notifier)
                              .add(summary);
                    if (result == ComparisonAddResult.atCapacity) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('You can compare at most 3 cleaners.'),
                        ),
                      );
                    }
                  },
                  child: Text(
                    selected ? 'Remove from Compare' : 'Add to Compare',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
