import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfExportService {
  // Utility function to format timestamp
  String _formatTimestamp(dynamic ts) {
    if (ts == null) return 'N/A';
    if (ts is Timestamp) {
      final d = ts.toDate();
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }
    return ts.toString();
  }

  Future<Uint8List> generateTradeReport(List<Map<String, dynamic>> trades) async {
    final pdf = pw.Document();

    // Calculate summary statistics
    double totalProfit = 0;
    int wins = 0;
    int losses = 0;

    for (var trade in trades) {
      final profit = double.tryParse(trade['profit'].toString()) ?? 0.0;
      totalProfit += profit;
      if (profit >= 0) {
        wins++;
      } else {
        losses++;
      }
    }

    final winRate = trades.isEmpty ? 0.0 : (wins / trades.length) * 100;
    
    // --- Document Structure ---

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Trading Journal Report',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.green700),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'Generated on: ${_formatTimestamp(Timestamp.now())}',
                style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
              ),
              pw.Divider(color: PdfColors.grey300),
            ],
          );
        },
        
        build: (pw.Context context) {
          return [
            // --- Summary Section ---
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.green50,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.green100),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Summary Statistics', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                  pw.SizedBox(height: 8),
                  _buildSummaryRow('Total Trades:', trades.length.toString()),
                  _buildSummaryRow('Total P&L:', (totalProfit >= 0 ? '+' : '') + '\$${totalProfit.toStringAsFixed(2)}', 
                      color: totalProfit >= 0 ? PdfColors.green800 : PdfColors.red800),
                  _buildSummaryRow('Win Rate:', '${winRate.toStringAsFixed(2)}%'),
                  _buildSummaryRow('Wins / Losses:', '$wins / $losses'),
                ],
              ),
            ),
            
            pw.SizedBox(height: 20),

            pw.Text(
              'Detailed Trade List',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
            ),
            
            pw.SizedBox(height: 10),

            // --- Trades Table ---
            pw.Table.fromTextArray(
              headers: ['Pair', 'Type', 'Amount (Lots)', 'Profit/Loss (\$)', 'Date'],
              data: trades.map((trade) {
                final profit = double.tryParse(trade['profit'].toString()) ?? 0.0;
                final profitString = (profit >= 0 ? '+' : '') + profit.toStringAsFixed(2);
                
                return [
                  trade['symbol'] ?? 'N/A',
                  trade['type'] ?? 'N/A',
                  trade['amount'] ?? 'N/A',
                  profitString,
                  _formatTimestamp(trade['createdAt']),
                ];
              }).toList(),
              
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.green500),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.all(6),
              rowDecoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey100, width: 0.5)),
              ),
              
              columnWidths: {
                0: const pw.FlexColumnWidth(2), // Pair
                1: const pw.FlexColumnWidth(1.5), // Type
                2: const pw.FlexColumnWidth(2), // Lots
                3: const pw.FlexColumnWidth(2.5), // P/L
                4: const pw.FlexColumnWidth(3), // Date
              },
            ),
            
            pw.SizedBox(height: 20),
            
            pw.Center(
              child: pw.Text(
                'End of Report',
                style: const pw.TextStyle(color: PdfColors.grey500),
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // Helper for summary rows
  pw.Widget _buildSummaryRow(String label, String value, {PdfColor color = PdfColors.black}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 14)),
          pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: color)),
        ],
      ),
    );
  }
}