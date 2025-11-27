import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart'; // Mobile-specific import restored
import 'dart:io'; // Mobile-specific import restored
import 'package:open_filex/open_filex.dart'; // Mobile-specific import restored

import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_service.dart';
import '../../providers/trades_provider.dart';
import '../../core/theme/text_styles.dart';
import '../../services/pdf_export_service.dart';
import '../../services/excel_export_service.dart';

class AllTradesScreen extends StatelessWidget {
  const AllTradesScreen({super.key});

  AppColors _getTheme(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    return themeService.isDarkMode ? AppColors.dark : AppColors.light;
  }

  String _formatTimestamp(dynamic ts) {
    if (ts == null) return '';
    if (ts is Timestamp) {
      final d = ts.toDate();
      return '${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
    }
    return ts.toString();
  }

  // Mobile file saving logic (restored as requested)
  Future<void> _saveFile(BuildContext context, Uint8List data, String filename) async {
    final theme = _getTheme(context);
    final dir = await getExternalStorageDirectory();
    final file = File('${dir!.path}/$filename');

    await file.writeAsBytes(data);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("File saved to ${file.path}", style: TextStyle(color: theme.textLight)),
        backgroundColor: theme.cardDark,
      ),
    );

    await OpenFilex.open(file.path);
  }

  Future<void> _exportToExcel(BuildContext context) async {
    final tradesProvider = Provider.of<TradesProvider>(context, listen: false);
    final trades = tradesProvider.trades;
    final theme = _getTheme(context);
    const filename = "trades_report.xlsx";

    if (trades.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Cannot export: No trades available",
                style: TextStyle(color: theme.textLight)),
            backgroundColor: theme.cardDark),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text("Generating Excel...", style: TextStyle(color: theme.textLight)),
          backgroundColor: theme.cardDark),
    );

    try {
      final excelService = ExcelExportService();
      final bytes = excelService.generateExcel(trades);

      // Using mobile file save logic
      await _saveFile(context, bytes, filename);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Excel generation failed: $e")),
      );
    }
  }

  Future<void> _exportToPdf(BuildContext context) async {
    final tradesProvider = Provider.of<TradesProvider>(context, listen: false);
    final trades = tradesProvider.trades;
    final theme = _getTheme(context);
    const filename = "trades_report.pdf";

    if (trades.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Cannot export: No trades available",
                style: TextStyle(color: theme.textLight)),
            backgroundColor: theme.cardDark),
      );
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Generating PDF...", style: TextStyle(color: theme.textLight)),
            backgroundColor: theme.cardDark),
      );
      
      final pdfService = PdfExportService();
      final bytes = await pdfService.generateTradeReport(trades);

      // Using mobile file save logic
      await _saveFile(context, bytes, filename);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("PDF generation failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = _getTheme(context);
    final tradesProvider = Provider.of<TradesProvider>(context);

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.background,
        elevation: 0,
        title: Text(
          "All Trades (${tradesProvider.trades.length})",
          style: AppTextStyles.heading2(color: theme.primary).copyWith(fontSize: 22),
        ),
        iconTheme: IconThemeData(color: theme.textLight),
        actions: [
          IconButton(
            // Use meaningful colors for actions
            icon: Icon(Icons.picture_as_pdf, color: theme.error),
            onPressed: () => _exportToPdf(context),
            tooltip: 'Export as PDF',
          ),
          IconButton(
            // Use meaningful colors for actions
            icon: Icon(Icons.table_view, color: theme.success),
            onPressed: () => _exportToExcel(context),
            tooltip: 'Export as Excel',
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: tradesProvider.isLoading
          ? Center(child: CircularProgressIndicator(color: theme.primary))
          : tradesProvider.trades.isEmpty
              ? Center(child: Text("No trades added yet", style: TextStyle(color: theme.textFaded)))
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: tradesProvider.trades.length,
                  itemBuilder: (context, index) {
                    final trade = tradesProvider.trades[index];
                    final profit = double.tryParse(trade['profit'].toString()) ?? 0;
                    final isWin = profit >= 0;
                    // Retrieve the strategy, default to 'Custom' if missing/null
                    final strategy = trade['strategy'] as String? ?? 'Custom';

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.cardDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: (isWin ? theme.success : theme.error).withOpacity(0.4),
                          width: 1.3,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header (Symbol + Strategy + P&L)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Row(
                                  children: [
                                    Text("${trade['symbol']}", style: AppTextStyles.heading3(color: theme.textLight)),
                                    const SizedBox(width: 8),
                                    // Strategy Tag
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: theme.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        strategy,
                                        style: TextStyle(
                                          color: theme.primary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // P&L
                              Text(
                                (isWin ? "+" : "") + "\$${profit.toStringAsFixed(2)}",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: isWin ? theme.success : theme.error,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 6),

                          // Type + Amount
                          Text(
                            "${trade['type']} | ${trade['amount']} lots",
                            style: TextStyle(color: theme.textFaded),
                          ),

                          const SizedBox(height: 6),

                          // Timestamp
                          Text(
                            _formatTimestamp(trade["createdAt"]),
                            style: TextStyle(color: theme.textFaded),
                          ),

                          if (trade["notes"] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                "Notes: ${trade['notes']}",
                                style: TextStyle(color: theme.textFaded),
                              ),
                            )
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}