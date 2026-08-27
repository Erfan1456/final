import 'package:flutter/material.dart';

/// Status chip that always includes text (never color alone).
class AppStatusChip extends StatelessWidget {
  const AppStatusChip({required this.label, super.key, this.tooltip});

  final String label;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final chip = Chip(
      label: Text(label, softWrap: true, overflow: TextOverflow.fade),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
    if (tooltip == null) {
      return Semantics(label: 'Status: $label', child: chip);
    }
    return Tooltip(
      message: tooltip!,
      child: Semantics(label: 'Status: $label', child: chip),
    );
  }
}
