import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/features/availability/presentation/cleaner_availability_screen.dart';
import 'package:home_cleaning_marketplace/features/catalog/data/marketplace_service.dart';
import 'package:home_cleaning_marketplace/features/discovery/presentation/comparison_controller.dart';

/// Local comparison of up to three discovered cleaners.
class CleanerComparisonScreen extends ConsumerWidget {
  const CleanerComparisonScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(comparisonControllerProvider).items;
    final currencies = items.map((item) => item.currencyCode).toSet();

    return Scaffold(
      appBar: AppBar(title: const Text('Compare cleaners')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: items.isEmpty
              ? const Text('Select up to 3 cleaners to compare.')
              : ListView(
                  children: [
                    if (currencies.length > 1)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: Text(
                          'Prices in different currencies are not automatically comparable.',
                        ),
                      ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final item in items)
                            SizedBox(
                              width: 220,
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.fullName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      Text('${item.yearsExperience} years'),
                                      Text(item.serviceArea),
                                      Text(item.service.name),
                                      Text(
                                        formatMinorHourlyRate(
                                          item.hourlyRateMinor,
                                          item.currencyCode,
                                        ),
                                      ),
                                      Text(
                                        item.nextAvailableAt == null
                                            ? 'Next availability: none'
                                            : 'Next: ${formatLocalDateTime(item.nextAvailableAt!)}',
                                      ),
                                      TextButton(
                                        onPressed: () => ref
                                            .read(
                                              comparisonControllerProvider
                                                  .notifier,
                                            )
                                            .remove(item.cleanerUserId),
                                        child: const Text('Remove'),
                                      ),
                                    ],
                                  ),
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
}
