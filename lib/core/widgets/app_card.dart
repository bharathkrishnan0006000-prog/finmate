import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

/// The single reusable "rounded card, soft shadow" container used across
/// every screen — dashboard tiles, list items, form sections.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final bool showShadow;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSizes.lg),
    this.onTap,
    this.color,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: AppSizes.elevationSoft,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: child,
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        onTap: onTap,
        child: content,
      ),
    );
  }
}
