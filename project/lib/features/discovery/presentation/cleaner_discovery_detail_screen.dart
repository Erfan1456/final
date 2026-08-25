import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/features/availability/presentation/cleaner_availability_screen.dart';
import 'package:home_cleaning_marketplace/features/catalog/data/marketplace_service.dart';
import 'package:home_cleaning_marketplace/features/discovery/data/cleaner_discovery_models.dart';
import 'package:home_cleaning_marketplace/features/discovery/presentation/comparison_controller.dart';
import 'package:home_cleaning_marketplace/features/discovery/presentation/discovery_controller.dart';

/// Customer-safe cleaner public profile and future availability.
class CleanerDiscoveryDetailScreen extends ConsumerStatefulWidget {
  const CleanerDiscoveryDetailScreen({super.key, required this.cleanerUserId});

  final String cleanerUserId;

  @override
  ConsumerState<CleanerDiscoveryDetailScreen> createState() =>
      _CleanerDiscoveryDetailScreenState();
}

class _CleanerDiscoveryDetailScreenState
    extends ConsumerState<CleanerDiscoveryDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref
          .read(discoveryControllerProvider.notifier)
          .loadDetail(widget.cleanerUserId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(discoveryControllerProvider);
    final detail = state.detail;
    final comparison = ref.watch(comparisonControllerProvider);
    final selected = comparison.contains(widget.cleanerUserId);

    return Scaffold(
      appBar: AppBar(title: const Text('Cleaner details')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: state.loading && detail == null
              ? const Center(child: CircularProgressIndicator())
              : detail == null
              ? Text(state.errorMessage ?? 'Cleaner was not found.')
              : ListView(
                  children: [
                    Text(
                      detail.fullName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(detail.bio),
                    Text('${detail.yearsExperience} years experience'),
                    Text(detail.serviceArea),
                    Text(detail.service.name),
                    Text('Billing: ${detail.service.billingModel.wireValue}'),
                    Text(
                      formatMinorHourlyRate(
                        detail.hourlyRateMinor,
                        detail.currencyCode,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Future availability'),
                    for (final slot in detail.availability)
                      ListTile(
                        title: Text(formatLocalDateTime(slot.startAt)),
                        subtitle: Text(
                          '${formatLocalDateTime(slot.endAt)} · ${slot.duration.inMinutes} min',
                        ),
                      ),
                    const SizedBox(height: 8),
                    const Text(
                      'Booking will use available slots in a later workflow.',
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () {
                        if (selected) {
                          ref
                              .read(comparisonControllerProvider.notifier)
                              .remove(widget.cleanerUserId);
                          return;
                        }
                        final summary = CleanerDiscoverySummary(
                          cleanerUserId: detail.cleanerUserId,
                          fullName: detail.fullName,
                          bioExcerpt: detail.bio,
                          yearsExperience: detail.yearsExperience,
                          serviceArea: detail.serviceArea,
                          service: detail.service,
                          hourlyRateMinor: detail.hourlyRateMinor,
                          currencyCode: detail.currencyCode,
                          nextAvailableAt: detail.availability.isEmpty
                              ? null
                              : detail.availability.first.startAt,
                        );
                        final result = ref
                            .read(comparisonControllerProvider.notifier)
                            .add(summary);
                        if (result == ComparisonAddResult.atCapacity) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'You can compare at most 3 cleaners.',
                              ),
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
        ),
      ),
    );
  }
}
