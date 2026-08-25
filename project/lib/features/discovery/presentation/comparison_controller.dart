import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/features/discovery/data/cleaner_discovery_models.dart';

const int maxComparisonSelections = 3;

enum ComparisonAddResult { added, alreadySelected, atCapacity }

class ComparisonState {
  const ComparisonState({this.items = const <CleanerDiscoverySummary>[]});

  final List<CleanerDiscoverySummary> items;

  bool contains(String cleanerUserId) {
    return items.any((item) => item.cleanerUserId == cleanerUserId);
  }
}

class ComparisonController extends Notifier<ComparisonState> {
  @override
  ComparisonState build() => const ComparisonState();

  ComparisonAddResult add(CleanerDiscoverySummary summary) {
    if (state.contains(summary.cleanerUserId)) {
      return ComparisonAddResult.alreadySelected;
    }
    if (state.items.length >= maxComparisonSelections) {
      return ComparisonAddResult.atCapacity;
    }
    state = ComparisonState(items: [...state.items, summary]);
    return ComparisonAddResult.added;
  }

  void remove(String cleanerUserId) {
    state = ComparisonState(
      items: [
        for (final item in state.items)
          if (item.cleanerUserId != cleanerUserId) item,
      ],
    );
  }

  void toggle(CleanerDiscoverySummary summary) {
    if (state.contains(summary.cleanerUserId)) {
      remove(summary.cleanerUserId);
      return;
    }
    add(summary);
  }
}

final comparisonControllerProvider =
    NotifierProvider<ComparisonController, ComparisonState>(
      ComparisonController.new,
    );
