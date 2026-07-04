/// Non-color, non-size constants: app metadata, default categories,
/// payment methods, and enums shared across layers.
class AppConstants {
  AppConstants._();

  static const String appName = 'FinMate';
  static const String appTagline = 'Track. Plan. Save.';
  static const String dbFileName = 'finmate.sqlite';
  static const String prefsAiEnabled = 'ai_features_enabled';
  static const String prefsOnboardingDone = 'onboarding_done';
  static const String prefsPinCode = 'pin_code';
  static const String prefsPinEnabled = 'pin_enabled';
  static const String prefsBiometricEnabled = 'biometric_enabled';
  static const String prefsLockTimeoutMinutes = 'lock_timeout_minutes';
  static const String prefsCurrency = 'currency_code';
  static const String prefsDarkMode = 'dark_mode';
  static const String prefsLanguage = 'language_code';

  static const List<String> defaultExpenseCategories = [
    'Food',
    'Travel',
    'Shopping',
    'Entertainment',
    'Bills',
    'Medical',
    'Fuel',
    'Rent',
    'Groceries',
    'Education',
    'Others',
  ];

  static const List<String> defaultIncomeCategories = [
    'Salary',
    'Freelance',
    'Business',
    'Investment',
    'Gift',
    'Refund',
    'Others',
  ];

  static const List<String> paymentMethods = [
    'UPI',
    'Cash',
    'Debit Card',
    'Credit Card',
    'Net Banking',
    'Wallet',
    'Other',
  ];

  static const List<String> subscriptionCycles = [
    'Weekly',
    'Monthly',
    'Quarterly',
    'Yearly',
  ];
}

enum TransactionType { income, expense }

enum TransactionSource { manual, imported }

enum SortOption { newest, oldest, highestAmount, lowestAmount }

enum ImportFileType { pdf, csv, xlsx, txt }

enum DeletionScope {
  today,
  yesterday,
  last7Days,
  last30Days,
  thisMonth,
  lastMonth,
  customRange,
  byCategory,
  importedOnly,
  manualOnly,
  incomeOnly,
  expenseOnly,
  everything,
}
