// lib/widgets/app_icon.dart
//
// Thin wrapper around HugeIcon that applies a consistent stroke width
// and falls back to the theme icon color when none is specified.
// Use this instead of Flutter's built-in Icon() widget.

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class AppIcon extends StatelessWidget {
  final dynamic icon;  // Changed from IconData to dynamic
  final Color? color;
  final double size;
  final double strokeWidth;

  const AppIcon(
      this.icon, {
        super.key,
        this.color,
        this.size = 24,
        this.strokeWidth = 1.6,
      });

  @override
  Widget build(BuildContext context) {
    return HugeIcon(
      icon: icon,
      color: color ?? Theme.of(context).iconTheme.color ?? Colors.black,
      size: size,
      strokeWidth: strokeWidth,
    );
  }
}

// ── Convenience constructors for common use-cases ─────────────────────────────

/// White icon — for use inside AppBar / primary-colored containers.
class AppIconWhite extends StatelessWidget {
  final dynamic icon;  // Changed from IconData to dynamic
  final double size;

  const AppIconWhite(this.icon, {super.key, this.size = 22});

  @override
  Widget build(BuildContext context) =>
      AppIcon(icon, color: Colors.white, size: size);
}

/// Primary-colored icon.
class AppIconPrimary extends StatelessWidget {
  final dynamic icon;  // Changed from IconData to dynamic
  final double size;

  const AppIconPrimary(this.icon, {super.key, this.size = 24});

  @override
  Widget build(BuildContext context) =>
      AppIcon(icon, color: Theme.of(context).primaryColor, size: size);
}