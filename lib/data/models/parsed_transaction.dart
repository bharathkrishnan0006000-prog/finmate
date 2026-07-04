import '../../core/constants/app_constants.dart';

/// Intermediate representation for a row extracted from an imported bank
/// statement, before it becomes a full Transaction in the database.
/// Keeping this separate lets the "Categorize Transactions" and
/// "duplicate review" screens work with lightweight, mutable objects.
class ParsedTransaction {
  final DateTime date;
  final String rawTime;
  final String description;
  final double amount;
  final TransactionType type; // derived from Credit/Debit
  final String referenceNumber;
  final String bankName;
  String category;
  bool isDuplicate;
  bool includeInImport;

  ParsedTransaction({
    required this.date,
    this.rawTime = '',
    required this.description,
    required this.amount,
    required this.type,
    this.referenceNumber = '',
    this.bankName = '',
    this.category = 'Others',
    this.isDuplicate = false,
    this.includeInImport = true,
  });
}

/// Summary shown on the "Imported Transactions" review screen.
class ImportSummary {
  final int totalParsed;
  final int duplicatesFound;
  final int skipped;
  final int incomeImported;
  final int expenseImported;
  final double totalIncomeAmount;
  final double totalExpenseAmount;

  const ImportSummary({
    required this.totalParsed,
    required this.duplicatesFound,
    required this.skipped,
    required this.incomeImported,
    required this.expenseImported,
    required this.totalIncomeAmount,
    required this.totalExpenseAmount,
  });
}
