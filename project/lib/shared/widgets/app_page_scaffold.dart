import 'package:flutter/material.dart';
import 'package:home_cleaning_marketplace/shared/presentation/app_layout.dart';

/// Standard page shell with optional content width constraint.
class AppPageScaffold extends StatelessWidget {
  const AppPageScaffold({
    required this.title,
    required this.body,
    super.key,
    this.actions,
    this.floatingActionButton,
    this.maxWidth = AppLayout.detailMaxWidth,
    this.padding = const EdgeInsets.all(AppLayout.pagePadding),
    this.scrollable = true,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final double maxWidth;
  final EdgeInsetsGeometry padding;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final content = AppLayout.constrained(
      maxWidth: maxWidth,
      padding: padding,
      child: body,
    );
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        child: scrollable ? SingleChildScrollView(child: content) : content,
      ),
    );
  }
}
