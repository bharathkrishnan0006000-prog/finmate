import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/routes/route_names.dart';
import '../../core/widgets/app_card.dart';
import '../../core/di/providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldGrey,
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.lg),
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.accentSoft,
                child: Icon(Icons.person_rounded, color: AppColors.primary, size: 32),
              ),
              const SizedBox(width: AppSizes.lg),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bharath', style: AppTextStyles.headingMd),
                  Text('bharath@example.com', style: AppTextStyles.bodyMd),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSizes.xxl),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _MenuTile(icon: Icons.account_circle_outlined, label: 'Account Settings', onTap: () {}),
                const Divider(height: 1, indent: 56),
                _MenuTile(
                  icon: Icons.currency_rupee_rounded,
                  label: 'Currency',
                  trailingText: 'INR (₹)',
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 56),
                _MenuTile(
                  icon: Icons.handshake_outlined,
                  label: 'Borrow & Lend',
                  onTap: () => context.push(RouteNames.borrowLend),
                ),
                const Divider(height: 1, indent: 56),
                _MenuTile(
                  icon: Icons.cloud_download_outlined,
                  label: 'Backup & Restore',
                  onTap: () => context.push(RouteNames.settings),
                ),
                const Divider(height: 1, indent: 56),
                _MenuTile(
                  icon: Icons.ios_share_rounded,
                  label: 'Export Data',
                  onTap: () => context.push(RouteNames.settings),
                ),
                const Divider(height: 1, indent: 56),
                _MenuTile(
                  icon: Icons.settings_outlined,
                  label: 'App Settings',
                  onTap: () => context.push(RouteNames.settings),
                ),
                const Divider(height: 1, indent: 56),
                _MenuTile(icon: Icons.help_outline_rounded, label: 'Help & Support', onTap: () {}),
                const Divider(height: 1, indent: 56),
                _MenuTile(icon: Icons.info_outline_rounded, label: 'About Us', onTap: () {}),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.xl),
          AppCard(
            onTap: () {},
            child: const Row(
              children: [
                Icon(Icons.logout_rounded, color: AppColors.error),
                SizedBox(width: AppSizes.md),
                Text('Logout', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailingText;
  final VoidCallback onTap;

  const _MenuTile({required this.icon, required this.label, this.trailingText, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(label, style: AppTextStyles.bodyLg),
      trailing: trailingText != null
          ? Text(trailingText!, style: AppTextStyles.bodySm)
          : const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
      onTap: onTap,
    );
  }
}
