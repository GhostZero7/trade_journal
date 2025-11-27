import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ExcelExportService {
  Uint8List generateExcel(List<Map<String, dynamic>> trades) {
    final excel = Excel.createExcel();

    // DELETE default empty sheet or else Excel looks empty
    excel.delete('Sheet1');

    final Sheet sheet = excel['Trades'];

    // Header row
    sheet.appendRow([
      'Symbol',
      'Type',
      'Lot Size',
      'Profit',
      'Notes',
      'Created At'
    ]);

    for (var trade in trades) {
      final profit = trade['profit'] ?? 0;
      final timestamp = trade['createdAt'];

      String formattedDate = '';
      if (timestamp is Timestamp) {
        final d = timestamp.toDate();
        formattedDate =
            '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
            '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
      }

      sheet.appendRow([
        trade['symbol'] ?? '',
        trade['type'] ?? '',
        trade['amount'] ?? '',
        profit.toString(),
        trade['notes'] ?? '',
        formattedDate,
      ]);
    }

    final List<int>? fileBytes = excel.encode();
    return Uint8List.fromList(fileBytes!);
  }
}
