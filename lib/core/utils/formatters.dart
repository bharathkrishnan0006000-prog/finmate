import 'package:intl/intl.dart';

/// Central place for all display formatting so every screen renders
/// amounts and dates identically.
class AppFormatters {
  AppFormatters._();

  /// Currency symbol is resolved from Settings at app start and cached
  /// here so widgets don't need to watch a provider just to format text.
  static String currencySymbol = '\u20B9'; // ₹ default (INR)

  static NumberFormat get _amountFormat =>
      NumberFormat.currency(locale: 'en_IN', symbol: currencySymbol, decimalDigits: 2);

  static NumberFormat get _amountFormatNoDecimals =>
      NumberFormat.currency(locale: 'en_IN', symbol: currencySymbol, decimalDigits: 0);

  static String amount(double value, {bool withDecimals = true}) {
    return withDecimals
        ? _amountFormat.format(value)
        : _amountFormatNoDecimals.format(value);
  }

  static String amountSigned(double value, {required bool isIncome}) {
    final formatted = amount(value.abs());
    return isIncome ? '+$formatted' : '-$formatted';
  }

  static String compactAmount(double value) {
    if (value.abs() >= 10000000) {
      return '$currencySymbol${(value / 10000000).toStringAsFixed(1)}Cr';
    } else if (value.abs() >= 100000) {
      return '$currencySymbol${(value / 100000).toStringAsFixed(1)}L';
    } else if (value.abs() >= 1000) {
      return '$currencySymbol${(value / 1000).toStringAsFixed(1)}K';
    }
    return amount(value, withDecimals: false);
  }

  static String date(DateTime date) => DateFormat('d MMM yyyy').format(date);

  static String dateShort(DateTime date) => DateFormat('d MMM').format(date);

  static String dayMonthYearTime(DateTime date) =>
      DateFormat('d MMM yyyy, h:mm a').format(date);

  static String time(DateTime date) => DateFormat('h:mm a').format(date);

  static String monthYear(DateTime date) => DateFormat('MMMM yyyy').format(date);

  static String relativeDay(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff == -1) return 'Tomorrow';
    if (diff > 1 && diff < 7) return DateFormat('EEEE').format(date);
    return AppFormatters.date(date);
  }

  static String percentage(double value) => '${value.toStringAsFixed(0)}%';
}
