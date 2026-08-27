import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_cleaning_marketplace/app/app.dart';
import 'package:home_cleaning_marketplace/app/theme/app_theme.dart';
import 'package:home_cleaning_marketplace/core/config/app_config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final config = AppConfig.fromEnvironment();
    runApp(
      ProviderScope(
        overrides: [appConfigProvider.overrideWithValue(config)],
        child: const HomeCleaningMarketplaceApp(),
      ),
    );
  } on AppConfigException catch (error) {
    runApp(_ConfigurationErrorApp(message: error.message));
  }
}

/// Safe startup failure UI when release configuration is invalid.
class _ConfigurationErrorApp extends StatelessWidget {
  const _ConfigurationErrorApp({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Home Cleaning Marketplace',
      theme: AppTheme.light,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'This build is not configured correctly.\n\n$message',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
