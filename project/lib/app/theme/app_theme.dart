import 'package:flutter/material.dart';

/// Application theme boundary.
///
/// Detailed branding and a full design system are deferred. This uses a
/// temporary Material 3 seed color so light/dark themes stay centralized
/// rather than scattered through screens.
abstract final class AppTheme {
  static const Color _seedColor = Color(0xFF00695C);

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.light,
      ),
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.dark,
      ),
    );
  }
}
