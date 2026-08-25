import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/core/network/api_failure.dart';
import 'package:home_cleaning_marketplace/features/catalog/data/marketplace_service.dart';
import 'package:home_cleaning_marketplace/features/catalog/data/service_catalog_api.dart';

class CatalogState {
  const CatalogState({
    required this.loading,
    this.items = const <MarketplaceService>[],
    this.errorMessage,
  });

  const CatalogState.loading()
    : loading = true,
      items = const <MarketplaceService>[],
      errorMessage = null;

  final bool loading;
  final List<MarketplaceService> items;
  final String? errorMessage;
}

class CatalogController extends Notifier<CatalogState> {
  @override
  CatalogState build() {
    Future<void>(load);
    return const CatalogState.loading();
  }

  Future<void> load() async {
    if (!ref.mounted) {
      return;
    }
    state = const CatalogState.loading();
    try {
      final items = await ref.read(serviceCatalogApiProvider).listActive();
      if (!ref.mounted) {
        return;
      }
      state = CatalogState(loading: false, items: items);
    } on ApiFailure catch (error) {
      if (!ref.mounted) {
        return;
      }
      state = CatalogState(loading: false, errorMessage: error.message);
    } catch (_) {
      if (!ref.mounted) {
        return;
      }
      state = const CatalogState(
        loading: false,
        errorMessage: 'Something went wrong. Please try again.',
      );
    }
  }
}

final catalogControllerProvider =
    NotifierProvider<CatalogController, CatalogState>(CatalogController.new);
