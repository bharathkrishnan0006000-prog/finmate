import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as xls;
import 'package:read_pdf_text/read_pdf_text.dart';
import 'package:intl/intl.dart';

import '../models/parsed_transaction.dart';
import '../../core/constants/app_constants.dart';
import '../../core/error/failures.dart';

/// Parses bank statements (PDF text, CSV, XLSX, TXT) into
/// [ParsedTransaction] rows. Critically: every row keeps the date found
/// *inside* the statement — never the date the file was uploaded.
///
/// Bank statement layouts vary a lot, so this uses tolerant heuristics:
/// - Header row detection by matching common column names
///   (date/description/narration/amount/debit/credit).
/// - A handful of common date formats.
/// - Credit columns/keywords -> Income, Debit columns/keywords -> Expense.
///
/// This is a best-effort generic parser. For a production release,
/// bank-specific adapters (SBI, HDFC, ICICI, etc.) can be layered on top
/// of this without changing the public API.
class StatementParserService {
  static const _dateFormats = [
    'dd/MM/yyyy',
    'dd-MM-yyyy',
    'dd MMM yyyy',
    'yyyy-MM-dd',
    'MM/dd/yyyy',
    'dd/MM/yy',
  ];

  DateTime? _tryParseDate(String raw) {
    final cleaned = raw.trim();
    if (cleaned.isEmpty) return null;
    for (final fmt in _dateFormats) {
      try {
        return DateFormat(fmt).parseStrict(cleaned);
      } catch (_) {
        continue;
      }
    }
    // Fallback: ISO-ish loose parse.
    return DateTime.tryParse(cleaned);
  }

  double? _tryParseAmount(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[₹,\s]'), '').replaceAll('Rs.', '');
    if (cleaned.isEmpty || cleaned == '-') return null;
    return double.tryParse(cleaned);
  }

  int _findColumn(List<String> headers, List<String> candidates) {
    for (var i = 0; i < headers.length; i++) {
      final h = headers[i].toLowerCase().trim();
      if (candidates.any((c) => h.contains(c))) return i;
    }
    return -1;
  }

  List<ParsedTransaction> _parseRows(List<List<dynamic>> rows) {
    if (rows.isEmpty) return [];
    final headers = rows.first.map((e) => e.toString()).toList();

    final dateCol = _findColumn(headers, ['date', 'txn date', 'value date']);
    final descCol = _findColumn(
        headers, ['description', 'narration', 'particulars', 'details']);
    final debitCol = _findColumn(headers, ['debit', 'withdrawal']);
    final creditCol = _findColumn(headers, ['credit', 'deposit']);
    final amountCol = _findColumn(headers, ['amount']);
    final typeCol = _findColumn(headers, ['type', 'cr/dr', 'dr/cr']);
    final refCol = _findColumn(headers, ['reference', 'ref no', 'cheque']);

    if (dateCol == -1) {
      throw const ImportFailure(
          'Could not find a date column in this statement. Please check the file format.');
    }

    final results = <ParsedTransaction>[];

    for (final row in rows.skip(1)) {
      if (row.length <= dateCol) continue;
      final date = _tryParseDate(row[dateCol].toString());
      if (date == null) continue;

      final description = descCol != -1 && descCol < row.length
          ? row[descCol].toString().trim()
          : 'Transaction';

      double? amount;
      TransactionType type;

      if (debitCol != -1 && creditCol != -1) {
        final debit = debitCol < row.length ? _tryParseAmount(row[debitCol].toString()) : null;
        final credit = creditCol < row.length ? _tryParseAmount(row[creditCol].toString()) : null;
        if (debit != null && debit > 0) {
          amount = debit;
          type = TransactionType.expense;
        } else if (credit != null && credit > 0) {
          amount = credit;
          type = TransactionType.income;
        } else {
          continue;
        }
      } else if (amountCol != -1 && typeCol != -1) {
        final rawAmount = amountCol < row.length ? _tryParseAmount(row[amountCol].toString()) : null;
        final rawType = typeCol < row.length ? row[typeCol].toString().toLowerCase() : '';
        if (rawAmount == null) continue;
        amount = rawAmount.abs();
        type = rawType.contains('cr') || rawType.contains('credit')
            ? TransactionType.income
            : TransactionType.expense;
      } else if (amountCol != -1) {
        final rawAmount = amountCol < row.length ? _tryParseAmount(row[amountCol].toString()) : null;
        if (rawAmount == null) continue;
        amount = rawAmount.abs();
        type = rawAmount < 0 ? TransactionType.expense : TransactionType.income;
      } else {
        continue;
      }

      results.add(ParsedTransaction(
        date: date,
        description: description.isEmpty ? 'Transaction' : description,
        amount: amount,
        type: type,
        referenceNumber:
            refCol != -1 && refCol < row.length ? row[refCol].toString() : '',
      ));
    }
    return results;
  }

  Future<List<ParsedTransaction>> parseCsv(File file) async {
    final content = await file.readAsString();
    final rows = const CsvToListConverter(eol: '\n').convert(content);
    return _parseRows(rows);
  }

