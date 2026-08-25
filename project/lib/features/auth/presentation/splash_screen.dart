import 'package:flutter/material.dart';

/// Session restoration placeholder shown while auth state is restoring.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Home Cleaning Service Marketplace',
              textAlign: TextAlign.center,
              style: textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Restoring session...', style: textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
