import 'package:flutter/material.dart';
import 'package:home_cleaning_marketplace/shared/presentation/app_spacing.dart';

/// Labeled section used on role homes and detail pages.
class AppSection extends StatelessWidget {
  const AppSection({
    required this.title,
    required this.children,
    super.key,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(subtitle!, style: theme.textTheme.bodyMedium),
        ],
        const SizedBox(height: AppSpacing.small),
        ...children,
      ],
    );
  }
}

/// Development/sandbox honesty banner.
class AppDevelopmentBanner extends StatelessWidget {
  const AppDevelopmentBanner({
    this.message = 'Development sandbox only — not a production provider.',
    super.key,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Development notice: $message',
      child: Material(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.normal),
          child: Row(
            children: [
              Icon(Icons.science_outlined, color: scheme.onTertiaryContainer),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: scheme.onTertiaryContainer),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Key/value row for detail summaries.
class AppKeyValueRow extends StatelessWidget {
  const AppKeyValueRow({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: theme.textTheme.labelLarge),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
