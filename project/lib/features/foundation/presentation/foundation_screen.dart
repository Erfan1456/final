import 'package:flutter/material.dart';

/// Temporary foundation screen that proves bootstrap, routing, theme, and
/// feature organization work.
///
/// This is not a product feature. There is no view model because the screen
/// has no presentation logic or state that would require one.
class FoundationScreen extends StatelessWidget {
  const FoundationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cleaning_services_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Home Cleaning Service Marketplace',
              textAlign: TextAlign.center,
              style: textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('Foundation ready', style: textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
