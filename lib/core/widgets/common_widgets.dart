import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../theme/app_text_styles.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({super.key, required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.headingSm),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel!, style: AppTextStyles.bodySm.copyWith(color: AppColors.primary)),
          ),
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.xxxl, horizontal: AppSizes.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.lg),
            decoration: const BoxDecoration(
              color: AppColors.accentSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 36, color: AppColors.primary),
          ),
          const SizedBox(height: AppSizes.lg),
          Text(title, style: AppTextStyles.headingSm, textAlign: TextAlign.center),
          const SizedBox(height: AppSizes.xs),
          Text(message,
              style: AppTextStyles.bodyMd, textAlign: TextAlign.center),
          if (action != null) ...[
            const SizedBox(height: AppSizes.lg),
            action!,
          ],
        ],
      ),
    );
  }
}

class AppProgressBar extends StatelessWidget {
  final double progress; // 0..1
  final Color color;
  final double height;

  const AppProgressBar({
    super.key,
    required this.progress,
    this.color = AppColors.primary,
    this.height = 8,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    final isOver = progress > 1.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.radiusPill),
      child: LinearProgressIndicator(
        value: clamped,
        minHeight: height,
        backgroundColor: AppColors.scaffoldGrey,
        valueColor: AlwaysStoppedAnimation(isOver ? AppColors.error : color),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const StatusPill({super.key, required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(label, style: AppTextStyles.bodySm.copyWith(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class CategoryIconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const CategoryIconBadge({super.key, required this.icon, required this.color, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}
