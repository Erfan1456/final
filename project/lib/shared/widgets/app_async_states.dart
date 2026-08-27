import 'package:flutter/material.dart';
import 'package:home_cleaning_marketplace/shared/presentation/app_spacing.dart';

/// Centered progress with optional context text.
class AppLoadingState extends StatelessWidget {
  const AppLoadingState({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.section),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.normal),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Non-error empty content with optional action.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    required this.title,
    super.key,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.section),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 40,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: AppSpacing.normal),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.small),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.normal),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Safe error presentation with optional retry.
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    required this.message,
    super.key,
    this.onRetry,
    this.retryLabel = 'Try Again',
  });

  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.section),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 40, color: theme.colorScheme.error),
            const SizedBox(height: AppSpacing.normal),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.normal),
              OutlinedButton(onPressed: onRetry, child: Text(retryLabel)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Soft success/info banner.
class AppSuccessBanner extends StatelessWidget {
  const AppSuccessBanner({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Material(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.normal),
          child: Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: scheme.onSecondaryContainer,
              ),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: scheme.onSecondaryContainer),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chooses loading / error / empty / content for list-style screens.
class AppAsyncContent extends StatelessWidget {
  const AppAsyncContent({
    required this.loading,
    required this.hasData,
    required this.builder,
    super.key,
    this.errorMessage,
    this.onRetry,
    this.emptyTitle = 'Nothing here yet.',
    this.emptyMessage,
    this.emptyActionLabel,
    this.onEmptyAction,
    this.loadingMessage,
  });

  final bool loading;
  final bool hasData;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final String emptyTitle;
  final String? emptyMessage;
  final String? emptyActionLabel;
  final VoidCallback? onEmptyAction;
  final String? loadingMessage;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    if (loading && !hasData) {
      return AppLoadingState(message: loadingMessage);
    }
    if (errorMessage != null && !hasData) {
      return AppErrorState(message: errorMessage!, onRetry: onRetry);
    }
    if (!hasData) {
      return AppEmptyState(
        title: emptyTitle,
        message: emptyMessage,
        actionLabel: emptyActionLabel,
        onAction: onEmptyAction,
      );
    }
    return builder(context);
  }
}
