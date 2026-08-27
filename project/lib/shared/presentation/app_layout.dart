import 'package:flutter/material.dart';
import 'package:home_cleaning_marketplace/shared/presentation/app_spacing.dart';

/// Readable content width constraints for phone and wide layouts.
abstract final class AppLayout {
  /// Horizontal page padding on typical phone widths.
  static const double pagePadding = AppSpacing.normal;

  /// Max width for forms and auth screens.
  static const double formMaxWidth = 600;

  /// Max width for detail pages.
  static const double detailMaxWidth = 800;

  /// Wider area for admin lists and dashboards.
  static const double dashboardMaxWidth = 1100;

  /// Centers [child] and clamps width for readable forms/details.
  static Widget constrained({
    required Widget child,
    double maxWidth = formMaxWidth,
    EdgeInsetsGeometry padding = const EdgeInsets.all(pagePadding),
  }) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
