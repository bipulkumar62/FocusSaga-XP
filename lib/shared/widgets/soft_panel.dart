import 'package:flutter/material.dart';

/// A light, soft, semi-transparent glass panel.
///
/// The standard surface for chips, badges and small widgets sitting directly
/// on the animated season background. Cards use the theme's glassy card color
/// instead; this panel is for ad-hoc containers that need the same look.
class SoftPanel extends StatelessWidget {
  const SoftPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    this.radius = 20,
    this.color,
    this.border = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final bool border;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? theme.colorScheme.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(radius),
        border: border
            ? Border.all(
                color: Colors.white.withValues(alpha: 0.35),
              )
            : null,
      ),
      child: child,
    );
  }
}