  Future<List<ParsedTransaction>> parseXlsx(File file) async {
    final bytes = await file.readAsBytes();
    final book = xls.Excel.decodeBytes(bytes);
    final sheet = book.tables[book.tables.keys.first];
    if (sheet == null) return [];
    final rows = sheet.rows
        .map((r) => r.map((cell) => cell?.value?.toString() ?? '').toList())
        .toList();
    return _parseRows(rows);
  }

  Future<List<ParsedTransaction>> parseTxt(File file) async {
    final lines = await file.readAsLines();
    // Expect simple delimited lines: date,description,amount,type
    final rows = lines
        .where((l) => l.trim().isNotEmpty)
        .map((l) => l.split(RegExp(r'[,\t]')).map((e) => e.trim()).toList())
        .toList();
    if (rows.isEmpty) return [];
    // Prepend a synthetic header so _parseRows' heuristics still apply if
    // the first line looks like a header; otherwise assume a fixed order.
    final looksLikeHeader = rows.first.any(
        (c) => ['date', 'description', 'amount'].contains(c.toLowerCase()));
    if (looksLikeHeader) return _parseRows(rows);

    final results = <ParsedTransaction>[];
    for (final row in rows) {
      if (row.length < 3) continue;
      final date = _tryParseDate(row[0]);
      final amount = _tryParseAmount(row[2]);
      if (date == null || amount == null) continue;
      final type = row.length > 3 && row[3].toLowerCase().contains('income')
          ? TransactionType.income
          : TransactionType.expense;
      results.add(ParsedTransaction(
        date: date,
        description: row[1],
        amount: amount.abs(),
        type: type,
      ));
    }
    return results;
  }

  /// Best-effort bank name detection from statement text/filename — used
  /// to tag transactions and to pick date-format preference, since a few
  /// major Indian banks default to different date orderings.
  String detectBank(String text) {
    final lower = text.toLowerCase();
    const banks = {
      'sbi': 'State Bank of India',
      'state bank of india': 'State Bank of India',
      'hdfc': 'HDFC Bank',
      'icici': 'ICICI Bank',
      'axis': 'Axis Bank',
      'kotak': 'Kotak Mahindra Bank',
      'pnb': 'Punjab National Bank',
      'bank of baroda': 'Bank of Baroda',
    };
    for (final entry in banks.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return '';
  }

  /// Shared line-based regex extraction used for both text-based PDFs and
  /// camera-scanned (OCR) statements — same input shape (raw text),
  /// same output shape (ParsedTransaction list).
  List<ParsedTransaction> parseTextLines(String text) {
    final bank = detectBank(text);
    final lineRegex = RegExp(
      r'(\d{1,2}[\/\-][A-Za-z0-9]{2,4}[\/\-]\d{2,4})\s+(.+?)\s+([\d,]+\.\d{2})\s*(Cr|Dr|CR|DR)?',
    );

    final results = <ParsedTransaction>[];
    for (final line in text.split('\n')) {
      final match = lineRegex.firstMatch(line);
      if (match == null) continue;
      final date = _tryParseDate(match.group(1)!);
      final amount = _tryParseAmount(match.group(3)!);
      if (date == null || amount == null) continue;
      final marker = (match.group(4) ?? '').toLowerCase();
      final type = marker == 'cr' ? TransactionType.income : TransactionType.expense;
      results.add(ParsedTransaction(
        date: date,
        description: match.group(2)!.trim(),
        amount: amount,
        type: type,
        bankName: bank,
      ));
    }
    return results;
  }

  /// Extracts raw text via native PDF text extraction (no OCR — this
  /// only works for text-based/selectable PDFs, per the agreed v1
  /// scope). Then applies line-based heuristics to find
  /// date/description/amount/Cr-Dr patterns.
  Future<List<ParsedTransaction>> parsePdf(File file) async {
    late final String text;
    try {
      text = await ReadPdfText.getPDFtext(file.path);
    } catch (e) {
      throw ImportFailure(
          'Could not read text from this PDF. If it is a scanned/image statement, use "Scan with Camera" instead. ($e)');
    }

    final results = parseTextLines(text);
    if (results.isEmpty) {
      throw const ImportFailure(
          'No transactions could be detected in this PDF. If it\'s a scanned statement, try "Scan with Camera" or export as CSV/Excel for best results.');
    }
    return results;
  }

  Future<List<ParsedTransaction>> parseFile(File file, ImportFileType type) {
    switch (type) {
      case ImportFileType.csv:
        return parseCsv(file);
      case ImportFileType.xlsx:
        return parseXlsx(file);
      case ImportFileType.txt:
        return parseTxt(file);
      case ImportFileType.pdf:
        return parsePdf(file);
    }
  }

  ImportFileType? typeFromExtension(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'csv':
        return ImportFileType.csv;
      case 'xlsx':
      case 'xls':
        return ImportFileType.xlsx;
      case 'txt':
        return ImportFileType.txt;
      case 'pdf':
        return ImportFileType.pdf;
      default:
        return null;
    }
  }
}
