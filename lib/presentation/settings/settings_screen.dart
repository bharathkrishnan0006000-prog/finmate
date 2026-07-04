import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/routes/route_names.dart';
import '../../core/di/providers.dart';
import '../../data/database/app_database.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const _timeoutOptions = <int, String>{
    0: 'Immediately',
    1: 'After 1 minute',
    5: 'After 5 minutes',
    -1: 'Never',
  };

  Future<void> _togglePin(bool enable) async {
    final auth = ref.read(authServiceProvider);
    final prefs = ref.read(sharedPreferencesProvider);
    if (enable) {
      final pin = await _promptSetPin();
      if (pin == null) return; // cancelled
      await auth.setPin(pin);
    } else {
      await auth.clearPin();
    }
    ref.read(pinEnabledProvider.notifier).state = enable;
    await prefs.setBool(AppConstants.prefsPinEnabled, enable);
  }

  Future<String?> _promptSetPin() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set a 4-6 digit PIN'),
        content: TextField(
          controller: controller,
          autofocus: true,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(hintText: 'Enter PIN'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final v = controller.text.trim();
              if (v.length >= 4) Navigator.of(context).pop(v);
            },
            child: const Text('Set PIN'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleBiometric(bool enable) async {
    final auth = ref.read(authServiceProvider);
    if (enable && !await auth.isBiometricAvailable()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Biometric authentication is not available on this device')));
      }
      return;
    }
    ref.read(biometricEnabledProvider.notifier).state = enable;
    await ref.read(sharedPreferencesProvider).setBool(AppConstants.prefsBiometricEnabled, enable);
  }

  @override
  Widget build(BuildContext context) {
    final aiEnabled = ref.watch(aiEnabledProvider);
    final darkMode = ref.watch(darkModeProvider);
    final prefs = ref.watch(sharedPreferencesProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldGrey,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.lg),
        children: [
          _SectionCard(
            title: 'Appearance',
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Dark Mode'),
                value: darkMode,
                activeThumbColor: AppColors.primary,
                onChanged: (v) {
                  ref.read(darkModeProvider.notifier).state = v;
                  prefs.setBool(AppConstants.prefsDarkMode, v);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Currency'),
                trailing: const Text('INR (₹)', style: TextStyle(color: AppColors.textSecondary)),
              ),
              const ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Language'),
                trailing: Text('English', style: TextStyle(color: AppColors.textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.lg),
          _SectionCard(
            title: 'AI Features',
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Enable AI Features'),
                subtitle: const Text('Rule-based, on-device. Only runs when you tap Analyze/Categorize.'),
                value: aiEnabled,
                activeThumbColor: AppColors.primary,
                onChanged: (v) {
                  ref.read(aiEnabledProvider.notifier).state = v;
                  prefs.setBool(AppConstants.prefsAiEnabled, v);
                },
              ),
            ],
          ),
          const SizedBox(height: AppSizes.lg),
          _SectionCard(
            title: 'Security',
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('PIN Lock'),
                value: ref.watch(pinEnabledProvider),
                activeThumbColor: AppColors.primary,
                onChanged: _togglePin,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Biometric Lock'),
                value: ref.watch(biometricEnabledProvider),
                activeThumbColor: AppColors.primary,
                onChanged: _toggleBiometric,
              ),
              if (ref.watch(pinEnabledProvider) || ref.watch(biometricEnabledProvider))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Lock after'),
                  trailing: DropdownButton<int>(
                    value: ref.watch(lockTimeoutMinutesProvider),
                    underline: const SizedBox.shrink(),
                    items: _timeoutOptions.entries
                        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      ref.read(lockTimeoutMinutesProvider.notifier).state = v;
                      ref.read(sharedPreferencesProvider).setInt(AppConstants.prefsLockTimeoutMinutes, v);
                    },
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSizes.lg),
          _SectionCard(
            title: 'Notifications',
            children: const [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Budget Warnings'),
                value: true,
                onChanged: null,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Subscription Reminders'),
                value: true,
                onChanged: null,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Savings Reminders'),
                value: true,
                onChanged: null,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.lg),
          _SectionCard(
            title: 'Categories & Data',
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.category_outlined, color: AppColors.textSecondary),
                title: const Text('Manage Categories'),
                onTap: () => context.push(RouteNames.categoryManagement),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.delete_sweep_outlined, color: AppColors.textSecondary),
                title: const Text('Bulk Delete'),
                onTap: () => context.push(RouteNames.bulkDelete),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.ios_share_rounded, color: AppColors.textSecondary),
                title: const Text('Export Data (CSV / Excel / PDF)'),
                onTap: () => _exportData(context),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.backup_outlined, color: AppColors.textSecondary),
                title: const Text('Backup'),
                subtitle: const Text('Saves transactions, categories, budgets, etc. as separate JSON files to a folder you choose'),
                onTap: () => _runBackup(context),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.restore_outlined, color: AppColors.textSecondary),
                title: const Text('Restore'),
                subtitle: const Text('Restores from a folder containing FinMate backup files'),
                onTap: () => _runRestore(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _runBackup(BuildContext context) async {
    final result = await ref.read(backupServiceProvider).backup(ref.read(sharedPreferencesProvider));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result.isSuccess ? 'Backup saved to ${result.data}' : result.failure!.message),
    ));
  }

  Future<void> _runRestore(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore from backup?'),
        content: const Text('This adds the backed-up data on top of what\'s already here. Duplicate transactions are not auto-merged.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Restore')),
        ],
      ),
    );
    if (confirmed != true) return;

    final result = await ref.read(backupServiceProvider).restore(ref.read(sharedPreferencesProvider));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result.isSuccess ? 'Restored ${result.data} transactions' : result.failure!.message),
    ));
  }

  Future<void> _exportData(BuildContext context) async {
    final txnRepo = ref.read(transactionRepositoryProvider);
    final exportService = ref.read(exportServiceProvider);
    final format = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(title: const Text('Export as CSV'), onTap: () => Navigator.pop(context, 'csv')),
          ListTile(title: const Text('Export as Excel'), onTap: () => Navigator.pop(context, 'xlsx')),
          ListTile(title: const Text('Export as PDF'), onTap: () => Navigator.pop(context, 'pdf')),
        ],
      ),
    );
    if (format == null) return;

    final all = await txnRepo.watchAll().first;
    late final dynamic file;
    switch (format) {
      case 'csv':
        file = await exportService.exportCsv(all);
        break;
      case 'xlsx':
        file = await exportService.exportExcel(all);
        break;
      case 'pdf':
        final income = all.where((t) => t.type == 'income').fold<double>(0, (s, t) => s + t.amount);
        final expense = all.where((t) => t.type == 'expense').fold<double>(0, (s, t) => s + t.amount);
        file = await exportService.exportPdf(all, totalIncome: income, totalExpense: expense);
        break;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exported to ${file.path}')));
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.titleMd),
          const SizedBox(height: AppSizes.sm),
          ...children,
        ],
      ),
    );
  }
}
