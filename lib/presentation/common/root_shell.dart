import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/routes/route_names.dart';

/// Shell wrapping Dashboard / Transactions / Future Planner / Profile with
/// a bottom nav bar (center "+" opens Add Expense) and a side drawer that
/// exposes the rest of the app (Analytics, Subscriptions, Budget Goals,
/// Savings Goals, Settings) — matching mockup #16.
class RootShell extends StatelessWidget {
  final Widget child;
  const RootShell({super.key, required this.child});

  static const _tabs = [
    RouteNames.dashboard,
    RouteNames.transactions,
    RouteNames.futurePlanner,
    RouteNames.profile,
  ];

  int _indexForLocation(String location) {
    final index = _tabs.indexWhere((t) => location.startsWith(t));
    return index == -1 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _indexForLocation(location);

    return Scaffold(
      drawer: const AppDrawer(),
      body: child,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        elevation: 2,
        shape: const CircleBorder(),
        onPressed: () => context.push(RouteNames.addExpense),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: AppColors.background,
        elevation: 8,
        height: AppSizes.bottomNavHeight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.home_rounded,
              label: 'Home',
              selected: currentIndex == 0,
              onTap: () => context.go(RouteNames.dashboard),
            ),
            _NavItem(
              icon: Icons.receipt_long_rounded,
              label: 'Transactions',
              selected: currentIndex == 1,
              onTap: () => context.go(RouteNames.transactions),
            ),
            const SizedBox(width: 48), // space for the notch/FAB
            _NavItem(
              icon: Icons.flag_rounded,
              label: 'Planner',
              selected: currentIndex == 2,
              onTap: () => context.go(RouteNames.futurePlanner),
            ),
            _NavItem(
              icon: Icons.person_rounded,
              label: 'Profile',
              selected: currentIndex == 3,
              onTap: () => context.go(RouteNames.profile),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textHint;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: AppSizes.iconMd),
            const SizedBox(height: 2),
            Text(label, style: AppTextStyles.caption.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              color: AppColors.primary,
              padding: const EdgeInsets.all(AppSizes.xl),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.person_rounded, color: Colors.white, size: 30),
                  ),
                  SizedBox(height: AppSizes.md),
                  Text('Bharath',
                      style: TextStyle(
                          color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                  Text('bharath@example.com',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
                children: [
                  _DrawerItem(Icons.dashboard_rounded, 'Dashboard', RouteNames.dashboard),
                  _DrawerItem(Icons.receipt_long_rounded, 'Transactions', RouteNames.transactions),
                  _DrawerItem(Icons.pie_chart_rounded, 'Analytics', RouteNames.analytics),
                  _DrawerItem(Icons.handshake_outlined, 'Borrow & Lend', RouteNames.borrowLend),
                  _DrawerItem(Icons.subscriptions_rounded, 'Subscriptions', RouteNames.subscriptions),
                  _DrawerItem(Icons.track_changes_rounded, 'Budget Goals', RouteNames.budgetGoals),
                  _DrawerItem(Icons.savings_rounded, 'Savings Goals', RouteNames.savingsGoals),
                  _DrawerItem(Icons.flag_rounded, 'Future Expenses', RouteNames.futurePlanner),
                  _DrawerItem(Icons.lightbulb_rounded, 'Insights', RouteNames.insights),
                  const Divider(height: AppSizes.xl),
                  _DrawerItem(Icons.settings_rounded, 'Settings', RouteNames.settings),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  const _DrawerItem(this.icon, this.label, this.route);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: AppSizes.iconMd),
      title: Text(label, style: AppTextStyles.bodyLg),
      onTap: () {
        Navigator.of(context).pop();
        context.push(route);
      },
    );
  }
}
