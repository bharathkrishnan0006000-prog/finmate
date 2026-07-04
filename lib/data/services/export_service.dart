import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as xls;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

import '../database/app_database.dart';
import '../../core/utils/formatters.dart';

/// Generates CSV / Excel / PDF exports of transactions and writes them
/// to the app's documents directory, ready to share via share_plus.
/// Entirely offline — no network calls.
class ExportService {
  Future<File> _targetFile(String extension) async {
    final dir = await getApplicationDocumentsDirectory();
    final exportsDir = Directory('${dir.path}/exports');
    if (!await exportsDir.exists()) {
      await exportsDir.create(recursive: true);
    }
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    return File('${exportsDir.path}/finmate_export_$stamp.$extension');
  }

  Future<File> exportCsv(List<Transaction> transactions) async {
    final rows = <List<dynamic>>[
      ['Date', 'Title', 'Category', 'Type', 'Amount', 'Payment Method', 'Notes'],
      ...transactions.map((t) => [
            AppFormatters.date(t.date),
            t.title,
            t.category,
            t.type,
            t.amount.toStringAsFixed(2),
            t.paymentMethod,
            t.notes,
          ]),
    ];
    final csvData = const ListToCsvConverter().convert(rows);
    final file = await _targetFile('csv');
    await file.writeAsString(csvData);
    return file;
  }

  Future<File> exportExcel(List<Transaction> transactions) async {
    final book = xls.Excel.createExcel();
    final sheet = book['Transactions'];
    sheet.appendRow([
      xls.TextCellValue('Date'),
      xls.TextCellValue('Title'),
      xls.TextCellValue('Category'),
      xls.TextCellValue('Type'),
      xls.TextCellValue('Amount'),
      xls.TextCellValue('Payment Method'),
      xls.TextCellValue('Notes'),
    ]);
    for (final t in transactions) {
      sheet.appendRow([
        xls.TextCellValue(AppFormatters.date(t.date)),
        xls.TextCellValue(t.title),
        xls.TextCellValue(t.category),
        xls.TextCellValue(t.type),
        xls.DoubleCellValue(t.amount),
        xls.TextCellValue(t.paymentMethod),
        xls.TextCellValue(t.notes),
      ]);
    }
    final bytes = book.encode()!;
    final file = await _targetFile('xlsx');
    await file.writeAsBytes(bytes);
    return file;
  }

  Future<File> exportPdf(
    List<Transaction> transactions, {
    required double totalIncome,
    required double totalExpense,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('FinMate — Transaction Report',
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Text('Generated on ${AppFormatters.date(DateTime.now())}'),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Total Income: ${AppFormatters.amount(totalIncome)}'),
              pw.Text('Total Expense: ${AppFormatters.amount(totalExpense)}'),
              pw.Text('Balance: ${AppFormatters.amount(totalIncome - totalExpense)}'),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Table.fromTextArray(
            headers: ['Date', 'Title', 'Category', 'Type', 'Amount'],
            data: transactions
                .map((t) => [
                      AppFormatters.date(t.date),
                      t.title,
                      t.category,
                      t.type,
                      AppFormatters.amount(t.amount),
                    ])
                .toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          ),
        ],
      ),
    );
    final file = await _targetFile('pdf');
    await file.writeAsBytes(await doc.save());
    return file;
  }
}
