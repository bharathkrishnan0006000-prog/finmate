import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'route_names.dart';
import '../../presentation/splash/splash_screen.dart';
import '../../presentation/onboarding/onboarding_screen.dart';
import '../../presentation/common/root_shell.dart';
import '../../presentation/dashboard/dashboard_screen.dart';
import '../../presentation/transactions/transaction_list_screen.dart';
import '../../presentation/transactions/add_expense_screen.dart';
import '../../presentation/transactions/transaction_detail_screen.dart';
import '../../presentation/statement_import/upload_statement_screen.dart';
import '../../presentation/statement_import/categorize_transactions_screen.dart';
import '../../presentation/statement_import/import_review_screen.dart';
import '../../presentation/analytics/analytics_screen.dart';
import '../../presentation/subscriptions/subscriptions_screen.dart';
import '../../presentation/subscriptions/add_subscription_screen.dart';
import '../../presentation/future_planner/future_planner_screen.dart';
import '../../presentation/future_planner/add_future_expense_screen.dart';
import '../../presentation/budget_goals/budget_goals_screen.dart';
import '../../presentation/budget_goals/add_budget_goal_screen.dart';
import '../../presentation/savings_goals/savings_goals_screen.dart';
import '../../presentation/savings_goals/add_savings_goal_screen.dart';
import '../../presentation/insights/insights_screen.dart';
import '../../presentation/profile/profile_screen.dart';
import '../../presentation/settings/settings_screen.dart';
import '../../presentation/borrow_lend/borrow_lend_screen.dart';
import '../../presentation/borrow_lend/add_debt_screen.dart';
import '../../presentation/settings/category_management_screen.dart';
import '../../presentation/settings/bulk_delete_screen.dart';
import '../../data/database/app_database.dart';
import '../../data/models/parsed_transaction.dart';
import '../../data/repositories/debt_repository.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: RouteNames.splash,
  routes: [
    GoRoute(
      path: RouteNames.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: RouteNames.onboarding,
      builder: (context, state) => const OnboardingScreen(),
    ),

    // Bottom-nav shell: Dashboard / Transactions / Analytics / Planner / Profile
    ShellRoute(
      navigatorKey: shellNavigatorKey,
      builder: (context, state, child) => RootShell(child: child),
      routes: [
        GoRoute(
          path: RouteNames.dashboard,
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: RouteNames.transactions,
          builder: (context, state) => const TransactionListScreen(),
        ),
        GoRoute(
          path: RouteNames.futurePlanner,
          builder: (context, state) => const FuturePlannerScreen(),
        ),
        GoRoute(
          path: RouteNames.profile,
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),

    GoRoute(
      path: RouteNames.addExpense,
      builder: (context, state) {
        final txn = state.extra as Transaction?;
        return AddExpenseScreen(existing: txn);
      },
    ),
    GoRoute(
      path: RouteNames.transactionDetail,
      builder: (context, state) => TransactionDetailScreen(
        transaction: state.extra as Transaction,
      ),
    ),
    GoRoute(
      path: RouteNames.uploadStatement,
      builder: (context, state) => const UploadStatementScreen(),
    ),
    GoRoute(
      path: RouteNames.categorizeTransactions,
      builder: (context, state) => CategorizeTransactionsScreen(
        parsedTransactions: state.extra as List<ParsedTransaction>,
      ),
    ),
    GoRoute(
      path: RouteNames.importReview,
      builder: (context, state) => ImportReviewScreen(
        parsedTransactions: state.extra as List<ParsedTransaction>,
      ),
    ),
    GoRoute(
      path: RouteNames.analytics,
      builder: (context, state) => const AnalyticsScreen(),
    ),
    GoRoute(
      path: RouteNames.subscriptions,
      builder: (context, state) => const SubscriptionsScreen(),
    ),
    GoRoute(
      path: RouteNames.addSubscription,
      builder: (context, state) => AddSubscriptionScreen(
        existing: state.extra as Subscription?,
      ),
    ),
    GoRoute(
      path: RouteNames.addFutureExpense,
      builder: (context, state) => const AddFutureExpenseScreen(),
    ),
    GoRoute(
      path: RouteNames.budgetGoals,
      builder: (context, state) => const BudgetGoalsScreen(),
    ),
    GoRoute(
      path: RouteNames.addBudgetGoal,
      builder: (context, state) => AddBudgetGoalScreen(
        existing: state.extra as Budget?,
      ),
    ),
    GoRoute(
      path: RouteNames.savingsGoals,
      builder: (context, state) => const SavingsGoalsScreen(),
    ),
    GoRoute(
      path: RouteNames.addSavingsGoal,
      builder: (context, state) => AddSavingsGoalScreen(
        existing: state.extra as SavingsGoal?,
      ),
    ),
    GoRoute(
      path: RouteNames.insights,
      builder: (context, state) => const InsightsScreen(),
    ),
    GoRoute(
      path: RouteNames.settings,
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: RouteNames.borrowLend,
      builder: (context, state) => const BorrowLendScreen(),
    ),
    GoRoute(
      path: RouteNames.addDebt,
      builder: (context, state) => AddDebtScreen(
        initialType: (state.extra as DebtType?) ?? DebtType.borrowed,
      ),
    ),
    GoRoute(
      path: RouteNames.categoryManagement,
      builder: (context, state) => const CategoryManagementScreen(),
    ),
    GoRoute(
      path: RouteNames.bulkDelete,
      builder: (context, state) => const BulkDeleteScreen(),
    ),
  ],
);
